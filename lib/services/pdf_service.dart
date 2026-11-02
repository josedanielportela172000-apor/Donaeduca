import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<Uint8List> generarCertificado({
    required String nombreEmpresa,
    required String nombreColegio,
    required String descripcion,
    required DateTime fecha,
  }) async {
    final pdf = pw.Document();

    // Intentar cargar logo (manejando error si la ruta falla)
    pw.ImageProvider? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = bytes.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      // Si falla, logoImage quedará null
    }

    final List<String> meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final String fechaStr = '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(50),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#16884b'), width: 8),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Image(logoImage, height: 80)
                else
                  pw.Text('DONAEDUCA', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#16884b'))),
                
                pw.SizedBox(height: 30),
                
                pw.Text(
                  'CERTIFICADO DE DONACIÓN',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#16884b'),
                  ),
                ),
                
                pw.SizedBox(height: 40),
                
                pw.Text('Otorgado a:', style: const pw.TextStyle(fontSize: 20)),
                
                pw.SizedBox(height: 15),
                
                pw.Text(
                  nombreEmpresa.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                pw.Text(
                  'Por su valioso aporte y compromiso con la educación, habiendo realizado una donación solidaria en favor de:',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 18),
                ),
                
                pw.SizedBox(height: 20),
                
                pw.Text(
                  nombreColegio.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#222222'),
                  ),
                ),

                if (descripcion.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 28),
                  pw.Text(
                    'En reconocimiento a la donación:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#16884b'),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text(
                      descripcion,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                
                pw.SizedBox(height: 40),
                
                pw.Text(
                  'Dado el $fechaStr',
                  style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
                
                pw.Spacer(),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 200, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text('Plataforma DonaEduca', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
