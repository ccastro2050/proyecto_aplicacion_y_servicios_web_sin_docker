# Investigación y decisiones — Versión 1: producto + SQL Server (C#/ASP.NET Core)

> **Versión 1** · **Lectura opcional** (el porqué de las decisiones del plan,
> con las alternativas que se evaluaron y descartaron). Complementa a
> [3_plan.md](3_plan.md); el orden de trabajo está en [8_tasks.md](8_tasks.md).

---

## D1 — El ejecutor de la capa de datos: Dapper (un ADR completo)

> Este documento funciona como registro de decisiones de arquitectura
> (**ADR**, *Architecture Decision Record*): cada D# captura contexto →
> opciones → criterios → decisión → consecuencias, y se versiona con el
> código. Esta D1 es el ejemplo más completo del formato.

**Contexto.** La capa de repositorios necesita (1) ejecutar SQL contra
el motor y (2) mapear filas ↔ objetos del modelo. Restricción de la
constitución (Art. 2): el SQL debe quedar VISIBLE en el código y SIEMPRE
parametrizado.

**Opciones evaluadas:** (a) Entity Framework Core (ORM de entidades) ·
(b) **Dapper** (micro-ejecutor) · (c) ADO.NET "crudo"
(`SqlConnection` + `SqlCommand` con el mapeo `GetString(0)` a mano).

**Criterios de ingeniería y comparación:**

| Criterio | EF Core | Dapper | ADO.NET crudo |
|---|---|---|---|
| SQL visible en el repositorio | ✗ (lo genera LINQ) | ✓ (se escribe a mano) | ✓ |
| Parametrización (anti-inyección) | ✓ | ✓ (`@param`) | ✓ (`@param`) |
| Rendimiento en lecturas | menor (tracking, traducción) | ≈ manual (mapeo con código emitido y CACHEADO) | máximo teórico |
| Líneas por método del repositorio | pocas | pocas | muchas (ciclo conexión→comando→lector) |
| Riesgo de abstracción con fuga | alto (N+1, tracking sorpresa) | bajo (no decide nada) | ninguno |
| Dependencias | pesada | 1 paquete MIT, estable | ninguna |
| Testabilidad de las capas | igual en las tres: la da la ARQUITECTURA (interfaces + repos falsos), no el ejecutor | | |

**Decisión: (b) Dapper.** `QueryAsync<T>`/`ExecuteAsync` reciben el SQL
escrito a mano; Dapper solo mapea columna→propiedad por nombre. EF queda
descartado por el criterio 1 (esconde exactamente lo que la constitución
exige ver); frente al crudo, Dapper empata en los criterios técnicos y
gana en costo de código.

**Consecuencias.** (+) Repositorios cortos y uniformes; el diseño queda
más visible que el ritual de infraestructura. (+) Sin lock-in: quitar
Dapper es volver a escribir el mapeo manual — el SQL no cambia. (−) El
ciclo conexión→comando→lector no se practica aquí (quien quiera verlo lo
tiene en los materiales del ecosistema del curso). (−) Una dependencia
más, mitigada por licencia MIT y madurez del paquete.

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
