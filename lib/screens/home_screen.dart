import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'sensors_screen.dart';
import 'gps_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    SensorsScreen(),
    GpsScreen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Sensores',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'GPS',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

// ─── Tab de bienvenida / Dashboard ───────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _isOnline = false;
  bool _checking = true;
  final SupabaseService _svc = SupabaseService();

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final ok = await _svc.checkConnection();
    if (mounted) {
      setState(() {
        _isOnline = ok;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: Colors.white, size: 36),
                      const SizedBox(width: 12),
                      const Text(
                        'SensorTrack',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _check,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Reconectar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitoreo de sensores en tiempo real',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // ── Tarjetas ────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Estado de conexión
                    _StatusCard(
                      icon: _checking
                          ? Icons.cloud_sync
                          : _isOnline
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                      iconColor: _checking
                          ? Colors.orange
                          : _isOnline
                              ? Colors.green
                              : Colors.red,
                      title: 'Supabase',
                      subtitle: _checking
                          ? 'Verificando conexión...'
                          : _isOnline
                              ? 'Conectado y listo'
                              : 'Sin conexión — revisa tu URL/Key',
                    ),
                    const SizedBox(height: 12),
                    // Sensores disponibles
                    const _StatusCard(
                      icon: Icons.speed,
                      iconColor: Colors.blue,
                      title: 'Acelerómetro',
                      subtitle: 'Disponible • Ejes X, Y, Z',
                    ),
                    const SizedBox(height: 12),
                    const _StatusCard(
                      icon: Icons.threesixty,
                      iconColor: Colors.purple,
                      title: 'Giroscopio',
                      subtitle: 'Disponible • Ejes X, Y, Z',
                    ),
                    const SizedBox(height: 12),
                    const _StatusCard(
                      icon: Icons.gps_fixed,
                      iconColor: Colors.teal,
                      title: 'GPS / Ubicación',
                      subtitle: 'Disponible • Lat, Lon, Precisión',
                    ),
                    const SizedBox(height: 24),
                    // Info de la app
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acerca del taller',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'SensorTrack captura datos de sensores físicos '
                              'del dispositivo (Acelerómetro, Giroscopio y GPS) '
                              'y los almacena en Supabase para su análisis histórico.',
                              style: TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Plataformas Móviles • Ciclo Oct 2026 - Feb 2027',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
