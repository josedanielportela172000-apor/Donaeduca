import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/necesidad_model.dart';
import '../models/usuario_model.dart';
import '../screens/necesidad_detalle_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/navigation.dart';

/// Servicio central de notificaciones.
///
/// Se encarga de:
///  - Pedir permisos y mostrar notificaciones locales en primer plano.
///  - Guardar el token FCM en el usuario y suscribirlo a topics.
///  - Leer la bandeja de notificaciones desde `usuarios/{uid}/notificaciones`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'donaeduca';
  static const String _channelName = 'DonaEduca';
  static const String _channelDescription = 'Notificaciones de DonaEduca';
  static const int _inboxPageSize = 20;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _currentUid;
  bool _initialized = false;
  bool _topicsApplied = false;
  RemoteMessage? _pendingMessage;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      settings: settings,
      // El usuario tocó una notificación local mostrada en primer plano.
      onDidReceiveNotificationResponse: (response) {
        _navigateToNecesidadId(response.payload);
      },
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // La app está en primer plano: mostramos la notificación manualmente.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    // La app estaba en segundo plano y el usuario tocó la notificación.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

    // La app fue abierta desde una notificación (estaba cerrada).
    // Diferimos la navegación hasta que el árbol de widgets exista.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingMessage = initialMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPending());
    }
  }

  /// Registra el token FCM, suscripciones y el directorio público del usuario.
  Future<void> setupUser(UsuarioModel usuario) async {
    if (usuario.uid == _currentUid) return;
    _currentUid = usuario.uid;
    // Si cambió el usuario, permitimos suscribir/desuscribir topics de nuevo.
    _topicsApplied = false;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('usuarios').doc(usuario.uid).update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint('No se pudo guardar el token FCM: $e');
    }

    try {
      // Empresas reciben avisos de nuevas necesidades (broadcast).
      if (usuario.tipo == 'empresa' && !_topicsApplied) {
        await _messaging.subscribeToTopic('empresas');
        _topicsApplied = true;
      }
    } catch (e) {
      debugPrint('No se pudo suscribir al topic de empresas: $e');
    }

    // Auto-regenera el directorio público de empresas si falta
    // (por ejemplo, cuentas creadas antes de esta funcionalidad).
    if (usuario.tipo == 'empresa') {
      try {
        await _db.collection('empresas_publicas').doc(usuario.uid).set({
          'tipo': 'empresa',
          'nombre': usuario.nombre,
        });
      } catch (e) {
        debugPrint('No se pudo actualizar empresas_publicas: $e');
      }
    }
  }

  // --- Bandeja de notificaciones (in-app) ---

  /// Stream de la bandeja del usuario, ordenadas por fecha descendente.
  Stream<List<NotificacionModel>> streamNotificaciones(String uid) => _db
      .collection('usuarios')
      .doc(uid)
      .collection('notificaciones')
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => NotificacionModel.fromMap(d.id, d.data()))
          .toList());

  /// Primera página de la bandeja (en vivo, limitada).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotificacionesQuery(
          String uid) =>
      _db
          .collection('usuarios')
          .doc(uid)
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .limit(_inboxPageSize)
          .snapshots();

  /// Página siguiente de la bandeja usando el último documento como cursor.
  Future<QuerySnapshot<Map<String, dynamic>>> getNotificacionesPage(
    String uid, {
    required DocumentSnapshot lastDoc,
    int limit = _inboxPageSize,
  }) =>
      _db
          .collection('usuarios')
          .doc(uid)
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

  /// Cantidad de notificaciones sin leer.
  Stream<int> streamNoLeidas(String uid) => _db
      .collection('usuarios')
      .doc(uid)
      .collection('notificaciones')
      .where('leida', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  Future<void> marcarLeida(String uid, String notificacionId) async {
    try {
      await _db
          .collection('usuarios')
          .doc(uid)
          .collection('notificaciones')
          .doc(notificacionId)
          .update({'leida': true});
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  Future<void> marcarTodasLeidas(String uid) async {
    try {
      // Procesamos en lotes de a 450 para no superar el límite por batch.
      while (true) {
        final snap = await _db
            .collection('usuarios')
            .doc(uid)
            .collection('notificaciones')
            .where('leida', isEqualTo: false)
            .limit(450)
            .get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.update(d.reference, {'leida': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error al marcar todas como leídas: $e');
    }
  }

  // --- Interno ---

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || notification.title == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: message.messageId.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails:
          const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data['necesidadId'],
    );
  }

  void _handleOpenedApp(RemoteMessage message) {
    _navigateToNecesidadId(message.data['necesidadId']);
  }

  /// Navega a la pantalla de detalle de la necesidad tocada.
  Future<void> _navigateToNecesidadId(String? necesidadId) async {
    if (necesidadId == null || necesidadId.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      // Aún no existe el Navigator (app recién abierta); esperamos.
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPending());
      return;
    }

    final NecesidadModel? necesidad =
        await FirestoreService.instance.getNecesidadById(necesidadId);
    if (necesidad == null || !context.mounted) return;

    UsuarioModel? usuario;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      usuario = await AuthService.instance.getUsuario(user.uid);
    }
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NecesidadDetalleScreen(
        necesidad: necesidad,
        usuario: usuario,
      ),
    ));
  }

  void _processPending() {
    final pending = _pendingMessage;
    if (pending == null) return;
    if (navigatorKey.currentContext == null) {
      // Aún no existe el Navigator; reintentamos en el siguiente frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPending());
      return;
    }
    _pendingMessage = null;
    _navigateToNecesidadId(pending.data['necesidadId']);
  }
}

/// Modelo de una notificación de la bandeja in-app.
class NotificacionModel {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime fecha;
  final String? necesidadId;
  final String? donacionId;

  NotificacionModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
    this.necesidadId,
    this.donacionId,
  });

  factory NotificacionModel.fromMap(String id, Map<String, dynamic> m) {
    return NotificacionModel(
      id: id,
      titulo: m['titulo'] ?? '',
      mensaje: m['mensaje'] ?? '',
      tipo: m['tipo'] ?? 'sistema',
      leida: m['leida'] ?? false,
      fecha: m['fecha'] is Timestamp
          ? (m['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      necesidadId: m['necesidadId'],
      donacionId: m['donacionId'],
    );
  }
}
