# Quickstart — Versión 1: arranque y smoke test (variante SIN Docker)

> **Versión 1** · Validación rápida de la versión ya construida. Si aún no
> hay nada construido, empiece por [8_tasks.md](8_tasks.md).

---

## 1. Arranque (dos comandos)

```powershell
# 1. Crear la BD en LocalDB (una sola vez; idempotente):
.\db\crear_bd.ps1

# 2. Arrancar la API (desde api_facturas/):
cd api_facturas
dotnet watch run
```

La primera vez `dotnet` restaura los paquetes y compila (~1 minuto). Al
final la consola dice que escucha en `http://localhost:8032`. La API queda
en esa terminal (para detenerla: `Ctrl+C`); abra OTRA terminal para los
comandos del smoke test.

## 2. Smoke test (equivale a los 6 criterios de 2_spec.md)

```powershell
# 1. Diagnóstico (y de paso: edite un .cs, guarde — recompila solo)
curl.exe http://localhost:8032/
# … y la documentación interactiva en el navegador: http://localhost:8032/swagger

# 2. Listar: 8 productos; con limite=3, exactamente 3
curl.exe http://localhost:8032/api/producto
curl.exe "http://localhost:8032/api/producto?limite=3"

# 3. Obtener: 200 con la Laptop; 404 con PR999
curl.exe http://localhost:8032/api/producto/PR001
curl.exe -i http://localhost:8032/api/producto/PR999

# 4. El ciclo de los 5 verbos
curl.exe -X POST http://localhost:8032/api/producto -H "Content-Type: application/json" -d "{\"codigo\":\"PR009\",\"nombre\":\"Webcam\",\"stock\":10,\"valorunitario\":350000}"
curl.exe -X PUT http://localhost:8032/api/producto/PR009 -H "Content-Type: application/json" -d "{\"nombre\":\"Webcam HD\",\"stock\":12,\"valorunitario\":380000}"
curl.exe -X PATCH http://localhost:8032/api/producto/PR009 -H "Content-Type: application/json" -d "{\"stock\":99}"
curl.exe http://localhost:8032/api/producto/PR009
curl.exe -X DELETE http://localhost:8032/api/producto/PR009
curl.exe -i -X DELETE http://localhost:8032/api/producto/PR009        # → 404

# 4b. El contraste didáctico: MISMO body, dos verbos
curl.exe -i -X PUT http://localhost:8032/api/producto/PR001 -H "Content-Type: application/json" -d "{\"stock\":99}"     # → 422
curl.exe -i -X PATCH http://localhost:8032/api/producto/PR001 -H "Content-Type: application/json" -d "{\"stock\":17}"   # → 200

# 5. La frontera de la petición — nunca llega a la BD
curl.exe -X POST http://localhost:8032/api/producto -H "Content-Type: application/json" -d "{\"codigo\":\"PRX\",\"nombre\":\"X\",\"stock\":-5,\"valorunitario\":10}"      # → 422 con errores[]
curl.exe -i -X POST http://localhost:8032/api/producto -H "Content-Type: application/json" -d "{\"codigo\":\"PRY\",\"nombre\":\"Y\",\"stock\":7.5,\"valorunitario\":10}"  # → 422 (el tipo es regla)

# 6. La prueba de capas (sin base de datos) — desde api_facturas/
dotnet run --project pruebas
# → CRITERIO 6 OK: el servicio funciona con el repositorio falso, sin SQL Server
```

## 3. Si algo falla

| Síntoma | Causa probable |
|---|---|
| `crear_bd.ps1` dice que `sqlcmd` o `sqllocaldb` no se reconocen | La sala no tiene las herramientas de SQL Server en el PATH — abra Visual Studio una vez (las registra) o pida soporte |
| `curl` no conecta al 8032 | La API no está corriendo (¿la terminal del `dotnet watch run` sigue abierta?) o aún compila — espere y reintente |
| La API responde 500 en todo | La BD no existe (¿corrió `.\db\crear_bd.ps1`?) o la instancia LocalDB está detenida (`sqllocaldb start MSSQLLocalDB`) |
| Guardo un .cs y no pasa nada | Espere la recompilación (segundos); si no, `Ctrl+C` y `dotnet watch run` |
| El puerto 8032 está ocupado | Otra copia de la API sigue corriendo — ciérrela, o cambie el puerto en `Properties/launchSettings.json` |
| Reset total de la BD | `sqlcmd -S "(localdb)\MSSQLLocalDB" -E -Q "DROP DATABASE bdfacturas_sqlserver_local"` y `.\db\crear_bd.ps1` |
