/**
 * Cloud Functions de DonaEduca.
 *
 * 1) notificarNuevaNecesidad: cuando un colegio publica una necesidad,
 *    se envía un push al topic 'empresas' y se crea un registro en la
 *    bandeja de cada empresa.
 *
 * 2) notificarDonacion: cuando una empresa dona, se envía un push al
 *    colegio beneficiario (por token FCM) y se crea un registro en su
 *    bandeja.
 *
 * 3) notificarReciboColegio: cuando el colegio confirma el recibo de una
 *    donación, se envía un push a la empresa donante.
 */
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');

initializeApp();
const db = getFirestore();

// NOTA: La bandeja in-app (usuarios/{uid}/notificaciones) la crea la propia app
// de forma validada (ver firestore.rules y firestore_service.dart). Estos Cloud
// Functions SOLO se encargan de enviar el push, para no duplicar los registros.

// --- 1) Nueva necesidad publicada -> push broadcast a las empresas ---
exports.notificarNuevaNecesidad = onDocumentCreated(
  'necesidades/{necesidadId}',
  async (event) => {
    const necesidad = event.data.data();
    if (!necesidad || necesidad.estado !== 'pendiente') return;

    const titulo = 'Nueva necesidad publicada';
    const mensaje = `${necesidad.colegioNombre} necesita: ${necesidad.descripcion}`;

    // Push broadcast al topic de empresas.
    try {
      await getMessaging().send({
        notification: { title: titulo, body: mensaje },
        data: { necesidadId: event.params.necesidadId },
        topic: 'empresas',
      });
    } catch (e) {
      console.error('Error enviando push a topic empresas:', e);
    }
  }
);

// --- 2) Nueva donación -> push dirigido al colegio beneficiario ---
exports.notificarDonacion = onDocumentCreated(
  'donaciones/{donacionId}',
  async (event) => {
    const donacion = event.data.data();
    if (!donacion || !donacion.colegioId) return;

    const titulo = '¡Recibiste una donación!';
    const mensaje = `${donacion.empresaNombre} donó para tu necesidad: ${donacion.descripcion}`;

    // Push dirigido al token del colegio.
    try {
      const colegioDoc = await db
        .collection('usuarios')
        .doc(donacion.colegioId)
        .get();
      const token = colegioDoc.exists ? colegioDoc.data().fcmToken : null;
      if (token) {
        await getMessaging().send({
          notification: { title: titulo, body: mensaje },
          data: { necesidadId: donacion.necesidadId },
          token,
        });
      }
    } catch (e) {
      console.error('Error enviando push al colegio:', e);
    }
  }
);

// --- 3) El colegio confirma el recibo -> push dirigido a la empresa ---
exports.notificarReciboColegio = onDocumentUpdated(
  'donaciones/{donacionId}',
  async (event) => {
    const antes = event.data.before.data();
    const despues = event.data.after.data();
    if (!despues || despues.estado !== 'Recibida') return;
    if (antes && antes.estado === 'Recibida') return; // ya notificado

    const titulo = '¡El colegio recibió tu donación!';
    const mensaje = `${despues.colegioNombre} confirmó el recibo de tu donación.`;

    try {
      const empresaDoc = await db
        .collection('usuarios')
        .doc(despues.empresaId)
        .get();
      const token = empresaDoc.exists ? empresaDoc.data().fcmToken : null;
      if (token) {
        await getMessaging().send({
          notification: { title: titulo, body: mensaje },
          data: { necesidadId: despues.necesidadId, donacionId: event.params.donacionId },
          token,
        });
      }
    } catch (e) {
      console.error('Error enviando push de recibo a la empresa:', e);
    }
  }
);

// --- 4) Sincronización de Custom Claims con Firebase Auth ---
// Asigna 'role' y 'tipo' como custom claims en Firebase Auth para que
// las reglas de Firestore (isAdmin, isColegio, isEmpresa) se evalúen
// de forma inmediata sin costo de lectura en la base de datos.
exports.sincronizarRolUsuario = onDocumentWritten(
  'usuarios/{userId}',
  async (event) => {
    const afterData = event.data?.after?.data();
    if (!afterData) {
      // Documento eliminado
      return;
    }

    const tipo = afterData.tipo;
    if (!tipo) return;

    const beforeData = event.data?.before?.data();
    if (beforeData && beforeData.tipo === tipo) {
      // El rol no cambió
      return;
    }

    const userId = event.params.userId;
    try {
      await getAuth().setCustomUserClaims(userId, {
        role: tipo,
        tipo: tipo,
      });
      console.log(`Custom claims asignados a ${userId}: role=${tipo}`);
    } catch (e) {
      console.error(`Error asignando custom claims a ${userId}:`, e);
    }
  }
);
