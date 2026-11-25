import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Servicio que gestiona los streams del Acelerómetro y Giroscopio
class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  /// Callbacks que las pantallas asignan para recibir actualizaciones
  void Function(double x, double y, double z)? onAccelUpdate;
  void Function(double x, double y, double z)? onGyroUpdate;

  /// Inicia la escucha de ambos sensores
  void startAll() {
    _startAccelerometer();
    _startGyroscope();
  }

  /// Detiene ambos sensores
  void stopAll() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  void _startAccelerometer() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      onAccelUpdate?.call(event.x, event.y, event.z);
    });
  }

  void _startGyroscope() {
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((event) {
      onGyroUpdate?.call(event.x, event.y, event.z);
    });
  }

  /// Libera todos los recursos
  void dispose() {
    stopAll();
  }
}
