#!/usr/bin/env python3
"""
harness.py — Loop agéntico de prototipos: OLLAMA hace TODO.
Filosofía: el modelo local genera, el harness testea, si falla se le manda
el error al modelo local y él corrige. Repite hasta N iteraciones.
Claude (u otro runner) solo lanza esto y reporta el resultado.

Uso: python3 harness.py <spec.md> <directorio_proyecto> [puerto]
  spec.md        — spec en el vault (o copia local)
  directorio     — donde se escribe el código (ej: /project/prototipos/<nombre>)
  puerto         — 8850-8899, default 8850

Archivos que mantiene:
  /project/prototipos/error_log.json — log acumulado de errores (aprende el modelo)

Salida: PASS en stdout con URL, o FAIL con el último error.
"""
import datetime, json, pathlib, re, subprocess, sys, urllib.request

OLLAMA = "http://192.168.0.99:11434/api/chat"
MODEL = "qwen2.5-coder:14b"
ERROR_LOG = pathlib.Path("/project/prototipos/error_log.json")
MAX_ITERS = int(sys.argv[4]) if len(sys.argv) > 4 else 6
HOST_IP = "192.168.0.64"

# ───────────────────────── helpers ─────────────────────────

def load_error_log():
    try:
        return json.loads(ERROR_LOG.read_text(encoding="utf-8"))
    except Exception:
        return []

def save_error_log(log):
    ERROR_LOG.parent.mkdir(parents=True, exist_ok=True)
    ERROR_LOG.write_text(json.dumps(log, ensure_ascii=False, indent=1), encoding="utf-8")

def lecciones_prefijo():
    log = load_error_log()[-15:]  # últimas 15, suficiente contexto
    if not log:
        return ""
    lines = []
    for e in log:
        lines.append(f"- {e.get('tipo','gen')}: {e.get('error','?')[:150]} -> fix: {e.get('fix','')[:120]}")
    return ("## LECCIONES DE ERRORES PREVIOS (NO REPETIRLOS):\n"
            + "\n".join(lines) + "\n")

def call_ollama(system, user):
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "stream": False,
        "options": {"temperature": 0.3, "num_ctx": 32768, "num_predict": 16384},
    }
    req = urllib.request.Request(OLLAMA, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(req, timeout=950).read())
    return resp["message"]["content"]

def parse_blocks(text):
    """=== ruta ===\n<contenido>\n=== FIN === -> {ruta: contenido}. Tolera fence markdown."""    
    text = re.sub(r"^```\w*\n|^\s*```\s*$", "", text, flags=re.M)
    blocks = {}
    for m in re.finditer(r"=== (.+?) ===\n(.*?)\n=== FIN ===", text, re.S):
        blocks[m.group(1).strip().lstrip("/")] = m.group(2).rstrip()
    if not blocks:
        # respuesta sin bloques: tratar todo como el archivo esperado
        blocks["ruta"] = text.strip()
    return blocks

def write_blocks(blocks, base: pathlib.Path):
    for rel, content in blocks.items():
        if rel == "ruta":
            rel = "app.py"
        rel = rel.lstrip("/")
        # colapsar rutas absolutas tipo /project/prototipos/<nombre>/x -> x
        for prefix in (f"/project/prototipos/{base.name}/", f"project/prototipos/{base.name}/",
                       f"/{base.name}/", f"{base.name}/"):
            if rel.startswith(prefix):
                rel = rel[len(prefix):]
                break
        if rel.startswith("project/prototipos/"):
            rel = rel.split("prototipos/", 1)[-1]
        target = base / pathlib.Path(rel)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content + "\n", encoding="utf-8")
        print(f"  [write] {rel} ({len(content)} chars)")

def find_undefined_names(src: str) -> list[str]:
    """Heurística: llama a nombres estilo foo(...)/foo bar con espacio que no
    están definidos ni importados ni son builtins obvios."""
    defined = (set(re.findall(r"^(?:async\s+)?def (\w+)", src, re.M))
               | set(re.findall(r"^class (\w+)", src, re.M)))
    defined |= {"date", "datetime", "timedelta", "time", "uuid", "json", "os",
                "pathlib", "Path", "re", "secrets", "subprocess", "sys", "tempfile",
                "urllib", "locale", "logging", "logging", "html", "request", "Form",
                "HTTPException", "Request", "RedirectResponse", "JSONResponse",
                "HTMLResponse", "StaticFiles", "Jinja2Templates", "FastAPI",
                "date_range", "parse_date", "max", "min", "len", "list", "dict",
                "set", "str", "int", "float", "bool", "enumerate", "zip", "sorted",
                "any", "all", "sum", "range", "next", "isinstance", "print", "open"}
    calls = re.findall(r"(?<![\w.])[a-z_]\w*(?=\s*\()", src)
    undefined = sorted({c for c in calls
                        if c not in defined and not c.startswith("_")})
    return [u for u in undefined if u not in ("if", "for", "while", "and", "or", "not", "in", "def", "return", "import", "response", "status", "html")]

