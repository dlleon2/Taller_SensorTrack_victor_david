import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_reading.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<SensorReading> _readings = [];
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'accelerometer', 'gyroscope', 'gps'

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getReadings(limit: 100);
      if (mounted) {
        setState(() => _readings = data);
      }
    } catch (e) {
      _showSnack('Error al cargar datos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReading(SensorReading reading) async {
    if (reading.id == null) return;
    try {
      await _supabaseService.deleteReading(reading.id!);
      await _loadReadings();
      _showSnack('Registro eliminado correctamente');
    } catch (e) {
      _showSnack('Error al eliminar: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  List<SensorReading> get _filtered {
    if (_filter == 'all') return _readings;
    return _readings.where((r) => r.sensorType == _filter).toList();
  }

  void _showDetail(SensorReading r) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.sensorLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              r.recordedAt != null ? fmt.format(r.recordedAt!) : '—',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            if (r.x != null) _DetailRow('Eje X', r.x!.toStringAsFixed(6)),
            if (r.y != null) _DetailRow('Eje Y', r.y!.toStringAsFixed(6)),
            if (r.z != null) _DetailRow('Eje Z', r.z!.toStringAsFixed(6)),
            if (r.latitude != null)
              _DetailRow('Latitud', r.latitude!.toStringAsFixed(6)),
            if (r.longitude != null)
              _DetailRow('Longitud', r.longitude!.toStringAsFixed(6)),
            if (r.accuracy != null)
              _DetailRow('Precisión', '${r.accuracy!.toStringAsFixed(1)} m'),
            const SizedBox(height: 8),
            if (r.id != null)
              Text(
                'ID: ${r.id}',
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            onPressed: _loadReadings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  'Todo',
                  'all',
                  _filter,
                  (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  'Acelerómetro',
                  'accelerometer',
                  _filter,
                  (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  'Giroscopio',
                  'gyroscope',
                  _filter,
                  (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  'GPS',
                  'gps',
                  _filter,
                  (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ),

          // ── Contador ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} registros',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin registros aún en Supabase',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final r = filtered[i];
                          return Dismissible(
                            key: Key(r.id ?? '$i'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteReading(r),
                            child: _ReadingTile(
                              reading: r,
                              onTap: () => _showDetail(r),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onSelect;

  const _FilterChip(this.label, this.value, this.current, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback onTap;

  const _ReadingTile({required this.reading, required this.onTap});

  IconData get _icon {
    switch (reading.sensorType) {
      case 'accelerometer':
        return Icons.speed;
      case 'gyroscope':
        return Icons.threesixty;
      case 'gps':
        return Icons.gps_fixed;
      default:
        return Icons.sensors;
    }
  }

  Color get _color {
    switch (reading.sensorType) {
      case 'accelerometer':
        return Colors.blue;
      case 'gyroscope':
        return Colors.purple;
      case 'gps':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get _subtitle {
    if (reading.sensorType == 'gps') {
      return 'Lat: ${reading.latitude?.toStringAsFixed(4)}  '
          'Lon: ${reading.longitude?.toStringAsFixed(4)}';
    }
    return 'X: ${reading.x?.toStringAsFixed(2)}  '
        'Y: ${reading.y?.toStringAsFixed(2)}  '
        'Z: ${reading.z?.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm:ss');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.12),
          child: Icon(_icon, color: _color, size: 20),
        ),
        title: Text(
          reading.sensorLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          _subtitle,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        trailing: Text(
          reading.recordedAt != null ? fmt.format(reading.recordedAt!) : '—',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
