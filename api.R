# ===================================================================
# PASO 0: CARGAR LIBRERÍAS
# ===================================================================
# install.packages(c("plumber", "tidyverse", "readxl", "writexl"))

library(plumber)
library(tidyverse)
library(readxl)
library(writexl)

#* @apiTitle API de Reportes de Vencimiento
#* @apiDescription Recibe 5 archivos Excel, los procesa y devuelve el reporte final.

### PLUMBER: Con @post /procesar, creamos un "endpoint" o URL.
### Make llamará a https://tu-servidor.com/procesar
#* @post /procesar
procesar_reporte <- function(req) {

  # ===================================================================
  # PASO 1: LEER LOS 5 ARCHIVOS ENVIADOS POR MAKE
  # ===================================================================
  ### Se leen los archivos desde el cuerpo ("body") de la petición HTTP.
  ### Los nombres (archivo_b2b, archivo_polizas, etc.) deben coincidir
  ### con las "Key" que configuraste en el módulo HTTP de Make.
  
  # req$body contiene los archivos. La parte "$datapath" nos da la ubicación temporal.
  clientes_b2b       <- read_excel(req$body$archivo_b2b$datapath)
  polizas            <- read_excel(req$body$archivo_polizas$datapath)
  asistencia_api     <- read_excel(req$body$archivo_api$datapath) # Este es el de 2025
  asistencia_2023    <- read_excel(req$body$archivo_2023$datapath)
  asistencia_2024    <- read_excel(req$body$archivo_2024$datapath)

  # ===================================================================
  # PASO 2: UNIFICAR LOS TRES ARCHIVOS DE HISTORIAL DE ASISTENCIA
  # ===================================================================
  # Se combinan los historiales de 2023, 2024 y el archivo de API/2025.
  asistencia_unificada <- bind_rows(
    asistencia_2023,
    asistencia_2024,
    asistencia_api
  ) %>%
    mutate(`NUM_POLIZA` = as.character(`NUM_POLIZA`))

  # ===================================================================
  # PASO 3 a 7: TU LÓGICA DE CRUCES Y SELECCIÓN (ESTO QUEDA IGUAL)
  # ===================================================================
  polizas_modificada <- polizas %>%
    mutate(
      Poliza_Completa = toupper(paste(trimws(Ramo), trimws(`Número de póliza`), sep = "-"))
    )

  asistencia_limpia <- asistencia_unificada %>%
    mutate(
      NUM_POLIZA_LIMPIA = toupper(trimws(as.character(NUM_POLIZA)))
    )

  cruce_polizas_asistencia <- left_join(
    polizas_modificada,
    asistencia_limpia,
    by = c("Poliza_Completa" = "NUM_POLIZA_LIMPIA")
  )

  cruce_final <- left_join(
    cruce_polizas_asistencia %>% mutate(Mapfre_Id_Limpio = toupper(trimws(`Mapfre Id`))),
    clientes_b2b %>% mutate(Mapfre_Id_Limpio = toupper(trimws(as.character(`Mapfre Id`)))),
    by = "Mapfre_Id_Limpio"
  )

  cruce_seleccionado <- cruce_final %>%
    select(
      Poliza_Completa,
      FEC_EFECTO,
      FEC_VENCIMIENTO,
      NUM_ASEGURADOS,
      `Mapfre Id.y`,
      `Mapfre Id_1`,
      `PromoCode.y`,
      `EMAIL_TOMADOR...1`,
      `Correo electrónico`,
      `Nº de Usos Digitales`,
      `CIF/NIF`,
      `Plan Actual`,
      `Fecha de nacimiento`,
      Nombre,
      Apellidos
    )

  # ===================================================================
  # PASO 8: FILTRADO Y EXPORTACIÓN FINAL
  # ===================================================================
  fecha_ayer <- Sys.Date() - 1
  
  resultado_filtrado <- cruce_seleccionado %>%
    filter(
      as.Date(FEC_VENCIMIENTO) == fecha_ayer,
      !is.na(`Nº de Usos Digitales`) & `Nº de Usos Digitales` >= 1 & `Nº de Usos Digitales` <= 50
    )

  # ===================================================================
  # PASO 9: PREPARAR Y DEVOLVER EL ARCHIVO A MAKE
  # ===================================================================
  ### En lugar de guardar en disco, creamos un archivo temporal
  temp_file <- tempfile(fileext = ".xlsx")
  write_xlsx(resultado_filtrado, temp_file)

  ### Leemos el contenido binario del archivo temporal
  file_content <- readBin(temp_file, "raw", n = file.info(temp_file)$size)

  ### Borramos el archivo temporal del servidor
  unlink(temp_file)

  ### Devolvemos el archivo a Make. Esto es lo que recibirá el módulo HTTP.
  return(file_content)
}