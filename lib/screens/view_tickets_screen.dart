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

  const ViewTicketsScreen({super.key, required this.userId, this.tickets});

  @override
  ViewTicketsScreenState createState() => ViewTicketsScreenState();
}

class ViewTicketsScreenState extends State<ViewTicketsScreen> {
  final TicketService _ticketService = TicketService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B5998);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mis Tickets',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refrescar',
            onPressed: () => setState(() {}),
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
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear Ticket',
        onPressed: () => _navigateToCreateTicket(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error al cargar tickets'),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Reintentar')),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
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

  Widget _buildTicketsList(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tickets.length,
      itemBuilder: (_, index) {
        final t = tickets[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: t.prioridad.isNotEmpty
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: _getPriorityColor(t.prioridad),
                        shape: BoxShape.circle),
                  )
                : const Icon(Icons.priority_high, color: Colors.grey),
            title: Text(t.titulo,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.flag, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text('Estado: ${_capitalize(t.estado)}'),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.date_range,
                      size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text('Creado: ${_dateFormat.format(t.fechaCreacion)}'),
                ]),
                if (t.prioridad.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.bolt, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Prioridad: ${_capitalize(t.prioridad)}'),
                  ]),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Generar PDF',
              onPressed: () => _onGeneratePdfPressed(t),
            ),
            onTap: () => _navigateToTicketDetail(context, t),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
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

  String _capitalize(String text) => text.isEmpty
      ? text
      : text[0].toUpperCase() + text.substring(1).toLowerCase();

  void _navigateToCreateTicket(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CreateTicketScreen()));
  }

  void _navigateToTicketDetail(BuildContext context, Ticket ticket) {}

  Future<void> _onGeneratePdfPressed(Ticket t) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await _generatePdf(t);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generatePdf(Ticket t) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Ticket de soporte',
                style:
                    pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text(t.titulo, style: const pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 10),
                    pw.Text('Descripción:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(t.descripcion,
                        style: const pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 10),
                    pw.Text('Fecha de creación:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_dateFormat.format(t.fechaCreacion)),
                    pw.SizedBox(height: 10),
                    pw.Text('Estado:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_capitalize(t.estado)),
                    pw.SizedBox(height: 10),
                    if (t.prioridad.isNotEmpty) ...[
                      pw.Text('Prioridad:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_capitalize(t.prioridad)),
                    ],
                  ]),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final file =
        await _getSaveFile(_sanitizeFileName('ticket_${t.titulo}.pdf'));

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
      Directory? dir;
      if (Platform.isAndroid) {
        final perm = await Permission.manageExternalStorage.request();
        if (!perm.isGranted) {
          _showSnackBar('Permiso de almacenamiento denegado');
          return null;
        }
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getTemporaryDirectory();
      }

      if (dir == null) return null;
      if (!dir.existsSync()) await dir.create(recursive: true);
      return File('${dir.path}/$filename');
    } catch (e) {
      debugPrint('Error al obtener directorio: $e');
      return null;
    }
  }

  String _sanitizeFileName(String name) =>
      name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
