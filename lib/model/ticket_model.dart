import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String titulo;
  final String descripcion;
  final String estado;
  final String userId;
  final String usuarioNombre;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String prioridad;
  final String categoria;

  Ticket({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.userId,
    required this.usuarioNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.prioridad,
    required this.categoria,
  });

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ticket(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      userId: data['userId'] ?? '',
      usuarioNombre: data['usuarioNombre'] ?? 'Usuario desconocido',
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
      prioridad: data['prioridad'] ?? 'media',
      categoria: data['categoria'] ?? 'general',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'userId': userId,
      'usuarioNombre': usuarioNombre,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'prioridad': prioridad,
      'categoria': categoria,
    };
  }
}

class Comentario {
  final String id;
  final String contenido;
  final String userId;
  final String usuarioNombre;
  final DateTime fecha;
  final bool esAdmin;

  Comentario({
    required this.id,
    required this.contenido,
    required this.userId,
    required this.usuarioNombre,
    required this.fecha,
    required this.esAdmin,
  });

  factory Comentario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comentario(
      id: doc.id,
      contenido: data['contenido'] ?? '',
      userId: data['userId'] ?? '',
      usuarioNombre: data['usuarioNombre'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      esAdmin: data['esAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contenido': contenido,
      'userId': userId,
      'usuarioNombre': usuarioNombre,
      'fecha': Timestamp.fromDate(fecha),
      'esAdmin': esAdmin,
    };
  }
}
