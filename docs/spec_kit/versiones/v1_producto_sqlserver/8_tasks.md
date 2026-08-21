# Tareas — Versión 1: api_facturas con producto + SQL Server LocalDB (C#/ASP.NET Core, sin Docker)

> **Versión 1** · El orden de construcción, partiendo de CERO. Cada fase
> termina en algo **verificable**. Requisitos: [2_spec.md](2_spec.md) ·
> técnica: [3_plan.md](3_plan.md) · contratos: [6_contracts.md](6_contracts.md) ·
> validación final: [7_quickstart.md](7_quickstart.md).

---

## Fase 0 — Base de datos y esqueleto
- [ ] Copiar a `db/` los DOS archivos **provistos** con esta versión:
      `bdfacturas.sql` (la BD completa en dialecto SQL Server — no se
      escribe ni se genera con IA) y `crear_bd.ps1` (el inicializador de
      LocalDB; ver [3_plan.md](3_plan.md) §4.6).
- [ ] Crear la BD: `.\db\crear_bd.ps1` (arranca LocalDB, crea
      `bdfacturas_sqlserver_local` y ejecuta el script — idempotente).
- [ ] Crear `api_facturas/` con subcarpetas `Modelos/`, `Peticiones/`, `Controllers/`,
      `Servicios/`, `Repositorios/`, `Excepciones/`, `Properties/` y
      `pruebas/`.

**Verificar:**
`sqlcmd -S "(localdb)\MSSQLLocalDB" -E -d bdfacturas_sqlserver_local -Q "SELECT count(*) FROM producto"`
da **8** (o mírelo en Visual Studio: *SQL Server Object Explorer* →
`(localdb)\MSSQLLocalDB` → las **12 tablas**).

## Fase 1 — El proyecto .NET y el modelo Producto (la clase entidad)
- [ ] `ApiFacturas.csproj`: proyecto Web de .NET 10, paquetes
      `Microsoft.Data.SqlClient` y `Swashbuckle.AspNetCore`, y la
      exclusión de `pruebas/**`.
- [ ] `appsettings.json` con la cadena de conexión a LocalDB
      (`Server=(localdb)\\MSSQLLocalDB; ... Trusted_Connection=True`).
- [ ] `Properties/launchSettings.json` fijando el puerto **8032**.
- [ ] `Modelos/Producto.cs`: la clase entidad con las 4 propiedades
      tipadas `{ get; set; }` (`Codigo` string, `Nombre` string, `Stock`
      int, `Valorunitario` decimal). En C#, las propiedades SON los
      getters/setters del lenguaje.

**Verificar:** `dotnet build` compila sin errores.

## Fase 2 — Las peticiones por verbo (la frontera de entrada) y la excepción
- [ ] `Peticiones/ProductoCrear.cs` (POST: todo obligatorio, con código),
      `Peticiones/ProductoReemplazo.cs` (PUT: todo obligatorio, sin código) y
      `Peticiones/ProductoActualizar.cs` (PATCH: todo opcional) — con las
      anotaciones y mensajes de [3_plan.md](3_plan.md) §4.2.
- [ ] `Excepciones/NoEncontradoExcepcion.cs`: la excepción que el
      controller traducirá a 404.

**Verificar:** `dotnet build` compila sin errores.

## Fase 3 — Contratos (interfaces) y repositorio SQL Server
- [ ] `Repositorios/IRepositorioProducto.cs`: interface con los 5 métodos
      async ([3_plan.md](3_plan.md) §4.1).
- [ ] `Servicios/IServicioProducto.cs`: interface del servicio.
- [ ] `Repositorios/RepositorioProductoSqlServer.cs`: Dapper (`QueryAsync`/`ExecuteAsync`) con los SQL
      de [3_plan.md](3_plan.md) §4.4 — `TOP (@limite)`, parámetros `@`,
      conexión por operación con `await using`, y el UPDATE con SET
      dinámico de lista blanca.

**Verificar:** `dotnet build` compila sin errores.

## Fase 4 — Servicio (y la prueba de capas)
- [ ] `Servicios/ServicioProducto.cs`: recibe `IRepositorioProducto` por
      constructor; valida reglas de negocio (`limite > 0`, código no
      vacío, PATCH sin campos → `ArgumentException`); traduce "no existe"
      a `NoEncontradoExcepcion`.
- [ ] `pruebas/PruebaCapas.csproj` (consola, con ProjectReference a la
      API) y `pruebas/Programa.cs`: el servicio con un **repositorio falso
      en memoria** (una clase `: IRepositorioProducto` sobre un
      diccionario) — crear/listar/obtener/actualizar/eliminar y las
      excepciones, SIN base de datos.

**Verificar (criterio 6):** `dotnet run --project pruebas` termina con
`CRITERIO 6 OK…`.

## Fase 5 — Controller y Program.cs
- [ ] `Controllers/ProductoController.cs`: `[Route("api/producto")]`, los 6
      métodos con sus atributos de verbo, cada uno con su try/catch
      ([3_plan.md](3_plan.md) §4.5) y el 204 para lista vacía.
- [ ] `Program.cs`: el ENSAMBLADOR (los dos AddScoped), la respuesta 422
      personalizada (`InvalidModelStateResponseFactory` → `{estado,
      mensaje, errores}`), **Swagger** (`AddSwaggerGen` + `UseSwagger` +
      `UseSwaggerUI`), el `GET /` de diagnóstico y `MapControllers`.

**Verificar:** con la BD creada y `dotnet run`, probar: listar (200 con 8 y
`?limite=3` con 3), obtener PR001 (200), PR999 (404), POST inválido (422
con `errores[]`), y el contraste PUT vs PATCH con `{"stock": 99}` (422 vs
200).

## Fase 6 — El arranque redondo (dotnet watch)
- [ ] Verificar el ciclo de desarrollo completo: `dotnet watch run` desde
      `api_facturas/` arranca en el 8032; editar un `.cs`, guardar, y
      comprobar que recompila y reinicia solo.
- [ ] Verificar que Swagger abre en `http://localhost:8032/swagger` y que
      desde ahí se puede ejecutar un GET.

**Verificar:** el arranque desde cero son DOS comandos (criterio 1 de la
spec): `.\db\crear_bd.ps1` + `dotnet watch run`.

## Fase 7 — Cierre de la versión
- [ ] Correr el smoke test completo de [7_quickstart.md](7_quickstart.md)
      §2 — equivale a los 6 criterios de aceptación de
      [2_spec.md](2_spec.md) §5.
- [ ] `.gitignore` (`bin/`, `obj/`, `*.session.sql`).
- [ ] Commit y tag `v1`.

**La v1 está TERMINADA.** Solo ahora se escribe la spec de la v2
([mapa de versiones](../0_mapa_versiones.md)).
