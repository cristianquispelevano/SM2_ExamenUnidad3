import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Iniciar sesión con username y contraseña
  Future<Usuario?> signInWithUsernameAndPassword(
      String username, String password) async {
    try {
      // 1. Buscar usuario por username para obtener el email
      final userQuery = await _firestore
          .collection('usuarios')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Usuario no encontrado',
        );
      }

      final userData = userQuery.docs.first.data();
      final email = userData['email'] as String;

      // 2. Autenticar con Firebase Auth usando el email
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Actualizar último login
      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .update({
        'ultimoLogin': FieldValue.serverTimestamp(),
      });

      // 4. Obtener y devolver el usuario completo
      return await _getUserFromFirestore(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      print('Error al iniciar sesión: ${e.message}');
      return null;
    }
  }

  // Registrar nuevo usuario
  Future<Usuario?> registerUser({
    required String username,
    required String email,
    required String password,
    required String nombreCompleto,
    String rol = 'usuario',
  }) async {
    try {
      // 1. Verificar si el username ya existe
      final usernameQuery = await _firestore
          .collection('usuarios')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'El nombre de usuario ya está en uso',
        );
      }

      // 2. Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Crear documento de usuario en Firestore
      final nuevoUsuario = Usuario(
        id: userCredential.user!.uid,
        username: username,
        email: email,
        nombreCompleto: nombreCompleto,
        fechaCreacion: DateTime.now(),
        emailVerificado: false,
        rol: rol,
      );

      await _firestore
          .collection('usuarios')
          .doc(nuevoUsuario.id)
          .set(nuevoUsuario.toFirestore());

      // 4. Enviar email de verificación
      await userCredential.user!.sendEmailVerification();

      return nuevoUsuario;
    } on FirebaseAuthException catch (e) {
      print('Error al registrar: ${e.message}');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener usuario actual
  Future<Usuario?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _getUserFromFirestore(user.uid);
  }

  // Stream de cambios de autenticación
  Stream<Usuario?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return await _getUserFromFirestore(user.uid);
    });
  }

  // Método auxiliar para obtener usuario de Firestore
  Future<Usuario> _getUserFromFirestore(String uid) async {
    final userDoc = await _firestore.collection('usuarios').doc(uid).get();
    return Usuario.fromFirestore(userDoc);
  }

  // Enviar email de verificación
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
