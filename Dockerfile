# Usar una imagen base de Ubuntu
FROM ubuntu

# Establecer el directorio de trabajo
WORKDIR /

# Definir variables de entorno directamente en el Dockerfile
ENV DOMAIN_ALLOWED=tusitio.com \
    DOMAIN=speedtest.tusitio.com \
    EMAIL=tuemail@tusitio.com \
    TZ=America/Argentina/Buenos_Aires

# Paso 1: Actualizar el sistema e instalar Certbot, Ookla, Nginx, cron y otras utilidades necesarias
RUN apt-get update && apt-get install -y \
    wget certbot tzdata curl apt-utils libssl-dev \
    libpng-dev libjpeg-dev unzip openssl nginx cron

# Paso 2: Configurar la zona horaria según la variable de entorno TZ
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Paso 3: Descargar e instalar el servidor Ookla
RUN wget http://install.speedtest.net/ooklaserver/ooklaserver.sh && \
    chmod a+x ooklaserver.sh && ./ooklaserver.sh install -f

# Paso 4: Desactivar Let's Encrypt interno de Ookla y ajustar propiedades
RUN if [ -f /OoklaServer.properties ]; then \
      sed -i 's|# OoklaServer.ssl.useLetsEncrypt = true|OoklaServer.ssl.useLetsEncrypt = false|' /OoklaServer.properties && \
      sed -i "s|# OoklaServer.allowedDomains = .*|OoklaServer.allowedDomains = *.ookla.com, *.speedtest.net, *.$DOMAIN_ALLOWED|" /OoklaServer.properties && \
      sed -i 's|# OoklaServer.enableAutoUpdate = true|OoklaServer.enableAutoUpdate = false|' /OoklaServer.properties; \
  else \
      echo "El archivo OoklaServer.properties no se encontró"; \
  fi

# Paso 5: Crear el directorio para speedtest y generar crossdomain.xml y latency.txt
RUN mkdir -p /var/www/html/speedtest && \
    echo '<cross-domain-policy> \
    <allow-access-from domain="*.ookla.com" to-ports="5060,8080"/> \
    <allow-access-from domain="*.speedtest.net" to-ports="5060,8080"/> \
    <allow-access-from domain="*.'"$DOMAIN_ALLOWED"'" to-ports="5060,8080"/> \
    <allow-access-from domain="*.speedtestcustom.com" to-ports="5060,8080"/> \
  </cross-domain-policy>' > /var/www/html/speedtest/crossdomain.xml && \
    echo "test=test" > /var/www/html/speedtest/latency.txt

# Paso 6: Configurar Nginx para manejar HTTP y HTTPS con ajustes de timeout
RUN echo "events { \
    worker_connections 4096; \
} \
http { \
    client_header_timeout 30s; \
    client_body_timeout 30s; \
    proxy_read_timeout 30s; \
    proxy_send_timeout 30s; \
    keepalive_timeout 65s; \
    send_timeout 30s; \
    server { \
        listen 80; \
        server_name ${DOMAIN}; \
        location /speedtest/ { \
            proxy_pass http://localhost:8080; \
            proxy_http_version 1.1; \
            proxy_set_header Upgrade \$http_upgrade; \
            proxy_set_header Connection 'Upgrade'; \
            proxy_set_header Host \$host; \
            proxy_set_header X-Real-IP \$remote_addr; \
            autoindex on; \
        } \
    } \
    server { \
        listen 443 ssl; \
        server_name ${DOMAIN}; \
        ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem; \
        ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem; \
        ssl_protocols TLSv1.2 TLSv1.3; \
        ssl_prefer_server_ciphers on; \
        ssl_ciphers HIGH:!aNULL:!MD5; \
        location /speedtest/ { \
            proxy_pass http://localhost:8080; \
            proxy_http_version 1.1; \
            proxy_set_header Upgrade \$http_upgrade; \
            proxy_set_header Connection 'Upgrade'; \
            proxy_set_header Host \$host; \
            proxy_set_header X-Real-IP \$remote_addr; \
            autoindex on; \
        } \
    } \
}" > /etc/nginx/nginx.conf

# Paso 7: Crear un volumen para los certificados persistentes de Let's Encrypt
VOLUME /etc/letsencrypt

# Paso 8: Configurar cron para renovar automáticamente el certificado SSL y detener Nginx antes
RUN echo "0 0,12 * * * root nginx -s stop && certbot renew --quiet && nginx -s reload" >> /etc/crontab

# Exponer los puertos necesarios
EXPOSE 80 443 8080 5060

# Paso 9: Ejecutar el script de inicio para manejar Nginx, el servidor Ookla y cron
CMD bash -c ' \
  # Iniciar cron para renovación automática del certificado \
  service cron start; \
  \
  # Detener Nginx si ya está corriendo \
  if pgrep nginx > /dev/null; then \
    echo "Deteniendo Nginx temporalmente para permitir a Certbot usar el puerto 80..." && \
    nginx -s stop; \
  fi; \
  \
  # Generar certificados SSL con Certbot si no existen \
  if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then \
    echo "Certificado SSL no encontrado. Intentando obtener uno nuevo con Certbot..." && \
    certbot certonly --standalone --non-interactive --agree-tos --email $EMAIL -d $DOMAIN; \
    if [ $? -ne 0 ]; then echo "Error al generar el certificado SSL con Certbot." && exit 1; fi; \
    echo "Certificado SSL generado exitosamente."; \
  else \
    echo "Certificado SSL ya existe. Reutilizándolo."; \
  fi; \
  \
  # Configurar Ookla para usar los certificados generados por Let's Encrypt \
  if [ -f /OoklaServer.properties ]; then \
    echo "openSSL.server.certificateFile = /etc/letsencrypt/live/$DOMAIN/fullchain.pem" >> /OoklaServer.properties && \
    echo "openSSL.server.privateKeyFile = /etc/letsencrypt/live/$DOMAIN/privkey.pem" >> /OoklaServer.properties && \
    echo "openSSL.server.minimumTLSProtocol = 1.2" >> /OoklaServer.properties; \
  else \
    echo "El archivo OoklaServer.properties no se encontró"; \
  fi; \
  \
  # Iniciar el servidor Ookla y Nginx \
  trap "exit 0" SIGTERM; ./OoklaServer & nginx -g "daemon off;" && tail -f /dev/null'
