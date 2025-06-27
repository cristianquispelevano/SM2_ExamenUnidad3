import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String username; // Nombre de usuario para login
  final String email; // Email para autenticación
  final String nombreCompleto; // Nombre real del usuario
  final DateTime fechaCreacion;
  final DateTime? ultimoLogin;
  final bool emailVerificado;
  final String rol;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.fechaCreacion,
    this.ultimoLogin,
    this.emailVerificado = false,
    required this.rol,
  });

  // Constructor desde Firestore
  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Usuario(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      nombreCompleto: data['nombreCompleto'] ?? '',
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      ultimoLogin: data['ultimoLogin'] != null
          ? (data['ultimoLogin'] as Timestamp).toDate()
          : null,
      emailVerificado: data['emailVerificado'] ?? false,
      rol: data['rol'] ?? 'usuario',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'nombreCompleto': nombreCompleto,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'ultimoLogin':
          ultimoLogin != null ? Timestamp.fromDate(ultimoLogin!) : null,
      'emailVerificado': emailVerificado,
      'rol': rol,
    };
  }

  // Método para actualizar último login
  Usuario copyWithLastLogin(DateTime loginTime) {
    return Usuario(
      id: id,
      username: username,
      email: email,
      nombreCompleto: nombreCompleto,
      fechaCreacion: fechaCreacion,
      ultimoLogin: loginTime,
      emailVerificado: emailVerificado,
      rol: rol,
    );
  }
}
