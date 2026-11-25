import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_reading.dart';
import '../services/supabase_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _supabaseService.getStats();
      setState(() => _stats = stats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('No hay datos'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SectionTitle('Resumen general'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total\nRegistros',
                              value: '${_stats!['total']}',
                              icon: Icons.storage,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Aceler.',
                              value: '${_stats!['accelerometer']}',
                              icon: Icons.speed,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Giroscopio',
                              value: '${_stats!['gyroscope']}',
                              icon: Icons.threesixty,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'GPS',
                              value: '${_stats!['gps']}',
                              icon: Icons.gps_fixed,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Distribución por sensor'),
                      const SizedBox(height: 12),
                      _PieChartWidget(stats: _stats!),
                      const SizedBox(height: 24),
                      if (_stats!['minX'] != null && _stats!['maxX'] != null) ...[
                        _SectionTitle('Acelerómetro - Eje X'),
                        const SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _MinMaxItem(
                                  label: 'Mínimo',
                                  value: (_stats!['minX'] as double)
                                      .toStringAsFixed(3),
                                  color: Colors.blue,
                                ),
                                Container(
                                    height: 40, width: 1, color: Colors.black12),
                                _MinMaxItem(
                                  label: 'Máximo',
                                  value: (_stats!['maxX'] as double)
                                      .toStringAsFixed(3),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle('Últimas lecturas - Acelerómetro X'),
                        const SizedBox(height: 12),
                        _LineChartWidget(
                          readings: (_stats!['recentAccel'] as List<SensorReading>)
                              .reversed
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_stats!['lastGps'] != null) ...[
                        _SectionTitle('Última ubicación GPS'),
                        const SizedBox(height: 12),
                        _GpsCard(reading: _stats!['lastGps'] as SensorReading),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _PieChartWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final accel = (stats['accelerometer'] as int).toDouble();
    final gyro = (stats['gyroscope'] as int).toDouble();
    final gps = (stats['gps'] as int).toDouble();
    final total = accel + gyro + gps;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Sin datos para graficar')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (accel > 0)
                      PieChartSectionData(
                        value: accel,
                        color: Colors.blue,
                        title: '${(accel / total * 100).toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    if (gyro > 0)
                      PieChartSectionData(
                        value: gyro,
                        color: Colors.purple,
                        title: '${(gyro / total * 100).toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    if (gps > 0)
                      PieChartSectionData(
                        value: gps,
                        color: Colors.teal,
                        title: '${(gps / total * 100).toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                  ],
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend('Aceleróm.', Colors.blue),
                const SizedBox(width: 16),
                _Legend('Giroscop.', Colors.purple),
                const SizedBox(width: 16),
                _Legend('GPS', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<SensorReading> readings;
  const _LineChartWidget({required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Card(
        child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Sin datos de acelerómetro'))),
      );
    }

    final spots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.x ?? 0.0))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.black12, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10, color: Colors.black45),
                    ),
                  ),
                ),
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2.5,
                  dotData: FlDotData(show: spots.length <= 10),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinMaxItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MinMaxItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace')),
        const Text('m/s²',
            style: TextStyle(color: Colors.black38, fontSize: 11)),
      ],
    );
  }
}

class _GpsCard extends StatelessWidget {
  final SensorReading reading;
  const _GpsCard({required this.reading});

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
            const Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.teal),
                SizedBox(width: 8),
                Text('Ultima ubicacion registrada',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            _GpsRow('Latitud', '${reading.latitude?.toStringAsFixed(6)}°'),
            const SizedBox(height: 6),
            _GpsRow('Longitud', '${reading.longitude?.toStringAsFixed(6)}°'),
            const SizedBox(height: 6),
            _GpsRow('Precision', '${reading.accuracy?.toStringAsFixed(1)} m'),
          ],
        ),
      ),
    );
  }
}

class _GpsRow extends StatelessWidget {
  final String l;
  final String v;
  const _GpsRow(this.l, this.v);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(l, style: const TextStyle(color: Colors.black54))),
        Text(v,
            style: const TextStyle(
                fontFamily: 'monospace', fontWeight: FontWeight.w600)),
      ],
    );
  }
}
