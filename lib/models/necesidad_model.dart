import 'package:cloud_firestore/cloud_firestore.dart';

class NecesidadModel {
  final String id, colegioId, colegioNombre;
  final String descripcion, categoria, estado;
  final DateTime fecha;
  final String? imagenUrl;

  NecesidadModel({
    required this.id,
    required this.colegioId,
    required this.colegioNombre,
    required this.descripcion,
    required this.categoria,
    required this.estado,
    required this.fecha,
    this.imagenUrl,
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
      imagenUrl: m['imagenUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'colegioId': colegioId,
        'colegioNombre': colegioNombre,
        'descripcion': descripcion,
        'categoria': categoria,
        'estado': estado,
        'fecha': Timestamp.fromDate(fecha),
        if (imagenUrl != null) 'imagenUrl': imagenUrl,
      };
}