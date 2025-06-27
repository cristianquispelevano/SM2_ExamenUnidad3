import 'package:flutter_test/flutter_test.dart';

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

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
  group('Tests para capitalize', () {
    test('Convierte la primera letra a mayúscula', () {
      expect(capitalize('hola'), 'Hola');
      expect(capitalize('mUNDO'), 'Mundo');
    });

    test('Retorna cadena vacía si el texto es vacío', () {
      expect(capitalize(''), '');
    });
  });

  group('Tests para getPriorityColor', () {
    test('Devuelve verde para prioridad baja', () {
      expect(getPriorityColor('baja'), 'verde');
    });

    test('Devuelve naranja para prioridad media', () {
      expect(getPriorityColor('media'), 'naranja');
    });

    test('Devuelve rojo para prioridad alta', () {
      expect(getPriorityColor('alta'), 'rojo');
    });

    test('Devuelve gris para prioridad desconocida', () {
      expect(getPriorityColor('urgente'), 'gris');
    });
  });
}
