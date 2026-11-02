import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/usuario_model.dart';
import '../models/donacion_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../widgets/error_retry_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'certificado_preview_screen.dart';

class HistorialScreen extends StatefulWidget {
  final UsuarioModel usuario;
  
  const HistorialScreen({super.key, required this.usuario});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const int _pageSize = 20;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _donacionesStream;
  final List<DonacionModel> _extra = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _confirmandoId;

  @override
  void initState() {
    super.initState();
    _donacionesStream = _createStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _createStream() {
    if (widget.usuario.tipo == 'empresa') {
      return FirestoreService.instance
          .streamDonacionesEmpresaQuery(widget.usuario.uid);
    }
    return FirestoreService.instance
        .streamDonacionesColegioQuery(widget.usuario.uid);
  }

  void _retry() {
    setState(() {
      _extra.clear();
      _lastDoc = null;
      _hasMore = false;
      _donacionesStream = _createStream();
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await FirestoreService.instance.getDonacionesPage(
        empresaId: widget.usuario.tipo == 'empresa' ? widget.usuario.uid : null,
        colegioId: widget.usuario.tipo == 'empresa' ? null : widget.usuario.uid,
        lastDoc: _lastDoc!,
        limit: _pageSize,
      );
      if (!mounted) return;
      final nuevos = page.docs
          .map((d) => DonacionModel.fromMap(d.data(), d.id))
          .toList();
      setState(() {
        _extra.addAll(nuevos);
        _lastDoc = page.docs.isNotEmpty ? page.docs.last : null;
        _hasMore = page.docs.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar más donaciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _llamar(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el marcador')),
        );
      }
    }
  }

  Future<void> _enviarEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el correo')),
        );
      }
    }
  }

  Future<void> _confirmarRecibo(DonacionModel d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar recibo'),
        content: Text('¿Confirmas que ${d.empresaNombre} entregó realmente la donación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, recibida'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      setState(() => _confirmandoId = d.id);
      await FirestoreService.instance.confirmarRecibo(donacionId: d.id, donacion: d);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recibo confirmado. La empresa ha sido notificada.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo confirmar el recibo: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _confirmandoId = null);
    }
  }

  /// Contacto de la empresa que donó (visible solo para el colegio).
  Widget _buildContactSection(DonacionModel d) {
    final hasContacto = (d.empresaTelefono ?? '').isNotEmpty ||
        (d.empresaEmail ?? '').isNotEmpty;
    if (!hasContacto) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacto del donante',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if ((d.empresaTelefono ?? '').isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
              title: Text(d.empresaTelefono!, style: const TextStyle(fontSize: 14)),
              trailing: IconButton(
                icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                tooltip: 'Llamar',
                onPressed: () => _llamar(d.empresaTelefono!),
              ),
            ),
          if ((d.empresaEmail ?? '').isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.email_rounded, color: AppColors.primary, size: 20),
              title: Text(d.empresaEmail!, style: const TextStyle(fontSize: 14)),
              trailing: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                tooltip: 'Escribir correo',
                onPressed: () => _enviarEmail(d.empresaEmail!),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = widget.usuario.tipo == 'empresa';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _donacionesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return ErrorRetryWidget(
              message: 'No se pudieron cargar las donaciones.',
              onRetry: _retry,
            );
          }

          final pageDocs = snap.data?.docs ?? [];
          final page = pageDocs
              .map((d) => DonacionModel.fromMap(d.data(), d.id))
              .toList();
          // Guardamos el cursor y si hay más páginas disponibles.
          _lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;
          _hasMore = pageDocs.length >= _pageSize;

          // Combinamos la página en vivo con las páginas extra, sin duplicados.
          final ids = <String>{for (final d in page) d.id};
          final lista = [
            ...page,
            ..._extra.where((d) => !ids.contains(d.id)),
          ];

          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEmpresa ? Icons.volunteer_activism_outlined : Icons.inventory_2_outlined,
                      size: 80, color: AppColors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    isEmpresa ? 'Aún no has realizado donaciones.' : 'Aún no has recibido donaciones.',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: lista.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == lista.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _loadingMore
                        ? const CircularProgressIndicator(color: AppColors.primary)
                        : OutlinedButton.icon(
                            onPressed: _loadMore,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Cargar más'),
                          ),
                  ),
                );
              }
              final d = lista[i];
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(d.fecha);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isEmpresa ? Icons.school_rounded : Icons.business_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isEmpresa ? 'Para: ${d.colegioNombre}' : 'De: ${d.empresaNombre}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(d.descripcion, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _estadoColor(d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _estadoColor(d), width: 1),
                        ),
                        child: Text(
                          d.estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _estadoColor(d),
                          ),
                        ),
                      ),
                      // El colegio ve cómo contactar a la empresa que donó.
                      if (!isEmpresa) _buildContactSection(d),
                      if (!isEmpresa && d.estado == 'Pendiente') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _confirmandoId == d.id ? null : () => _confirmarRecibo(d),
                            icon: _confirmandoId == d.id
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.verified_rounded, size: 18),
                            label: Text(
                              _confirmandoId == d.id ? 'Confirmando...' : 'Confirmar Recibo',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formattedDate, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                          if (isEmpresa)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => CertificadoPreviewScreen(donacion: d),
                                ));
                              },
                              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                              label: const Text('Certificado'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                            ),
                          if (!isEmpresa)
                            TextButton.icon(
                              onPressed: () => _mostrarQROrDialog(d),
                              icon: const Icon(Icons.qr_code_rounded, size: 18),
                              label: const Text('Generar QR'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
    );
  }

  Color _estadoColor(DonacionModel d) {
    switch (d.estado) {
      case 'Completada':
        return Colors.green;
      case 'Recibida':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _mostrarQROrDialog(DonacionModel d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validación de Entrega', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: d.id,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Muestra este código al administrador o a la empresa para confirmar que has recibido la donación.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }
}
