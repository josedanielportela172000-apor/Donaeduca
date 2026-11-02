import 'package:donaeduca/models/usuario_model.dart';
import 'package:donaeduca/screens/edit_profile_screen.dart';
import 'package:donaeduca/screens/creditos_screen.dart';
import 'package:donaeduca/services/auth_service.dart';
import 'package:donaeduca/utils/app_theme.dart';
import 'package:donaeduca/widgets/notification_bell.dart';
import 'package:donaeduca/models/necesidad_model.dart';
import 'package:donaeduca/models/donacion_model.dart';
import 'package:donaeduca/services/firestore_service.dart';
import 'package:donaeduca/utils/categorias.dart';
import 'package:donaeduca/widgets/app_branding.dart';
import 'package:donaeduca/widgets/profile_info_card.dart';
import 'package:donaeduca/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:donaeduca/screens/admin_map_screen.dart';
import 'package:donaeduca/screens/admin_qr_scanner_screen.dart';
import 'package:donaeduca/screens/settings_screen.dart';
import 'package:donaeduca/screens/change_password_screen.dart';
import 'package:donaeduca/screens/admin_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const AdminHomeScreen({super.key, required this.usuario});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroNecesidades = 'todas';

  static const _pageTitles = [
    'Necesidades',
    'Colegios',
    'Mapa de Cobertura',
    'Donaciones',
    'Mi Perfil',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildNecesidadesTab(),
      _buildColegiosTab(),
      const AdminMapScreen(),
      _buildDonacionesTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: AppBranding(subtitle: _pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [
          NotificationBell(usuario: widget.usuario),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AdminQrScannerScreen(),
          ));
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.dark),
        label: const Text('Escanear QR', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Necesidades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Colegios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_rounded),
            label: 'Donaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 0: NECESIDADES
  // ─────────────────────────────────────────────
  Widget _buildNecesidadesTab() {
    final service = FirestoreService.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _buildFiltroChip('todas', 'Todas', Icons.apps_rounded),
              const SizedBox(width: 8),
              _buildFiltroChip('pendiente', 'Pendientes', Icons.hourglass_empty_rounded),
              const SizedBox(width: 8),
              _buildFiltroChip('cubierta', 'Cubiertas', Icons.check_circle_rounded),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildChart(service),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<NecesidadModel>>(
            stream: service.getAllNecesidades(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) return _buildError('necesidades', snap.error);

              var lista = snap.data ?? [];
              if (_filtroNecesidades != 'todas') {
                lista = lista.where((n) => n.estado == _filtroNecesidades).toList();
              }
              if (lista.isEmpty) return _buildEmpty('No hay necesidades para este filtro.');

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = lista[i];
                  final esPendiente = n.estado == 'pendiente';
                  final stateColor = esPendiente ? const Color(0xFFf5a623) : AppColors.secondary;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: stateColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(esPendiente ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded, size: 13, color: stateColor),
                                  const SizedBox(width: 4),
                                  Text(esPendiente ? 'Pendiente' : 'Cubierta', style: TextStyle(fontSize: 11, color: stateColor, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(DateFormat('dd MMM yyyy').format(n.fecha), style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(n.descripcion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.school_rounded, size: 13, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('${n.colegioNombre} · ${normalizarCategoria(n.categoria)}', style: const TextStyle(fontSize: 12, color: AppColors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        if (esPendiente) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildAccionBtn(
                                label: 'Marcar cubierta',
                                icon: Icons.check_rounded,
                                color: AppColors.secondary,
                                onTap: () => _marcarCubierta(n),
                              ),
                              const SizedBox(width: 8),
                              _buildAccionBtn(
                                label: 'Eliminar',
                                icon: Icons.delete_rounded,
                                color: Colors.red,
                                onTap: () => _eliminarNecesidad(n),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _marcarCubierta(NecesidadModel n) async {
    final confirm = await _showConfirmDialog(
      titulo: 'Marcar como cubierta',
      mensaje: '¿Marcar esta necesidad de "${n.colegioNombre}" como cubierta manualmente?',
      accion: 'Confirmar',
      color: AppColors.secondary,
    );
    if (confirm == true) {
      try {
        await FirestoreService.instance.updateNecesidad(n.id, {'estado': 'cubierta'});
        if (mounted) _showSnack('Necesidad marcada como cubierta.');
      } catch (e) {
        if (mounted) _showSnack('Error: $e', error: true);
      }
    }
  }

  Future<void> _eliminarNecesidad(NecesidadModel n) async {
    final confirm = await _showConfirmDialog(
      titulo: 'Eliminar necesidad',
      mensaje: '¿Eliminar la necesidad de "${n.colegioNombre}"? Esta acción es permanente.',
      accion: 'Eliminar',
      color: Colors.red,
    );
    if (confirm == true) {
      try {
        await FirestoreService.instance.deleteNecesidad(n.id);
        if (mounted) _showSnack('Necesidad eliminada.');
      } catch (e) {
        if (mounted) _showSnack('Error: $e', error: true);
      }
    }
  }

  String _filtroTipoUsuario = 'colegio';

  // ─────────────────────────────────────────────
  // TAB 1: COLEGIOS Y EMPRESAS
  // ─────────────────────────────────────────────
  Widget _buildColegiosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Colegios'),
                selected: _filtroTipoUsuario == 'colegio',
                onSelected: (_) => setState(() => _filtroTipoUsuario = 'colegio'),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _filtroTipoUsuario == 'colegio' ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Empresas'),
                selected: _filtroTipoUsuario == 'empresa',
                onSelected: (_) => setState(() => _filtroTipoUsuario = 'empresa'),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _filtroTipoUsuario == 'empresa' ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildUsuariosFiltrados(tipoFiltro: _filtroTipoUsuario)),
      ],
    );
  }

  Widget _buildUsuariosFiltrados({required String tipoFiltro}) {
    final service = FirestoreService.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: tipoFiltro == 'colegio' ? 'Buscar colegio...' : 'Buscar empresa...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: service.getAllUsuarios(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) return _buildError('usuarios', snap.error);

              var lista = snap.data ?? [];
              lista = lista.where((u) => (u['tipo'] ?? '') == tipoFiltro).toList();

              if (_searchQuery.isNotEmpty) {
                lista = lista.where((u) {
                  final nombre = (u['nombre'] ?? '').toString().toLowerCase();
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  return nombre.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();
              }

              if (lista.isEmpty) {
                return _buildEmpty(
                  tipoFiltro == 'colegio'
                      ? 'No se encontraron colegios.'
                      : 'No se encontraron empresas.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final u = lista[i];
                  final nombre = (u['nombre'] ?? '') as String;
                  final email = (u['email'] ?? '') as String;
                  final uid = (u['uid'] ?? '') as String;
                  final telefono = (u['telefono'] ?? '') as String;
                  final comuna = (u['comuna'] ?? '') as String;
                  final direccion = (u['direccion'] ?? '') as String;
                  final color = tipoFiltro == 'colegio'
                      ? const Color(0xFF3B82F6)
                      : AppColors.primary;
                  final icon = tipoFiltro == 'colegio'
                      ? Icons.school_rounded
                      : Icons.business_rounded;

                  return GestureDetector(
                    onTap: () => _mostrarDetalleUsuario(u),
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          fotoUrl: u['fotoUrl'] as String?,
                          nombre: nombre,
                          radius: 24,
                          color: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre.isEmpty ? '(Sin nombre)' : nombre,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (telefono.isNotEmpty || comuna.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (telefono.isNotEmpty) ...[
                                      const Icon(Icons.phone_rounded, size: 12, color: AppColors.grey),
                                      const SizedBox(width: 3),
                                      Flexible(child: Text(telefono, style: const TextStyle(fontSize: 11, color: AppColors.grey))),
                                    ],
                                    if (telefono.isNotEmpty && comuna.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                    ],
                                    if (comuna.isNotEmpty) ...[
                                      const Icon(Icons.map_rounded, size: 12, color: AppColors.grey),
                                      const SizedBox(width: 3),
                                      Flexible(child: Text(comuna, style: const TextStyle(fontSize: 11, color: AppColors.grey))),
                                    ],
                                  ],
                                ),
                              ],
                              if (direccion.isNotEmpty)
                                Text(direccion, style: const TextStyle(fontSize: 11, color: AppColors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(icon, size: 13, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    tipoFiltro[0].toUpperCase() + tipoFiltro.substring(1),
                                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.visibility_rounded, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  const Text('Ver detalles', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (uid.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) => _onUsuarioAction(value, uid, nombre),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(children: [
                                  Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Eliminar usuario', style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onUsuarioAction(String action, String uid, String nombre) async {
    if (action == 'eliminar') {
      final confirm = await _showConfirmDialog(
        titulo: 'Eliminar usuario',
        mensaje: '¿Estás seguro de que quieres eliminar a "$nombre"? Esta acción no se puede deshacer.',
        accion: 'Eliminar',
        color: Colors.red,
      );
      if (confirm == true) {
        try {
          await FirestoreService.instance.deleteUsuario(uid);
          if (mounted) _showSnack('Usuario eliminado correctamente.');
        } catch (e) {
          if (mounted) _showSnack('Error al eliminar: $e', error: true);
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  // TAB 3: DONACIONES
  // ─────────────────────────────────────────────
  Widget _buildDonacionesTab() {
    return StreamBuilder<List<DonacionModel>>(
      stream: FirestoreService.instance.getAllDonaciones(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) return _buildError('donaciones', snap.error);
        final lista = snap.data ?? [];
        if (lista.isEmpty) return _buildEmpty('No hay donaciones registradas.');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = lista[i];
            return GestureDetector(
              onTap: () => _mostrarDetallesDonacion(d),
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(d.empresaNombre,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _mostrarQROrDialog(d),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(d.colegioNombre,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(d.descripcion,
                            style: const TextStyle(fontSize: 12, color: AppColors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(DateFormat('dd MMM yyyy • HH:mm').format(d.fecha),
                                style: TextStyle(fontSize: 11, color: AppColors.grey.withOpacity(0.7))),
                            const Spacer(),
                            const Text('Ver detalles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // TAB 4: PERFIL
  // ─────────────────────────────────────────────
  Widget _buildProfileTab() {
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
              fallbackIcon: Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 16),
            Text(usuario.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(usuario.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey)),
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
              leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
              title: const Text('Panel Avanzado (Gráficas y Empresas)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminScreen(),
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

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _buildFiltroChip(String value, String label, IconData icon) {
    final selected = _filtroNecesidades == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroNecesidades = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.grey),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: AppColors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildError(String tipo, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('No se pudieron cargar los $tipo.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('${error ?? ""}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String titulo,
    required String mensaje,
    required String accion,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(accion),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
  
  Widget _buildChart(FirestoreService service) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        service.getTotalNecesidadesPendientes(),
        service.getTotalNecesidadesCubiertas(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final pendientes = snapshot.data![0];
        final cubiertas = snapshot.data![1];

        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (pendientes > cubiertas ? pendientes : cubiertas).toDouble() + 5,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return Text('Pendientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color));
                        case 1:
                          return Text('Cubiertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color));
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: pendientes.toDouble(),
                      color: const Color(0xFFf5a623),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: cubiertas.toDouble(),
                      color: const Color(0xFF3B82F6),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesDonacion(DonacionModel d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.volunteer_activism_rounded, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text('Detalles de la Donación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem(icon: Icons.business_rounded, label: 'Empresa donante', value: d.empresaNombre),
              if (d.empresaTelefono != null && d.empresaTelefono!.isNotEmpty)
                _buildDetailItem(icon: Icons.phone_rounded, label: 'Teléfono de contacto', value: d.empresaTelefono!),
              if (d.empresaEmail != null && d.empresaEmail!.isNotEmpty)
                _buildDetailItem(icon: Icons.email_rounded, label: 'Correo de contacto', value: d.empresaEmail!),
              _buildDetailItem(icon: Icons.school_rounded, label: 'Colegio beneficiario', value: d.colegioNombre),
              _buildDetailItem(icon: Icons.notes_rounded, label: 'Descripción', value: d.descripcion),
              _buildDetailItem(icon: Icons.schedule_rounded, label: 'Fecha', value: DateFormat('dd MMM yyyy • HH:mm').format(d.fecha)),
              _buildDetailItem(icon: Icons.tag_rounded, label: 'Código de donación', value: d.id),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: QrImageView(
                    data: d.id,
                    version: QrVersions.auto,
                    size: 130,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleUsuario(Map<String, dynamic> u) {
    final nombre = (u['nombre'] ?? '') as String;
    final email = (u['email'] ?? '') as String;
    final tipo = (u['tipo'] ?? '') as String;
    final titulo = tipo == 'colegio'
        ? 'Detalles del Colegio'
        : tipo == 'empresa'
            ? 'Detalles de la Empresa'
            : 'Detalles del Usuario';
    final icono = tipo == 'colegio' ? Icons.school_rounded : Icons.people_alt_rounded;
    final color = tipo == 'colegio' ? const Color(0xFF3B82F6) : AppColors.primary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem(icon: Icons.badge_rounded, label: 'Nombre', value: nombre),
              _buildDetailItem(icon: Icons.email_rounded, label: 'Correo', value: email),
              _buildDetailItem(icon: Icons.phone_rounded, label: 'Teléfono', value: (u['telefono'] ?? '') as String),
              _buildDetailItem(icon: Icons.location_on_rounded, label: 'Dirección', value: (u['direccion'] ?? '') as String),
              if (tipo == 'colegio')
                _buildDetailItem(icon: Icons.map_rounded, label: 'Comuna', value: (u['comuna'] ?? '') as String),
              if (tipo == 'empresa')
                _buildDetailItem(icon: Icons.badge_outlined, label: 'Identificación', value: (u['identificacion'] ?? '') as String),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarQROrDialog(DonacionModel d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR de la Donación', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: d.id,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Escanea este código con la cámara del administrador para validar la entrega.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }
}
