import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_moviles2/screens/login_screen.dart';
import 'package:proyecto_moviles2/screens/create_ticket_screen.dart';
import 'package:proyecto_moviles2/screens/view_tickets_screen.dart';
import 'package:proyecto_moviles2/screens/admin_tickets_screen.dart';
import 'package:proyecto_moviles2/services/ticket_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TicketService _ticketService = TicketService();
  User? _user;
  String _userRole = '';
  bool _isLoadingRole = true;

  final Color primaryColor = const Color(0xFF3B5998);

  @override
  void initState() {
    super.initState();
    _loadUserAndRole();
  }

  Future<void> _loadUserAndRole() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(_user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          _userRole = (userDoc.data()?['rol'] ?? '').toString();
          _isLoadingRole = false;
        });
      } else {
        setState(() {
          _userRole = '';
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      setState(() {
        _userRole = '';
        _isLoadingRole = false;
      });
      print('Error al cargar rol: $e');
    }
  }

  bool get isAdmin => _userRole.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sistema de Tickets'),
          backgroundColor: primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'Sistema de Tickets',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionButton(
              icon: Icons.add,
              label: 'Crear Ticket',
              color: Colors.blue,
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateTicketScreen()),
                  ),
            ),
            _buildActionButton(
              icon: Icons.list_alt,
              label: 'Mis Tickets',
              color: Colors.green,
              onPressed: () {
                if (_user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewTicketsScreen(userId: _user!.uid),
                  ),
                );
              },
            ),
            if (isAdmin)
              _buildActionButton(
                icon: Icons.admin_panel_settings,
                label: 'Administrar Tickets',
                color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminTicketsScreen()),
                  );
                },
              ),
            _buildActionButton(
              icon: Icons.search,
              label: 'Buscar Tickets',
              color: Colors.purple,
              onPressed: () => _showSearchDialog(context),
            ),
            if (isAdmin)
              _buildActionButton(
                icon: Icons.analytics,
                label: 'Reportes',
                color: Colors.redAccent,
                onPressed: () => _generateReports(context),
              ),
            _buildActionButton(
              icon: Icons.settings,
              label: 'Configuración',
              color: Colors.grey,
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateTicketScreen()),
          );
        },
        tooltip: 'Crear Ticket Rápido',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // fondo azul muy suave para destacar
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: color),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey[900], // texto oscuro para buen contraste
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buscar Tickets'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Título del Ticket',
                    hintText: 'Ingrese el título del ticket',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final searchQuery = _searchController.text.trim();
                    if (searchQuery.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor ingrese un valor para buscar',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_user == null) return;

                    try {
                      final tickets = await _ticketService
                          .buscarTicketsPorTituloYUsuarioLocal(
                            searchQuery,
                            _user!.uid,
                          );

                      if (tickets.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se encontraron tickets con ese título',
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ViewTicketsScreen(
                                  userId: _user!.uid,
                                  tickets: tickets,
                                ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al buscar tickets: $e')),
                      );
                    }
                  },
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _generateReports(BuildContext context) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando reportes...')));
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notificaciones'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Ayuda'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }
}
