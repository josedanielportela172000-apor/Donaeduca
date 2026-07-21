import 'package:donaeduca/screens/login_screen.dart';
import 'package:donaeduca/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:donaeduca/models/usuario_model.dart';
import 'package:donaeduca/models/necesidad_model.dart';
import '../models/donacion_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

class EmpresaHomeScreen extends StatefulWidget {
  final UsuarioModel? usuario;
  const EmpresaHomeScreen({super.key, required this.usuario});

  @override
  State<EmpresaHomeScreen> createState() => _EmpresaHomeScreenState();
}

class _EmpresaHomeScreenState extends State<EmpresaHomeScreen> {
  late final Stream<List<NecesidadModel>> _necesidadesStream;

  @override
  void initState() {
    super.initState();
    _necesidadesStream = FirestoreService().getNecesidadesPendientes();
  }

  bool get isGuest => widget.usuario == null;

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acción requerida'),
        content: const Text('Para realizar una donación, necesitas iniciar sesión o crear una cuenta.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Iniciar Sesión / Registrarse'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Cierra el dialogo
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _donar(BuildContext context, NecesidadModel necesidad) async {
    if (isGuest) {
      _showLoginRequiredDialog(context);
      return;
    }

    try {
      final donacion = DonacionModel(
        id: '',
        empresaId: widget.usuario!.uid,
        empresaNombre: widget.usuario!.nombre,
        colegioId: necesidad.colegioId,
        colegioNombre: necesidad.colegioNombre,
        necesidadId: necesidad.id,
        descripcion: necesidad.descripcion,
        fecha: DateTime.now(),
      );
      await FirestoreService().donar(donacion: donacion, necesidadId: necesidad.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu donación!'), backgroundColor: AppColors.secondary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la donación: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isGuest, // Oculta el botón de atrás si es invitado
        title: Text(isGuest ? 'Necesidades (Invitado)' : widget.usuario!.nombre),
        actions: isGuest
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                  child: const Text('Login', style: TextStyle(color: Colors.white)),
                )
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar Perfil',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditProfileScreen(usuario: widget.usuario!),
                  )),
                ),
                IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService().logout())
              ],
      ),
      body: StreamBuilder<List<NecesidadModel>>(
        stream: _necesidadesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return const Center(child: Text('No hay necesidades publicadas por el momento.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final n = lista[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.colegioNombre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(n.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(n.categoria, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _donar(context, n),
                          child: const Text('Donar'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}