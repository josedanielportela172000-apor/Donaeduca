import 'package:cloud_firestore/cloud_firestore.dart';

class NecesidadModel {
  final String id, colegioId, colegioNombre;
  final String descripcion, categoria, estado;
  final DateTime fecha;

  NecesidadModel({
    required this.id,
    required this.colegioId,
    required this.colegioNombre,
    required this.descripcion,
    required this.categoria,
    required this.estado,
    required this.fecha,
  });

  factory NecesidadModel.fromMap(Map<String, dynamic> m, String id) {
    return NecesidadModel(
      id: id,
      colegioId: m['colegioId'] ?? '',
      colegioNombre: m['colegioNombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      categoria: m['categoria'] ?? '',
      estado: m['estado'] ?? 'pendiente',
      fecha: m['fecha'] is Timestamp 
          ? (m['fecha'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'colegioId': colegioId,
        'colegioNombre': colegioNombre,
        'descripcion': descripcion,
        'categoria': categoria,
        'estado': estado,
        'fecha': Timestamp.fromDate(fecha)
      };
}