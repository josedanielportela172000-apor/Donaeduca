import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Avatar circular para colegios y empresas.
///
/// Muestra la foto de perfil si existe y, si falla la carga o no hay foto,
/// cae a la inicial del nombre o a un ícono según el tipo de cuenta.
class UserAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nombre;
  final double radius;
  final IconData? fallbackIcon;
  final Color? color;

  const UserAvatar({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.radius = 50,
    this.fallbackIcon,
    this.color,
  });

  bool get _hasPhoto => fotoUrl != null && fotoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.1),
      ),
      child: _hasPhoto
          ? Image.network(
              fotoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(accent),
            )
          : _buildFallback(accent),
    );
  }

  Widget _buildFallback(Color accent) {
    if (fallbackIcon != null) {
      return Center(
        child: Icon(fallbackIcon, size: radius * 0.95, color: accent),
      );
    }
    final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : '?';
    return Center(
      child: Text(
        inicial,
        style: TextStyle(
          fontSize: radius * 0.75,
          color: accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
