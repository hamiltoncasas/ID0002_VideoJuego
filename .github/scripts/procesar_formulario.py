#!/usr/bin/env python3
"""Procesa el cuerpo del issue del formulario 'Nuevo Item Jerárquico'
recibido por stdin y escribe las variables extraídas a stdout para GITHUB_ENV."""
import re
import sys

# Forzar UTF-8 en stdin, stdout y stderr (compatibilidad multiplataforma)
if hasattr(sys.stdin, 'reconfigure'):
    sys.stdin.reconfigure(encoding='utf-8')
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

# Leer el cuerpo del issue desde stdin (UTF-8 explícito)
body = sys.stdin.read()
body = body.replace('\r', '')
lines = [line.rstrip() for line in body.split('\n')]


def normalize(text):
    text = text.strip()
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'[\(\)\[\]"\'"\?\!\.,]', '', text)
    text = text.rstrip(':').strip().lower()
    # Eliminar acentos y diacríticos
    text = re.sub(r'[áàäâ]', 'a', text)
    text = re.sub(r'[éèëê]', 'e', text)
    text = re.sub(r'[íìïî]', 'i', text)
    text = re.sub(r'[óòöô]', 'o', text)
    text = re.sub(r'[úùüû]', 'u', text)
    text = re.sub(r'[ñ]', 'n', text)
    return text


expected = {
    'nivel': 'Nivel',
    'status': 'Status',
    'fecha previsto inicio': 'Fecha Previsto Inicio',
    'fecha previsto fin': 'Fecha Previsto Fin',
    'fecha real inicio': 'Fecha Real Inicio',
    'fecha real final': 'Fecha Real Final',
    'descripcion': 'Descripción',
}

values = {v: '' for v in expected.values()}

for i, line in enumerate(lines):
    stripped = line.strip()
    m = re.match(r'^(#+)\s*(.+)$', stripped)
    if not m:
        continue
    heading = normalize(m.group(2))
    if heading in expected:
        target = expected[heading]
        # El valor suele estar en la línea siguiente al heading,
        # pero GitHub Forms inserta una línea en blanco entre el
        # heading y el valor. Saltamos líneas en blanco y nos
        # detenemos al encontrar otro heading (campo vacío).
        for next_line in lines[i + 1:]:
            next_line = next_line.strip()
            if next_line.startswith('#'):
                break
            if next_line and next_line.lower() != 'no response' and not values[target]:
                values[target] = next_line
                break

if not values['Nivel']:
    print('ERROR: No se encontró el valor de Nivel en el cuerpo del issue.', file=sys.stderr)
    print('Contenido recibido (líneas no vacías):', file=sys.stderr)
    for idx, l in enumerate(lines):
        l_stripped = l.strip()
        if l_stripped:
            print(f'  {idx}: {l_stripped}', file=sys.stderr)
    print('Asegúrate de usar un encabezado "### Nivel" y escribir el valor en la línea siguiente.', file=sys.stderr)
    sys.exit(1)

print(f"NIVEL={values['Nivel']}")
print(f"STATUS={values['Status']}")
print(f"FECHA_PREVISTO_INICIO={values['Fecha Previsto Inicio']}")
print(f"FECHA_PREVISTO_FIN={values['Fecha Previsto Fin']}")
print(f"FECHA_REAL_INICIO={values['Fecha Real Inicio']}")
print(f"FECHA_REAL_FINAL={values['Fecha Real Final']}")
print(f"DESCRIPCION={values['Descripción']}")