class UsuarioModel {
  final String uid, nombre, email, tipo;
  final String? direccion, comuna, telefono, identificacion;
  final String? fotoUrl;
  final double? lat;
  final double? lng;
  final bool? geoPreciso;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.direccion,
    this.comuna,
    this.telefono,
    this.identificacion,
    this.fotoUrl,
    this.lat,
    this.lng,
    this.geoPreciso,
  });

  // `id` es el ID real del documento en Firestore, que debe coincidir con el
  // UID de Auth. Tiene prioridad sobre el campo guardado porque un documento
  // creado a mano (p. ej. el admin) puede tener un `uid` desactualizado y eso
  // rompe los permisos al escribir.
  factory UsuarioModel.fromMap(Map<String, dynamic> m, {String? id}) {
    return UsuarioModel(
      uid: (id != null && id.isNotEmpty) ? id : (m['uid'] ?? ''),
      nombre: m['nombre'] ?? '',
      email: m['email'] ?? '',
      tipo: m['tipo'] ?? '',
      direccion: m['direccion'],
      comuna: m['comuna'],
      telefono: m['telefono'],
      identificacion: m['identificacion'],
      fotoUrl: m['fotoUrl'],
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      geoPreciso: m['geo_preciso'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'tipo': tipo,
      'direccion': direccion,
      'comuna': comuna,
      'telefono': telefono,
      'identificacion': identificacion,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (geoPreciso == true) 'geo_preciso': true,
    };
  }
}