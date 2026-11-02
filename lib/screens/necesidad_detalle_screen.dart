import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/necesidad_model.dart';
import '../models/usuario_model.dart';
import '../models/donacion_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/categorias.dart';
import 'login_screen.dart';

class NecesidadDetalleScreen extends StatefulWidget {
  final NecesidadModel necesidad;
  final UsuarioModel? usuario;

  const NecesidadDetalleScreen({super.key, required this.necesidad, required this.usuario});

  @override
  State<NecesidadDetalleScreen> createState() => _NecesidadDetalleScreenState();
}

class _NecesidadDetalleScreenState extends State<NecesidadDetalleScreen> {
  bool _isLoading = false;
  UsuarioModel? _colegio;

  @override
  void initState() {
    super.initState();
    _cargarColegio();
  }

  Future<void> _cargarColegio() async {
    final c = await FirestoreService.instance.getUsuario(widget.necesidad.colegioId);
    if (mounted) setState(() => _colegio = c);
  }

  void _verEnMapa() {
    final c = _colegio;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final tieneCoords = c != null && c.lat != null && c.lng != null;
        final center = c != null && c.lat != null && c.lng != null
            ? LatLng(c.lat!, c.lng!)
            : const LatLng(3.4516, -76.5320);
        return Container(
          height: 460,
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubicación del colegio',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (c != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Text(
                    '${c.nombre} — ${c.direccion ?? ''}${(c.comuna ?? '').isNotEmpty ? ', ${c.comuna}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: tieneCoords ? 16 : 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.donaeduca.app',
                        ),
                        if (tieneCoords)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: center,
                                width: 50,
                                height: 50,
                                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (!tieneCoords)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Material(
                          color: Colors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Este colegio aún no ha definido su ubicación en el mapa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.grey),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String texto) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(texto, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acción requerida'),
        content: const Text('Para realizar una donación, necesitas iniciar sesión o crear una cuenta.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Iniciar Sesión'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailVerificationRequiredDialog() async {
    bool reenviando = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread_rounded, color: AppColors.error),
              SizedBox(width: 10),
              Expanded(child: Text('Verificación requerida', style: TextStyle(fontSize: 18))),
            ],
          ),
          content: const Text(
            'Para realizar donaciones a colegios, debes verificar tu correo electrónico. Esta medida protege a las instituciones y garantiza la transparencia de las donaciones.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: reenviando ? null : () async {
                setDialogState(() => reenviando = true);
                final err = await AuthService.instance.enviarVerificacion();
                if (ctx.mounted && mounted) {
                  setDialogState(() => reenviando = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Correo de verificación reenviado. Revisa tu bandeja de entrada.'),
                      backgroundColor: err == null ? AppColors.secondary : AppColors.error,
                    ),
                  );
                }
              },
              child: reenviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reenviar correo'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isVerif = await AuthService.instance.reloadEmailVerification();
                if (ctx.mounted && mounted) {
                  Navigator.pop(ctx);
                  if (isVerif) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Correo verificado con éxito! Procesando donación...'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                    _donar();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aún no has verificado el enlace que llegó a tu correo.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya lo verifiqué'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _donar() async {
    if (widget.usuario == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    final isVerif = await AuthService.instance.reloadEmailVerification();
    if (!isVerif) {
      if (mounted) _showEmailVerificationRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final donacion = DonacionModel(
        id: '',
        empresaId: widget.usuario!.uid,
        empresaNombre: widget.usuario!.nombre,
        colegioId: widget.necesidad.colegioId,
        colegioNombre: widget.necesidad.colegioNombre,
        necesidadId: widget.necesidad.id,
        descripcion: widget.necesidad.descripcion,
        fecha: DateTime.now(),
        empresaTelefono: widget.usuario!.telefono,
        empresaEmail: widget.usuario!.email,
      );
      await FirestoreService.instance.donar(donacion: donacion, necesidadId: widget.necesidad.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu donación!'), backgroundColor: AppColors.secondary),
      );
      Navigator.pop(context); // Volver al inicio
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la donación: $e'), backgroundColor: AppColors.error),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.necesidad;
    final formattedDate = DateFormat('dd MMM yyyy').format(n.fecha);
    final isGuest = widget.usuario == null;
    final isEmpresa = !isGuest && widget.usuario!.tipo == 'empresa';
    final canDonate = isGuest || isEmpresa; // Los colegios no donan

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Necesidad')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.imagenUrl != null && n.imagenUrl!.isNotEmpty)
              Image.network(
                n.imagenUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.grey.withOpacity(0.1),
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 50)),
                ),
              )
            else
              Container(
                height: 200,
                color: AppColors.primary.withOpacity(0.1),
                child: const Center(child: Icon(Icons.volunteer_activism_rounded, size: 80, color: AppColors.primary)),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(normalizarCategoria(n.categoria), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                      ),
                      const Spacer(),
                      Text(formattedDate, style: const TextStyle(color: AppColors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    n.descripcion,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppColors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n.colegioNombre,
                          style: const TextStyle(fontSize: 16, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Acerca de esta solicitud',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El colegio ${n.colegioNombre} ha solicitado donaciones en la categoría de ${normalizarCategoria(n.categoria).toLowerCase()}. '
                    'Al donar, ayudarás directamente a mejorar las condiciones educativas de la institución.',
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sobre el colegio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          if (_colegio == null)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                  SizedBox(width: 12),
                                  Text('Cargando información del colegio...', style: TextStyle(color: AppColors.grey)),
                                ],
                              ),
                            )
                          else ...[
                            if ((_colegio!.direccion ?? '').isNotEmpty)
                              _infoTile(Icons.location_on_outlined, _colegio!.direccion!),
                            if ((_colegio!.comuna ?? '').isNotEmpty)
                              _infoTile(Icons.map_outlined, _colegio!.comuna!),
                            if ((_colegio!.telefono ?? '').isNotEmpty)
                              _infoTile(Icons.phone_outlined, _colegio!.telefono!),
                            if (_colegio!.email.isNotEmpty)
                              _infoTile(Icons.email_outlined, _colegio!.email),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              leading: const Icon(Icons.map_rounded, color: AppColors.primary),
                              title: const Text('Ver ubicación en el mapa', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                              onTap: _verEnMapa,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (canDonate && n.estado == 'pendiente')
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _donar,
                        icon: _isLoading 
                            ? const SizedBox.shrink() 
                            : const Icon(Icons.favorite_rounded),
                        label: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                            : const Text('¡Donar Ahora!', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  if (n.estado == 'cubierta')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Text('Esta necesidad ya ha sido cubierta', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
