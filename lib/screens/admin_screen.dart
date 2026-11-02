import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/donacion_model.dart';
import '../models/necesidad_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/categorias.dart';
import '../widgets/app_branding.dart';
import '../widgets/user_avatar.dart';
import 'admin_map_screen.dart';
import 'admin_qr_scanner_screen.dart';

class AdminScreen extends StatefulWidget {
  final int initialIndex;
  const AdminScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroNecesidades = 'todas'; // 'todas', 'pendiente', 'cubierta'
  Key _dashboardKey = UniqueKey();

  // --- Paginación para Usuarios ---
  final List<Map<String, dynamic>> _usuarios = [];
  DocumentSnapshot? _lastUsuarioDoc;
  bool _hasMoreUsuarios = true;
  bool _loadingUsuarios = false;
  bool _loadingMoreUsuarios = false;

  // --- Paginación para Necesidades ---
  final List<NecesidadModel> _necesidades = [];
  DocumentSnapshot? _lastNecesidadDoc;
  bool _hasMoreNecesidades = true;
  bool _loadingNecesidades = false;
  bool _loadingMoreNecesidades = false;

  // --- Paginación para Donaciones ---
  final List<DonacionModel> _donaciones = [];
  DocumentSnapshot? _lastDonacionDoc;
  bool _hasMoreDonaciones = true;
  bool _loadingDonaciones = false;
  bool _loadingMoreDonaciones = false;

