import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../screens/notificaciones_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

/// Campana de notificaciones con badge de no leídas.
class NotificationBell extends StatelessWidget {
  final UsuarioModel usuario;
  const NotificationBell({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.instance.streamNoLeidas(usuario.uid),
      builder: (context, snap) {
        final noLeidas = snap.data ?? 0;
        return IconButton(
          icon: Badge(
            isLabelVisible: noLeidas > 0,
            label: Text(noLeidas > 99 ? '99+' : '$noLeidas'),
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notificaciones',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NotificacionesScreen(usuario: usuario),
          )),
        );
      },
    );
  }
}
