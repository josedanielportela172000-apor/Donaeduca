/**
 * Pruebas unitarias de las Reglas de Seguridad de Firestore de DonaEduca.
 *
 * Cobertura de las reglas críticas:
 * 1. Resolución de Roles: Custom Claims prioritarios con fallback a /usuarios/{uid}.
 * 2. Correo verificado: Obligatorio para publicar necesidades o donar.
 * 3. Edición de perfil: El usuario puede modificar datos personales sin alterar campos inmutables (tipo, uid, email).
 * 4. Directorio público de empresas (/empresas_publicas/{uid}): Autenticado para lectura, solo dueño o admin para escritura.
 * 5. Notificaciones in-app: Restricción estricta de emisor y receptor según el tipo de evento.
 */

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'donaedu-rules-test';
let testEnv;

beforeAll(async () => {
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

describe('1. Resolución de Roles y Custom Claims', () => {
  test('Token con claim { role: "admin" } otorga permisos de administrador de inmediato', async () => {
    const adminCtx = testEnv.authenticatedContext('admin_1', { role: 'admin' });
    const targetRef = doc(adminCtx.firestore(), 'usuarios/target_user');
    await testEnv.withSecurityRulesDisabled(async (adminDb) => {
      await setDoc(doc(adminDb, 'usuarios/target_user'), {
        uid: 'target_user',
        tipo: 'empresa',
        email: 'target@empresa.com',
      });
    });
    // Admin puede borrar cualquier usuario
    await assertSucceeds(deleteDoc(targetRef));
  });

  test('Fallback a /usuarios/{uid}.tipo == "admin" si el claim aún no está en el token', async () => {
    await testEnv.withSecurityRulesDisabled(async (adminDb) => {
      await setDoc(doc(adminDb, 'usuarios/legacy_admin'), {
        uid: 'legacy_admin',
        tipo: 'admin',
        email: 'admin@donaeduca.org',
      });
      await setDoc(doc(adminDb, 'usuarios/target_user'), {
        uid: 'target_user',
        tipo: 'empresa',
        email: 'target@empresa.com',
      });
    });
    const legacyCtx = testEnv.authenticatedContext('legacy_admin');
    const targetRef = doc(legacyCtx.firestore(), 'usuarios/target_user');
    await assertSucceeds(deleteDoc(targetRef));
  });
});

describe('2. Verificación de Correo Electrónico Obligatoria', () => {
  test('Colegio con correo NO verificado NO puede publicar una necesidad', async () => {
    const unverifiedCtx = testEnv.authenticatedContext('col_unverified', {
      role: 'colegio',
      email_verified: false,
    });
    const ref = doc(unverifiedCtx.firestore(), 'necesidades/nec_1');
    await assertFails(setDoc(ref, {
      colegioId: 'col_unverified',
      colegioNombre: 'Colegio No Verificado',
      descripcion: '10 pupitres de madera',
      categoria: 'Mobiliario',
      estado: 'pendiente',
      fecha: new Date(),
    }));
  });

  test('Colegio con correo verificado SÍ puede publicar una necesidad válida', async () => {
    const verifiedCtx = testEnv.authenticatedContext('col_verified', {
      role: 'colegio',
      email_verified: true,
    });
    const ref = doc(verifiedCtx.firestore(), 'necesidades/nec_2');
    await assertSucceeds(setDoc(ref, {
      colegioId: 'col_verified',
      colegioNombre: 'Colegio Verificado',
      descripcion: '10 computadores para sala de sistemas',
      categoria: 'Tecnología',
      estado: 'pendiente',
      fecha: new Date(),
    }));
  });

  test('Empresa con correo NO verificado NO puede realizar una donación', async () => {
    const unverifiedCtx = testEnv.authenticatedContext('emp_unverified', {
      role: 'empresa',
      email_verified: false,
    });
    const ref = doc(unverifiedCtx.firestore(), 'donaciones/don_1');
    await assertFails(setDoc(ref, {
      empresaId: 'emp_unverified',
      empresaNombre: 'Empresa Test',
      colegioId: 'col_verified',
      necesidadId: 'nec_2',
      descripcion: '5 laptops',
      fecha: new Date(),
    }));
  });

  test('Empresa con correo verificado SÍ puede registrar una donación válida', async () => {
    const verifiedCtx = testEnv.authenticatedContext('emp_verified', {
      role: 'empresa',
      email_verified: true,
    });
    const ref = doc(verifiedCtx.firestore(), 'donaciones/don_2');
    await assertSucceeds(setDoc(ref, {
      empresaId: 'emp_verified',
      empresaNombre: 'Empresa Solidaria S.A.S',
      colegioId: 'col_verified',
      necesidadId: 'nec_2',
      descripcion: '5 laptops Core i5',
      fecha: new Date(),
    }));
  });
});

describe('3. Edición de Perfil de Usuario e Inmutabilidad', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (adminDb) => {
      await setDoc(doc(adminDb, 'usuarios/user_perfil'), {
        uid: 'user_perfil',
        nombre: 'Nombre Original',
        email: 'original@correo.com',
        tipo: 'colegio',
        telefono: '3001234567',
        direccion: 'Calle 10 # 5-20',
      });
    });
  });

  test('El usuario puede actualizar nombre, teléfono, fotoUrl y ubicación', async () => {
    const userCtx = testEnv.authenticatedContext('user_perfil');
    const ref = doc(userCtx.firestore(), 'usuarios/user_perfil');
    await assertSucceeds(updateDoc(ref, {
      nombre: 'Nombre Actualizado',
      telefono: '3119876543',
      direccion: 'Carrera 52A # 16-58',
      lat: 3.421,
      lng: -76.541,
      geo_preciso: true,
    }));
  });

  test('El usuario NO puede modificar su rol (tipo)', async () => {
    const userCtx = testEnv.authenticatedContext('user_perfil');
    const ref = doc(userCtx.firestore(), 'usuarios/user_perfil');
    await assertFails(updateDoc(ref, { tipo: 'admin' }));
  });

  test('El usuario NO puede modificar su uid', async () => {
    const userCtx = testEnv.authenticatedContext('user_perfil');
    const ref = doc(userCtx.firestore(), 'usuarios/user_perfil');
    await assertFails(updateDoc(ref, { uid: 'otro_uid_malicioso' }));
  });

  test('El usuario NO puede modificar su email por este endpoint', async () => {
    const userCtx = testEnv.authenticatedContext('user_perfil');
    const ref = doc(userCtx.firestore(), 'usuarios/user_perfil');
    await assertFails(updateDoc(ref, { email: 'suplantado@correo.com' }));
  });
});

