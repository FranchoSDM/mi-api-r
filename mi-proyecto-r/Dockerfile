# Usamos una imagen base de R oficial y moderna
FROM rocker/r-ver:4.4

# Instalamos librerías del sistema que R necesita para los paquetes
RUN apt-get update -qq && apt-get install -y \
  libssl-dev \
  libcurl4-openssl-dev \
  libxml2-dev

# Instalamos los paquetes de R que tu script necesita
RUN R -e "install.packages(c('plumber', 'tidyverse', 'readxl', 'writexl'))"

# Copiamos los dos archivos de nuestro proyecto (tu API y el lanzador)
# dentro del contenedor que estamos construyendo.
COPY api.R /srv/api.R
COPY run_api.R /srv/run_api.R

# Establecemos el directorio de trabajo
WORKDIR /srv

# Le decimos a Google que nuestro servicio se ejecutará en el puerto 8080
EXPOSE 8080

# El comando final para arrancar la API cuando el contenedor se inicie
CMD ["Rscript", "run_api.R"]
