import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/model/usuario_model.dart';
import 'package:proyecto_moviles2/services/usuario_service.dart';
import 'package:proyecto_moviles2/screens/admin_create_user_screen.dart';

class AdminUsersScreen extends StatelessWidget {
  final UsuarioService _usuarioService = UsuarioService();

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<List<Usuario>>(
        stream: _usuarioService.obtenerUsuarios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text('No hay usuarios registrados'));

          final usuarios = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    usuario.nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${usuario.username} - ${usuario.rol}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        tooltip: 'Editar usuario',
                        onPressed:
                            () => _mostrarFormularioEditar(context, usuario),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Eliminar usuario',
                        onPressed: () async {
                          final confirmar = await showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('¿Eliminar usuario?'),
                                  content: Text(
                                    '¿Estás seguro de eliminar a ${usuario.nombreCompleto}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmar == true) {
                            await _usuarioService.eliminarUsuario(usuario.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Crear nuevo usuario',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminCreateUserScreen()),
          );
        },
      ),
    );
  }

  void _mostrarFormularioEditar(BuildContext context, Usuario usuario) {
    final nombreController = TextEditingController(
      text: usuario.nombreCompleto,
    );
    final usernameController = TextEditingController(text: usuario.username);
    final emailController = TextEditingController(text: usuario.email);
    String rolSeleccionado = usuario.rol;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Editar Usuario'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.grey),
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              ['usuario', 'admin'].map((rol) {
                                return DropdownMenuItem(
                                  value: rol,
                                  child: Text(rol),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => rolSeleccionado = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      child: const Text('Guardar'),
                      onPressed: () async {
                        final actualizado = Usuario(
                          id: usuario.id,
                          username: usernameController.text.trim(),
                          email: usuario.email,
                          nombreCompleto: nombreController.text.trim(),
                          fechaCreacion: usuario.fechaCreacion,
                          ultimoLogin: usuario.ultimoLogin,
                          emailVerificado: usuario.emailVerificado,
                          rol: rolSeleccionado,
                        );

                        await _usuarioService.actualizarUsuario(actualizado);
                        Navigator.pop(context);
                        usernameController.dispose();
                        nombreController.dispose();
                        emailController.dispose();
                      },
                    ),
                  ],
                ),
          ),
    );
  }
}
