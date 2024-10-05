# speedtest-ookla-docker

Proyecto basado en Docker y Docker Compose para desplegar un servidor Ookla Speedtest con Nginx y Let's Encrypt para SSL. Este repositorio proporciona una configuración completa para configurar un servidor de pruebas de velocidad con renovación automática de certificados SSL.

## Requisitos

- **Docker**: [Instalar Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Instalar Docker Compose](https://docs.docker.com/compose/install/)

## Instalación y configuración

1. Clona el repositorio:

   ```bash
   git clone https://github.com/leaffre/speedtest-ookla-docker.git
   cd speedtest-ookla-docker
   
Edita el archivo Dockerfile si es necesario. Por defecto, las siguientes variables están definidas en el Dockerfile:

    DOMAIN_ALLOWED: Dominio principal autorizado (ejemplo: tusitio.com)
    DOMAIN: El subdominio donde se desplegará el servidor Speedtest (ejemplo: speedtest.tusitio.com)
    EMAIL: Correo electrónico para Let's Encrypt (ejemplo: tuemail@tusitio.com)
    TZ: Zona horaria (ejemplo: America/Argentina/Buenos_Aires)

Construye y levanta el contenedor con Docker Compose:

    docker-compose up -d --build

    El servidor debería estar corriendo en el puerto 80 para HTTP y en el puerto 443 para HTTPS. Puedes acceder al servidor en tu navegador utilizando el dominio que configuraste.

## Variables de Entorno

Estas son las variables que puedes ajustar dentro del Dockerfile:

    DOMAIN_ALLOWED: El dominio principal autorizado para acceder al servidor de pruebas.
    DOMAIN: El subdominio donde se desplegará el servidor de pruebas.
    EMAIL: Correo electrónico del administrador para obtener los certificados SSL con Let's Encrypt.
    TZ: Zona horaria del servidor.

Estas variables están configuradas directamente en el Dockerfile para que se pueda modificar según su entorno.



## Renovación Automática de SSL

El contenedor está configurado para solicitar certificados SSL automáticamente de Let's Encrypt en su primer inicio. Certbot se encargará de gestionar el certificado. Para garantizar la renovación automática antes de los 90 días, se recomienda configurar un cron job en el host o dentro del contenedor para ejecutar la renovación periódica de los certificados.

## Directorios y Archivos Importantes

El contenedor crea y utiliza algunos directorios y archivos importantes para su funcionamiento:

    /etc/letsencrypt/: Contiene los certificados SSL generados por Let's Encrypt.
    /var/www/html/speedtest/: Aquí se aloja el contenido estático para el servidor de pruebas, incluyendo los archivos crossdomain.xml y latency.txt.


Accede al servidor en tu navegador utilizando el subdominio que configuraste. Ejemplo:

https://speedtest.tusitio.com

Si todo funciona correctamente, verás la página de pruebas de velocidad y podrás comenzar a realizar pruebas.
