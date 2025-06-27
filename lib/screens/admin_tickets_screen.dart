import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';
import 'package:proyecto_moviles2/services/ticket_service.dart';
import 'package:proyecto_moviles2/services/auth_service.dart';
import 'package:proyecto_moviles2/screens/login_screen.dart';
import 'package:proyecto_moviles2/screens/admin_ticket_detail_screen.dart';
import 'package:proyecto_moviles2/screens/admin_users_screen.dart';
import 'package:proyecto_moviles2/widgets/dashboard_widget.dart';

class AdminTicketsScreen extends StatefulWidget {
  @override
  _AdminTicketsScreenState createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber.shade700;
      case 'en_proceso':
        return Colors.blueAccent;
      case 'resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);
    final buttonColor = const Color(0xFF4267B2);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Administrador de Tickets',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "Filtrar:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  items:
                      ['todos', 'pendiente', 'en_proceso', 'resuelto']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(letterSpacing: 1.2),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _filterStatus = value!);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group, size: 20),
                  label: const Text(
                    'Usuarios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black45,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminUsersScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título o usuario',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: buttonColor, width: 2),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildTicketsList()),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    final stream =
        _filterStatus == 'todos'
            ? TicketService().obtenerTodosLosTickets()
            : TicketService().obtenerTicketsPorEstado(_filterStatus);

    return StreamBuilder<List<Ticket>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay tickets disponibles'));
        }

        final tickets = snapshot.data!;
        final filteredTickets =
            tickets.where((ticket) {
              final titulo = ticket.titulo.toLowerCase();
              final nombre = ticket.usuarioNombre.toLowerCase();
              return titulo.contains(_searchQuery) ||
                  nombre.contains(_searchQuery);
            }).toList();

        if (filteredTickets.isEmpty) {
          return const Center(
            child: Text('No hay resultados para tu búsqueda'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          itemCount:
              (_filterStatus == 'todos' ? 1 : 0) + filteredTickets.length,
          separatorBuilder:
              (_, __) => const Divider(
                height: 1,
                color: Colors.grey,
                indent: 12,
                endIndent: 12,
              ),
          itemBuilder: (context, index) {
            if (_filterStatus == 'todos' && index == 0) {
              return DashboardWidget(tickets: tickets);
            }

            final ticket =
                filteredTickets[_filterStatus == 'todos' ? index - 1 : index];

            return Card(
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getStatusColor(ticket.estado),
                  child: const Icon(
                    Icons.receipt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  ticket.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ticket.usuarioNombre,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ticket.estado.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(ticket.estado),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.priority_high,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ticket.prioridad,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Editar ticket',
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF3B5998)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AdminTicketDetailScreen(ticket: ticket),
                            ),
                          );
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Eliminar ticket',
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmarEliminar(ticket),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarEliminar(Ticket ticket) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Eliminar Ticket?'),
            content: const Text('¿Estás seguro de eliminar este ticket?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await TicketService().eliminarTicket(ticket.id);
                  Navigator.pop(context);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}
