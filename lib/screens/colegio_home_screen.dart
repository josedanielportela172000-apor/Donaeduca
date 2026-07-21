import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usuario_model.dart';
import '../models/necesidad_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'publicar_necesidad_screen.dart';
import 'edit_profile_screen.dart';

class ColegioHomeScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const ColegioHomeScreen({super.key, required this.usuario});

  @override
  State<ColegioHomeScreen> createState() => _ColegioHomeScreenState();
}

class _ColegioHomeScreenState extends State<ColegioHomeScreen> {
  late final Stream<List<NecesidadModel>> _necesidadesStream;

  @override
  void initState() {
    super.initState();
    _necesidadesStream = FirestoreService().getNecesidadesColegio(widget.usuario.uid);
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
                await FirestoreService().deleteNecesidad(necesidadId);
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!mounted) return;
                Navigator.of(ctx).pop();
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.usuario.nombre),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar Perfil',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditProfileScreen(usuario: widget.usuario),
              )),
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService().logout())
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicarNecesidadScreen(usuario: widget.usuario))),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Publicar necesidad', style: TextStyle(color: Colors.white))),
        body: StreamBuilder<List<NecesidadModel>>(
            stream: _necesidadesStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final lista = snap.data ?? [];
              if (lista.isEmpty) return const Center(child: Text('Presiona + para publicar una necesidad'));
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor:
                              esPendiente ? AppColors.accent.withValues(alpha: 0.25) : AppColors.secondary.withValues(alpha: 0.2),
                          child: Icon(esPendiente ? Icons.hourglass_empty : Icons.check_circle,
                              color: esPendiente ? AppColors.dark : AppColors.secondary),
                        ),
                        title: Text(n.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${n.categoria} - $formattedDate'),
                        trailing: esPendiente
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Eliminar necesidad',
                                onPressed: () => _showDeleteConfirmationDialog(n.id),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Text('Cubierta',
                                    style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                      ),
                    );
                  });
            }),
      );
}