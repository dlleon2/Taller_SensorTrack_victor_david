import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';
import '../services/supabase_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final SensorService _sensorService = SensorService();
  final SupabaseService _supabaseService = SupabaseService();

  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  bool _isCapturing = false;
  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _sensorService.onAccelUpdate = (x, y, z) {
      if (mounted) setState(() { _accelX = x; _accelY = y; _accelZ = z; });
    };
    _sensorService.onGyroUpdate = (x, y, z) {
      if (mounted) setState(() { _gyroX = x; _gyroY = y; _gyroZ = z; });
    };
  }

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }

  void _toggleCapture() {
    setState(() => _isCapturing = !_isCapturing);
    if (_isCapturing) {
      _sensorService.startAll();
      _setStatus('Capturando datos en tiempo real...');
    } else {
      _sensorService.stopAll();
      _setStatus('Captura detenida.');
    }
  }

  void _setStatus(String msg) {
    setState(() => _statusMessage = msg);
  }

  Future<void> _saveAccelerometer() async {
    setState(() => _isSaving = true);
    try {
      final reading = SensorReading(
        sensorType: 'accelerometer',
        x: _accelX,
        y: _accelY,
        z: _accelZ,
      );
      await _supabaseService.insertReading(reading);
      _setStatus('✅ Acelerómetro guardado en Supabase');
    } catch (e) {
      _setStatus('❌ Error al guardar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveGyroscope() async {
    setState(() => _isSaving = true);
    try {
      final reading = SensorReading(
        sensorType: 'gyroscope',
        x: _gyroX,
        y: _gyroY,
        z: _gyroZ,
      );
      await _supabaseService.insertReading(reading);
      _setStatus('✅ Giroscopio guardado en Supabase');
    } catch (e) {
      _setStatus('❌ Error al guardar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Switch(
              value: _isCapturing,
              onChanged: (_) => _toggleCapture(),
              thumbColor: WidgetStateProperty.all(Colors.white),
              trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                    ? Colors.green
                    : Colors.white30,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Estado de captura ───────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isCapturing
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCapturing ? Colors.green : Colors.grey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCapturing ? Icons.fiber_manual_record : Icons.stop_circle,
                  color: _isCapturing ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCapturing ? 'Capturando datos...' : 'Captura detenida',
                  style: TextStyle(
                    color: _isCapturing ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Acelerómetro ────────────────────────────────
          _SensorCard(
            title: 'Acelerómetro',
            icon: Icons.speed,
            color: Colors.blue,
            unit: 'm/s²',
            x: _accelX,
            y: _accelY,
            z: _accelZ,
            onSave: _isSaving ? null : _saveAccelerometer,
          ),

          const SizedBox(height: 16),

          // ── Giroscopio ──────────────────────────────────
          _SensorCard(
            title: 'Giroscopio',
            icon: Icons.360,
            color: Colors.purple,
            unit: 'rad/s',
            x: _gyroX,
            y: _gyroY,
            z: _gyroZ,
            onSave: _isSaving ? null : _saveGyroscope,
          ),

          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Widget de tarjeta de sensor ─────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final double x, y, z;
  final VoidCallback? onSave;

  const _SensorCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.x,
    required this.y,
    required this.z,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(unit,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            _AxisRow(label: 'X', value: x, color: Colors.red),
            const SizedBox(height: 8),
            _AxisRow(label: 'Y', value: y, color: Colors.green),
            const SizedBox(height: 8),
            _AxisRow(label: 'Z', value: z, color: Colors.blue),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar medición'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AxisRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: ((value + 20) / 40).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            value.toStringAsFixed(3),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
