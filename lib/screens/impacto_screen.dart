import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../models/donacion_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../widgets/error_retry_widget.dart';

class ImpactoScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const ImpactoScreen({super.key, required this.usuario});

  @override
  State<ImpactoScreen> createState() => _ImpactoScreenState();
}

class _ImpactoScreenState extends State<ImpactoScreen> {
  late final Stream<List<DonacionModel>> _donacionesStream;

  @override
  void initState() {
    super.initState();
    _donacionesStream = _createStream();
  }

  Stream<List<DonacionModel>> _createStream() {
    if (widget.usuario.tipo == 'empresa') {
      return FirestoreService.instance.getDonacionesEmpresa(widget.usuario.uid);
    }
    return FirestoreService.instance.getDonacionesColegio(widget.usuario.uid);
  }

  void _retry() {
    setState(() {
      _donacionesStream = _createStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = widget.usuario.tipo == 'empresa';

    return StreamBuilder<List<DonacionModel>>(
        stream: _donacionesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return ErrorRetryWidget(
              message: 'No se pudieron cargar tus estadísticas.',
              onRetry: _retry,
            );
          }

          final donaciones = snap.data ?? [];
          final totalDonaciones = donaciones.length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isEmpresa),
                const SizedBox(height: 32),
                _buildStatCard(
                  title: isEmpresa ? 'Total Donaciones Realizadas' : 'Total Donaciones Recibidas',
                  value: totalDonaciones.toString(),
                  icon: Icons.volunteer_activism_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: isEmpresa ? 'Colegios Impactados' : 'Empresas Aliadas',
                  value: _countUnique(donaciones, isEmpresa).toString(),
                  icon: isEmpresa ? Icons.school_rounded : Icons.business_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 32),
                if (totalDonaciones > 0)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.star_rounded, size: 48, color: AppColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          isEmpresa 
                              ? '¡Gracias por hacer la diferencia! Tu compromiso con la educación ayuda a construir un mejor futuro.'
                              : '¡El apoyo que recibes es fundamental para seguir brindando educación de calidad!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                if (isEmpresa) ...[
                  const SizedBox(height: 32),
                  _buildLogrosSection(totalDonaciones),
                ],
              ],
            ),
          );
        },
    );
  }

  Widget _buildHeader(bool isEmpresa) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: const Icon(Icons.auto_graph_rounded, size: 50, color: AppColors.accent),
        ),
        const SizedBox(height: 16),
        Text(
          isEmpresa ? 'Impacto Social' : 'Resumen de Apoyo',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isEmpresa 
              ? 'Descubre cómo tus aportes están cambiando vidas.' 
              : 'Mira el resumen de la ayuda que has recibido.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countUnique(List<DonacionModel> donaciones, bool isEmpresa) {
    if (isEmpresa) {
      return donaciones.map((d) => d.colegioId).toSet().length;
    } else {
      return donaciones.map((d) => d.empresaId).toSet().length;
    }
  }

  Widget _buildLogrosSection(int totalDonaciones) {
    final List<Map<String, dynamic>> logros = [
      {'titulo': 'Semilla de Esperanza', 'donacionesReq': 1, 'color': Colors.brown[400], 'icono': Icons.eco_rounded},
      {'titulo': 'Héroe Educativo', 'donacionesReq': 3, 'color': Colors.blueGrey[300], 'icono': Icons.shield_rounded},
      {'titulo': 'Pilar de la Comunidad', 'donacionesReq': 10, 'color': Colors.amber[600], 'icono': Icons.emoji_events_rounded},
      {'titulo': 'Leyenda DonaEduca', 'donacionesReq': 20, 'color': Colors.cyan[300], 'icono': Icons.diamond_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tus Insignias',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: logros.length,
          itemBuilder: (context, index) {
            final logro = logros[index];
            final bool unlocked = totalDonaciones >= logro['donacionesReq'];
            final Color baseColor = logro['color'];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unlocked ? baseColor.withOpacity(0.1) : AppColors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: unlocked ? baseColor.withOpacity(0.5) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        logro['icono'],
                        size: 48,
                        color: unlocked ? baseColor : AppColors.grey.withOpacity(0.3),
                      ),
                      if (!unlocked)
                        Icon(Icons.lock_rounded, size: 24, color: AppColors.grey.withOpacity(0.8)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    logro['titulo'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: unlocked ? Theme.of(context).colorScheme.onSurface : AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked ? '¡Desbloqueado!' : '${logro['donacionesReq']} donaciones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: unlocked ? baseColor : AppColors.grey,
                      fontSize: 12,
                      fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
