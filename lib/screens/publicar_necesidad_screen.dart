import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../models/necesidad_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

const _categorias = [
  'Tecnologia',
  'Mobiliario',
  'utiles escolares',
  'Deportes',
  'Libros',
  'Infraestructura',
  'Alimentacion',
  'Otro'
];

class PublicarNecesidadScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const PublicarNecesidadScreen({super.key, required this.usuario});

  @override
  State<PublicarNecesidadScreen> createState() => _PNState();
}

class _PNState extends State<PublicarNecesidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _cat = 'Tecnologia';
  bool _isLoading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirestoreService().publicarNecesidad(NecesidadModel(
          id: '',
          colegioId: widget.usuario.uid,
          colegioNombre: widget.usuario.nombre,
          descripcion: _descController.text.trim(),
          categoria: _cat,
          estado: 'pendiente',
          fecha: DateTime.now()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Necesidad publicada con éxito')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Publicar necesidad')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                    value: _cat,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _cat = v!)),
                const SizedBox(height: 18),
                const Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Ej: Necesitamos 20 sillas para 5to grado...'),
                    validator: (v) => v!.isEmpty ? 'Escribe la descripcion' : null),
                const SizedBox(height: 28),
                SizedBox(
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _publicar,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Publicar necesidad', style: TextStyle(fontSize: 16)))),
              ],
            ),
          ),
        ),
      );
}