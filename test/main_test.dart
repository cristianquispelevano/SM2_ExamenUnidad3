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
  test('capitalize convierte la primera letra a mayúscula', () {
    expect(capitalize('hola'), 'Hola');
  });

  test('capitalize retorna cadena vacía si texto está vacío', () {
    expect(capitalize(''), '');
  });

  test('getPriorityColor devuelve rojo para prioridad alta', () {
    expect(getPriorityColor('alta'), 'rojo');
  });
}
