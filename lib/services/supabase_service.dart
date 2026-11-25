import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_reading.dart';

/// Servicio centralizado para todas las operaciones con Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _table = 'sensor_readings';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Verifica si hay conexión activa con Supabase
  Future<bool> checkConnection() async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from(_table).select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error de conexion Supabase: $e');
      return false;
    }
  }

  /// Inserta una nueva lectura en Supabase
  Future<void> insertReading(SensorReading reading) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase no está configurado. Revisa lib/main.dart');
    }
    await client.from(_table).insert(reading.toJson());
  }

  /// Obtiene todas las lecturas ordenadas por fecha (más reciente primero)
  Future<List<SensorReading>> getReadings({int limit = 100}) async {
    final client = _client;
    if (client == null) return [];

    final response = await client
        .from(_table)
        .select()
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => SensorReading.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene lecturas filtradas por sensor
  Future<List<SensorReading>> getReadingsByType(
    String sensorType, {
    int limit = 100,
  }) async {
    final client = _client;
    if (client == null) return [];

    final response = await client
        .from(_table)
        .select()
        .eq('sensor_type', sensorType)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => SensorReading.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Elimina un registro por ID
  Future<void> deleteReading(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from(_table).delete().eq('id', id);
  }

  /// Obtiene estadísticas: total de registros, conteo por tipo y min/max
  Future<Map<String, dynamic>> getStats() async {
    final all = await getReadings(limit: 500);

    if (all.isEmpty) {
      return {
        'total': 0,
        'accelerometer': 0,
        'gyroscope': 0,
        'gps': 0,
        'lastGps': null,
        'minX': null,
        'maxX': null,
        'recentAccel': <SensorReading>[],
      };
    }

    final accel = all.where((r) => r.sensorType == 'accelerometer').toList();
    final gyro = all.where((r) => r.sensorType == 'gyroscope').toList();
    final gpsReadings = all.where((r) => r.sensorType == 'gps').toList();

    double? minX, maxX;
    if (accel.isNotEmpty) {
      final xValues = accel.map((r) => r.x ?? 0.0).toList();
      xValues.sort();
      minX = xValues.first;
      maxX = xValues.last;
    }

    SensorReading? lastGps = gpsReadings.isNotEmpty ? gpsReadings.first : null;

    return {
      'total': all.length,
      'accelerometer': accel.length,
      'gyroscope': gyro.length,
      'gps': gpsReadings.length,
      'lastGps': lastGps,
      'minX': minX,
      'maxX': maxX,
      'recentAccel': accel.take(20).toList(),
    };
  }
}
