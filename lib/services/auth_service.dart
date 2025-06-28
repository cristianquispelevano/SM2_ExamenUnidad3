import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Iniciar sesión con username y contraseña
  Future<Usuario?> signInWithUsernameAndPassword(
      String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Usuario o contraseña vacíos');
    }

    try {
      // Buscar usuario por username para obtener email
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
      final email = userData['email'] as String? ?? '';

      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user-data',
          message: 'Email no encontrado para el usuario',
        );
      }

      // Autenticar con email y contraseña
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar último login si existe documento en Firestore
      final userDocRef =
          _firestore.collection('usuarios').doc(userCredential.user!.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        await userDocRef.update({
          'ultimoLogin': FieldValue.serverTimestamp(),
        });
      }

      // Obtener usuario completo
      return await _getUserFromFirestore(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      // Puedes usar un logger o manejo más sofisticado aquí
      print('Error al iniciar sesión: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado en inicio de sesión: $e');
      rethrow;
    }
  }

  /// Registrar nuevo usuario
  Future<Usuario?> registerUser({
    required String username,
    required String email,
    required String password,
    required String nombreCompleto,
    String rol = 'usuario',
  }) async {
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        nombreCompleto.isEmpty) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Campos obligatorios vacíos');
    }

    try {
      // Verificar si el username ya existe
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

      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

      // Enviar email de verificación
      await userCredential.user!.sendEmailVerification();

      return nuevoUsuario;
    } on FirebaseAuthException catch (e) {
      print('Error al registrar: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al registrar: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtener usuario actual
  Future<Usuario?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _getUserFromFirestore(user.uid);
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Stream de cambios de autenticación
  Stream<Usuario?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      try {
        return await _getUserFromFirestore(user.uid);
      } catch (e) {
        print('Error en stream usuario: $e');
        return null;
      }
    });
  }

  /// Obtener usuario de Firestore, con manejo de documento no existente
  Future<Usuario> _getUserFromFirestore(String uid) async {
    final userDoc = await _firestore.collection('usuarios').doc(uid).get();
    if (!userDoc.exists) {
      throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Usuario no encontrado en Firestore');
    }
    return Usuario.fromFirestore(userDoc);
  }

  /// Enviar email de verificación
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Email vacío');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }
}
