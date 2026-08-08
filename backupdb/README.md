# backupdb — respaldos de la base de datos

En esta carpeta se guardan los **respaldos (backups)** de `bdfacturas`.
SQL Server (LocalDB incluido) no usa dumps `.sql`: su mecanismo nativo es
`BACKUP DATABASE`, que produce un archivo **`.bak`** binario (datos + log
en un solo archivo) — el formato estándar de respaldo del mundo Microsoft.

> ¿En qué se diferencia de `db/bdfacturas.sql`? En que ese script crea la
> BD en su **estado inicial** (los datos de fábrica del curso), mientras
> que un backup captura **SU estado actual**: lo que usted insertó, editó
> o borró. Si solo quiere volver al estado inicial, no necesita backup:
> borre la BD y vuelva a correr `.\db\crear_bd.ps1`.

Convención de nombres: `bdfacturas_localdb_AAAA-MM-DD.bak` (si hace varios
el mismo día, agregue un sufijo: `_2.bak`).

---

## Cómo hacer un backup

Desde la **raíz del repositorio**, un solo comando (LocalDB escribe el
archivo directamente en esta carpeta — sin contenedores de por medio):

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -Q "BACKUP DATABASE bdfacturas_sqlserver_local TO DISK='$PWD\backupdb\bdfacturas_localdb_2026-08-08.bak' WITH INIT"
```

Qué hace cada pieza:

- `sqlcmd -E` — el cliente de SQL Server con autenticación de Windows
  (sin claves).
- `BACKUP DATABASE ... TO DISK` — el comando T-SQL nativo de respaldo;
  `WITH INIT` sobreescribe el archivo si ya existía.
- `$PWD` — la carpeta actual (por eso se corre desde la raíz del repo).

## Cómo restaurar un backup (restore)

`WITH REPLACE` pisa la BD actual; el `SINGLE_USER` saca las conexiones
abiertas (por ejemplo la de la API — deténgala primero con Ctrl+C si está
corriendo) y `MULTI_USER` las vuelve a permitir:

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -Q "ALTER DATABASE bdfacturas_sqlserver_local SET SINGLE_USER WITH ROLLBACK IMMEDIATE; RESTORE DATABASE bdfacturas_sqlserver_local FROM DISK='$PWD\backupdb\bdfacturas_localdb_2026-08-08.bak' WITH REPLACE; ALTER DATABASE bdfacturas_sqlserver_local SET MULTI_USER;"
```

Verifique: arranque la API (`dotnet watch run`) y
`http://localhost:8032/api/producto` debe mostrar los datos tal como
estaban cuando hizo el backup.

## Para probar el ciclo completo (ejercicio)

1. Haga un backup (arriba).
2. Cambie algo a propósito: cree un producto `PR999` con la API (POST
   desde Swagger) o edite el stock de uno existente.
3. Restaure el backup.
4. `PR999` desapareció (o el stock volvió) — la BD regresó EXACTAMENTE al
   momento del backup. Eso es un respaldo funcionando.

> ⚠️ El restore pisa TODO el contenido actual de la BD con el del archivo.
> Lo que haya cambiado DESPUÉS del backup se pierde. Por eso los respaldos
> se hacen ANTES de operaciones riesgosas (y en producción, con agenda).
