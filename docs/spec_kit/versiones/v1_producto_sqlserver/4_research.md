# Investigación y decisiones — Versión 1: producto + SQL Server (C#/ASP.NET Core)

> **Versión 1** · **Lectura opcional** (el porqué de las decisiones del plan,
> con las alternativas que se evaluaron y descartaron). Complementa a
> [3_plan.md](3_plan.md); el orden de trabajo está en [8_tasks.md](8_tasks.md).

---

## D1 — ADO.NET crudo: sin Entity Framework (ni Dapper)

**Alternativas descartadas:** Entity Framework Core (el ORM de .NET) y
Dapper (micro-ORM).
**Decisión:** `SqlConnection` + `SqlCommand` con SQL parametrizado a mano.
**Por qué:** el objetivo es aprender **SQL y arquitectura**, no un ORM. EF
esconde exactamente lo que el curso quiere mostrar (el SQL, el mapeo, las
transacciones); Dapper es razonable pero igual tapa el ciclo
conexión→comando→lector que un estudiante debe ver una vez en la vida.
**Precio asumido:** más líneas por método del repositorio — cada una es
lección.

## D2 — Capas completas desde el día 1 (y no un MVP en un solo archivo)

**Alternativa descartada:** v1 = todo en `Program.cs` con minimal APIs y
refactorizar a capas después.
**Decisión:** controller → servicio → repositorio con interfaces desde v1.
**Por qué:** el valor de la v1 es el **esqueleto** sobre el que crecen las
demás versiones sin reescribir. El criterio de aceptación 6 (probar el
servicio con un repositorio falso, sin SQL Server) **solo es posible** si el
servicio depende de una `interface` — la prueba objetiva de que las capas
quedaron bien cortadas.

## D3 — Sin fábrica ni selección de motor: el ensamblador es la DI de Program.cs

**Alternativa descartada:** escribir de una vez la fábrica multi-motor.
**Decisión:** dos registros `AddScoped` que instancian la única combinación
existente (YAGNI con dirección).
**Por qué:** una fábrica con un solo producto es código muerto. La interfaz
`IRepositorioProducto` SÍ se escribe hoy — es la puerta por la que entrará
el segundo motor — pero el mecanismo de selección llega cuando exista algo
que seleccionar (v3). El examen del principio abierto/cerrado será ese: en
v3, solo el ensamblador cambia.

## D4 — La BD completa desde la v1 (la API solo toca `producto`)

**Alternativa descartada:** una BD mínima que crece con cada versión.
**Decisión:** `db/bdfacturas.sql` crea `bdfacturas` COMPLETA (12 tablas,
triggers, SPs); la regla es que el código de v1 solo puede nombrar
`producto`.
**Por qué:** los estudiantes ya vieron bases de datos — la BD es
**infraestructura dada**; lo que se construye por versiones es la API. Evita
migraciones entre versiones y deja los triggers y SPs de facturación
esperando a la v2. Costo asumido: 11 tablas a la vista que aún no se usan —
por eso la regla se declara explícita en la spec.

## D5 — La validación vive en las PETICIONES (una por verbo)

**Alternativas descartadas:** validar con ifs dentro del controlador, una
clase validadora aparte, o no validar y dejar que la BD rechace.
**Decisión:** tres clases de PETICIÓN (`ProductoCrear`, `ProductoReemplazo`,
`ProductoActualizar`) que DECLARAN sus reglas con anotaciones; ASP.NET
valida y responde 422 con la lista de errores (formato personalizado en
`Program.cs`).
**Por qué:** es la manera idiomática del framework — la petición declara, el
framework hace cumplir — y materializa la semántica de cada verbo: el mismo
body `{"stock": 7}` falla en PUT (le faltan campos) y pasa en PATCH. Bono
didáctico: **el tipo es regla** — `stock` es `int?`, así que un `7.5` o un
`"texto"` caen en 422 sin escribir ni un if.
**Nota de nombre:** estas clases NO son modelos — modelo = clase entidad
(`Modelos/`, en v1 `Producto`). Por eso viven en su propia carpeta
`Peticiones/`: describen lo que LLEGA en cada verbo, no lo que ES.

## D6 — SQL Server LocalDB como motor (y su inicializador)

**Alternativas descartadas:** SQL Server Express como servicio (hay que
instalarlo y administrarlo), SQLite (cambia el dialecto) y Docker (esta
variante existe justamente para salas SIN Docker).
**Decisión:** v1 usa **LocalDB** — la edición de desarrollo de SQL Server
que viene con Visual Studio — con `db/crear_bd.ps1` como inicializador.
**Por qué:** es el MISMO motor y dialecto T-SQL del mundo real, sin
instalar ni configurar nada: la instancia `(localdb)\MSSQLLocalDB` ya
existe en las salas, arranca bajo demanda y usa la autenticación de
Windows (sin claves). El precio: SQL Server no crea bases de datos solo —
de ahí el script inicializador (idempotente), que además es lección de
automatización en PowerShell.

## D7 — dotnet watch como ciclo de desarrollo

**Alternativa descartada:** `dotnet run` a secas (hay que reiniciar a mano
en cada cambio) o depurar solo desde Visual Studio (F5).
**Decisión:** `dotnet watch run` como forma estándar de trabajar la v1,
con el puerto fijado en `Properties/launchSettings.json` (8032).
**Por qué:** el ciclo del curso es guardar → recompila solo → refrescar.
`dotnet watch` lo da gratis con el SDK, funciona igual en VS Code y en la
terminal, y `launchSettings.json` deja el puerto declarado en el proyecto
(no en la cabeza de nadie).

## D8 — Arranque en dos comandos (la variante sin Docker)

**Alternativa descartada:** exigir Docker (no está disponible en todas las
salas del curso) o dejar el arranque "a mano" sin guion.
**Decisión:** el arranque completo son dos comandos declarados en la
constitución: `.\db\crear_bd.ps1` (una vez) y `dotnet watch run`.
**Por qué:** el espíritu del Artículo 4 (arranque simple y reproducible)
se mantiene sin contenedores: el script de la BD es idempotente y el watch
hace el resto. Quien tenga Docker puede usar la variante principal del
curso — misma API, misma spec, otra infraestructura.
