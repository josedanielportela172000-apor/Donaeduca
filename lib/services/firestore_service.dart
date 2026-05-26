import &#39;package:cloud_firestore/cloud_firestore.dart&#39;;
import &#39;../models/necesidad_model.dart&#39;;
import &#39;../models/donacion_model.dart&#39;;
class FirestoreService {
final _db = FirebaseFirestore.instance;
Future&lt;void&gt; publicarNecesidad(NecesidadModel n) =&gt;
_db.collection(&#39;necesidades&#39;).add(n.toMap());
Stream&lt;List&lt;NecesidadModel&gt;&gt; getNecesidadesPendientes() =&gt;
_db.collection(&#39;necesidades&#39;)
.where(&#39;estado&#39;, isEqualTo:&#39;pendiente&#39;)
.orderBy(&#39;fecha&#39;, descending:true)
.snapshots()
.map((s) =&gt; s.docs.map(
(d) =&gt; NecesidadModel.fromMap(d.data(),d.id)).toList());
Stream&lt;List&lt;NecesidadModel&gt;&gt; getNecesidadesColegio(
String colegioId) =&gt;
_db.collection(&#39;necesidades&#39;)
.where(&#39;colegioId&#39;, isEqualTo:colegioId)

.orderBy(&#39;fecha&#39;, descending:true)
.snapshots()
.map((s) =&gt; s.docs.map(
(d) =&gt; NecesidadModel.fromMap(d.data(),d.id)).toList());
Future&lt;void&gt; donar({required DonacionModel donacion,
required String necesidadId}) async {
final batch = _db.batch();
batch.set(_db.collection(&#39;donaciones&#39;).doc(),
donacion.toMap());
batch.update(_db.collection(&#39;necesidades&#39;).doc(necesidadId),
{&#39;estado&#39;:&#39;cubierta&#39;});
await batch.commit();
}
Stream&lt;List&lt;DonacionModel&gt;&gt; getDonacionesEmpresa(
String empresaId) =&gt;
_db.collection(&#39;donaciones&#39;)
.where(&#39;empresaId&#39;, isEqualTo:empresaId)
.orderBy(&#39;fecha&#39;, descending:true)
.snapshots()
.map((s) =&gt; s.docs.map(
(d) =&gt; DonacionModel.fromMap(d.data(),d.id)).toList());
Stream&lt;List&lt;DonacionModel&gt;&gt; getDonacionesColegio(
String colegioId) =&gt;
_db.collection(&#39;donaciones&#39;)
.where(&#39;colegioId&#39;, isEqualTo:colegioId)
.orderBy(&#39;fecha&#39;, descending:true)
.snapshots()
.map((s) =&gt; s.docs.map(
(d) =&gt; DonacionModel.fromMap(d.data(),d.id)).toList());
}