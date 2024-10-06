
# speedtest-ookla-docker

Proyecto basado en Docker y Docker Compose para desplegar un servidor Ookla Speedtest con Nginx y Let's Encrypt para SSL. Este repositorio proporciona una configuración completa para configurar un servidor de pruebas de velocidad con renovación automática de certificados SSL.

## Requisitos

- **Docker**: [Instalar Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Instalar Docker Compose](https://docs.docker.com/compose/install/)
- **IP Pública**
- **Subdominio Configurado**

## Instalación y configuración

1. Clona el repositorio:

   ```bash
   git clone https://github.com/leaffre/speedtest-ookla-docker.git
   cd speedtest-ookla-docker
   ```

2. Edita el archivo `Dockerfile` si es necesario. Las siguientes variables están definidas en el Dockerfile:

   - `DOMAIN_ALLOWED`: Dominio principal autorizado (ejemplo: `tusitio.com`)
   - `DOMAIN`: El subdominio donde se desplegará el servidor Speedtest (ejemplo: `speedtest.tusitio.com`)
   - `EMAIL`: Correo electrónico para Let's Encrypt (ejemplo: `tuemail@tusitio.com`)
   - `TZ`: Zona horaria (ejemplo: `America/Argentina/Buenos_Aires`)

3. Construye y levanta el contenedor con Docker Compose:

   ```bash
   docker-compose up -d --build
   ```

   El servidor debería estar corriendo en el puerto 80 para HTTP y en el puerto 443 para HTTPS. Puedes acceder al servidor en tu navegador utilizando el subdominio configurado.

## Variables de Entorno

Las siguientes variables están definidas en el `Dockerfile` y pueden modificarse según tus necesidades:

- `DOMAIN_ALLOWED`: El dominio principal autorizado para acceder al servidor de pruebas.
- `DOMAIN`: El subdominio donde se desplegará el servidor de pruebas.
- `EMAIL`: Correo electrónico del administrador para obtener los certificados SSL con Let's Encrypt.
- `TZ`: Zona horaria del servidor.

Estas variables se configuran dentro del Dockerfile para facilitar la personalización del entorno según el uso deseado.

## Renovación Automática de SSL

El contenedor está configurado para solicitar certificados SSL automáticamente de Let's Encrypt en su primer inicio. Certbot gestiona los certificados SSL. Para garantizar la renovación automática antes de los 90 días, **cron** se ha configurado dentro del contenedor para ejecutar la renovación periódica de los certificados:

```bash
0 0,12 * * * root nginx -s stop && certbot renew --quiet && nginx -s reload
```

Este cron job detiene temporalmente Nginx, renueva los certificados SSL y reinicia Nginx automáticamente.

## Directorios y Archivos Importantes

El contenedor crea y utiliza los siguientes directorios y archivos clave:

- `/etc/letsencrypt/`: Contiene los certificados SSL generados por Let's Encrypt.
- `/var/www/html/speedtest/`: Aquí se aloja el contenido estático del servidor de pruebas, incluyendo archivos como `crossdomain.xml` y `latency.txt`.

## Acceso al Servidor

Una vez que el contenedor esté funcionando, accede al servidor utilizando el subdominio que configuraste:

```bash
https://speedtest.tusitio.com:8080 y http://speedtest.tusitio.com:8080
```

Si todo está configurado correctamente, verás la página del servidor Speedtest. También puedes verificar el estado del servidor con el [Host Tester de Speedtest](https://www.speedtest.net/host-tester).



## Solución de Problemas

### Errores comunes:

1. **"Connection reset by peer"**: Esto puede deberse a limitaciones de timeout o exceso de conexiones simultáneas. Asegúrate de revisar los ajustes de tiempo en Nginx en el `nginx.conf`.

2. **Fallo en la obtención de certificados SSL**: Asegúrate de que el puerto 80 esté disponible para Let's Encrypt y de que la IP pública y el dominio estén correctamente configurados.

---

¡Gracias por usar este proyecto! Si tienes alguna duda o problema, no dudes en abrir un issue en el repositorio de GitHub.
