import 'package:donaeduca/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:donaeduca/models/usuario_model.dart';
import 'package:donaeduca/models/necesidad_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/categorias.dart';
import '../widgets/error_retry_widget.dart';
import 'necesidad_detalle_screen.dart';
import 'historial_screen.dart';
import 'impacto_screen.dart';
import 'admin_screen.dart';
import 'admin_map_screen.dart';
import 'creditos_screen.dart';
import 'settings_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/app_branding.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/user_avatar.dart';
import 'change_password_screen.dart';

class EmpresaHomeScreen extends StatefulWidget {
  final UsuarioModel? usuario;
  const EmpresaHomeScreen({super.key, required this.usuario});

  @override
  State<EmpresaHomeScreen> createState() => _EmpresaHomeScreenState();
}

class _EmpresaHomeScreenState extends State<EmpresaHomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late final List<String> _pageTitles;
  int _retryToken = 0;

  @override
  void initState() {
    super.initState();
    _rebuildPages();
  }
  void _rebuildPages() {
    _pageTitles = ['Necesidades', 'Mapa Colegios', 'Mi Impacto', 'Historial', 'Mi Perfil'];
    _pages = [_buildNecesidadesList(), const AdminMapScreen(), _buildImpactoPage(), _buildHistorialPage(), _buildProfilePage()];
  }

  bool get isGuest => widget.usuario == null;

  Widget _buildNecesidadesList() {
    return KeyedSubtree(
      key: ValueKey(_retryToken),
      child: StreamBuilder<List<NecesidadModel>>(
        stream: FirestoreService.instance.getNecesidadesPendientes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return ErrorRetryWidget(
              message: 'No se pudieron cargar las necesidades.',
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
                  Icon(Icons.volunteer_activism_rounded, size: 80, color: AppColors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No hay necesidades publicadas aún.', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey)),
                  const SizedBox(height: 8),
                  const Text('¡Vuelve pronto para ayudar a un colegio!', 
                    style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final n = lista[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NecesidadDetalleScreen(necesidad: n, usuario: widget.usuario)
                  )),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.imagenUrl != null && n.imagenUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            n.imagenUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(n.colegioNombre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(n.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(normalizarCategoria(n.categoria), style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          ),
                          const Spacer(),
                          const Text('Ver detalles', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }

  Widget _buildImpactoPage() {
    if (isGuest) return const SizedBox.shrink();
    return ImpactoScreen(usuario: widget.usuario!);
  }

  Widget _buildHistorialPage() {
    if (isGuest) return const SizedBox.shrink();
    return HistorialScreen(usuario: widget.usuario!);
  }

  Widget _buildProfilePage() {
    if (isGuest) return const SizedBox.shrink();
    return StreamBuilder<UsuarioModel?>(
      stream: AuthService.instance.streamUsuario(widget.usuario!.uid),
      builder: (context, snapshot) {
        final usuario = snapshot.data ?? widget.usuario!;
        final bool isAdmin = usuario.tipo == 'admin';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            UserAvatar(
              fotoUrl: usuario.fotoUrl,
              nombre: usuario.nombre,
              radius: 50,
              fallbackIcon: isAdmin ? Icons.admin_panel_settings_rounded : Icons.business_rounded,
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
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded),
                title: const Text('Panel de Administrador'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AdminScreen(),
                )),
              ),
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
    if (isGuest) {
      return Scaffold(body: _buildNecesidadesList());
    }

    return Scaffold(
      appBar: AppBar(
        title: AppBranding(subtitle: _pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [NotificationBell(usuario: widget.usuario!)],
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph_rounded), label: 'Impacto'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}