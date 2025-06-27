import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';
import 'package:proyecto_moviles2/services/ticket_service.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  AdminTicketDetailScreen({required this.ticket});

  @override
  _AdminTicketDetailScreenState createState() =>
      _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  late TextEditingController _tituloController;
  String _estado = '';
  String _prioridad = '';

  final primaryColor = const Color(0xFF3B5998);

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.ticket.titulo);
    _estado = widget.ticket.estado;
    _prioridad = widget.ticket.prioridad;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final actualizado = Ticket(
      id: widget.ticket.id,
      titulo: _tituloController.text.trim(),
      descripcion: widget.ticket.descripcion,
      estado: _estado,
      prioridad: _prioridad,
      categoria: widget.ticket.categoria,
      userId: widget.ticket.userId,
      usuarioNombre: widget.ticket.usuarioNombre,
      fechaCreacion: widget.ticket.fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );

    await TicketService().actualizarTicket(actualizado);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Editar Ticket'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInputField(controller: _tituloController, label: 'Título'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: InputDecoration(
                labelText: 'Estado',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items:
                  ['pendiente', 'en_proceso', 'resuelto']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _estado = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _prioridad,
              decoration: InputDecoration(
                labelText: 'Prioridad',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items:
                  ['baja', 'media', 'alta']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _prioridad = val!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarCambios,
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
                child: const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
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
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
