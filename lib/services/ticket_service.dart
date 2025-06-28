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
    if ([titulo, descripcion, prioridad, categoria].any((e) => e.isEmpty)) {
      throw Exception(
          'Todos los campos son obligatorios para crear un ticket.');
    }

    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');

    try {
      final ref = _firestore.collection('tickets').doc();
      final now = DateTime.now();

      final ticket = Ticket(
        id: ref.id,
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

      await ref.set(ticket.toFirestore());
      return ticket;
    } catch (e) {
      throw Exception('Error al crear ticket: $e');
    }
  }

  /// Todos los tickets (admin)
  Stream<List<Ticket>> obtenerTodosLosTickets() => _firestore
      .collection('tickets')
      .orderBy('fechaCreacion', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Ticket.fromFirestore).toList());

  /// Tickets por usuario
  Stream<List<Ticket>> obtenerTicketsPorUsuario(String uid) => _firestore
      .collection('tickets')
      .where('userId', isEqualTo: uid)
      .orderBy('fechaCreacion', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Ticket.fromFirestore).toList());

  /// Tickets por estado
  Stream<List<Ticket>> obtenerTicketsPorEstado(String estado) => _firestore
      .collection('tickets')
      .where('estado', isEqualTo: estado)
      .orderBy('fechaCreacion', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Ticket.fromFirestore).toList());

  /// Cambiar estado
  Future<void> actualizarEstadoTicket({
    required String ticketId,
    required String nuevoEstado,
  }) async {
    if (ticketId.isEmpty || nuevoEstado.isEmpty) {
      throw Exception('ID de ticket y nuevo estado son obligatorios.');
    }
    await _firestore.collection('tickets').doc(ticketId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  /// Agregar comentario
  Future<void> agregarComentario({
    required String ticketId,
    required String contenido,
    required bool esAdmin,
  }) async {
    if (ticketId.isEmpty || contenido.isEmpty) {
      throw Exception('ID de ticket y contenido son obligatorios.');
    }

    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado.');

    final ref = _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('comentarios')
        .doc();

    final comentario = Comentario(
      id: ref.id,
      contenido: contenido,
      userId: user.uid,
      usuarioNombre: user.displayName ?? user.email ?? 'Usuario',
      fecha: DateTime.now(),
      esAdmin: esAdmin,
    );

    await ref.set(comentario.toFirestore());
  }

  /// Actualizar datos del ticket
  Future<void> actualizarTicket(Ticket t) =>
      _firestore.collection('tickets').doc(t.id).update({
        'titulo': t.titulo,
        'estado': t.estado,
        'prioridad': t.prioridad,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

  /// Eliminar ticket
  Future<void> eliminarTicket(String id) =>
      _firestore.collection('tickets').doc(id).delete();

  /// Comentarios de un ticket
  Stream<List<Comentario>> obtenerComentarios(String ticketId) => _firestore
      .collection('tickets')
      .doc(ticketId)
      .collection('comentarios')
      .orderBy('fecha')
      .snapshots()
      .map((s) => s.docs.map(Comentario.fromFirestore).toList());

  /// Búsqueda global por título
  Stream<List<Ticket>> buscarTicketsPorTitulo(String titulo) {
    if (titulo.isEmpty) return Stream.value([]);

    return _firestore
        .collection('tickets')
        .where('titulo', isGreaterThanOrEqualTo: titulo)
        .where('titulo', isLessThanOrEqualTo: '$titulo\uf8ff')
        .snapshots()
        .map((s) => s.docs.map(Ticket.fromFirestore).toList());
  }

  /// Búsqueda local por título + usuario
  Future<List<Ticket>> buscarTicketsPorTituloYUsuarioLocal(
      String titulo, String uid) async {
    if (uid.isEmpty) throw Exception('ID de usuario obligatorio.');

    final snap = await _firestore
        .collection('tickets')
        .where('userId', isEqualTo: uid)
        .get();

    return snap.docs
        .map(Ticket.fromFirestore)
        .where((t) => t.titulo.toLowerCase().contains(titulo.toLowerCase()))
        .toList();
  }
}
