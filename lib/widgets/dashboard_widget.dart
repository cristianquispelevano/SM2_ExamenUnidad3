import 'package:flutter/material.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';

class DashboardWidget extends StatelessWidget {
  final List<Ticket> tickets;

  const DashboardWidget({Key? key, required this.tickets}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = tickets.length;

    final Map<String, int> estadoCounts = {
      'pendiente': 0,
      'en_proceso': 0,
      'resuelto': 0,
    };

    for (var ticket in tickets) {
      if (estadoCounts.containsKey(ticket.estado)) {
        estadoCounts[ticket.estado] = estadoCounts[ticket.estado]! + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumen de Tickets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCard('Pendientes', estadoCounts['pendiente']!, total,
                  Colors.orange),
              _buildCard('En Proceso', estadoCounts['en_proceso']!, total,
                  Colors.amber),
              _buildCard(
                  'Resueltos', estadoCounts['resuelto']!, total, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String label, int count, int total, Color color) {
    final double porcentaje = total > 0 ? count / total : 0;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: porcentaje,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text(
                '$count ticket${count != 1 ? 's' : ''} (${(porcentaje * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
