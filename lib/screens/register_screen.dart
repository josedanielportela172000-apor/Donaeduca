import 'package:flutter/material.dart';
import 'package:donaeduca/services/auth_service.dart';
import '../utils/app_theme.dart';
import '../models/usuario_model.dart';
import 'empresa_home_screen.dart';
import 'colegio_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _direccionController = TextEditingController();
  final _comunaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _authService = AuthService();
  String _tipo = 'empresa';
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
  final UsuarioModel newUser = await _authService.registrar(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nombre: _nameController.text.trim(),
          tipo: _tipo,
          direccion: _direccionController.text.trim(),
          telefono: _telefonoController.text.trim(),
          comuna: _tipo == 'colegio' ? _comunaController.text.trim() : null,
          identificacion: _tipo == 'empresa' ? _identificacionController.text.trim() : null);

      if (!mounted) return;

      final homeScreen = newUser.tipo == 'empresa'
          ? EmpresaHomeScreen(usuario: newUser)
          : ColegioHomeScreen(usuario: newUser);
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => homeScreen), (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Tipo de cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _buildTypeBtn('empresa', Icons.business)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTypeBtn('colegio', Icons.school)),
                ]),
                const SizedBox(height: 20),
                if (_tipo == 'empresa') ...[
                  TextFormField(
                      controller: _identificacionController,
                      decoration: const InputDecoration(labelText: 'Identificación (RUC/RUT)', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: _tipo == 'empresa' ? 'Nombre completo de la empresa' : 'Nombre completo del colegio',
                        prefixIcon: Icon(_tipo == 'empresa' ? Icons.business : Icons.school)),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
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
                if (_tipo == 'colegio') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _comunaController,
                      decoration: const InputDecoration(labelText: 'Comuna', prefixIcon: Icon(Icons.map_outlined)),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null)],
                const SizedBox(height: 14),
                TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña (min. 6 caracteres)', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) => v!.length < 6 ? 'Min 6 caracteres' : null),
                const SizedBox(height: 28),
                SizedBox(
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Crear cuenta', style: TextStyle(fontSize: 16)))),
              ],
            ),
          ),
        ),
      );

  Widget _buildTypeBtn(String tipo, IconData icon) {
    final isSelected = _tipo == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey)),
        child: Column(children: [
          Icon(icon, color: isSelected ? Colors.white : AppColors.grey),
          const SizedBox(height: 4),
          Text(tipo == 'empresa' ? 'Empresa' : 'Colegio',
              style: TextStyle(color: isSelected ? Colors.white : AppColors.grey, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}