import 'package:flutter/material.dart';
import 'privacidad_screen.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y Condiciones')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Términos y Condiciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. Introducción\n'
              'Bienvenido a DonaEduca. Al utilizar nuestra aplicación, aceptas los presentes términos y condiciones, que rigen la conexión entre empresas donantes e instituciones educativas.\n\n'
              '2. Uso de la Aplicación y Cuentas\n'
              'Debes proporcionar información veraz (como el NIT) al registrarte. El usuario es responsable de mantener la confidencialidad de sus credenciales. DonaEduca se reserva el derecho de suspender cuentas que presenten actividad fraudulenta o suplantación de identidad.\n\n'
              '3. Compromiso de Donación y Certificados\n'
              'DonaEduca actúa como un facilitador. Las empresas se comprometen a que los bienes donados existan y se entreguen en buen estado. Los certificados generados en formato PDF tienen un propósito informativo y de validación de entrega mediante código QR.\n\n'
              '4. Contenido Generado por el Usuario\n'
              'Las instituciones educativas son responsables de las necesidades y fotografías que publican. Nos reservamos el derecho de eliminar contenido inapropiado o que vulnere nuestros lineamientos comunitarios.\n\n'
              '5. Limitación de Responsabilidad\n'
              'DonaEduca no se hace responsable por acuerdos no cumplidos entre las partes, ni por daños directos o indirectos derivados del uso de la plataforma. Nuestro objetivo es promover la buena fe y la transparencia.\n\n',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadScreen())),
              child: const Text(
                'Ver Políticas de Privacidad',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
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
