import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Usuario?> signInWithUsernameAndPassword(
      String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Usuario o contraseña vacíos');
    }

    try {
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

      final email = userQuery.docs.first.get('email') as String? ?? '';
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user-data',
          message: 'Email no encontrado para el usuario',
        );
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = _firestore.collection('usuarios').doc(cred.user!.uid);
      if ((await userDoc.get()).exists) {
        await userDoc.update({'ultimoLogin': FieldValue.serverTimestamp()});
      }

      return _getUserFromFirestore(cred.user!.uid);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<Usuario?> registerUser({
    required String username,
    required String email,
    required String password,
    required String nombreCompleto,
    String rol = 'usuario',
  }) async {
    if ([username, email, password, nombreCompleto].any((e) => e.isEmpty)) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Campos obligatorios vacíos');
    }

    final exists = await _firestore
        .collection('usuarios')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (exists.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'El nombre de usuario ya está en uso',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final nuevoUsuario = Usuario(
      id: cred.user!.uid,
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

    await cred.user!.sendEmailVerification();
    return nuevoUsuario;
  }

  Future<void> signOut() => _auth.signOut();

  Future<Usuario?> get currentUser async {
    final user = _auth.currentUser;
    return user == null ? null : _getUserFromFirestore(user.uid);
  }

  Stream<Usuario?> get user => _auth
      .authStateChanges()
      .asyncMap((u) => u == null ? null : _getUserFromFirestore(u.uid));

  Future<Usuario> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuario no encontrado en Firestore',
      );
    }
    return Usuario.fromFirestore(doc);
  }

  Future<void> sendVerificationEmail() async {
    final u = _auth.currentUser;
    if (u != null && !u.emailVerified) await u.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    if (email.isEmpty) {
      throw FirebaseAuthException(
          code: 'invalid-input', message: 'Email vacío');
    }
    return _auth.sendPasswordResetEmail(email: email);
  }
}
