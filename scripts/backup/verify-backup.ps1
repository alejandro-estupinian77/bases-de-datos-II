# verify-backup.ps1
Write-Host "=== VERIFICACION DE BACKUP ==="

# Obtener el backup más reciente
$latestBackup = Get-ChildItem .\backups\*.sql | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestBackup) {
    Write-Host "Backup analizado: $($latestBackup.Name)"
    Write-Host "Tamaño: $([math]::Round($latestBackup.Length/1024, 2)) KB"
    Write-Host "Fecha: $($latestBackup.LastWriteTime)"
    
    # Buscar datos específicos
    Write-Host "`nContenido encontrado en el backup:"
    
    $patterns = @{
        "Tabla clientes" = "CREATE TABLE.*clientes|INSERT.*clientes"
        "Tabla productos" = "CREATE TABLE.*productos|INSERT.*productos" 
        "Tabla pedidos" = "CREATE TABLE.*pedidos|INSERT.*pedidos"
        "Pollo Sanjuanero" = "Pollo|pollo"
    }
    
    foreach ($desc in $patterns.Keys) {
        $matches = Select-String -Path $latestBackup.FullName -Pattern $patterns[$desc] -AllMatches
        if ($matches) {
            Write-Host "✅ $desc : $($matches.Count) coincidencias"
        } else {
            Write-Host "❌ $desc : No encontrado"
        }
    }
    
    # Mostrar algunas líneas del INSERT
    Write-Host "`nEjemplo de datos en el backup:"
    Select-String -Path $latestBackup.FullName -Pattern "INSERT.*VALUES" -Context 0,2 | Select-Object -First 3
    
} else {
    Write-Host "No se encontraron archivos de backup"
}