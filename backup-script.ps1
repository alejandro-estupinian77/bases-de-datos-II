# backup-script-corregido.ps1
$BACKUP_DIR = ".\backups"
$DATE = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = ".\backup.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

# Crear directorio
if (!(Test-Path $BACKUP_DIR)) { 
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
    Write-Log "Directorio de backups creado"
}

Write-Log "=== INICIANDO BACKUP ==="

# Usar el nombre exacto del contenedor
$containerName = "primary"
Write-Log "Usando contenedor: $containerName"

# Verificar que el contenedor está ejecutándose
$containerStatus = docker inspect --format='{{.State.Status}}' $containerName

if ($containerStatus -eq "running") {
    Write-Log "Contenedor esta en ejecucion"
    
    try {
        Write-Log "Ejecutando pg_dumpall..."
        
        # Ejecutar el backup
        docker exec $containerName pg_dumpall -U postgres | Out-File -FilePath "$BACKUP_DIR\full_backup_$DATE.sql" -Encoding UTF8
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Backup completado exitosamente"
            Write-Log "Archivo: full_backup_$DATE.sql"
            
            # Verificar que se creó el archivo
            if (Test-Path "$BACKUP_DIR\full_backup_$DATE.sql") {
                $fileInfo = Get-Item "$BACKUP_DIR\full_backup_$DATE.sql"
                Write-Log "Tamaño del backup: $([math]::Round($fileInfo.Length/1024, 2)) KB"
            } else {
                Write-Log "El archivo de backup no se creo"
            }
        } else {
            Write-Log "Error en pg_dumpall (codigo: $LASTEXITCODE)"
        }
    } catch {
        Write-Log "Error ejecutando backup: $($_.Exception.Message)"
    }
} else {
    Write-Log "El contenedor no esta en ejecucion. Estado: $containerStatus"
}

Write-Log "=== PROCESO COMPLETADO ==="
Add-Content -Path $LOG_FILE -Value "----------------------------------------"