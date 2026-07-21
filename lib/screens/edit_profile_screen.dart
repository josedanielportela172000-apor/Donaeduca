import 'package:donaeduca/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const EditProfileScreen({super.key, required this.usuario});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _direccionController;
  late TextEditingController _comunaController;
  late TextEditingController _telefonoController;
  late TextEditingController _identificacionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.usuario.nombre);
    _direccionController = TextEditingController(text: widget.usuario.direccion);
    _comunaController = TextEditingController(text: widget.usuario.comuna);
    _telefonoController = TextEditingController(text: widget.usuario.telefono);
    _identificacionController = TextEditingController(text: widget.usuario.identificacion);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _direccionController.dispose();
    _comunaController.dispose();
    _telefonoController.dispose();
    _identificacionController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'nombre': _nameController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      if (widget.usuario.tipo == 'colegio') 'comuna': _comunaController.text.trim(),
      if (widget.usuario.tipo == 'empresa') 'identificacion': _identificacionController.text.trim(),
    };

    try {
      await FirestoreService().updateUsuario(widget.usuario.uid, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: AppColors.secondary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColegio = widget.usuario.tipo == 'colegio';

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isColegio) ...[
                TextFormField(
                    controller: _identificacionController,
                    decoration: const InputDecoration(labelText: 'Identificación (RUC/RUT)', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 14),
              ],
              TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: isColegio ? 'Nombre completo del colegio' : 'Nombre completo de la empresa',
                      prefixIcon: Icon(isColegio ? Icons.school : Icons.business)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 14),
              TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono de contacto', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 14),
              TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              if (isColegio) ...[
                const SizedBox(height: 14),
                TextFormField(
                    controller: _comunaController,
                    decoration: const InputDecoration(labelText: 'Comuna', prefixIcon: Icon(Icons.map_outlined)),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null)
              ],
              const SizedBox(height: 28),
              SizedBox(
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ),
                child: const Text('Cambiar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}