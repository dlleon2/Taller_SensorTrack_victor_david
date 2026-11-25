# SensorTrack 📡

Aplicación móvil Flutter para monitoreo de sensores físicos del dispositivo, con almacenamiento en la nube mediante **Supabase**.

## Características

| Módulo | Descripción |
|--------|-------------|
| 🏠 **Dashboard** | Estado de conexión con Supabase y sensores disponibles |
| 📐 **Sensores** | Lectura en tiempo real del Acelerómetro y Giroscopio (X, Y, Z) |
| 📍 **GPS** | Ubicación actual con latitud, longitud, precisión y altitud |
| 📋 **Historial** | Lista de mediciones guardadas con filtros y detalle |
| 📊 **Estadísticas** | Totales, min/max y gráficas con `fl_chart` |

## Configuración

### 1. Supabase — Crear la tabla

Ejecuta en el **SQL Editor** de tu proyecto Supabase:

```sql
CREATE TABLE sensor_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_type TEXT NOT NULL,
    x DOUBLE PRECISION,
    y DOUBLE PRECISION,
    z DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir lectura publica" ON sensor_readings FOR SELECT USING (true);
CREATE POLICY "Permitir insercion publica" ON sensor_readings FOR INSERT WITH CHECK (true);
```

### 2. Configurar credenciales en la app

Abre `lib/main.dart` y reemplaza:

```dart
const String supabaseUrl = 'TU_SUPABASE_URL';
const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
```

### 3. Instalar dependencias y ejecutar

```bash
flutter pub get
flutter run
```

## Dependencias principales

- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) — Backend en la nube
- [`sensors_plus`](https://pub.dev/packages/sensors_plus) — Acelerómetro y Giroscopio
- [`geolocator`](https://pub.dev/packages/geolocator) — GPS / Ubicación
- [`fl_chart`](https://pub.dev/packages/fl_chart) — Gráficas
- [`intl`](https://pub.dev/packages/intl) — Formato de fechas

## Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada + config Supabase
├── models/
│   └── sensor_reading.dart    # Modelo de datos
├── services/
│   ├── supabase_service.dart  # CRUD con Supabase
│   └── sensor_service.dart    # Acelerómetro y Giroscopio
└── screens/
    ├── home_screen.dart       # Dashboard principal
    ├── sensors_screen.dart    # Pantalla de sensores
    ├── gps_screen.dart        # Pantalla de GPS
    ├── history_screen.dart    # Historial de registros
    └── stats_screen.dart      # Estadísticas y gráficas
```

## Autor

**Plataformas Móviles — Ciclo Oct 2026 / Feb 2027**
