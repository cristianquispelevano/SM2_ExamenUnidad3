import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';

class DashboardWidget extends StatelessWidget {
  final List<Ticket> tickets;

  const DashboardWidget({Key? key, required this.tickets}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = tickets.length;
    final pendientes = tickets.where((t) => t.estado == 'pendiente').length;
    final enProceso = tickets.where((t) => t.estado == 'en_proceso').length;
    final resueltos = tickets.where((t) => t.estado == 'resuelto').length;

    // Si quieres mostrar el resumen de prioridades, puedes agregarlo similarmente

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen de Tickets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCard('Pendientes', pendientes, total, Colors.orange),
              _buildCard('En Proceso', enProceso, total, Colors.amber),
              _buildCard('Resueltos', resueltos, total, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String label, int count, int total, Color color) {
    final double porcentaje = total > 0 ? count / total : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: porcentaje,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '$count tickets (${(porcentaje * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
