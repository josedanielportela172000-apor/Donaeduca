import 'dart:io';
import 'package:donaeduca/screens/change_password_screen.dart';
import 'package:donaeduca/screens/map_location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../services/geocoding_service.dart';
import '../utils/app_theme.dart';
import '../widgets/user_avatar.dart';

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
  LatLng? _pickedLocation;
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.usuario.nombre);
    _direccionController = TextEditingController(text: widget.usuario.direccion ?? '');
    _comunaController = TextEditingController(text: widget.usuario.comuna ?? '');
    _telefonoController = TextEditingController(text: widget.usuario.telefono ?? '');
    _identificacionController = TextEditingController(text: widget.usuario.identificacion ?? '');
    _fotoUrl = widget.usuario.fotoUrl;

    // Inicializamos la ubicación previa si ya existe en la base de datos
    if (widget.usuario.lat != null && widget.usuario.lng != null) {
      _pickedLocation = LatLng(widget.usuario.lat!, widget.usuario.lng!);
    }
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

  bool get _isColegio => widget.usuario.tipo.trim().toLowerCase() == 'colegio';
  bool get _isEmpresa => widget.usuario.tipo.trim().toLowerCase() == 'empresa';

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) _setSelectedImage(image);
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) _setSelectedImage(image);
  }

  void _setSelectedImage(XFile image) {
    final file = File(image.path);
    if (file.lengthSync() > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen es demasiado grande (máx. 5 MB).'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    setState(() => _selectedImage = file);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
            if (_selectedImage != null || (_fotoUrl != null && _fotoUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Eliminar foto', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImage = null;
                    _fotoUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'nombre': _nameController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      if (_isColegio) 'comuna': _comunaController.text.trim(),
      if (_isEmpresa) 'identificacion': _identificacionController.text.trim(),
    };

    // Los colegios se geocodifican o usan el pin manual fijado en el mapa
    if (_isColegio) {
      double? lat = widget.usuario.lat;
      double? lng = widget.usuario.lng;
      bool preciso = widget.usuario.geoPreciso ?? false;

      if (_pickedLocation != null) {
        lat = _pickedLocation!.latitude;
        lng = _pickedLocation!.longitude;
        preciso = true;
      } else if (_direccionController.text.trim().isNotEmpty) {
        try {
          final geo = await GeocodingService.instance.geocodeDireccion(
            direccion: _direccionController.text.trim(),
            comuna: _comunaController.text.trim(),
          );
          if (geo != null) {
            lat = geo.lat;
            lng = geo.lng;
            preciso = geo.preciso;
          }
        } catch (e) {
          debugPrint('Error en geocodificación automática: $e');
        }
      }

      if (lat != null && lng != null) {
        data['lat'] = lat;
        data['lng'] = lng;
        data['geo_preciso'] = preciso;
      }
    }

    try {
      String? fotoUrl = _fotoUrl;
      if (_selectedImage != null) {
        final url = await CloudinaryService().uploadImage(_selectedImage!);
        if (url == null) {
          throw Exception('No se pudo subir la foto de perfil. Intenta de nuevo.');
        }
        fotoUrl = url;
      }
      data['fotoUrl'] = fotoUrl;

      await FirestoreService.instance.updateUsuario(widget.usuario.uid, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil y ubicación actualizados con éxito'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirMapa() async {
    final puntoInicial = _pickedLocation ??
        (widget.usuario.lat != null && widget.usuario.lng != null
            ? LatLng(widget.usuario.lat!, widget.usuario.lng!)
            : null);

    final punto = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLocation: puntoInicial,
          direccion: _direccionController.text.trim(),
          comuna: _comunaController.text.trim(),
          usuarioId: widget.usuario.uid,
        ),
      ),
    );

    if (punto != null && mounted) {
      setState(() => _pickedLocation = punto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ubicación exacta guardada en el mapa!'),
          backgroundColor: AppColors.secondary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _isLoading ? null : _showPhotoOptions,
              child: Stack(
                children: [
                  if (_selectedImage != null)
                    Container(
                      width: 100,
                      height: 100,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  else
                    UserAvatar(
                      fotoUrl: _fotoUrl,
                      nombre: widget.usuario.nombre,
                      radius: 50,
                      fallbackIcon: _isColegio ? Icons.school_rounded : Icons.business_rounded,
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca la foto para cambiarla',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              widget.usuario.nombre,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              widget.usuario.email,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.grey),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.05),
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
                    Text(
                      'Información de cuenta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          AuthService.instance.emailVerificado
                              ? Icons.verified_rounded
                              : Icons.mark_email_unread_outlined,
                          color: AuthService.instance.emailVerificado
                              ? AppColors.secondary
                              : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AuthService.instance.emailVerificado
                                ? 'Correo verificado'
                                : 'Correo no verificado',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AuthService.instance.emailVerificado
                                  ? AppColors.secondary
                                  : AppColors.error,
                            ),
                          ),
                        ),
                        if (!AuthService.instance.emailVerificado)
                          TextButton(
                            onPressed: () async {
                              final error = await AuthService.instance.enviarVerificacion();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error ?? 'Correo de verificación enviado'),
                                  backgroundColor: error == null ? AppColors.secondary : AppColors.error,
                                ),
                              );
                            },
                            child: const Text('Reenviar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isColegio) ...[
                      TextFormField(
                        controller: _identificacionController,
                        decoration: const InputDecoration(
                          labelText: 'NIT (identificación)',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _isColegio ? 'Nombre del colegio' : 'Nombre de la empresa',
                        prefixIcon: Icon(_isColegio ? Icons.school_rounded : Icons.business_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de contacto',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección física',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    if (_isColegio) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _comunaController,
                        decoration: const InputDecoration(
                          labelText: 'Comuna (ej: 17)',
                          prefixIcon: Icon(Icons.map_rounded),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _abrirMapa,
                        icon: const Icon(Icons.map_rounded, color: AppColors.primary),
                        label: Text(
                          _pickedLocation == null
                              ? 'Ajustar ubicación exacta en el mapa'
                              : 'Ajustar punto en el mapa',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      if (_pickedLocation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Punto fijado: ${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Guardar Cambios', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      child: const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}