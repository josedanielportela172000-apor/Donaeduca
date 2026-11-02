import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/necesidad_model.dart';
import '../models/donacion_model.dart';
import '../models/usuario_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const int _pageSize = 50;

  final _db = FirebaseFirestore.instance;

  Future<void> publicarNecesidad(NecesidadModel n) async {
    try {
      final ref = await _db.collection('necesidades').add(n.toMap());
      // Bandeja in-app (sin Cloud Functions): avisamos a todas las empresas
      // en lotes de a 450 para no superar el límite de 500 operaciones por batch.
      try {
        final empresas = await _db.collection('empresas_publicas').get();
        final docs = empresas.docs;
        if (docs.isEmpty) return;
        const int maxBatch = 450;
        for (var i = 0; i < docs.length; i += maxBatch) {
          final batch = _db.batch();
          final chunk = docs.skip(i).take(maxBatch);
          for (final emp in chunk) {
            batch.set(
              _db.collection('usuarios').doc(emp.id).collection('notificaciones').doc(),
              {
                'titulo': 'Nueva necesidad publicada',
                'mensaje': '${n.colegioNombre} necesita: ${_truncate(n.descripcion)}',
                'tipo': 'necesidad',
                'leida': false,
                'fecha': FieldValue.serverTimestamp(),
                'necesidadId': ref.id,
              },
            );
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Error al notificar a las empresas: $e');
      }
    } catch (e) {
      // Es importante capturar errores de red o permisos
      debugPrint('Error al publicar necesidad en Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateUsuario(String uid, Map<String, dynamic> data) async {
    await _db.collection('usuarios').doc(uid).update(data);
    // Sincronizar nombre en empresas_publicas si es empresa
    if (data.containsKey('nombre')) {
      try {
        final empDoc = _db.collection('empresas_publicas').doc(uid);
        final snap = await empDoc.get();
        if (snap.exists) {
          await empDoc.update({
            'nombre': data['nombre'],
          });
        }
      } catch (e) {
        debugPrint('Error sincronizando empresas_publicas: $e');
      }
    }
  }

  Future<void> deleteUsuario(String uid) async {
    await _db.collection('usuarios').doc(uid).delete();
    // Intenta borrarlo también de empresas_publicas por si era empresa
    try {
      await _db.collection('empresas_publicas').doc(uid).delete();
    } catch (_) {}
  }

  Future<void> deleteNecesidad(String necesidadId) async {
    await _db.collection('necesidades').doc(necesidadId).delete();
  }


  Stream<List<NecesidadModel>> getNecesidadesPendientes() => _db
      .collection('necesidades')
      .where('estado', isEqualTo: 'pendiente')
      .orderBy('fecha', descending: true)
      .limit(_pageSize)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)).toList());

  Stream<List<NecesidadModel>> getNecesidadesColegio(String colegioId) => _db
      .collection('necesidades')
      .where('colegioId', isEqualTo: colegioId)
      .orderBy('fecha', descending: true)
      .limit(_pageSize)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)).toList());

  Future<void> donar({required DonacionModel donacion, required String necesidadId}) async {
    final donacionRef = _db.collection('donaciones').doc();
    // Usamos una transacción para evitar donaciones duplicadas: si dos
    // empresas intentan donar a la misma necesidad a la vez, solo una lo logra.
    await _db.runTransaction((txn) async {
      final necesidadRef = _db.collection('necesidades').doc(necesidadId);
      final doc = await txn.get(necesidadRef);
      if (!doc.exists || doc.data()?['estado'] == 'cubierta') {
        throw Exception('Esta necesidad ya fue cubierta.');
      }
      // Guardar la donación
      txn.set(donacionRef, donacion.toMap());
      // Actualizar el estado de la necesidad
      txn.update(necesidadRef, {'estado': 'cubierta'});
    });

    // Bandeja in-app (sin Cloud Functions): avisamos al colegio beneficiario.
    try {
      await _db
          .collection('usuarios')
          .doc(donacion.colegioId)
          .collection('notificaciones')
          .add({
        'titulo': '¡Recibiste una donación!',
        'mensaje': '${donacion.empresaNombre} donó para tu necesidad: ${_truncate(donacion.descripcion)}',
        'tipo': 'donacion',
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'necesidadId': necesidadId,
        'donacionId': donacionRef.id,
      });
    } catch (e) {
      debugPrint('Error al notificar al colegio: $e');
    }
  }

  /// Todas las donaciones de una empresa (sin límite: se usa en estadísticas).
  Stream<List<DonacionModel>> getDonacionesEmpresa(String empresaId) => _db
      .collection('donaciones')
      .where('empresaId', isEqualTo: empresaId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)).toList());

  /// Todas las donaciones de un colegio (sin límite: se usa en estadísticas).
  Stream<List<DonacionModel>> getDonacionesColegio(String colegioId) => _db
      .collection('donaciones')
      .where('colegioId', isEqualTo: colegioId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)).toList());

  // --- Consultas paginadas (historial) ---

  /// Primera página de donaciones de una empresa (en vivo, limitada).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDonacionesEmpresaQuery(
          String empresaId) =>
      _db
          .collection('donaciones')
          .where('empresaId', isEqualTo: empresaId)
          .orderBy('fecha', descending: true)
          .limit(_pageSize)
          .snapshots();

  /// Primera página de donaciones de un colegio (en vivo, limitada).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDonacionesColegioQuery(
          String colegioId) =>
      _db
          .collection('donaciones')
          .where('colegioId', isEqualTo: colegioId)
          .orderBy('fecha', descending: true)
          .limit(_pageSize)
          .snapshots();

  /// Página siguiente de donaciones, usando el último documento como cursor.
  Future<QuerySnapshot<Map<String, dynamic>>> getDonacionesPage({
    required String? empresaId,
    required String? colegioId,
    required DocumentSnapshot lastDoc,
    int limit = _pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('donaciones');
    if (empresaId != null) query = query.where('empresaId', isEqualTo: empresaId);
    if (colegioId != null) query = query.where('colegioId', isEqualTo: colegioId);
    return query
        .orderBy('fecha', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
  }

  Future<void> updateNecesidad(String id, Map<String, dynamic> data) async {
    await _db.collection('necesidades').doc(id).update(data);
  }

  /// El colegio beneficiario confirma que recibió la donación.
  /// Marca la donación como 'Recibida' y avisa a la empresa en su bandeja.
  Future<void> confirmarRecibo({
    required String donacionId,
    required DonacionModel donacion,
  }) async {
    await _db.collection('donaciones').doc(donacionId).update({
      'estado': 'Recibida',
      'recibidaEn': FieldValue.serverTimestamp(),
    });

    // Notificamos a la empresa en la bandeja in-app.
    try {
      await _db
          .collection('usuarios')
          .doc(donacion.empresaId)
          .collection('notificaciones')
          .add({
        'titulo': '¡El colegio recibió tu donación!',
        'mensaje': '${donacion.colegioNombre} confirmó el recibo: ${_truncate(donacion.descripcion)}',
        'tipo': 'recibo',
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'necesidadId': donacion.necesidadId,
        'donacionId': donacionId,
      });
    } catch (e) {
      debugPrint('Error al notificar recibo a la empresa: $e');
    }
  }

  // --- Admin Queries ---

  Stream<List<NecesidadModel>> getAllNecesidades() => _db
      .collection('necesidades')
      .orderBy('fecha', descending: true)
      .limit(_pageSize)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NecesidadModel.fromMap(d.data(), d.id)).toList());

  Stream<List<DonacionModel>> getAllDonaciones() => _db
      .collection('donaciones')
      .orderBy('fecha', descending: true)
      .limit(_pageSize)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => DonacionModel.fromMap(d.data(), d.id)).toList());

  Stream<List<Map<String, dynamic>>> getAllUsuarios() => _db
      .collection('usuarios')
      .orderBy('nombre', descending: false)
      .limit(_pageSize)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<int> getTotalUsuarios() async {
    final snap = await _db.collection('usuarios').count().get();
    return snap.count ?? 0;
  }

  Future<int> getTotalDonaciones() async {
    final snap = await _db.collection('donaciones').count().get();
    return snap.count ?? 0;
  }

  Future<int> getTotalNecesidadesPendientes() async {
    final snap = await _db
        .collection('necesidades')
        .where('estado', isEqualTo: 'pendiente')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getTotalNecesidadesCubiertas() async {
    final snap = await _db
        .collection('necesidades')
        .where('estado', isEqualTo: 'cubierta')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Paginación real de usuarios con cursor.
  Future<QuerySnapshot<Map<String, dynamic>>> getUsuariosPage({
    DocumentSnapshot? lastDoc,
    int limit = _pageSize,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('usuarios')
        .orderBy('nombre', descending: false);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.limit(limit).get();
  }

  /// Paginación real de necesidades con cursor.
  Future<QuerySnapshot<Map<String, dynamic>>> getAdminNecesidadesPage({
    DocumentSnapshot? lastDoc,
    String? estado,
    int limit = _pageSize,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('necesidades')
        .orderBy('fecha', descending: true);
    if (estado != null && estado != 'todas') {
      query = query.where('estado', isEqualTo: estado);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.limit(limit).get();
  }

  /// Paginación real de donaciones con cursor para panel admin.
  Future<QuerySnapshot<Map<String, dynamic>>> getAdminDonacionesPage({
    DocumentSnapshot? lastDoc,
    int limit = _pageSize,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('donaciones')
        .orderBy('fecha', descending: true);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.limit(limit).get();
  }

  /// Paginación real de colegios con cursor para panel admin.
  Future<QuerySnapshot<Map<String, dynamic>>> getColegiosPage({
    DocumentSnapshot? lastDoc,
    int limit = _pageSize,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('usuarios')
        .where('tipo', isEqualTo: 'colegio')
        .orderBy('nombre', descending: false);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.limit(limit).get();
  }

  Future<NecesidadModel?> getNecesidadById(String id) async {
    try {
      final doc = await _db.collection('necesidades').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return NecesidadModel.fromMap(doc.data()!, id);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener necesidad: $e');
      return null;
    }
  }

  Future<UsuarioModel?> getUsuario(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UsuarioModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      return null;
    }
  }

  // Limita el mensaje de la notificación (reglas de Firestore: máx 500).
  static String _truncate(String value) =>
      value.length > 480 ? value.substring(0, 480) : value;
}