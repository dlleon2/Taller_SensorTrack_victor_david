// Modelo de datos para las lecturas de sensores
class SensorReading {
  final String? id;
  final String sensorType;
  final double? x;
  final double? y;
  final double? z;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? recordedAt;

  const SensorReading({
    this.id,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.recordedAt,
  });

  /// Crear desde mapa de Supabase
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as String?,
      sensorType: (map['sensor_type'] as String?) ?? '',
      x: (map['x'] as num?)?.toDouble(),
      y: (map['y'] as num?)?.toDouble(),
      z: (map['z'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      recordedAt: map['recorded_at'] != null
          ? DateTime.parse(map['recorded_at'] as String)
          : null,
    );
  }

  /// Convertir a mapa para insertar en Supabase
  Map<String, dynamic> toMap() {
    return {
      'sensor_type': sensorType,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  /// Etiqueta legible del tipo de sensor
  String get sensorLabel {
    switch (sensorType) {
      case 'accelerometer':
        return 'Acelerómetro';
      case 'gyroscope':
        return 'Giroscopio';
      case 'gps':
        return 'GPS';
      default:
        return sensorType;
    }
  }

  // Alias para compatibilidad
  String get displayTitle => sensorLabel;

  String get displayValues {
    if (sensorType == 'gps') {
      return 'Lat: ${latitude?.toStringAsFixed(5)} | Lon: ${longitude?.toStringAsFixed(5)}';
    }
    return 'X: ${x?.toStringAsFixed(3)} | Y: ${y?.toStringAsFixed(3)} | Z: ${z?.toStringAsFixed(3)}';
  }
}
