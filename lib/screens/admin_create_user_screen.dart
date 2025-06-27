import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/services/auth_service.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';

class AdminCreateUserScreen extends StatefulWidget {
  @override
  _AdminCreateUserScreenState createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolSeleccionado = 'usuario';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _nombreCompletoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nuevoUsuario = await AuthService().registerUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombreCompleto: _nombreCompletoController.text.trim(),
        rol: _rolSeleccionado,
      );

      if (nuevoUsuario != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Crear Usuario'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(
                controller: _nombreCompletoController,
                label: 'Nombre completo',
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _usernameController,
                label: 'Username',
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo requerido'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value == null || !value.contains('@')
                            ? 'Email inválido'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: true,
                validator:
                    (value) =>
                        value != null && value.length >= 6
                            ? null
                            : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items:
                    ['usuario', 'admin']
                        .map(
                          (rol) =>
                              DropdownMenuItem(value: rol, child: Text(rol)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _rolSeleccionado = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _crearUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Crear Usuario'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3B5998), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
