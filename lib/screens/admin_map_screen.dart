import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();

  // Caja geográfica de Cali (evita marcadores caídos fuera de la ciudad).
  static const double _latMin = 3.25;
  static const double _latMax = 3.60;
  static const double _lngMin = -76.70;
  static const double _lngMax = -76.35;

  // Coordenadas base (Cali, Colombia)
  final LatLng _center = const LatLng(3.4516, -76.5320);

  static bool _enCali(double lat, double lng) =>
      lat >= _latMin && lat <= _latMax && lng >= _lngMin && lng <= _lngMax;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getAllUsuarios(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final colegios = snapshot.data!
            .where((u) => (u['tipo'] ?? '').toString().toLowerCase() == 'colegio')
            .toList();

        // Separamos los que tienen coordenadas válidas de los que no.
        final conUbicacion = <Map<String, dynamic>>[];
        final sinUbicacion = <Map<String, dynamic>>[];
        for (final c in colegios) {
          final lat = (c['lat'] as num?)?.toDouble();
          final lng = (c['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && _enCali(lat, lng)) {
            conUbicacion.add(c);
          } else {
            sinUbicacion.add(c);
          }
        }

        return Column(
          children: [
            if (sinUbicacion.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.accent.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.dark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${sinUbicacion.length} colegio(s) aún sin ubicación definida. '
                        'Solicita que ajusten su punto en el mapa desde su perfil.',
                        style: const TextStyle(fontSize: 12, color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.donaeduca.app',
                  ),
                  MarkerLayer(
                    markers: conUbicacion.map((colegio) {
                      final lat = (colegio['lat'] as num).toDouble();
                      final lng = (colegio['lng'] as num).toDouble();
                      final preciso = colegio['geo_preciso'] == true;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            _showColegioInfo(colegio);
                          },
                          child: Icon(
                            Icons.school,
                            color: preciso ? AppColors.primary : AppColors.grey,
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showColegioInfo(Map<String, dynamic> colegio) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(colegio['nombre'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(colegio['email'] ?? '', style: const TextStyle(color: AppColors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(colegio['direccion'] ?? ''),
            const SizedBox(height: 8),
            const Text('Comuna:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(colegio['comuna'] ?? 'N/A'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