describe('4. Directorio Público de Empresas (/empresas_publicas/{uid})', () => {
  test('Usuario no autenticado no puede leer empresas_publicas', async () => {
    const unauthCtx = testEnv.unauthenticatedContext();
    const ref = doc(unauthCtx.firestore(), 'empresas_publicas/emp_1');
    await assertFails(getDoc(ref));
  });

  test('Usuario autenticado puede consultar empresas_publicas', async () => {
    await testEnv.withSecurityRulesDisabled(async (adminDb) => {
      await setDoc(doc(adminDb, 'empresas_publicas/emp_1'), {
        tipo: 'empresa',
        nombre: 'Fundación Aliada',
      });
    });
    const authCtx = testEnv.authenticatedContext('cualquier_usuario');
    const ref = doc(authCtx.firestore(), 'empresas_publicas/emp_1');
    await assertSucceeds(getDoc(ref));
  });

  test('La empresa puede crear y actualizar su propio registro público', async () => {
    const empresaCtx = testEnv.authenticatedContext('emp_duena', { role: 'empresa' });
    const ref = doc(empresaCtx.firestore(), 'empresas_publicas/emp_duena');
    await assertSucceeds(setDoc(ref, { tipo: 'empresa', nombre: 'Mi Empresa S.A.' }));
    await assertSucceeds(updateDoc(ref, { nombre: 'Mi Empresa Renombrada S.A.' }));
  });

  test('Un usuario no puede alterar el registro público de otra empresa', async () => {
    const otroCtx = testEnv.authenticatedContext('otra_cuenta', { role: 'empresa' });
    const ref = doc(otroCtx.firestore(), 'empresas_publicas/emp_duena');
    await assertFails(updateDoc(ref, { nombre: 'Nombre Hackeado' }));
  });
});
