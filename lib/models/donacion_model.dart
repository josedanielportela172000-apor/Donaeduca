import 'package:cloud_firestore/cloud_firestore.dart';
 
class DonacionModel {
  final String id;
  final String empresaId;
  final String empresaNombre;
  final String colegioId;
  final String colegioNombre;
  final String necesidadId;
  final String descripcion;
  final DateTime fecha;
 
  DonacionModel({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.colegioId,
    required this.colegioNombre,
    required this.necesidadId,
    required this.descripcion,
    required this.fecha,
  });

  factory DonacionModel.fromMap(Map<String, dynamic> m, String id) {
    return DonacionModel(
      id: id,
      empresaId: m['empresaId'] ?? '',
      empresaNombre: m['empresaNombre'] ?? '',
      colegioId: m['colegioId'] ?? '',
      colegioNombre: m['colegioNombre'] ?? '',
      necesidadId: m['necesidadId'] ?? '',
      descripcion: m['descripcion'] ?? '',
      // Conversión segura de Timestamp a DateTime
      fecha: m['fecha'] is Timestamp 
          ? (m['fecha'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresaId': empresaId,
      'empresaNombre': empresaNombre,
      'colegioId': colegioId,
      'colegioNombre': colegioNombre,
      'necesidadId': necesidadId,
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}