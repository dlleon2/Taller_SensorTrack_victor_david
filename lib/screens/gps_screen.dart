import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/sensor_reading.dart';
import '../services/supabase_service.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  Position? _position;
  bool _isLoading = false;
  bool _isSaving = false;
  String _statusMessage = '';
  String _permissionStatus = 'No solicitado';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    setState(() => _permissionStatus = _permLabel(perm));
  }

  String _permLabel(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
        return 'Siempre ✅';
      case LocationPermission.whileInUse:
        return 'En uso ✅';
      case LocationPermission.denied:
        return 'Denegado ❌';
      case LocationPermission.deniedForever:
        return 'Denegado permanente ❌';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _requestAndGetLocation() async {
    setState(() { _isLoading = true; _statusMessage = ''; });

    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = '❌ El servicio de ubicación está deshabilitado.';
          _isLoading = false;
        });
        return;
      }

      // 2. Solicitar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage =
              '❌ Permiso denegado permanentemente. Ve a Ajustes del dispositivo.';
          _isLoading = false;
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = '❌ Permiso de ubicación denegado.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _permissionStatus = _permLabel(permission));

      // 3. Obtener posición
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _position = pos;
        _statusMessage = '✅ Ubicación obtenida correctamente';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_position == null) {
      setState(() => _statusMessage = '⚠️ Primero obtén tu ubicación.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final reading = SensorReading(
        sensorType: 'gps',
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        accuracy: _position!.accuracy,
      );
      await _supabaseService.insertReading(reading);
      setState(() => _statusMessage = '✅ Ubicación guardada en Supabase');
    } catch (e) {
      setState(() => _statusMessage = '❌ Error al guardar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(title: const Text('GPS / Ubicación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Permiso ─────────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A009688),
                child: Icon(Icons.security, color: Colors.teal),
              ),
              title: const Text('Permiso de ubicación',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_permissionStatus),
              trailing: TextButton(
                onPressed: _requestAndGetLocation,
                child: const Text('Solicitar'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Datos GPS ───────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0x1A009688),
                        child: Icon(Icons.gps_fixed, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      const Text('Coordenadas',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  _GpsRow(
                    label: 'Latitud',
                    value: _position != null
                        ? '${_position!.latitude.toStringAsFixed(6)}°'
                        : '—',
                    icon: Icons.north,
                  ),
                  const SizedBox(height: 10),
                  _GpsRow(
                    label: 'Longitud',
                    value: _position != null
                        ? '${_position!.longitude.toStringAsFixed(6)}°'
                        : '—',
                    icon: Icons.east,
                  ),
                  const SizedBox(height: 10),
                  _GpsRow(
                    label: 'Precisión',
                    value: _position != null
                        ? '${_position!.accuracy.toStringAsFixed(1)} m'
                        : '—',
                    icon: Icons.my_location,
                  ),
                  const SizedBox(height: 10),
                  _GpsRow(
                    label: 'Altitud',
                    value: _position != null
                        ? '${_position!.altitude.toStringAsFixed(1)} m'
                        : '—',
                    icon: Icons.height,
                  ),
                  const SizedBox(height: 10),
                  _GpsRow(
                    label: 'Fecha/Hora',
                    value: _position != null
                        ? fmt.format(_position!.timestamp.toLocal())
                        : '—',
                    icon: Icons.access_time,
                  ),
                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _requestAndGetLocation,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.gps_fixed),
                          label:
                              Text(_isLoading ? 'Obteniendo...' : 'Obtener'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving || _position == null
                              ? null
                              : _saveLocation,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_alt),
                          label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

class _GpsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GpsRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
