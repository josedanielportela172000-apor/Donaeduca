import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usuario_model.dart';
import '../models/necesidad_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/categorias.dart';
import '../widgets/error_retry_widget.dart';
import 'publicar_necesidad_screen.dart';
import 'edit_profile_screen.dart';
import 'necesidad_detalle_screen.dart';
import 'historial_screen.dart';
import 'impacto_screen.dart';
import 'creditos_screen.dart';
import 'settings_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_branding.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/user_avatar.dart';
import 'change_password_screen.dart';

class ColegioHomeScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const ColegioHomeScreen({super.key, required this.usuario});

  @override
  State<ColegioHomeScreen> createState() => _ColegioHomeScreenState();
}

class _ColegioHomeScreenState extends State<ColegioHomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late final List<String> _pageTitles;
  int _retryToken = 0;

  @override
  void initState() {
    super.initState();
    _rebuildPages();
    _pageTitles = ['Mis Necesidades', 'Impacto Recibido', 'Historial', 'Mi Perfil'];
  }

  void _rebuildPages() {
    _pages = [_buildNecesidadesList(), _buildImpactoPage(), _buildHistorialPage(), _buildProfilePage()];
  }

  void _showDeleteConfirmationDialog(String necesidadId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta necesidad? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
            onPressed: () async {
              try {
                await FirestoreService.instance.deleteNecesidad(necesidadId);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNecesidadesList() {
    return KeyedSubtree(
      key: ValueKey(_retryToken),
      child: StreamBuilder<List<NecesidadModel>>(
        stream: FirestoreService.instance.getNecesidadesColegio(widget.usuario.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return ErrorRetryWidget(
              message: 'No se pudieron cargar tus necesidades.',
              onRetry: () => setState(() {
                _retryToken++;
                _rebuildPages();
              }),
            );
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_rounded, size: 80, color: AppColors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('Aún no tienes necesidades',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 8),
                  const Text('Presiona el botón inferior para publicar una.', style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final n = lista[i];
                final esPendiente = n.estado == 'pendiente';
                final formattedDate = DateFormat('dd MMM yyyy').format(n.fecha);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NecesidadDetalleScreen(necesidad: n, usuario: widget.usuario))),
                    contentPadding: const EdgeInsets.all(14),
                    leading: n.imagenUrl != null && n.imagenUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              n.imagenUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                backgroundColor:
                                    esPendiente ? AppColors.accent.withOpacity(0.25) : AppColors.secondary.withOpacity(0.2),
                                child: Icon(esPendiente ? Icons.hourglass_empty : Icons.check_circle,
                                    color: esPendiente ? AppColors.dark : AppColors.secondary),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor:
                                esPendiente ? AppColors.accent.withOpacity(0.25) : AppColors.secondary.withOpacity(0.2),
                            child: Icon(esPendiente ? Icons.hourglass_empty : Icons.check_circle,
                                color: esPendiente ? AppColors.dark : AppColors.secondary),
                          ),
                    title: Text(n.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${normalizarCategoria(n.categoria)} - $formattedDate'),
                    trailing: esPendiente
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                tooltip: 'Editar necesidad',
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PublicarNecesidadScreen(
                                            usuario: widget.usuario, necesidad: n))),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Eliminar necesidad',
                                onPressed: () => _showDeleteConfirmationDialog(n.id),
                              ),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Cubierta',
                                style:
                                    TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                  ),
                );
              });
        },
      ),
    );
  }

  Widget _buildImpactoPage() {
    return ImpactoScreen(usuario: widget.usuario);
  }

  Widget _buildHistorialPage() {
    return HistorialScreen(usuario: widget.usuario);
  }

  Widget _buildProfilePage() {
    return StreamBuilder<UsuarioModel?>(
      stream: AuthService.instance.streamUsuario(widget.usuario.uid),
      builder: (context, snapshot) {
        final usuario = snapshot.data ?? widget.usuario;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            UserAvatar(
              fotoUrl: usuario.fotoUrl,
              nombre: usuario.nombre,
              radius: 50,
              fallbackIcon: Icons.school_rounded,
            ),
            const SizedBox(height: 16),
            Text(usuario.nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(usuario.email, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 24),
            ProfileInfoCard(usuario: usuario),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Perfil'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditProfileScreen(usuario: usuario),
              )),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Configuración'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              )),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar Contraseña'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(),
              )),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Créditos'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CreditosScreen(),
              )),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
              onTap: () => AuthService.instance.logout(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBranding(subtitle: _pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [NotificationBell(usuario: widget.usuario)],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PublicarNecesidadScreen(usuario: widget.usuario))),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Publicar', style: TextStyle(color: Colors.white)))
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph_rounded), label: 'Impacto'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}