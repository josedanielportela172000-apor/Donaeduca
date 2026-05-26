import &#39;package:cloud_firestore/cloud_firestore.dart&#39;;
class NecesidadModel {
final String id, colegioId, colegioNombre;
final String descripcion, categoria, estado;
final DateTime fecha;
NecesidadModel({required this.id,
required this.colegioId, required this.colegioNombre,
required this.descripcion, required this.categoria,
required this.estado, required this.fecha});
factory NecesidadModel.fromMap(
Map&lt;String,dynamic&gt; m, String id) =&gt;
NecesidadModel(
id:id, colegioId:m[&#39;colegioId&#39;]??&#39;&#39;,
colegioNombre:m[&#39;colegioNombre&#39;]??&#39;&#39;,
descripcion:m[&#39;descripcion&#39;]??&#39;&#39;,

categoria:m[&#39;categoria&#39;]??&#39;&#39;,
estado:m[&#39;estado&#39;]??&#39;pendiente&#39;,
fecha:(m[&#39;fecha&#39;] as Timestamp).toDate());
Map&lt;String,dynamic&gt; toMap() =&gt; {
&#39;colegioId&#39;:colegioId,&#39;colegioNombre&#39;:colegioNombre,
&#39;descripcion&#39;:descripcion,&#39;categoria&#39;:categoria,
&#39;estado&#39;:estado,&#39;fecha&#39;:Timestamp.fromDate(fecha)};
}