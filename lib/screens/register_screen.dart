import 'package:flutter/material.dart';
import 'package:donaeduca/services/auth_service.dart';
import '../utils/app_theme.dart';
import '../models/usuario_model.dart';
import 'home_wrapper.dart';
import 'admin_home_screen.dart';
import 'legal_screen.dart';
import 'privacidad_screen.dart';

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
  final _authService = AuthService.instance;
  
  String _tipo = 'empresa';
  bool _isLoading = false;
  bool _acceptedTerms = false;

  static String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final email = value.trim();
    final ok = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    return ok ? null : 'Correo inválido';
  }

  static String? _validarNit(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 6 || cleaned.length > 12) {
      return 'Ingresa un NIT válido (6 a 12 dígitos)';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones para continuar'), backgroundColor: AppColors.error),
      );
      return;
    }
    
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

      // Enviamos el correo de verificación (no bloquea el registro).
      await _authService.enviarVerificacion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Revisa tu correo para verificar tu cuenta.'),
          backgroundColor: AppColors.secondary,
        ),
      );

      final Widget homeScreen = newUser.tipo == 'admin'
          ? AdminHomeScreen(usuario: newUser)
          : const HomeWrapper();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => homeScreen), (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.bold))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('¿Cómo quieres registrarte?', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(children: [
                  Expanded(child: _buildTypeBtn('empresa', Icons.business_rounded)),
                  Expanded(child: _buildTypeBtn('colegio', Icons.school_rounded)),
                ]),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_tipo == 'empresa') ...[
                        TextFormField(
                            controller: _identificacionController,
                            decoration: const InputDecoration(labelText: 'NIT (identificación)', prefixIcon: Icon(Icons.badge_rounded)),
                            validator: _validarNit),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                              labelText: _tipo == 'empresa' ? 'Nombre de la empresa' : 'Nombre del colegio',
                              prefixIcon: Icon(_tipo == 'empresa' ? Icons.business_rounded : Icons.school_rounded)),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_rounded)),
                          validator: _validarEmail),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Teléfono de contacto', prefixIcon: Icon(Icons.phone_rounded)),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_rounded)),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      if (_tipo == 'colegio') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _comunaController,
                            decoration: const InputDecoration(labelText: 'Comuna', prefixIcon: Icon(Icons.map_rounded)),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null)],
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Contraseña (min. 6 caracteres)', prefixIcon: Icon(Icons.lock_rounded)),
                          validator: (v) => v!.length < 6 ? 'Min 6 caracteres' : null),
                      
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                                  child: const Text(
                                    'Acepto los términos y condiciones',
                                    style: TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadScreen())),
                                  child: const Text(
                                    'Acepto las políticas de privacidad',
                                    style: TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                          height: 56,
                          child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                                  : const Text('Completar registro', style: TextStyle(fontSize: 18)))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTypeBtn(String tipo, IconData icon) {
    final isSelected = _tipo == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.grey),
            const SizedBox(width: 8),
            Text(tipo == 'empresa' ? 'Empresa' : 'Colegio',
                style: TextStyle(color: isSelected ? Colors.white : AppColors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
          ]
        ),
      ),
    );
  }
}