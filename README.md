# Proyecto Aplicación y Servicios Web (SIN Docker) — construcción por versiones

Proyecto de curso (ITM) — **variante para salas sin Docker**: todo corre
directamente sobre Windows con lo que trae Visual Studio (el SDK de .NET y
LocalDB). Aquí NO se descarga un sistema terminado: **se construye un
sistema real por versiones en C# / ASP.NET Core**, guiado por
especificaciones. El repositorio siempre contiene la **versión en curso,
funcionando** — usted la ejecuta, la estudia y luego la **reconstruye desde
cero** en su propio proyecto.

> 🐳 ¿Su sala (o su PC) SÍ tiene Docker? Use la variante principal del
> curso: <https://github.com/ccastro2050/proyecto_aplicacion_y_servicios_web>
> — mismo contenido, con la infraestructura en contenedores.

---

## 1. Cómo le trabaja el estudiante (léame primero)

### Qué necesita instalado (las salas ITM ya lo tienen)

| Herramienta | Para qué |
|---|---|
| **Git** | Clonar el repositorio y traer versiones nuevas |
| **Visual Studio** (o VS Code + SDK .NET 10) | Trae el SDK de .NET **y LocalDB** (el SQL Server "de bolsillo") |
| La terminal **PowerShell** | Los comandos del curso (en VS Code: *Terminal → New Terminal*) |

### Primera vez: cargar y EJECUTAR la versión (dos comandos)

En PowerShell:

```powershell
git clone https://github.com/ccastro2050/proyecto_aplicacion_y_servicios_web_sin_docker.git
cd proyecto_aplicacion_y_servicios_web_sin_docker

# 1. Crear la base de datos en LocalDB (una sola vez):
.\db\crear_bd.ps1

# 2. Arrancar la API:
cd api_facturas
dotnet watch run
```

Al terminar quedan corriendo la base de datos (bdfacturas completa en
LocalDB) y la API:

| Qué | Dónde |
|---|---|
| **API Facturas** — diagnóstico | http://localhost:8032/ |
| **Swagger** (documentación interactiva: ver y probar los endpoints) | http://localhost:8032/swagger |
| Listar productos | http://localhost:8032/api/producto |
| LocalDB (para el SQL Server Object Explorer de Visual Studio) | servidor `(localdb)\MSSQLLocalDB`, autenticación de Windows |

Pruebe la joya didáctica de la v1: PUT con solo `{"stock": 99}` → 422; el
mismo body en PATCH → 200. Esa diferencia es parte de lo que enseña la
versión (contratos exactos en el spec kit).

> ℹ️ La API usa el puerto 8032 (fijado en
> `api_facturas/Properties/launchSettings.json`). La BD no usa puerto:
> LocalDB se conecta por nombre de instancia.

### Los días siguientes (volver a encender)

```powershell
cd api_facturas
dotnet watch run          # la BD ya existe; LocalDB arranca sola
```

(Para detener la API: `Ctrl+C` en esa terminal.)

### Cuando hay cambios

| Qué cambió | Qué hacer |
|---|---|
| **Usted edita un `.cs`** | **Nada** — `dotnet watch` recompila y reinicia solo (espere unos segundos) |
| **El profesor publicó una versión nueva** | `git pull` y volver a arrancar (`dotnet watch run`) |
| **Quiere resetear la BD** a sus datos originales | `sqlcmd -S "(localdb)\MSSQLLocalDB" -E -Q "DROP DATABASE bdfacturas_sqlserver_local"` y luego `.\db\crear_bd.ps1` (⚠️ borra los datos) |
| **Apagar todo** | `Ctrl+C` en la terminal de la API (LocalDB se duerme solo) |

### Y ahora, SU trabajo: reconstruirla desde cero

Ejecutar la versión del repo es solo el punto de partida. Lo que se evalúa
es **reconstruirla usted mismo, en una carpeta propia (fuera del clon)**,
siguiendo las especificaciones — con o sin ayuda de IA:

