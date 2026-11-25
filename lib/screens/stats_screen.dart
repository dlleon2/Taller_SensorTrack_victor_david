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
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getStats();
      if (mounted) {
        setState(() => _stats = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _stats['total'] ?? 0;
    final accelCount = _stats['accelerometer'] ?? 0;
    final gyroCount = _stats['gyroscope'] ?? 0;
    final gpsCount = _stats['gps'] ?? 0;
    final lastGps = _stats['lastGps'] as SensorReading?;
    final minX = _stats['minX'] as double?;
    final maxX = _stats['maxX'] as double?;
    final recentAccel = (_stats['recentAccel'] as List<SensorReading>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Totales ────────────────────────────────
                Row(
                  children: [
                    _StatBox(
                      label: 'Total',
                      value: '$total',
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'Acelerómetro',
                      value: '$accelCount',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'Giroscopio',
                      value: '$gyroCount',
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'GPS',
                      value: '$gpsCount',
                      color: Colors.teal,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Min / Max Acelerómetro X ───────────────
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acelerómetro — Eje X',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MinMaxTile(
                                label: 'Mínimo',
                                value: minX != null
                                    ? minX.toStringAsFixed(3)
                                    : '—',
                                icon: Icons.arrow_downward,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MinMaxTile(
                                label: 'Máximo',
                                value: maxX != null
                                    ? maxX.toStringAsFixed(3)
                                    : '—',
                                icon: Icons.arrow_upward,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Última ubicación GPS ───────────────────
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Última ubicación GPS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (lastGps == null)
                          const Text(
                            'Sin registros GPS todavía.',
                            style: TextStyle(color: Colors.black54),
                          )
                        else ...[
                          _InfoRow(
                            Icons.north,
                            'Latitud',
                            '${lastGps.latitude?.toStringAsFixed(6)}°',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            Icons.east,
                            'Longitud',
                            '${lastGps.longitude?.toStringAsFixed(6)}°',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            Icons.my_location,
                            'Precisión',
                            '${lastGps.accuracy?.toStringAsFixed(1)} m',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Gráfica de Acelerómetro X ──────────────
                if (recentAccel.isNotEmpty) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evolución Acelerómetro (eje X)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Últimas 20 mediciones',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (v, _) => Text(
                                        v.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: recentAccel
                                        .reversed
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(
                                              e.key.toDouble(),
                                              e.value.x ?? 0,
                                            ))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Distribución por sensor (gráfico de barras) ──
                if (total > 0)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribución por sensor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 160,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, _) {
                                        const labels = [
                                          'Aceleró.',
                                          'Girosco.',
                                          'GPS',
                                        ];
                                        if (v.toInt() < labels.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              labels[v.toInt()],
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [
                                    BarChartRodData(
                                      toY: accelCount.toDouble(),
                                      color: Colors.blue,
                                      width: 28,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 1, barRods: [
                                    BarChartRodData(
                                      toY: gyroCount.toDouble(),
                                      color: Colors.purple,
                                      width: 28,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ]),
                                  BarChartGroupData(x: 2, barRods: [
                                    BarChartRodData(
                                      toY: gpsCount.toDouble(),
                                      color: Colors.teal,
                                      width: 28,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinMaxTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MinMaxTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 11)),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ],
    );
  }
}
