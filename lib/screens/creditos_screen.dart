import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'),
        // El AppBar automáticamente añade el botón para regresar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: const AssetImage('assets/images/logo.png'),
              child: const Icon(
                Icons.school_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DonaEduca',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            const Text(
              'Donaciones para instituciones educativas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            Center(
              child: Chip(
                avatar: const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                label: const Text('Versión $_version', style: TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 28),
            _buildSection(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Sobre la aplicación',
              children: [
                Text(
                  'DonaEduca conecta a colegios que necesitan insumos con empresas '
                  'dispuestas a donar. Las instituciones publican sus necesidades, las '
                  'empresas las cubren con una donación y cada aporte queda registrado '
                  'con su certificado para medir el impacto real en la educación.',
                  style: TextStyle(fontSize: 14.5, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Desarrollador',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.code_rounded, color: Colors.white),
                  ),
                  title: Text(
                    'Jose Daniel Portela Romero',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: const Text(
                    'Diseño, desarrollo y puesta en marcha',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.memory_rounded,
              title: 'Tecnologías utilizadas',
              children: [
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TechChip(label: 'Flutter'),
                    _TechChip(label: 'Firebase Auth'),
                    _TechChip(label: 'Cloud Firestore'),
                    _TechChip(label: 'Cloud Messaging'),
                    _TechChip(label: 'Cloudinary'),
                    _TechChip(label: 'Generación de PDF'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Aplicación desarrollada con Flutter solo para Android, con backend '
                  'de Firebase (autenticación, base de datos en tiempo real y notificaciones '
                  'push) y generación de certificados de donación en PDF.',
                  style: TextStyle(fontSize: 14.5, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondary),
      backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