def route_probe(base: pathlib.Path):
    """Genera checks de rutas leyendo los decoradores de app.py."""
    src = (base / "app.py").read_text(encoding="utf-8")
    routes = []
    for m in re.finditer(r'@app\.(get|post)\("([^"]+)"[^)]*(?:response_class=(\w+))?', src):
        method, path = m.group(1), m.group(2)
        ic = "text/calendar" in src[m.end():m.end()+400] or ".ics" in path
        routes.append((method, path, ic))
    return routes

def validate(base: pathlib.Path):
    """Corre todas las validaciones. Devuelve lista de errores (vacía = PASS)."""
    fails = []
    app = base / "app.py"
    if not app.exists():
        return ["app.py no existe — el modelo no generó el archivo"]

    r = subprocess.run(["python3", "-m", "py_compile", str(app)], capture_output=True, text=True)
    if r.returncode != 0:
        fails.append("[compile] " + r.stderr.decode()[-2500:] if isinstance(r.stderr, bytes) else "[compile] " + r.stderr[-2500:])

    src = app.read_text(encoding="utf-8")
    src = src.lstrip()
    if src.startswith("```"):
        fails.append("[fence] app.py empieza con fence markdown")

    for t in (base / "templates").glob("*.html") if (base / "templates").exists() else []:
        if t.read_text(encoding="utf-8").lstrip().startswith("```"):
            fails.append(f"[fence] templates/{t.name} empieza con fence")

    for m in re.finditer(r'TemplateResponse\("([^"]+)"', src):
        if not (base / "templates" / m.group(1)).exists():
            fails.append(f"[template] TemplateResponse refiere a {m.group(1)} que no existe")

    undef = find_undefined_names(src)
    if undef:
        fails.append(f"[undefined] posibles helpers sin definir: {undef}")

    # probes HTTP
    uvicorn_cmd = str(base / ".venv/bin/uvicorn") if (base / ".venv/bin/uvicorn").exists() else \
        "/project/prototipos/.venv-harness/bin/uvicorn" if pathlib.Path("/project/prototipos/.venv-harness/bin/uvicorn").exists() else "uvicorn"
    server = subprocess.Popen(
        [uvicorn_cmd, "app:app", "--host", "127.0.0.1", "--port", str(PORT)],
        cwd=str(base), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    import time as _t; _t.sleep(4)
    try:
        keys = []
        srcf = (base / "data/calendar_sources.json")
        if srcf.exists():
            try:
                keys = list(json.loads(srcf.read_text(encoding="utf-8")).keys())
            except Exception:
                keys = []
        for method, path, ics in route_probe(base):
            probe_path = path
            if "{apartamento}" in path:
                if not keys:
                    continue  # sin key real, se omite
                probe_path = path.replace("{apartamento}", keys[0])
            try:
                if method == "get":
                    resp = urllib.request.urlopen(f"http://127.0.0.1:{PORT}{path}", timeout=10)
                    if resp.status != 200:
                        fails.append(f"[http] GET {path} -> {resp.status}")
                    if ics and "BEGIN:VCALENDAR" not in resp.read().decode():
                        fails.append(f"[http] {path} no devuelve VCALENDAR")
                else:
                    try:
                        urllib.request.urlopen(f"http://127.0.0.1:{PORT}{path}",
                                               data=b"", timeout=10)
                    except urllib.error.HTTPError as e:
                        if e.code == 500:
                            fails.append(f"[http] POST {path} -> 500")
                    except Exception:
                        pass
            except urllib.error.HTTPError as e:
                fails.append(f"[http] {method.upper()} {path} -> {e.code}")
            except Exception as e:
                fails.append(f"[http] {method.upper()} {path} -> EXC {type(e).__name__}: {str(e)[:120]}")
    finally:
        server.terminate()
    return fails

# ───────────────────────── loop principal ─────────────────────────

def main():
    global PORT
    spec_path, proj = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    PORT = int(sys.argv[3]) if len(sys.argv) > 3 else 8850
    spec_text = spec_path.read_text(encoding="utf-8")
    proj.mkdir(parents=True, exist_ok=True)

    print(f"=== HARNESS: {proj.name} | modelo {MODEL} | max {MAX_ITERS} iteraciones ===")
    print(f"=== spec: {spec_path.name} ===")
    lecciones = lecciones_prefijo()
    errores_registrados = []

    system_base = """Eres un ingeniero senior de Python/FastAPI que termina el trabajo COMPLETO.
Responde SOLO con bloques:
=== ruta/archivo ===
<contenido COMPLETO del archivo, sin markdown, sin fences>
=== FIN ===
No explicaciones. No resúmenes. No 'no pude'. Si algo falla, dices dónde falla y arreglas.
""" + lecciones

    resultado_final = "FAIL"
    for it in range(1, MAX_ITERS + 1):
        print(f"\n--- Iteración {it}/{MAX_ITERS} ---")
        if it == 1:
            user = (f"Genera el prototipo completo siguiendo el spec. Archivos a producir:\n{proj}"
                    f"\n\n=== SPEC ===\n{spec_text}\n")
            blocks = parse_blocks(call_ollama(system_base, user))
            print(f"  [gen] {len(blocks)} bloques")
        else:
            err_text = "\n".join(current_fails)[-4000:]
            files_snapshot = []
            fs = sorted(proj.rglob("*.py")) + (sorted((proj / "templates").glob("*.html")) if (proj / "templates").exists() else [])
            for f in fs:
                files_snapshot.append(f"----- INICIO ARCHIVO: {f.relative_to(proj)} -----\n{f.read_text(encoding='utf-8', errors='replace')}\n----- FIN ARCHIVO -----")
            user = (f"EL PROTOTIPO FALLA con estos errores:\n---\n{err_text}\n---\n\n"
                    f"Devuelve SOLO los archivos que necesitas corregir, COMPLETOS, en el formato habitual "
                    f"(=== ruta === ... === FIN ===). Si el error no tiene sentido o el código ya está bien, "
                    f"explica el error real en una línea antes de los bloques.\n\n"
                    f"----- CONTEXTO: CÓDIGO ACTUAL -----\n" + "\n".join(files_snapshot)[-14000:] +
                    "\n----- FIN CONTEXTO -----\n\n----- SPEC (referencia) -----\n" + spec_text[-3000:])
            blocks = parse_blocks(call_ollama(system_base, user))
            print(f"  [repair] {len(blocks)} bloques corregidos")

        write_blocks(blocks, proj)
        current_fails = validate(proj)

        if current_fails:
            prev_signature = getattr(validate, "_prev", None)
            sig = [(f.name, f.read_text(encoding="utf-8", errors="replace").strip()[:200]) for f in sorted(proj.rglob("*.py"))]
            if sig == prev_signature and it > 1:
                print("  [!] el modelo repitió código idéntico — se fuerza contexto limpio")
                current_fails.insert(0, "[repetido] la corrección anterior no cambió ningún archivo")
            validate._prev = sig
            print(f"  [FALLA] {len(current_fails)} chequeos rojos:")
            for fl in current_fails[:8]:
                print(f"    ✗ {fl[:200]}")
            # registrar en el log de errores para que aprenda
            errores_registrados.append({
                "fecha": datetime.datetime.now().isoformat(timespec="seconds"),
                "proyecto": proj.name, "iteracion": it,
                "tipo": "gen" if it == 1 else "repair",
                "error": current_fails[0][:300],
                "total_chequeos": len(current_fails),
                "resuelto": False,
            })
        else:
            resultado_final = "PASS"
            print(f"\n  [PASS] todos los chequeos verdes en iteración {it}")
            # levantar servicio definitivo
            uvw = str(proj / ".venv/bin/uvicorn") if (proj / ".venv").exists() else \
                "/project/prototipos/.venv-harness/bin/uvicorn" if pathlib.Path("/project/prototipos/.venv-harness/bin/uvicorn").exists() else "uvicorn"
            r = subprocess.run(
                ["systemd-run", f"--unit=proto-{proj.name}", f"--working-directory={proj}",
                 uvw, "app:app", "--host", "0.0.0.0", "--port", str(PORT)],
                capture_output=True, text=True)
            print("  [servicio] " + ("OK" if r.returncode == 0 else r.stderr[:150]))
            break
    else:
        current_fails = validate(proj)  # última foto
        print(f"\n[FAIL] se agotaron las {MAX_ITERS} iteraciones")
        print(f"  último error: {current_fails[:1]}")

    # persistir log de errores
    if errores_registrados:
        log = load_error_log()
        log.extend(errores_registrados)
        save_error_log(log)

    if resultado_final == "PASS":
        print(f"\n✅ PROTOTIPO {proj.name} LISTO")
        print(f"   URL: http://{HOST_IP}:{PORT}/")
        print(f"   Modelo: {MODEL} | Iteraciones: {it} | Errores corregidos: {len(errores_registrados)}")
    else:
        print("\n❌ OLLAMA NO PUDO COMPLETARLO")
    sys.exit(0 if resultado_final == "PASS" else 1)

if __name__ == "__main__":
    main()