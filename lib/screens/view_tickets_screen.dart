import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_moviles2/model/ticket_model.dart';
import 'package:proyecto_moviles2/services/ticket_service.dart';
import 'package:proyecto_moviles2/screens/create_ticket_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class ViewTicketsScreen extends StatefulWidget {
  final String userId;
  final List<Ticket>? tickets;

  const ViewTicketsScreen({Key? key, required this.userId, this.tickets})
      : super(key: key);

  @override
  State<ViewTicketsScreen> createState() => _ViewTicketsScreenState();
}

class _ViewTicketsScreenState extends State<ViewTicketsScreen> {
  final TicketService _ticketService = TicketService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B5998);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Tickets',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.tickets != null
              ? _buildTicketsList(widget.tickets!)
              : StreamBuilder<List<Ticket>>(
                  stream:
                      _ticketService.obtenerTicketsPorUsuario(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildTicketsList(snapshot.data!);
                  },
                ),
          if (_isGeneratingPdf)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTicket(context),
        tooltip: 'Crear Ticket',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error al cargar tickets'),
          Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No hay tickets creados'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _navigateToCreateTicket(context),
            child: const Text('Crear primer ticket'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: (ticket.prioridad != null && ticket.prioridad!.isNotEmpty)
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket.prioridad!),
                      shape: BoxShape.circle,
                    ),
                  )
                : const Icon(Icons.priority_high, color: Colors.grey),
            title: Text(
              ticket.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Estado: ${_capitalize(ticket.estado)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.date_range,
                        size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Creado: ${_dateFormat.format(ticket.fechaCreacion)}'),
                  ],
                ),
                if (ticket.prioridad != null &&
                    ticket.prioridad!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Prioridad: ${_capitalize(ticket.prioridad!)}'),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _onGeneratePdfPressed(ticket),
              tooltip: 'Generar PDF',
            ),
            onTap: () => _navigateToTicketDetail(context, ticket),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'baja':
        return Colors.green;
      case 'media':
        return Colors.orange;
      case 'alta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _navigateToCreateTicket(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
    );
  }

  void _navigateToTicketDetail(BuildContext context, Ticket ticket) {
    // Implementar detalle si quieres
  }

  Future<void> _onGeneratePdfPressed(Ticket ticket) async {
    setState(() {
      _isGeneratingPdf = true;
    });
    try {
      await _generatePdf(ticket);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _generatePdf(Ticket ticket) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Ticket de soporte',
                  style: pw.TextStyle(
                      fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                  borderRadius: pw.BorderRadius.circular(10),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Título:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(ticket.titulo,
                        style: const pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 10),
                    pw.Text('Descripción:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(ticket.descripcion,
                        style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 10),
                    pw.Text('Fecha de creación:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_dateFormat.format(ticket.fechaCreacion)),
                    pw.SizedBox(height: 10),
                    pw.Text('Estado:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_capitalize(ticket.estado)),
                    pw.SizedBox(height: 10),
                    if (ticket.prioridad != null &&
                        ticket.prioridad!.isNotEmpty) ...[
                      pw.Text('Prioridad:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_capitalize(ticket.prioridad!)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    final filename = _sanitizeFileName('ticket_${ticket.titulo}.pdf');
    final file = await _getSaveFile(filename);

    if (file == null) {
      _showSnackBar('No se pudo obtener directorio para guardar');
      return;
    }

    await file.writeAsBytes(bytes);

    if (!mounted) return;

    _showSnackBar('Archivo PDF guardado: ${file.path}');

    await OpenFilex.open(file.path);
  }

  Future<File?> _getSaveFile(String filename) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          _showSnackBar('Permiso de almacenamiento denegado');
          return null;
        }
        directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getTemporaryDirectory();
      }

      if (directory == null) return null;

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final path = '${directory.path}/$filename';
      return File(path);
    } catch (e) {
      debugPrint('Error al obtener directorio: $e');
      return null;
    }
  }

  String _sanitizeFileName(String name) {
    // Remueve caracteres no válidos en nombres de archivo
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return sanitized;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