> 🤖 ¿Va a trabajar con IA? Siga la **[Guía para construir la versión con
> IA](docs/GUIA_IA.md)** — cubre los dos caminos con su prompt exacto listo
> para copiar: **chat web** (Gemini, DeepSeek, ChatGPT: qué archivos
> subirle) e **IDE agéntico** (Antigravity, Cursor, Claude Code: cómo
> supervisar al agente).

### Conceptos resumidos (los que acaba de usar)

| Concepto | En una frase |
|---|---|
| **Clonar** | Descargar el repositorio con su historial; `git pull` trae lo nuevo |
| **LocalDB** | El SQL Server "de bolsillo" de Visual Studio: mismo motor, sin instalar servidor |
| **dotnet watch** | El vigilante del código: guardar un `.cs` recompila y reinicia la API sola |
| **Spec kit** | Los documentos que dicen QUÉ/CÓMO/EN QUÉ ORDEN — la fuente de verdad |
| **Versión / tag** | Un incremento cerrado y verificado (`v1`, `v2`, …): se avanza solo en verde |

> Detalle del entorno local (LocalDB, dónde viven los datos, el reset):
> [docs/ENTORNO_LOCAL.md](docs/ENTORNO_LOCAL.md).

---

## 2. Estructura del repositorio

Qué es cada carpeta y cada archivo, y para qué sirve:

```
proyecto_aplicacion_y_servicios_web_sin_docker/
├── db/
│   ├── bdfacturas.sql           # Crea bdfacturas COMPLETA (12 tablas, triggers, SPs,
│   │                            #   datos) — dialecto SQL Server
│   └── crear_bd.ps1             # El inicializador: arranca LocalDB, crea la BD si no
│                                #   existe y ejecuta el script (idempotente)
│
├── backupdb/                    # Respaldos (.bak) de la BD — su README explica
│                                #   cómo hacer el backup y cómo restaurarlo
│
├── api_facturas/                # LA API DE LA v1 — C#/ASP.NET Core (puerto 8032)
│   ├── ApiFacturas.csproj       # El proyecto .NET (paquetes: SqlClient, Dapper y Swashbuckle)
│   ├── Program.cs               # Punto de entrada: ENSAMBLADOR (DI) + 422 + rutas
│   ├── appsettings.json         # Cadena de conexión a LocalDB (autenticación Windows)
│   ├── Properties/launchSettings.json  # Fija el puerto 8032 para dotnet run/watch
│   ├── Controllers/             # Capa 1 — HTTP: atributos de verbo y try/catch → códigos
│   ├── Modelos/                 # Los MODELOS = las clases ENTIDAD (v1: Producto)
│   ├── Peticiones/              # Los body por verbo (Crear/Reemplazo/Actualizar):
│   │                            #   sus anotaciones validan la entrada → 422
│   ├── Servicios/               # Capa 2 — negocio: interfaz + reglas
│   ├── Repositorios/            # Capa 3 — datos: interfaz + ADO.NET/SQL Server
│   ├── Excepciones/             # NoEncontradoExcepcion (el servicio la lanza → 404)
│   └── pruebas/                 # Proyecto de consola: el servicio con repositorio
│                                #   FALSO en memoria (criterio 6, corre sin BD)
├── docs/
│   ├── spec_kit/                # LAS ESPECIFICACIONES: constitución permanente +
│   │                            #   una carpeta de specs por versión (v1, v2, …)
│   ├── GUIA_IA.md               # Cómo reconstruir la versión desde 0 con ayuda de una IA
│   ├── FLUJO_DE_UNA_PETICION.md # Dónde "está" el GET, dónde se captura el POST
│   ├── ENTORNO_LOCAL.md         # LocalDB y dotnet watch: el "Docker" de esta variante
│   ├── TUTORIAL_SSMS.md         # Administrar la BD con SQL Server Management Studio
│   ├── TUTORIAL_VSCODE_MSSQL.md # Administrar la BD desde VS Code (extensión mssql)
│   ├── PARADIGMA_POO.md         # Material conceptual: POO, SOLID+capas, ACID y SDD
│   ├── SOLID_CAPAS_PATRONES.md         #   (un .md por tema)
│   ├── PRINCIPIOS_ACID.md       #
│   └── SDD_SPECKIT.md           #
│
├── .gitignore / .gitattributes  # Higiene del repo (bin/, obj/, .session.sql)
└── README.md                    # Este archivo
```

