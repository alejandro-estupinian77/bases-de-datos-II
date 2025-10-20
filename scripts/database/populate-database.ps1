# populate-database.ps1
Write-Host "=== POBLANDO BASE DE DATOS ==="

# Datos de la empresa Pollo Sanjuanero S.A.
$scripts = @(
    "CREATE TABLE IF NOT EXISTS clientes (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        telefono VARCHAR(20),
        email VARCHAR(100),
        direccion TEXT,
        fecha_registro TIMESTAMP DEFAULT NOW()
    );",
    
    "CREATE TABLE IF NOT EXISTS productos (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        descripcion TEXT,
        precio DECIMAL(10,2) NOT NULL,
        stock INTEGER DEFAULT 0,
        categoria VARCHAR(50),
        activo BOOLEAN DEFAULT true
    );",
    
    "CREATE TABLE IF NOT EXISTS pedidos (
        id SERIAL PRIMARY KEY,
        cliente_id INTEGER REFERENCES clientes(id),
        fecha_pedido TIMESTAMP DEFAULT NOW(),
        total DECIMAL(10,2),
        estado VARCHAR(20) DEFAULT 'pendiente'
    );",
    
    "INSERT INTO clientes (nombre, telefono, email, direccion) VALUES 
    ('Supermercado La Esperanza', '1234-5678', 'compras@laesperanza.com', 'Zona 1, Ciudad'),
    ('Restaurante El Fogón', '2345-6789', 'pedidos@elfogon.com', 'Zona 10, Ciudad'),
    ('Comedor Central', '3456-7890', 'administracion@comedorcentral.com', 'Zona 5, Ciudad'),
    ('Distribuidora QuickFood', '4567-8901', 'ventas@quickfood.com', 'Zona 15, Ciudad');",
    
    "INSERT INTO productos (nombre, descripcion, precio, stock, categoria) VALUES 
    ('Pollo Entero Grado A', 'Pollo entero fresco de primera calidad', 45.50, 100, 'Carnes'),
    ('Pechuga de Pollo Sin Hueso', 'Pechuga de pollo sin hueso ni piel', 65.75, 80, 'Carnes'),
    ('Muslos de Pollo', 'Muslos de pollo para asar o guisar', 38.25, 120, 'Carnes'),
    ('Alitas de Pollo', 'Alitas de pollo para snacks', 42.00, 90, 'Carnes'),
    ('Huevos Blancos Grade A', 'Huevos blancos frescos por unidad', 0.25, 2000, 'Huevos'),
    ('Huevos Rojos Grade AA', 'Huevos rojos premium por unidad', 0.32, 1500, 'Huevos'),
    ('Medio Pollo Rostizado', 'Medio pollo rostizado listo para servir', 55.00, 50, 'Preparados'),
    ('Pollo Entero Rostizado', 'Pollo entero rostizado listo para servir', 95.00, 30, 'Preparados');",
    
    "INSERT INTO pedidos (cliente_id, total, estado) VALUES 
    (1, 1250.75, 'completado'),
    (2, 890.50, 'completado'),
    (3, 2100.25, 'procesando'),
    (4, 750.00, 'pendiente');"
)

# Ejecutar cada script
foreach ($script in $scripts) {
    Write-Host "Ejecutando: $($script.Substring(0, [Math]::Min(50, $script.Length)))..."
    docker exec primary psql -U postgres -c "$script"
}

Write-Host "`n=== VERIFICANDO DATOS INSERTADOS ==="

# Verificar tablas y conteos
docker exec primary psql -U postgres -c "
SELECT 'Clientes' as tabla, COUNT(*) as total FROM clientes
UNION ALL
SELECT 'Productos', COUNT(*) FROM productos
UNION ALL
SELECT 'Pedidos', COUNT(*) FROM pedidos;"

Write-Host "`n=== POBLACION COMPLETADA ==="