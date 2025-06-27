import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nombreCompletoController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar si el username ya existe
      final usernameQuery =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('username', isEqualTo: _usernameController.text.trim())
              .limit(1)
              .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'El nombre de usuario ya está en uso',
        );
      }

      // Crear usuario en Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Guardar información adicional en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'nombreCompleto': _nombreCompletoController.text.trim(),
            'fechaCreacion': FieldValue.serverTimestamp(),
            'rol': 'usuario',
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso. Por favor inicia sesión.')),
      );
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
      case 'email-already-in-use':
        return 'El correo electrónico ya está registrado';
      case 'username-already-in-use':
        return 'El nombre de usuario ya está en uso';
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      default:
        return 'Error al registrar el usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 100,
                  color: primaryColor,
                ),

                const SizedBox(height: 24),

                Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Regístrate para comenzar',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 32),

                _buildTextField(
                  controller: _usernameController,
                  labelText: 'Nombre de usuario',
                  prefixIcon: Icons.person,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nombreCompletoController,
                  labelText: 'Nombre completo',
                  prefixIcon: Icons.badge,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Correo electrónico',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
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
                        onPressed: _register,
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '¿Ya tienes cuenta? Inicia sesión',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        floatingLabelStyle: const TextStyle(color: Colors.black),
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreCompletoController.dispose();
    super.dispose();
  }
}
