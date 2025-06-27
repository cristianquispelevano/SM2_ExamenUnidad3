import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // para acceder a la key
import 'package:proyecto_moviles2/services/ticket_service.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'media';
  String _category = 'Mesa de Partes';
  bool _isLoading = false;
  bool _priorityDetermined = false;
  bool _canCreateTicket = false;
  String? _recommendation;

  final TicketService _ticketService = TicketService();

  final Color primaryColor = const Color(0xFF3B5998);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crear Nuevo Ticket',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Por favor ingrese un título'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada de la falla',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  if (value.length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_priorityDetermined)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_priority),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Prioridad: ${_priority.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (_priorityDetermined && _recommendation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _recommendation!,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              DropdownButtonFormField<String>(
                value: _category,
                items: _buildCategoryItems(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(
                  labelText: 'Área de la Municipalidad',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    if (!_priorityDetermined)
                      ElevatedButton.icon(
                        onPressed: _analyzePriority,
                        icon: const Icon(Icons.analytics),
                        label: const Text('ANALIZAR PRIORIDAD'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_priorityDetermined)
                      ElevatedButton.icon(
                        onPressed: _canCreateTicket ? _submitTicket : null,
                        icon: const Icon(Icons.send),
                        label: const Text('CREAR TICKET'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    const List<String> categorias = [
      'Mesa de Partes',
      'Portería de Ingreso de Personal',
      'Equipo Funcional de Archivo Central',
      'Gerencia Municipal',
      'Secretaria de Gerencia Municipal',
      'Gerencia de Administracion y Finanzas',
      'Sub Gerencia de Tesoreria',
      'Sub Gerencia de Recursos Humanos',
      'Sub Gerencia de Abastecimiento',
      'Sub Gerencia de Bienes Patrimoniales',
      'Sub Gerencia de Contabilidad',
      'Gerencia de Administracion Tributaria',
      'Sub Gerencia de Ejecutoria Coactiva',
      'Gerencia de Desarrollo Urbano e Infraestructura',
      'Sub Gerencia de Estudios de Inversiones',
      'Sub Gerencia de Planeamiento Urbano y Catastro',
      'Gerencia de Asesoria Juridica',
      'Gerencia de Planeamiento, Presupuesto y Desarrollo Organizacional',
      'Equipo Funcional de Tecnologias de la Informacion y Comunicaciones',
      'Gerencia de Desarrollo Social y Economico',
      'Sub Gerencia de Gestion Ambiental y Mantenimiento',
      'SISFOH',
      'DEMUNA',
      'Almacen Central',
      'Sub Gerencia de Serenazgo Municipal',
      'Servicio Cementerio General',
      'Servicio Equipo Mecanico',
      'Sub Gerencia de Desarrollo Economico y Turismo',
    ];
    return categorias.map((area) {
      return DropdownMenuItem(value: area, child: Text(area));
    }).toList();
  }

  Future<void> _analyzePriority() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendation = null;
    });

    try {
      final result = await _determinePriorityWithAI(
        _descriptionController.text.trim(),
      );

      setState(() {
        _priority = result['priority']!;
        _recommendation = result['recommendation'];
        _priorityDetermined = true;
        _canCreateTicket = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar prioridad: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitTicket() async {
    setState(() => _isLoading = true);

    try {
      await _ticketService.crearTicket(
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        prioridad: _priority,
        categoria: _category,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket creado con prioridad ${_priority.toUpperCase()}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _determinePriorityWithAI(
    String description,
  ) async {
    final apiKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
    if (apiKey.isEmpty)
      throw Exception('API Key de Hugging Face no configurada.');

    final response = await http.post(
      Uri.parse(
        'https://api-inference.huggingface.co/models/nlptown/bert-base-multilingual-uncased-sentiment',
      ),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': description}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> outerList = jsonDecode(response.body);
      if (outerList.isNotEmpty &&
          outerList[0] is List &&
          outerList[0].isNotEmpty) {
        final label = outerList[0][0]['label'] as String;

        String priority;
        String recommendation;

        if (label.startsWith('1') || label.startsWith('2')) {
          priority = 'alta';
          recommendation =
              'Por favor, contacte al soporte técnico de inmediato.';
        } else if (label.startsWith('3')) {
          priority = 'media';
          recommendation = 'Revise los procedimientos estándar y reintente.';
        } else {
          priority = 'baja';
          recommendation =
              'Puede esperar una respuesta en las próximas 48 horas.';
        }

        return {'priority': priority, 'recommendation': recommendation};
      } else {
        throw Exception('Respuesta inesperada del modelo.');
      }
    } else {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
