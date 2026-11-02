import 'package:flutter/material.dart';

/// Clave global del Navigator para poder navegar desde cualquier parte
/// del código (por ejemplo, al tocar una notificación push).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
