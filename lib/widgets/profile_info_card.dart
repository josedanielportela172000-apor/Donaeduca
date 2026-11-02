import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../utils/app_theme.dart';

/// Tarjeta con los datos de la cuenta del usuario (perfil).
class ProfileInfoCard extends StatelessWidget {
  final UsuarioModel usuario;

  const ProfileInfoCard({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final esColegio = usuario.tipo == 'colegio';
    final esAdmin = usuario.tipo == 'admin';
    final tipoLabel = esAdmin ? 'Administrador' : esColegio ? 'Colegio' : 'Empresa';
    final tipoColor = esAdmin ? const Color(0xFF7C3AED) : esColegio ? const Color(0xFF3B82F6) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildFila(
            icon: esAdmin ? Icons.admin_panel_settings_rounded : esColegio ? Icons.school_rounded : Icons.business_rounded,
            label: 'Tipo de cuenta',
            value: tipoLabel,
            color: tipoColor,
          ),
          _buildFila(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: usuario.telefono ?? '',
            color: AppColors.secondary,
          ),
          _buildFila(
            icon: Icons.location_on_rounded,
            label: 'Dirección',
            value: usuario.direccion ?? '',
            color: AppColors.primary,
          ),
          if (esColegio) ...[
            _buildFila(
              icon: Icons.map_rounded,
              label: 'Comuna',
              value: usuario.comuna ?? '',
              color: const Color(0xFF3B82F6),
            ),
            _buildFila(
              icon: Icons.pin_drop_rounded,
              label: 'Ubicación en el mapa',
              value: (usuario.lat != null && usuario.lng != null)
                  ? (usuario.geoPreciso == true ? 'Fijada en el mapa (Exacta)' : 'Aproximada')
                  : 'Sin fijar en el mapa',
              color: (usuario.lat != null && usuario.lng != null)
                  ? AppColors.secondary
                  : AppColors.error,
            ),
          ],
          if (!esColegio && !esAdmin)
            _buildFila(
              icon: Icons.badge_outlined,
              label: 'NIT (empresa)',
              value: usuario.identificacion ?? '',
              color: const Color(0xFFf5a623),
            ),
        ],
      ),
    );
  }

  Widget _buildFila({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}