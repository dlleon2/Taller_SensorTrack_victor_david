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
  String _filter = 'todos';

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getReadings(limit: 100);
      setState(() => _readings = data);
    } catch (e) {
      _showSnack('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReading(SensorReading r) async {
    if (r.id == null) return;
    try {
      await _supabaseService.deleteReading(r.id!);
      setState(() => _readings.remove(r));
      _showSnack('Registro eliminado');
    } catch (e) {
      _showSnack('Error al eliminar: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<SensorReading> get _filtered {
    if (_filter == 'todos') return _readings;
    return _readings.where((r) => r.sensorType == _filter).toList();
  }

  Color _colorFor(String type) {
    switch (type) {
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

  IconData _iconFor(String type) {
    switch (type) {
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _colorFor(r.sensorType).withOpacity(0.15),
                  child: Icon(_iconFor(r.sensorType),
                      color: _colorFor(r.sensorType)),
                ),
                const SizedBox(width: 12),
                Text(r.displayTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            if (r.sensorType != 'gps') ...[
              _DetailRow('Eje X', r.x?.toStringAsFixed(6) ?? 'N/A'),
              _DetailRow('Eje Y', r.y?.toStringAsFixed(6) ?? 'N/A'),
              _DetailRow('Eje Z', r.z?.toStringAsFixed(6) ?? 'N/A'),
            ],
            if (r.sensorType == 'gps') ...[
              _DetailRow('Latitud', '${r.latitude?.toStringAsFixed(8)}°'),
              _DetailRow('Longitud', '${r.longitude?.toStringAsFixed(8)}°'),
              _DetailRow('Precision', '${r.accuracy?.toStringAsFixed(2)} m'),
            ],
            _DetailRow('Fecha/Hora',
                r.recordedAt != null
                    ? fmt.format(r.recordedAt!.toLocal())
                    : 'N/A'),
            _DetailRow('ID', r.id ?? 'N/A'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReadings,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos', Icons.list_alt),
                  const SizedBox(width: 8),
                  _buildFilterChip('Acelerometro', 'accelerometer', Icons.speed),
                  const SizedBox(width: 8),
                  _buildFilterChip('Giroscopio', 'gyroscope', Icons.threesixty),
                  const SizedBox(width: 8),
                  _buildFilterChip('GPS', 'gps', Icons.gps_fixed),
                ],
              ),
            ),
          ),
          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${filtered.length} registros',
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ),
          ),
          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 60, color: Colors.black26),
                            SizedBox(height: 12),
                            Text('Sin registros',
                                style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReadings,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
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
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteReading(r),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 1,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _colorFor(r.sensorType)
                                        .withOpacity(0.12),
                                    child: Icon(_iconFor(r.sensorType),
                                        color: _colorFor(r.sensorType),
                                        size: 20),
                                  ),
                                  title: Text(r.displayTitle,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  subtitle: Text(r.displayValues,
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                    r.recordedAt != null
                                        ? fmt.format(r.recordedAt!.toLocal())
                                        : '—',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45),
                                  ),
                                  onTap: () => _showDetail(r),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
