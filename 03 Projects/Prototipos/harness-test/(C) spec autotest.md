# (C) Spec autotest harness

Prototipo mínimo para validar el harness agéntico.

## Qué es
Una app FastAPI mínima de un solo archivo: `app.py`.

## Archivos esperados
- `app.py`: FastAPI con una sola ruta `GET /` que responde HTML con el texto "Hola prototipo".

## Criterio de funciona
- `python3 -m py_compile app.py` pasa.
- `GET /` responde 200 y el cuerpo contiene "Hola prototipo".
- Sin placeholders ni fences de markdown.