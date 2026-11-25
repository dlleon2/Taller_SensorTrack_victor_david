import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_reading.dart';

/// Servicio centralizado para todas las operaciones con Supabase
class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _table = 'sensor_readings';

  // ─── INSERT ──────────────────────────────────────────────────────────────────

  /// Inserta una lectura de sensor en la tabla de Supabase
  Future<void> insertReading(SensorReading reading) async {
    await _client.from(_table).insert(reading.toMap());
  }

  // ─── SELECT ──────────────────────────────────────────────────────────────────

  /// Obtiene las últimas [limit] lecturas ordenadas por fecha descendente
  Future<List<SensorReading>> getReadings({int limit = 50}) async {
    final response = await _client
        .from(_table)
        .select()
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene las lecturas de un sensor específico
  Future<List<SensorReading>> getReadingsByType(
      String sensorType, {
      int limit = 50,
    }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('sensor_type', sensorType)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────────

  /// Elimina un registro por su UUID
  Future<void> deleteReading(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ─── ESTADÍSTICAS ─────────────────────────────────────────────────────────────

  /// Calcula estadísticas generales: conteos, min/max, última ubicación GPS
  Future<Map<String, dynamic>> getStats() async {
    // 1. Obtener todos los registros (últimos 500)
    final all = await getReadings(limit: 500);

    final accelList =
        all.where((r) => r.sensorType == 'accelerometer').toList();
    final gyroList =
        all.where((r) => r.sensorType == 'gyroscope').toList();
    final gpsList =
        all.where((r) => r.sensorType == 'gps').toList();

    // Min/Max eje X del acelerómetro
    double? minX, maxX;
    if (accelList.isNotEmpty) {
      final xValues = accelList.map((r) => r.x ?? 0.0).toList();
      xValues.sort();
      minX = xValues.first;
      maxX = xValues.last;
    }

    // Última ubicación GPS
    SensorReading? lastGps = gpsList.isNotEmpty ? gpsList.first : null;

    // Últimas 20 lecturas del acelerómetro para la gráfica
    final recentAccel = accelList.take(20).toList();

    return {
      'total': all.length,
      'accelerometer': accelList.length,
      'gyroscope': gyroList.length,
      'gps': gpsList.length,
      'minX': minX,
      'maxX': maxX,
      'lastGps': lastGps,
      'recentAccel': recentAccel,
    };
  }

  // ─── CONECTIVIDAD ─────────────────────────────────────────────────────────────

  /// Verifica si Supabase responde correctamente (ping)
  Future<bool> isConnected() async {
    try {
      await _client.from(_table).select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}
