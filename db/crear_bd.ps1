# ==============================================================
# crear_bd.ps1 — crea la base de datos bdfacturas en LocalDB.
#
# LocalDB es el SQL Server "de bolsillo" que viene con Visual
# Studio: el mismo motor, sin instalar ni configurar un servidor.
# Este script hace lo que en otros entornos hace un inicializador:
# arranca la instancia, crea la BD si no existe y ejecuta el
# script provisto bdfacturas.sql (las 12 tablas con sus datos).
#
# Es IDEMPOTENTE: correrlo mil veces no daña nada — si la BD ya
# existe, no hace nada.
#
# Uso (desde la raíz del proyecto):
#   .\db\crear_bd.ps1
#
# Para crear una BD con OTRO nombre (por ejemplo la de SU
# reconstrucción de la guía de IA):
#   .\db\crear_bd.ps1 -NombreBd bdfacturas_mi_v1
# ==============================================================

# param() declara los parámetros del script; si no se pasa nada,
# se usa el nombre de la BD del curso:
param(
    [string]$NombreBd = "bdfacturas_sqlserver_local"
)

# La instancia de LocalDB que trae Visual Studio (existe en todas
# las instalaciones estándar):
$instancia = "(localdb)\MSSQLLocalDB"

# $PSScriptRoot = la carpeta donde vive ESTE script (db\), así el
# script funciona sin importar desde dónde se llame:
$script = Join-Path $PSScriptRoot "bdfacturas.sql"

Write-Host "[crear_bd] Arrancando la instancia de LocalDB..."
# sqllocaldb es la herramienta de administración de LocalDB.
# "start" enciende la instancia si estaba apagada (es inofensivo
# si ya estaba encendida):
sqllocaldb start MSSQLLocalDB | Out-Null

Write-Host "[crear_bd] Verificando si la base de datos $NombreBd existe..."
# sqlcmd es el cliente de línea de comandos de SQL Server.
#   -S  = a cuál servidor conectarse (la instancia de LocalDB)
#   -E  = autenticación de Windows (la de su sesión; sin claves)
#   -h -1 -W = salida limpia (solo el valor, sin encabezados)
#   -Q  = ejecutar esta consulta y salir
$existe = sqlcmd -S $instancia -E -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$NombreBd'"

if ($existe.Trim() -eq "1") {
    Write-Host "[crear_bd] La base de datos $NombreBd ya existe. No se hace nada."
    exit 0
}

Write-Host "[crear_bd] Creando la base de datos $NombreBd..."
sqlcmd -S $instancia -E -Q "CREATE DATABASE [$NombreBd]"

Write-Host "[crear_bd] Ejecutando bdfacturas.sql (12 tablas, triggers, datos)..."
#   -d = conectarse A esa base de datos;  -i = ejecutar el archivo
sqlcmd -S $instancia -E -d $NombreBd -i $script

Write-Host "[crear_bd] Listo: $NombreBd creada con sus 12 tablas y datos de ejemplo."
