import 'package:flutter/material.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Políticas de Privacidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Políticas de Privacidad',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            Text(
              'Última actualización: Septiembre 2026\n\n'
              '1. Recopilación de Datos Personales\n'
              'DonaEduca recopila información estrictamente necesaria para el funcionamiento de la plataforma:\n'
              '• Datos de registro: Nombre, correo electrónico y documento de identidad colombiano (NIT para empresas e instituciones).\n'
              '• Datos de uso: Interacciones con donaciones y necesidades.\n'
              '• Permisos del dispositivo: Acceso a la cámara (estrictamente para escanear códigos QR de donaciones) y ubicación (opcional, para visualizar instituciones en el mapa).\n\n'
              '2. Uso de la Información\n'
              'Tus datos se utilizan para: conectar empresas con colegios, verificar la autenticidad de los actores, generar certificados de donación, y operar la plataforma mediante los servicios de Google Firebase.\n\n'
              '3. Compartición con Terceros\n'
              'No vendemos, alquilamos ni compartimos tus datos con terceros para fines comerciales. La información es procesada a través de Firebase (Google) bajo sus estrictos estándares de seguridad y Cloudinary (para almacenamiento de imágenes públicas).\n\n'
              '4. Retención y Eliminación de Datos\n'
              'Conservamos tu información mientras tu cuenta esté activa. Tienes derecho a solicitar la eliminación permanente de tu cuenta y todos tus datos personales asociados en cualquier momento escribiendo a contacto.donaeduca@gmail.com. El proceso de eliminación se completará en un plazo máximo de 30 días.\n\n'
              '5. Seguridad\n'
              'Toda la información viaja cifrada y se almacena en servidores seguros. Sin embargo, ningún sistema es infalible, por lo que te instamos a usar contraseñas seguras.\n',
              style: TextStyle(fontSize: 15, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido y volver'),
            ),
          ],
        ),
      ),
    );
  }
}
