import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/necesidad_model.dart';
import '../models/donacion_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> publicarNecesidad(NecesidadModel n) async {
    try {
      await _db.collection('necesidades').add(n.toMap());
    } catch (e) {
      // Es importante capturar errores de red o permisos
      debugPrint('Error al publicar necesidad en Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateUsuario(String uid, Map<String, dynamic> data) async {
    await _db.collection('usuarios').doc(uid).update(data);
  }

  Future<void> deleteNecesidad(String necesidadId) async {
    await _db.collection('necesidades').doc(necesidadId).delete();
  }


  Stream<List<NecesidadModel>> getNecesidadesPendientes() => _db
      .collection('necesidades')
      .where('estado', isEqualTo: 'pendiente')
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)).toList());

  Stream<List<NecesidadModel>> getNecesidadesColegio(String colegioId) => _db
      .collection('necesidades')
      .where('colegioId', isEqualTo: colegioId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)).toList());

  Future<void> donar({required DonacionModel donacion, required String necesidadId}) async {
    final batch = _db.batch();
    // Guardar la donación
    batch.set(_db.collection('donaciones').doc(), donacion.toMap());
    // Actualizar el estado de la necesidad
    batch.update(_db.collection('necesidades').doc(necesidadId), 
        {'estado': 'cubierta'});
    
    await batch.commit();
  }

  Stream<List<DonacionModel>> getDonacionesEmpresa(String empresaId) => _db
      .collection('donaciones')
      .where('empresaId', isEqualTo: empresaId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)).toList());

  Stream<List<DonacionModel>> getDonacionesColegio(String colegioId) => _db
      .collection('donaciones')
      .where('colegioId', isEqualTo: colegioId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)).toList());
}