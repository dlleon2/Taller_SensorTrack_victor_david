-- ==============================================================================
-- TALLER PRÁCTICO: SensorTrack
-- Script SQL para Supabase (PostgreSQL)
-- ==============================================================================

-- 1. Crear tabla para almacenar las lecturas de los sensores
CREATE TABLE IF NOT EXISTS sensor_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_type TEXT NOT NULL,          -- 'accelerometer', 'gyroscope', 'gps'
    x DOUBLE PRECISION,                 -- Eje X (Acelerómetro / Giroscopio)
    y DOUBLE PRECISION,                 -- Eje Y (Acelerómetro / Giroscopio)
    z DOUBLE PRECISION,                 -- Eje Z (Acelerómetro / Giroscopio)
    latitude DOUBLE PRECISION,          -- Latitud GPS
    longitude DOUBLE PRECISION,         -- Longitud GPS
    accuracy DOUBLE PRECISION,          -- Precisión en metros (GPS)
    recorded_at TIMESTAMPTZ DEFAULT NOW() -- Fecha y hora de captura
);

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de acceso (lectura e inserción para la aplicación)
DROP POLICY IF EXISTS "Permitir lectura publica" ON sensor_readings;
CREATE POLICY "Permitir lectura publica"
    ON sensor_readings FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Permitir insercion publica" ON sensor_readings;
CREATE POLICY "Permitir insercion publica"
    ON sensor_readings FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir eliminacion publica" ON sensor_readings;
CREATE POLICY "Permitir eliminacion publica"
    ON sensor_readings FOR DELETE
    USING (true);

-- 4. Índices para acelerar consultas de historial y estadísticas
CREATE INDEX IF NOT EXISTS idx_sensor_readings_type ON sensor_readings(sensor_type);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_date ON sensor_readings(recorded_at DESC);
