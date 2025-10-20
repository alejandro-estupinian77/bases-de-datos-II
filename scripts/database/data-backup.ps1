# Ver qué tablas y datos contiene el backup más grande
$backupFile = ".\backups\full_backup_20251020_102850.sql"

# Contar inserciones en el backup
Write-Host "=== ANALISIS DETALLADO DEL BACKUP ==="
Write-Host "INSERT de clientes: $( (Select-String -Path $backupFile -Pattern "INSERT.*clientes" -AllMatches).Matches.Count )"
Write-Host "INSERT de productos: $( (Select-String -Path $backupFile -Pattern "INSERT.*productos" -AllMatches).Matches.Count )"
Write-Host "INSERT de pedidos: $( (Select-String -Path $backupFile -Pattern "INSERT.*pedidos" -AllMatches).Matches.Count )"