La regla de lectura: **la BD vive en `db/`** (script + inicializador), la
API vive en `api_facturas/` (una carpeta por capa), y **todo lo que
explica** vive en `docs/`. Cuando lleguen las versiones siguientes, aquí
aparecerán más carpetas de componentes.

## 3. La ruta de versiones

```
v1  api_facturas (C#/ASP.NET Core): CRUD de producto, SQL Server (LocalDB)  ← USTED ESTÁ AQUÍ
v2  más tablas (persona, factura maestro-detalle…)
v3  segundo motor (PostgreSQL) — nace la fábrica de repositorios
v4  tercer motor (MariaDB) — los tres motores conviviendo
v5  frontend BLAZOR: CRUD de las 12 entidades + login + facturación
```

La regla del juego: la **constitución** es permanente, cada versión tiene
su propia spec, y una versión está TERMINADA solo cuando pasa sus criterios
de aceptación (commit + tag). Mapa completo:
[docs/spec_kit/versiones/0_mapa_versiones.md](docs/spec_kit/versiones/0_mapa_versiones.md).

## 4. Las especificaciones de la versión actual (v1)

| Documento | Contenido |
|---|---|
| [1_constitution.md](docs/spec_kit/1_constitution.md) | Las reglas permanentes del proyecto |
| [2_spec.md](docs/spec_kit/versiones/v1_producto_sqlserver/2_spec.md) | QUÉ construir y los criterios de aceptación |
| [3_plan.md](docs/spec_kit/versiones/v1_producto_sqlserver/3_plan.md) | CÓMO: stack, estructura y diseño de las capas |
| [4_research.md](docs/spec_kit/versiones/v1_producto_sqlserver/4_research.md) | Decisiones y alternativas (el porqué) |
| [5_data_model.md](docs/spec_kit/versiones/v1_producto_sqlserver/5_data_model.md) | La BD completa (dada) y la tabla producto |
| [6_contracts.md](docs/spec_kit/versiones/v1_producto_sqlserver/6_contracts.md) | Los 7 endpoints con formatos exactos |
| [7_quickstart.md](docs/spec_kit/versiones/v1_producto_sqlserver/7_quickstart.md) | Arranque y smoke test |
| [8_tasks.md](docs/spec_kit/versiones/v1_producto_sqlserver/8_tasks.md) | Orden de construcción por fases verificables |

## 5. Material conceptual del curso

| Documento | Qué cubre |
|---|---|
| [El flujo de una petición](docs/FLUJO_DE_UNA_PETICION.md) | **Léalo primero:** dónde está el GET, dónde se captura el POST, y el viaje completo por las capas |
| [El entorno local](docs/ENTORNO_LOCAL.md) | LocalDB (qué es, dónde viven los datos, el reset) y dotnet watch |
| [SDD y Spec Kit](docs/SDD_SPECKIT.md) | La metodología: la spec manda sobre el código |
| [El paradigma P.O.O. en C#](docs/PARADIGMA_POO.md) | Qué es un paradigma, los 4 pilares, y las propiedades e interfaces de C# |
| [SOLID, capas y patrones de diseño](docs/SOLID_CAPAS_PATRONES.md) | Los 5 principios y las capas — y en qué versión se demuestra cada uno |
| [Principios ACID](docs/PRINCIPIOS_ACID.md) | Las 4 garantías transaccionales, por qué una facturación las exige |

---

*Proyecto Aplicación y Servicios Web (variante sin Docker) · ITM · Base de
datos bdfacturas (facturación + RBAC).*
