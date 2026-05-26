import &#39;package:cloud_firestore/cloud_firestore.dart&#39;;
class DonacionModel {
final String id, empresaId, empresaNombre;
final String colegioId, colegioNombre;
final String necesidadId, descripcion;
final DateTime fecha;
DonacionModel({required this.id,
required this.empresaId, required this.empresaNombre,
required this.colegioId, required this.colegioNombre,
required this.necesidadId, required this.descripcion,
required this.fecha});
factory DonacionModel.fromMap(
Map&lt;String,dynamic&gt; m, String id) =&gt;
DonacionModel(
id:id, empresaId:m[&#39;empresaId&#39;]??&#39;&#39;,
empresaNombre:m[&#39;empresaNombre&#39;]??&#39;&#39;,
colegioId:m[&#39;colegioId&#39;]??&#39;&#39;,
colegioNombre:m[&#39;colegioNombre&#39;]??&#39;&#39;,
necesidadId:m[&#39;necesidadId&#39;]??&#39;&#39;,
descripcion:m[&#39;descripcion&#39;]??&#39;&#39;,
fecha:(m[&#39;fecha&#39;] as Timestamp).toDate());
Map&lt;String,dynamic&gt; toMap() =&gt; {
&#39;empresaId&#39;:empresaId,&#39;empresaNombre&#39;:empresaNombre,
&#39;colegioId&#39;:colegioId,&#39;colegioNombre&#39;:colegioNombre,
&#39;necesidadId&#39;:necesidadId,&#39;descripcion&#39;:descripcion,
&#39;fecha&#39;:Timestamp.fromDate(fecha)};
}