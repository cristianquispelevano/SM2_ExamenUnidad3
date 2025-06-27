# Informe SM2_ExamenUnidad3

---

## Curso  
**Desarrollo de Aplicaciones Móviles II**  

## Fecha  
27 de junio de 2025  

## Estudiante  
Juan Pérez García  

---

## URL del repositorio  
[https://github.com/juanperez/SM2_ExamenUnidad3](https://github.com/juanperez/SM2_ExamenUnidad3)  

---

## Capturas de pantalla

### Estructura de carpetas `.github/workflows/`

![Estructura de carpetas](screenshots/github_workflows_folder.png)  
_Estructura de la carpeta donde se encuentran los workflows para GitHub Actions._

---

### Contenido del archivo `quality-check.yml`

```yaml
name: Flutter Quality Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.7.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test
