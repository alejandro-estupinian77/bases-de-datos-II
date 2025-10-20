# cleanup.ps1 - Script simple de limpieza
Write-Host "=== LIMPIANDO SISTEMA ==="

# Parar y eliminar contenedores
Write-Host "Deteniendo contenedores..."
docker-compose down 2>$null
docker stop primary standby replica 2>$null

Write-Host "Eliminando contenedores..."
docker rm primary standby replica 2>$null

# Eliminar volúmenes
Write-Host "Eliminando volúmenes..."
docker volume prune -f

# Limpiar backups antiguos (>7 días)
Write-Host "Limpiando backups antiguos..."
$cutoffDate = (Get-Date).AddDays(-7)
Get-ChildItem -Path ".\backups" -Filter "*.sql" -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
    ForEach-Object { 
        Write-Host "Eliminando: $($_.Name)"
        Remove-Item $_.FullName -Force 
    }

Write-Host "✅ Limpieza completada"