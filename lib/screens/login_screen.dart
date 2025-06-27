import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/screens/home_screen.dart';
import 'admin_tickets_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingrese usuario y contraseña';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Usuario no encontrado';
          _isLoading = false;
        });
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final email = userDoc['email'] as String;

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Error al autenticar usuario';
          _isLoading = false;
        });
        return;
      }

      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      if (!userSnapshot.exists) {
        setState(() {
          _errorMessage =
              'No se encontró información del usuario en la base de datos.';
          _isLoading = false;
        });
        return;
      }

      final rol = userSnapshot.get('rol');
      if (rol == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminTicketsScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error desconocido: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'network-request-failed':
        return 'Error de red. Verifique su conexión.';
      default:
        return 'Error al iniciar sesión';
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo asistente de soporte
              Icon(
                Icons.support_agent_outlined,
                size: 100,
                color: primaryColor,
              ),

              const SizedBox(height: 24),

              // Título Bienvenido
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 32),

              _buildTextField(
                controller: _usernameController,
                labelText: 'Nombre de usuario',
                prefixIcon: Icons.person,
                textInputAction: TextInputAction.next,
                textColor: Colors.black, // aquí ponemos negro
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                labelText: 'Contraseña',
                prefixIcon: Icons.lock,
                obscureText: true,
                onSubmitted: (_) => _login(),
                textColor: Colors.black, // aquí también negro
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _navigateToRegister,
                child: Text(
                  '¿No tienes cuenta? Regístrate aquí',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    Color textColor = Colors.black, // texto negro por defecto
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        floatingLabelStyle: TextStyle(color: Colors.black),
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFF3B5998), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
