import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService.instance;
  bool _isLoading = false;
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Es una buena práctica verificar si el widget sigue montado antes de la operación asíncrona.
    if (!mounted) return;

    setState(() => _isLoading = true);

    final error = await _authService.updatePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    // Si el widget fue desmontado durante la espera, no continuamos.
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar('Contraseña actualizada con éxito');
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _isCurrentPasswordObscured,
                  decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: const Icon(Icons.lock_open_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_isCurrentPasswordObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isCurrentPasswordObscured = !_isCurrentPasswordObscured),
                      )),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 14),
              TextFormField(
                  controller: _newPasswordController,
                  obscureText: _isNewPasswordObscured,
                  decoration: InputDecoration(
                      labelText: 'Nueva Contraseña (min. 6 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isNewPasswordObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isNewPasswordObscured = !_isNewPasswordObscured),
                      )),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null),
              const SizedBox(height: 14),
              TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                      )),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Requerido';
                    }
                    if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  }),
              const SizedBox(height: 28),
              SizedBox(
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                SizedBox(width: 24),
                                Text('Actualizando...'),
                              ],
                            )
                          : const Text('Actualizar Contraseña'))),
            ],
          ),
        ),
      ),
    );
  }
}