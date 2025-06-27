import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';

class UsuarioService {
  final CollectionReference<Map<String, dynamic>> _usuariosRef =
      FirebaseFirestore.instance.collection('usuarios');

  // Obtener todos los usuarios
  Stream<List<Usuario>> obtenerUsuarios() {
    return _usuariosRef
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Usuario.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  // Obtener usuario por ID
  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    final doc = await _usuariosRef.doc(id).get();
    if (!doc.exists) return null;
    return Usuario.fromFirestore(doc);
  }

  // Crear usuario (solo en Firestore, no en Auth)
  Future<void> crearUsuario(Usuario usuario) async {
    await _usuariosRef.doc(usuario.id).set(usuario.toFirestore());
  }

  // Actualizar usuario
  Future<void> actualizarUsuario(Usuario usuario) async {
    await _usuariosRef.doc(usuario.id).update(usuario.toFirestore());
  }

  // Eliminar usuario
  Future<void> eliminarUsuario(String id) async {
    await _usuariosRef.doc(id).delete();
  }
}
