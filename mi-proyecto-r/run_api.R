library(plumber)

# Cargar la API definida en el archivo api.R
pr <- plumb("api.R")

# Obtener el puerto que Google Cloud nos asigna (por defecto 8080)
port <- strtoi(Sys.getenv("PORT", 8080))

# Ejecutar la API
pr$run(port = port, host = "0.0.0.0")