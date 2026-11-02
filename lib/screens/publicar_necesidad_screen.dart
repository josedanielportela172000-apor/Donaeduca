import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/usuario_model.dart';
import '../models/necesidad_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/categorias.dart';

const _categorias = categorias;

class PublicarNecesidadScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final NecesidadModel? necesidad;
  const PublicarNecesidadScreen({super.key, required this.usuario, this.necesidad});

  @override
  State<PublicarNecesidadScreen> createState() => _PNState();
}

class _PNState extends State<PublicarNecesidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  late String _cat;
  bool _isLoading = false;
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  bool get _isEditing => widget.necesidad != null;

  @override
  void initState() {
    super.initState();
    _cat = normalizarCategoria(widget.necesidad?.categoria ?? '') == ''
        ? 'Tecnología'
        : normalizarCategoria(widget.necesidad?.categoria ?? '');
    if (widget.necesidad != null) {
      _descController.text = widget.necesidad!.descripcion;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      _setSelectedImage(image);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      _setSelectedImage(image);
    }
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
    setState(() {
      _selectedImage = file;
    });
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Eliminar imagen', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmailVerificationRequiredDialog() async {
    bool reenviando = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread_rounded, color: AppColors.error),
              SizedBox(width: 10),
              Expanded(child: Text('Verificación requerida', style: TextStyle(fontSize: 18))),
            ],
          ),
          content: const Text(
            'Para publicar necesidades en la plataforma, debes tener tu correo electrónico verificado. Esto protege a la comunidad contra publicaciones falsas o no autorizadas.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: reenviando ? null : () async {
                setDialogState(() => reenviando = true);
                final err = await AuthService.instance.enviarVerificacion();
                if (ctx.mounted && mounted) {
                  setDialogState(() => reenviando = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Correo de verificación reenviado. Revisa tu bandeja de entrada.'),
                      backgroundColor: err == null ? AppColors.secondary : AppColors.error,
                    ),
                  );
                }
              },
              child: reenviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reenviar correo'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isVerif = await AuthService.instance.reloadEmailVerification();
                if (ctx.mounted && mounted) {
                  Navigator.pop(ctx);
                  if (isVerif) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Correo verificado con éxito! Ahora puedes publicar.'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                    _submit();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aún no has verificado el enlace que llegó a tu correo.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya lo verifiqué'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isVerif = await AuthService.instance.reloadEmailVerification();
    if (!isVerif) {
      if (mounted) _showEmailVerificationRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.necesidad?.imagenUrl;

      if (_selectedImage != null) {
        final cloudinaryService = CloudinaryService();
        final nuevaUrl = await cloudinaryService.uploadImage(_selectedImage!);

        if (nuevaUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al subir la imagen. Intenta de nuevo.'),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }
        imageUrl = nuevaUrl;
      }

      if (_isEditing) {
        await FirestoreService.instance.updateNecesidad(widget.necesidad!.id, {
          'colegioId': widget.usuario.uid,
          'colegioNombre': widget.usuario.nombre,
          'descripcion': _descController.text.trim(),
          'categoria': _cat,
          'estado': widget.necesidad!.estado,
          'fecha': widget.necesidad!.fecha,
          if (imageUrl != null) 'imagenUrl': imageUrl,
        });
      } else {
        await FirestoreService.instance.publicarNecesidad(NecesidadModel(
          id: '',
          colegioId: widget.usuario.uid,
          colegioNombre: widget.usuario.nombre,
          descripcion: _descController.text.trim(),
          categoria: _cat,
          estado: 'pendiente',
          fecha: DateTime.now(),
          imagenUrl: imageUrl,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Necesidad actualizada con éxito' : 'Necesidad publicada con éxito'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar necesidad' : 'Publicar necesidad')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategoriaDropdown(),
                const SizedBox(height: 18),
                _buildDescripcionField(),
                const SizedBox(height: 18),
                const Text('Imagen (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildImageSection(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      );

  Widget _buildCategoriaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _cat,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
          items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _cat = v!),
        ),
      ],
    );
  }

  Widget _buildDescripcionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          maxLength: 480,
          decoration: const InputDecoration(hintText: 'Ej: Necesitamos 20 sillas para 5to grado...'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe la descripcion' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Text('Guardando...'),
                ],
              )
            : Text(
                _isEditing ? 'Guardar cambios' : 'Publicar necesidad',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: _showImagePickerDialog,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImagePickerDialog,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'Toca para agregar una imagen',
              style: TextStyle(color: AppColors.grey.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
