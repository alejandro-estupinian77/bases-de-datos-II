# backup-final.ps1
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

# Verificar que el primary esté ejecutándose
$containerStatus = docker inspect --format='{{.State.Status}}' primary 2>$null

if ($LASTEXITCODE -ne 0 -or $containerStatus -ne "running") {
    Write-Log "ERROR: El contenedor primary no esta ejecutandose"
    Write-Log "Estado actual: $containerStatus"
    Write-Log "Intentando iniciar contenedores..."
    docker-compose up -d primary
    Start-Sleep -Seconds 5
}

# Verificar conexión a PostgreSQL
Write-Log "Verificando conexion a PostgreSQL..."
$connectionTest = docker exec primary psql -U postgres -c "SELECT version();" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Log "ERROR: No se puede conectar a PostgreSQL: $connectionTest"
    exit 1
}

Write-Log "Conexion establecida correctamente"

# Realizar backup
try {
    $backupFile = "$BACKUP_DIR\full_backup_$DATE.sql"
    Write-Log "Creando backup: $backupFile"
    
    docker exec primary pg_dumpall -U postgres --verbose > $backupFile 2> "$BACKUP_DIR\backup_errors_$DATE.log"
    
    if ($LASTEXITCODE -eq 0) {
        $fileInfo = Get-Item $backupFile -ErrorAction SilentlyContinue
        if ($fileInfo -and $fileInfo.Length -gt 0) {
            Write-Log "Backup exitoso: $([math]::Round($fileInfo.Length/1024, 2)) KB"
        } else {
            Write-Log "ADVERTENCIA: Archivo de backup vacio o no creado"
        }
    } else {
        Write-Log "ERROR en backup (codigo: $LASTEXITCODE)"
        if (Test-Path "$BACKUP_DIR\backup_errors_$DATE.log") {
            Get-Content "$BACKUP_DIR\backup_errors_$DATE.log" | ForEach-Object { Write-Log "  $_" }
        }
    }
} catch {
    Write-Log "Error durante backup: $($_.Exception.Message)"
}

# Limpieza de backups antiguos (7 días)
Write-Log "Aplicando retencion de 7 dias..."
Get-ChildItem -Path $BACKUP_DIR -Filter "*.sql" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | ForEach-Object {
    Write-Log "Eliminando backup antiguo: $($_.Name)"
    Remove-Item $_.FullName -Force
}

Write-Log "=== BACKUP COMPLETADO ==="