import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/firestore_service.dart';
import '../services/geocoding_service.dart';
import '../utils/app_theme.dart';

/// Pantalla para que el colegio ajuste manualmente el punto exacto
/// de su ubicación en el mapa. Guarda directamente en Firestore y retorna [LatLng].
class MapLocationPickerScreen extends StatefulWidget {
  /// Ubicación inicial (la geocodificada o la ya guardada).
  final LatLng? initialLocation;

  /// Dirección escrita por el usuario, para mostrarla como referencia.
  final String? direccion;

  /// Comuna escrita por el usuario (opcional).
  final String? comuna;

  /// UID del usuario en Firestore (para persistir la ubicación de inmediato).
  final String? usuarioId;

  const MapLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.direccion,
    this.comuna,
    this.usuarioId,
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  static const LatLng _cali = LatLng(3.4516, -76.5320);

  final MapController _mapController = MapController();
  late LatLng _punto;
  double _zoom = 16;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _punto = widget.initialLocation ?? _cali;

    // Si no había ubicación previa pero sí hay dirección escrita,
    // intentamos centrar el mapa cerca de su calle automáticamente.
    if (widget.initialLocation == null && widget.direccion != null && widget.direccion!.isNotEmpty) {
      _geolocalizarDireccionInicial();
    }
  }

  Future<void> _geolocalizarDireccionInicial() async {
    try {
      final geo = await GeocodingService.instance.geocodeDireccion(
        direccion: widget.direccion!,
        comuna: widget.comuna,
      );
      if (geo != null && mounted) {
        final nuevoPunto = LatLng(geo.lat, geo.lng);
        setState(() => _punto = nuevoPunto);
        _mapController.move(nuevoPunto, 16.5);
      }
    } catch (_) {
      // Si falla, el mapa permanece en Cali sin bloquear al usuario
    }
  }

  void _onTap(TapPosition _, LatLng point) {
    setState(() => _punto = point);
  }

  void _zoomIn() {
    setState(() => _zoom = (_zoom + 1.0).clamp(5, 19).toDouble());
    _mapController.move(_punto, _zoom);
  }

  void _zoomOut() {
    setState(() => _zoom = (_zoom - 1.0).clamp(5, 19).toDouble());
    _mapController.move(_punto, _zoom);
  }

  void _centerOnPin() {
    setState(() => _zoom = 17);
    _mapController.move(_punto, 17);
  }

  void _fijarPinEnCentro() {
    final center = _mapController.camera.center;
    setState(() => _punto = center);
  }

  Future<void> _guardarUbicacion() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    if (widget.usuarioId != null && widget.usuarioId!.isNotEmpty) {
      try {
        await FirestoreService.instance.updateUsuario(widget.usuarioId!, {
          'lat': _punto.latitude,
          'lng': _punto.longitude,
          'geo_preciso': true,
        });
      } catch (e) {
        debugPrint('Error al guardar ubicación en Firestore: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pop(_punto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _guardarUbicacion,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            label: const Text('Guardar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _punto,
              initialZoom: _zoom,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.donaeduca.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _punto,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.error,
                      size: 56,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tarjeta con instrucciones y dirección de referencia
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Toca el mapa en el punto exacto del colegio',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                          ),
                          if (widget.direccion != null && widget.direccion!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.direccion!,
                              style: TextStyle(fontSize: 12, color: subtitleColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            '${_punto.latitude.toStringAsFixed(6)}, ${_punto.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Controles de zoom y centrado
          Positioned(
            right: 12,
            bottom: 130,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: cardColor,
                  foregroundColor: textColor,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: cardColor,
                  foregroundColor: textColor,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 74,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'pin_center',
                  tooltip: 'Fijar pin en centro',
                  backgroundColor: cardColor,
                  foregroundColor: AppColors.primary,
                  onPressed: _fijarPinEnCentro,
                  child: const Icon(Icons.add_location_alt_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center',
                  tooltip: 'Centrar en el pin',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: _centerOnPin,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),
          // Botón principal
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarUbicacion,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Guardando ubicación...' : 'Guardar esta ubicación',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}