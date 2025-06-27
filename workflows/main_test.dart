import 'package:flutter_test/flutter_test.dart';

// Ejemplo de función simple que podrías tener en tu proyecto
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// Función para obtener color de prioridad (simulado)
String getPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'baja':
      return 'verde';
    case 'media':
      return 'naranja';
    case 'alta':
      return 'rojo';
    default:
      return 'gris';
  }
}

void main() {
  group('Función capitalize', () {
    test('Convierte la primera letra a mayúscula y resto a minúscula', () {
      expect(capitalize('hola'), 'Hola');
      expect(capitalize('mUNDO'), 'Mundo');
    });

    test('Si el texto está vacío, retorna vacío', () {
      expect(capitalize(''), '');
    });
  });

  group('Función getPriorityColor', () {
    test('Devuelve color correcto para prioridad baja', () {
      expect(getPriorityColor('baja'), 'verde');
    });

    test('Devuelve color correcto para prioridad media', () {
      expect(getPriorityColor('media'), 'naranja');
    });

    test('Devuelve color correcto para prioridad alta', () {
      expect(getPriorityColor('alta'), 'rojo');
    });

    test('Devuelve gris para prioridad desconocida', () {
      expect(getPriorityColor('urgente'), 'gris');
    });
  });
}
