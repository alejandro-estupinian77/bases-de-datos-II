# setup-replication.ps1
$LOG_FILE = ".\setup.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

Write-Log "=== CONFIGURACION COMPLETA DE REPLICACION ==="

# 1. Limpieza completa
Write-Log "Paso 1: Limpieza completa..."
docker-compose down 2>$null
docker stop primary standby replica 2>$null
docker rm primary standby replica 2>$null
docker volume prune -f

# 2. Crear directorio de backups
if (!(Test-Path ".\backups")) {
    New-Item -ItemType Directory -Path ".\backups" -Force | Out-Null
    Write-Log "Directorio backups creado"
}

# 3. Iniciar solo el primary primero
Write-Log "Paso 2: Iniciando contenedor primary..."
docker-compose up -d primary

# 4. Esperar a que PostgreSQL esté listo
Write-Log "Paso 3: Esperando a que PostgreSQL este listo..."
$maxAttempts = 30
$attempt = 0
$primaryReady = $false

do {
    $attempt++
    Write-Log "Intento $attempt de $maxAttempts..."
    
    try {
        $result = docker exec primary pg_isready -U postgres -h localhost
        if ($LASTEXITCODE -eq 0) {
            $primaryReady = $true
            Write-Log "PostgreSQL esta listo!"
            break
        }
    } catch {
        # Ignorar errores y continuar esperando
    }
    
    Start-Sleep -Seconds 2
} while ($attempt -lt $maxAttempts)

if (-not $primaryReady) {
    Write-Log "ERROR: PostgreSQL no se inicio correctamente"
    Write-Log "Logs del contenedor primary:"
    docker logs primary
    exit 1
}

# 5. Configurar la replicación en el primary
Write-Log "Paso 4: Configurando replicacion en primary..."

# Crear usuario de replicación
docker exec primary psql -U postgres -c "CREATE USER replicador WITH REPLICATION ENCRYPTED PASSWORD 'replica123';"
docker exec primary psql -U postgres -c "SELECT pg_create_physical_replication_slot('replication_slot_standby');"
docker exec primary psql -U postgres -c "SELECT pg_create_physical_replication_slot('replication_slot_replica');"

# Verificar configuración
Write-Log "Verificando configuracion..."
docker exec primary psql -U postgres -c "SELECT name, setting FROM pg_settings WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots', 'hot_standby');"
docker exec primary psql -U postgres -c "SELECT * FROM pg_replication_slots;"

# 6. Configurar pg_hba.conf para replicación
Write-Log "Paso 5: Configurando autenticacion..."
$hba_content = @"
host replication replicador standby trust
host replication replicador replica trust
host all all all md5
"@

docker exec primary bash -c "echo '$hba_content' >> /var/lib/postgresql/data/pgdata/pg_hba.conf"

# 7. Reiniciar primary para aplicar cambios
Write-Log "Paso 6: Reiniciando primary..."
docker-compose restart primary

# Esperar a que se reinicie
Start-Sleep -Seconds 5

# 8. Iniciar standby y replica
Write-Log "Paso 7: Iniciando standby y replica..."
docker-compose up -d standby replica

Write-Log "=== CONFIGURACION COMPLETADA ==="
Write-Log "Primary: localhost:5432"
Write-Log "Standby: localhost:5433" 
Write-Log "Replica: localhost:5434"
Write-Log "Usuario: postgres"
Write-Log "Password: postgres"