  // --- Paginación para Colegios ---
  final List<Map<String, dynamic>> _colegios = [];
  DocumentSnapshot? _lastColegioDoc;
  bool _hasMoreColegios = true;
  bool _loadingColegios = false;
  bool _loadingMoreColegios = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      initialIndex: widget.initialIndex.clamp(0, 5),
      vsync: this,
    );
    _loadUsuarios();
    _loadNecesidades();
    _loadDonaciones();
    _loadColegios();
  }

  Future<void> _loadUsuarios({bool refresh = false}) async {
    if (_loadingUsuarios || _loadingMoreUsuarios) return;
    if (refresh) {
      _lastUsuarioDoc = null;
      _hasMoreUsuarios = true;
      _usuarios.clear();
    }
    if (!_hasMoreUsuarios && !refresh) return;

    if (_usuarios.isEmpty) {
      setState(() => _loadingUsuarios = true);
    } else {
      setState(() => _loadingMoreUsuarios = true);
    }

    try {
      final snap = await FirestoreService.instance.getUsuariosPage(
        lastDoc: _lastUsuarioDoc,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _usuarios.addAll(snap.docs.map((d) => d.data()));
        _lastUsuarioDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMoreUsuarios = snap.docs.length >= 20;
      });
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingUsuarios = false;
          _loadingMoreUsuarios = false;
        });
      }
    }
  }

  Future<void> _loadNecesidades({bool refresh = false}) async {
    if (_loadingNecesidades || _loadingMoreNecesidades) return;
    if (refresh) {
      _lastNecesidadDoc = null;
      _hasMoreNecesidades = true;
      _necesidades.clear();
    }
    if (!_hasMoreNecesidades && !refresh) return;

    if (_necesidades.isEmpty) {
      setState(() => _loadingNecesidades = true);
    } else {
      setState(() => _loadingMoreNecesidades = true);
    }

    try {
      final snap = await FirestoreService.instance.getAdminNecesidadesPage(
        lastDoc: _lastNecesidadDoc,
        estado: _filtroNecesidades,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _necesidades.addAll(snap.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)));
        _lastNecesidadDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMoreNecesidades = snap.docs.length >= 20;
      });
    } catch (e) {
      debugPrint('Error cargando necesidades: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingNecesidades = false;
          _loadingMoreNecesidades = false;
        });
      }
    }
  }

  Future<void> _loadDonaciones({bool refresh = false}) async {
    if (_loadingDonaciones || _loadingMoreDonaciones) return;
    if (refresh) {
      _lastDonacionDoc = null;
      _hasMoreDonaciones = true;
      _donaciones.clear();
    }
    if (!_hasMoreDonaciones && !refresh) return;

    if (_donaciones.isEmpty) {
      setState(() => _loadingDonaciones = true);
    } else {
      setState(() => _loadingMoreDonaciones = true);
    }

    try {
      final snap = await FirestoreService.instance.getAdminDonacionesPage(
        lastDoc: _lastDonacionDoc,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _donaciones.addAll(snap.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)));
        _lastDonacionDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMoreDonaciones = snap.docs.length >= 20;
      });
    } catch (e) {
      debugPrint('Error cargando donaciones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDonaciones = false;
          _loadingMoreDonaciones = false;
        });
      }
    }
  }

  Future<void> _loadColegios({bool refresh = false}) async {
    if (_loadingColegios || _loadingMoreColegios) return;
    if (refresh) {
      _lastColegioDoc = null;
      _hasMoreColegios = true;
      _colegios.clear();
    }
    if (!_hasMoreColegios && !refresh) return;

    if (_colegios.isEmpty) {
      setState(() => _loadingColegios = true);
    } else {
      setState(() => _loadingMoreColegios = true);
    }

    try {
      final snap = await FirestoreService.instance.getColegiosPage(
        lastDoc: _lastColegioDoc,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _colegios.addAll(snap.docs.map((d) => d.data()));
        _lastColegioDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMoreColegios = snap.docs.length >= 20;
      });
    } catch (e) {
      debugPrint('Error cargando colegios: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingColegios = false;
          _loadingMoreColegios = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const AppBranding(
          light: true,
          subtitle: 'Panel de Administrador',
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Resumen'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Usuarios'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Necesidades'),
            Tab(icon: Icon(Icons.volunteer_activism_rounded), text: 'Donaciones'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Colegios'),
            Tab(icon: Icon(Icons.map_rounded), text: 'Mapa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildDashboard(service),
          _buildUsuarios(service),
          _buildNecesidades(service),
          _buildDonaciones(service),
          _buildColegios(service),
          const AdminMapScreen(),
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
    );
  }

  // ─────────────────────────────────────────────
  // TAB 0: DASHBOARD
  // ─────────────────────────────────────────────
  Widget _buildDashboard(FirestoreService service) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _dashboardKey = UniqueKey());
      },
      child: ListView(
        key: _dashboardKey,
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          const Text('Vista General', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Estadísticas en tiempo real (agregaciones globales)', style: TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // Tarjetas de stats con agregaciones de Firestore count()
          Row(
            children: [
              Expanded(child: _buildStatCard(future: service.getTotalUsuarios(), label: 'Usuarios', icon: Icons.people_alt_rounded, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(future: service.getTotalDonaciones(), label: 'Donaciones', icon: Icons.volunteer_activism_rounded, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                future: service.getTotalNecesidadesPendientes(),
                label: 'Pendientes',
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFf5a623),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                future: service.getTotalNecesidadesCubiertas(),
                label: 'Cubiertas',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF3B82F6),
              )),
            ],
          ),

          const SizedBox(height: 32),
          const Text('Estado de Necesidades (Gráfica)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildChart(service),
          const SizedBox(height: 32),
          const Text('Actividad Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Últimas donaciones
          StreamBuilder<List<DonacionModel>>(
            stream: service.getAllDonaciones(),
            builder: (context, snap) {
              final lista = snap.data ?? [];
              if (lista.isEmpty) return const SizedBox.shrink();
              final recientes = lista.take(3).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Últimas donaciones', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...recientes.map((d) => _buildActividadTile(
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.secondary,
                    title: '${d.empresaNombre} → ${d.colegioNombre}',
                    subtitle: DateFormat('dd MMM yyyy').format(d.fecha),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    Future<int>? future,
    Stream<int>? stream,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    Widget buildContent(AsyncSnapshot<int> snap) {
      final value = snap.data ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                snap.connectionState == ConnectionState.waiting
                    ? const SizedBox(width: 32, height: 28, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                    : Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );
    }

    if (future != null) {
      return FutureBuilder<int>(
        future: future,
        builder: (context, snap) => buildContent(snap),
      );
    }

    return StreamBuilder<int>(
      stream: stream ?? const Stream.empty(),
      builder: (context, snap) => buildContent(snap),
    );
  }

  Widget _buildActividadTile({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: USUARIOS
  // ─────────────────────────────────────────────
  Widget _buildUsuarios(FirestoreService service) {
    var lista = _usuarios;
    if (_searchQuery.isNotEmpty) {
      lista = lista.where((u) {
        final nombre = (u['nombre'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return nombre.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o correo...',
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
          child: RefreshIndicator(
            onRefresh: () => _loadUsuarios(refresh: true),
            child: _loadingUsuarios && _usuarios.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : lista.isEmpty
                    ? _buildEmpty('No se encontraron usuarios.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: lista.length + (_hasMoreUsuarios && _searchQuery.isEmpty ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == lista.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _loadingMoreUsuarios
                                    ? const CircularProgressIndicator(color: AppColors.primary)
                                    : OutlinedButton.icon(
                                        onPressed: () => _loadUsuarios(),
                                        icon: const Icon(Icons.arrow_downward_rounded),
                                        label: const Text('Cargar más usuarios'),
                                      ),
                              ),
                            );
                          }
                          final u = lista[i];
                          final nombre = (u['nombre'] ?? '') as String;
                          final tipo = (u['tipo'] ?? '') as String;
                          final email = (u['email'] ?? '') as String;
                          final uid = (u['uid'] ?? '') as String;

                          Color chipColor;
                          IconData chipIcon;
                          if (tipo == 'empresa') {
                            chipColor = AppColors.primary;
                            chipIcon = Icons.business_rounded;
                          } else if (tipo == 'admin') {
                            chipColor = const Color(0xFF7C3AED);
                            chipIcon = Icons.admin_panel_settings_rounded;
                          } else {
                            chipColor = const Color(0xFF3B82F6);
                            chipIcon = Icons.school_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  fotoUrl: u['fotoUrl'] as String?,
                                  nombre: nombre,
                                  radius: 24,
                                  color: chipColor,
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(chipIcon, size: 13, color: chipColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            tipo.isEmpty
                                                ? '—'
                                                : tipo[0].toUpperCase() + tipo.substring(1),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: chipColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (uid.isNotEmpty && tipo != 'admin')
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    onSelected: (value) => _onUsuarioAction(value, uid, nombre),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('Eliminar usuario', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
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
          if (mounted) {
            setState(() {
              _usuarios.removeWhere((u) => u['uid'] == uid);
              _colegios.removeWhere((u) => u['uid'] == uid);
            });
            _showSnack('Usuario eliminado correctamente.');
          }
        } catch (e) {
          if (mounted) _showSnack('Error al eliminar: $e', error: true);
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  // TAB 2: NECESIDADES
  // ─────────────────────────────────────────────
  Widget _buildNecesidades(FirestoreService service) {
    return Column(
      children: [
        // Filtro de estado
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadNecesidades(refresh: true),
            child: _loadingNecesidades && _necesidades.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _necesidades.isEmpty
                    ? _buildEmpty('No hay necesidades para este filtro.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _necesidades.length + (_hasMoreNecesidades ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == _necesidades.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _loadingMoreNecesidades
                                    ? const CircularProgressIndicator(color: AppColors.primary)
                                    : OutlinedButton.icon(
                                        onPressed: () => _loadNecesidades(),
                                        icon: const Icon(Icons.arrow_downward_rounded),
                                        label: const Text('Cargar más necesidades'),
                                      ),
                              ),
                            );
                          }
                          final n = _necesidades[i];
                          final esPendiente = n.estado == 'pendiente';
                          final stateColor = esPendiente ? const Color(0xFFf5a623) : AppColors.secondary;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stateColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            esPendiente
                                                ? Icons.hourglass_empty_rounded
                                                : Icons.check_circle_rounded,
                                            size: 13,
                                            color: stateColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            esPendiente ? 'Pendiente' : 'Cubierta',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: stateColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(n.fecha),
                                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  n.descripcion,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.school_rounded, size: 13, color: AppColors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${n.colegioNombre} · ${normalizarCategoria(n.categoria)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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
                      ),
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
        if (mounted) {
          setState(() {
            final idx = _necesidades.indexWhere((item) => item.id == n.id);
            if (idx != -1) {
              _necesidades[idx] = n.copyWith(estado: 'cubierta');
            }
          });
          _showSnack('Necesidad marcada como cubierta.');
        }
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
        if (mounted) {
          setState(() {
            _necesidades.removeWhere((item) => item.id == n.id);
          });
          _showSnack('Necesidad eliminada.');
        }
      } catch (e) {
        if (mounted) _showSnack('Error: $e', error: true);
      }
    }
  }

  // ─────────────────────────────────────────────
  // TAB 3: DONACIONES
  // ─────────────────────────────────────────────
  Widget _buildDonaciones(FirestoreService service) {
    if (_loadingDonaciones && _donaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_donaciones.isEmpty) return _buildEmpty('No hay donaciones registradas.');

    return RefreshIndicator(
      onRefresh: () => _loadDonaciones(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _donaciones.length + (_hasMoreDonaciones ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == _donaciones.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _loadingMoreDonaciones
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : OutlinedButton.icon(
                        onPressed: () => _loadDonaciones(),
                        icon: const Icon(Icons.arrow_downward_rounded),
                        label: const Text('Cargar más donaciones'),
                      ),
              ),
            );
          }
          final d = _donaciones[i];
          return GestureDetector(
            onTap: () => _mostrarDetallesDonacion(d),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
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
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.empresaNombre,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: AppColors.primary),
                              onPressed: () => _mostrarQROrDialog(d),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                d.colegioNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.descripcion,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(d.fecha),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.grey.withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Ver detalles',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
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
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 4: COLEGIOS
  // ─────────────────────────────────────────────
  Widget _buildColegios(FirestoreService service) {
    if (_loadingColegios && _colegios.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_colegios.isEmpty) return _buildEmpty('No se encontraron colegios.');

    return RefreshIndicator(
      onRefresh: () => _loadColegios(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _colegios.length + (_hasMoreColegios ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == _colegios.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _loadingMoreColegios
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : OutlinedButton.icon(
                        onPressed: () => _loadColegios(),
                        icon: const Icon(Icons.arrow_downward_rounded),
                        label: const Text('Cargar más colegios'),
                      ),
              ),
            );
          }
          final u = _colegios[i];
          final nombre = (u['nombre'] ?? '') as String;
          final email = (u['email'] ?? '') as String;
          final telefono = (u['telefono'] ?? '') as String;
          final comuna = (u['comuna'] ?? '') as String;
          final direccion = (u['direccion'] ?? '') as String;

          return GestureDetector(
            onTap: () => _mostrarDetalleUsuario(u),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    fotoUrl: u['fotoUrl'] as String?,
                    nombre: nombre,
                    radius: 24,
                    color: const Color(0xFF3B82F6),
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
                        if (comuna.isNotEmpty || telefono.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (comuna.isNotEmpty) ...[
                                const Icon(Icons.map_rounded, size: 13, color: AppColors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    comuna,
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                  ),
                                ),
                              ],
                              if (comuna.isNotEmpty && telefono.isNotEmpty) ...[
                                const SizedBox(width: 12),
                              ],
                              if (telefono.isNotEmpty) ...[
                                const Icon(Icons.phone_rounded, size: 13, color: AppColors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  telefono,
                                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (direccion.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            direccion,
                            style: const TextStyle(fontSize: 11, color: AppColors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Ver detalles',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _buildFiltroChip(String value, String label, IconData icon) {
    final selected = _filtroNecesidades == value;
    return GestureDetector(
      onTap: () {
        if (_filtroNecesidades == value) return;
        setState(() => _filtroNecesidades = value);
        _loadNecesidades(refresh: true);
      },
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
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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


  Future<bool?> _showConfirmDialog({required String titulo, required String mensaje, required String accion, required Color color}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final pendientes = snapshot.data![0];
        final cubiertas = snapshot.data![1];

        return Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (pendientes > cubiertas ? pendientes : cubiertas).toDouble() + 5,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return Text('Pendientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color));
                        case 1:
                          return Text('Cubiertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color));
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      width: 25,
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
                      width: 25,
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
              const SizedBox(height: 24),
              if (tipo != 'admin')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Eliminar usuario permanentemente'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onUsuarioAction('eliminar', (u['uid'] ?? '') as String, nombre);
                    },
                  ),
                ),
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

