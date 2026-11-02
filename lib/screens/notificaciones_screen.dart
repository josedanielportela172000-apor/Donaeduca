import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/necesidad_model.dart';
import '../models/usuario_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import 'necesidad_detalle_screen.dart';

class NotificacionesScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const NotificacionesScreen({super.key, required this.usuario});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  static const int _pageSize = 20;
  final List<NotificacionModel> _extra = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = false;
  bool _loadingMore = false;

  Future<void> _openNecesidad(String? necesidadId) async {
    if (necesidadId == null) return;
    final NecesidadModel? necesidad =
        await FirestoreService.instance.getNecesidadById(necesidadId);
    if (!mounted) return;
    if (necesidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta necesidad ya no existe')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NecesidadDetalleScreen(
        necesidad: necesidad,
        usuario: widget.usuario,
      ),
    ));
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await NotificationService.instance.getNotificacionesPage(
        widget.usuario.uid,
        lastDoc: _lastDoc!,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _extra.addAll(page.docs
            .map((d) => NotificacionModel.fromMap(d.id, d.data()))
            .toList());
        _lastDoc = page.docs.isNotEmpty ? page.docs.last : null;
        _hasMore = page.docs.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar más notificaciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () => service.marcarTodasLeidas(widget.usuario.uid),
            child: const Text(
              'Marcar todas',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.streamNotificacionesQuery(widget.usuario.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(
              child: Text('No se pudieron cargar las notificaciones.\n${snap.error}',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey)),
            );
          }
          final pageDocs = snap.data?.docs ?? [];
          final page = pageDocs
              .map((d) => NotificacionModel.fromMap(d.id, d.data()))
              .toList();
          _lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;
          _hasMore = pageDocs.length >= _pageSize;

          final ids = <String>{for (final n in page) n.id};
          final lista = [
            ...page,
            ..._extra.where((n) => !ids.contains(n.id)),
          ];

          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No tienes notificaciones aún.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 8),
                  const Text('Aquí verás donaciones y nuevas necesidades.',
                      style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lista.length + (_hasMore ? 1 : 0),
            separatorBuilder: (_, i) {
              if (i == lista.length - 1) return const SizedBox.shrink();
              return const Divider(height: 1);
            },
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
              final n = lista[i];
              final icon = n.tipo == 'donacion'
                  ? Icons.favorite_rounded
                  : Icons.campaign_rounded;
              final color = n.tipo == 'donacion' ? AppColors.secondary : AppColors.primary;
              return ListTile(
                onTap: () {
                  service.marcarLeida(widget.usuario.uid, n.id);
                  _openNecesidad(n.necesidadId);
                },
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  n.titulo,
                  style: TextStyle(
                    fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(n.mensaje, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(n.fecha),
                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                  ],
                ),
                trailing: n.leida
                    ? null
                    : const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 10, height: 10),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
