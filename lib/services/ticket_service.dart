import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crear nuevo ticket
  Future<Ticket> crearTicket({
    required String titulo,
    required String descripcion,
    required String prioridad,
    required String categoria,
  }) async {
    if (titulo.isEmpty ||
        descripcion.isEmpty ||
        prioridad.isEmpty ||
        categoria.isEmpty) {
      throw Exception(
          'Todos los campos son obligatorios para crear un ticket.');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      final ticketRef = _firestore.collection('tickets').doc();
      final now = DateTime.now();

      final ticket = Ticket(
        id: ticketRef.id,
        titulo: titulo,
        descripcion: descripcion,
        estado: 'pendiente',
        userId: user.uid,
        usuarioNombre: user.displayName ?? user.email ?? 'Usuario',
        fechaCreacion: now,
        fechaActualizacion: now,
        prioridad: prioridad,
        categoria: categoria,
      );

      await ticketRef.set(ticket.toFirestore());
      return ticket;
    } catch (e) {
      throw Exception('Error al crear ticket: ${e.toString()}');
    }
  }

  /// Obtener todos los tickets (para admin)
  Stream<List<Ticket>> obtenerTodosLosTickets() {
    return _firestore
        .collection('tickets')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .handleError(
          (error) => throw Exception('Error al obtener tickets: $error'),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  /// Obtener tickets por usuario
  Stream<List<Ticket>> obtenerTicketsPorUsuario(String userId) {
    return _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('fechaCreacion', descending: true) // Se puede ordenar aquí
        .snapshots()
        .handleError(
          (error) =>
              throw Exception('Error al obtener tickets por usuario: $error'),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  /// Obtener tickets por estado
  Stream<List<Ticket>> obtenerTicketsPorEstado(String estado) {
    return _firestore
        .collection('tickets')
        .where('estado', isEqualTo: estado)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .handleError(
          (error) =>
              throw Exception('Error al obtener tickets por estado: $error'),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  /// Actualizar estado del ticket
  Future<void> actualizarEstadoTicket({
    required String ticketId,
    required String nuevoEstado,
  }) async {
    if (ticketId.isEmpty || nuevoEstado.isEmpty) {
      throw Exception('ID de ticket y nuevo estado son obligatorios.');
    }
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar ticket: ${e.toString()}');
    }
  }

  /// Agregar comentario a un ticket
  Future<void> agregarComentario({
    required String ticketId,
    required String contenido,
    required bool esAdmin,
  }) async {
    if (ticketId.isEmpty || contenido.isEmpty) {
      throw Exception(
          'ID de ticket y contenido del comentario son obligatorios.');
    }
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      final comentariosRef = _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('comentarios')
          .doc();

      final comentario = Comentario(
        id: comentariosRef.id,
        contenido: contenido,
        userId: user.uid,
        usuarioNombre: user.displayName ?? user.email ?? 'Usuario',
        fecha: DateTime.now(),
        esAdmin: esAdmin,
      );

      await comentariosRef.set(comentario.toFirestore());
    } catch (e) {
      throw Exception('Error al agregar comentario: ${e.toString()}');
    }
  }

  /// Actualizar ticket (solo ciertos campos)
  Future<void> actualizarTicket(Ticket ticket) async {
    if (ticket.id.isEmpty) {
      throw Exception('ID del ticket es obligatorio para actualizar.');
    }
    try {
      await _firestore.collection('tickets').doc(ticket.id).update({
        'titulo': ticket.titulo,
        'estado': ticket.estado,
        'prioridad': ticket.prioridad,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar el ticket: ${e.toString()}');
    }
  }

  /// Eliminar ticket
  Future<void> eliminarTicket(String ticketId) async {
    if (ticketId.isEmpty) {
      throw Exception('ID del ticket es obligatorio para eliminar.');
    }
    try {
      await _firestore.collection('tickets').doc(ticketId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el ticket: ${e.toString()}');
    }
  }

  /// Obtener comentarios de un ticket
  Stream<List<Comentario>> obtenerComentarios(String ticketId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('comentarios')
        .orderBy('fecha', descending: false)
        .snapshots()
        .handleError(
          (error) => throw Exception('Error al obtener comentarios: $error'),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comentario.fromFirestore(doc)).toList());
  }

  /// Buscar tickets por título (coincidencia parcial)
  Stream<List<Ticket>> buscarTicketsPorTitulo(String titulo) {
    if (titulo.isEmpty) {
      // Retorna stream vacío si no hay título para buscar
      return Stream.value([]);
    }
    final query = _firestore
        .collection('tickets')
        .where('titulo', isGreaterThanOrEqualTo: titulo)
        .where('titulo', isLessThanOrEqualTo: titulo + '\uf8ff')
        .snapshots();

    return query
        .handleError(
          (error) => throw Exception('Error al buscar tickets: $error'),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  /// Buscar tickets por título y usuario, filtrado localmente
  Future<List<Ticket>> buscarTicketsPorTituloYUsuarioLocal(
      String titulo, String userId) async {
    if (userId.isEmpty) {
      throw Exception('ID de usuario es obligatorio para la búsqueda.');
    }
    try {
      final querySnapshot = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .get();

      final tickets =
          querySnapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList();

      // Filtrar localmente por título, insensible a mayúsculas
      final filteredTickets = tickets
          .where((ticket) =>
              ticket.titulo.toLowerCase().contains(titulo.toLowerCase()))
          .toList();

      return filteredTickets;
    } catch (e) {
      throw Exception('Error al buscar tickets por título y usuario local: $e');
    }
  }
}
