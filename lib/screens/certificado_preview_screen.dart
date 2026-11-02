import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/donacion_model.dart';
import '../services/pdf_service.dart';

class CertificadoPreviewScreen extends StatelessWidget {
  final DonacionModel donacion;

  const CertificadoPreviewScreen({super.key, required this.donacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificado de Donación', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: PdfPreview(
        build: (format) => PdfService.generarCertificado(
          nombreEmpresa: donacion.empresaNombre,
          nombreColegio: donacion.colegioNombre,
          descripcion: donacion.descripcion,
          fecha: donacion.fecha,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
