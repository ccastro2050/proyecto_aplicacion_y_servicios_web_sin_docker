# El entorno local — LocalDB y dotnet watch

> Documento conceptual de esta variante del curso: cómo corre el sistema
> SIN contenedores, directamente sobre Windows con lo que trae Visual
> Studio.

---

## 1. Las dos piezas del entorno

| Pieza | Qué hace | Quién la trae |
|---|---|---|
| **LocalDB** | El motor de base de datos (SQL Server "de bolsillo") | Visual Studio |
| **dotnet watch** | Compila, ejecuta y recompila la API al guardar | El SDK de .NET |

## 2. LocalDB: SQL Server sin servidor

**LocalDB** es una edición especial de SQL Server pensada para desarrollo:
el MISMO motor y el MISMO dialecto T-SQL, pero **sin servicio instalado**
— arranca bajo demanda como un proceso de su sesión de usuario y se duerme
solo cuando nadie lo usa.

- **La instancia**: se llama `MSSQLLocalDB` y se conecta con el nombre
  `(localdb)\MSSQLLocalDB` — no hay puerto ni contraseña: usa la
  **autenticación de Windows** de su sesión.
- **Dónde viven los datos**: cada base de datos son dos archivos (`.mdf`
  de datos y `.ldf` de log) en su perfil de usuario
  (`C:\Users\<usted>\`). Por eso sus datos sobreviven a reinicios — y por
  eso cada usuario del PC tiene SUS bases de datos.
- **Administrarla**: la herramienta de línea de comandos es `sqllocaldb`:

```powershell
sqllocaldb info                  # qué instancias existen
sqllocaldb info MSSQLLocalDB     # estado de la instancia (Running / Stopped)
sqllocaldb start MSSQLLocalDB    # encenderla (crear_bd.ps1 lo hace por usted)
sqllocaldb stop MSSQLLocalDB     # apagarla (rara vez necesario)
```

- **Verla con interfaz**: en Visual Studio, *Ver → SQL Server Object
  Explorer* → `(localdb)\MSSQLLocalDB` → Databases →
  `bdfacturas_sqlserver_local` — ahí están las 12 tablas, y puede hacer
  clic derecho → *New Query* para ejecutar SQL.

## 3. El inicializador: db\crear_bd.ps1

SQL Server no crea bases de datos solo: alguien tiene que ejecutar el
script. En esta variante ese "alguien" es `db\crear_bd.ps1` (comentado
línea a línea), que hace tres cosas:

1. Arranca la instancia de LocalDB (`sqllocaldb start`).
2. Pregunta si la BD ya existe — si existe, **no hace nada** (es
   idempotente: correrlo mil veces no daña nada).
3. Si no existe: la crea y ejecuta `bdfacturas.sql` (las 12 tablas,
   triggers, procedimientos y datos de ejemplo).

**El reset de la BD** (volver a los datos originales) es borrarla y
recrearla:

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -Q "DROP DATABASE bdfacturas_sqlserver_local"
.\db\crear_bd.ps1
```

## 4. dotnet watch: el ciclo de desarrollo

```powershell
cd api_facturas
dotnet watch run
```

`dotnet watch` compila el proyecto, lo ejecuta (en el puerto 8032, fijado
en `Properties/launchSettings.json`) y **se queda vigilando los
archivos**: al guardar un `.cs`, recompila y reinicia solo. Guardar →
esperar unos segundos → refrescar. Para detener: `Ctrl+C`.

| Qué cambió | Qué hacer |
|---|---|
| Un `.cs` | Nada — watch recompila solo |
| El `.csproj` (paquetes) | watch normalmente se reinicia solo; si no, `Ctrl+C` y `dotnet watch run` |
| `appsettings.json` | `Ctrl+C` y volver a arrancar |

## 5. El mapa mental (comparación de entornos)

Esta variante y la variante con Docker del curso hacen LO MISMO con piezas
distintas:

| Concepto | Aquí (sin Docker) | En la variante con Docker |
|---|---|---|
| El motor de BD | LocalDB (proceso de su sesión) | Contenedor de SQL Server |
| Crear la BD | `.\db\crear_bd.ps1` | El contenedor inicializador |
| Arrancar la API | `dotnet watch run` | `docker compose up -d` |
| El hot-reload | dotnet watch (local) | dotnet watch (dentro del contenedor) |
| Dónde viven los datos | Archivos .mdf en su perfil | El volumen de Docker |
| El reset | DROP DATABASE + crear_bd.ps1 | `docker compose down -v` + `up` |

La arquitectura de la API (capas, interfaces, contratos) es **idéntica**:
lo único que cambia es el andamiaje de infraestructura.

## 6. Referencias

1. Microsoft — *SQL Server Express LocalDB*:
   <https://learn.microsoft.com/sql/database-engine/configure-windows/sql-server-express-localdb>
2. Microsoft — *dotnet watch*:
   <https://learn.microsoft.com/dotnet/core/tools/dotnet-watch>
3. En este repositorio: `db/crear_bd.ps1` (comentado) y el
   [README](../README.md).
