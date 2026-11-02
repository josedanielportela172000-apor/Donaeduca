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
  // Datos de contacto de la empresa donante, para que el colegio pueda contactarla.
  final String? empresaTelefono;
  final String? empresaEmail;
  final String estado; // 'Pendiente', 'Recibida' o 'Completada'
  final DateTime? fechaRecibida;
 
  DonacionModel({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.colegioId,
    required this.colegioNombre,
    required this.necesidadId,
    required this.descripcion,
    required this.fecha,
    this.empresaTelefono,
    this.empresaEmail,
    this.estado = 'Pendiente',
    this.fechaRecibida,
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
      empresaTelefono: m['empresaTelefono'],
      empresaEmail: m['empresaEmail'],
      estado: m['estado'] ?? 'Pendiente',
      fechaRecibida: m['recibidaEn'] is Timestamp ? (m['recibidaEn'] as Timestamp).toDate() : null,
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
      if (empresaTelefono != null) 'empresaTelefono': empresaTelefono,
      if (empresaEmail != null) 'empresaEmail': empresaEmail,
      'estado': estado,
      if (fechaRecibida != null) 'recibidaEn': Timestamp.fromDate(fechaRecibida!),
    };
  }
}