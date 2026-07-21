class UsuarioModel {
  final String uid, nombre, email, tipo;
  final String? direccion, comuna, telefono, identificacion;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.direccion,
    this.comuna,
    this.telefono,
    this.identificacion,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> m) {
    return UsuarioModel(
      uid: m['uid'] ?? '',
      nombre: m['nombre'] ?? '',
      email: m['email'] ?? '',
      tipo: m['tipo'] ?? '',
      direccion: m['direccion'],
      comuna: m['comuna'],
      telefono: m['telefono'],
      identificacion: m['identificacion'],
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
    };
  }
}