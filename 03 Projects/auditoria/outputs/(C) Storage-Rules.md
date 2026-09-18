# Reglas de Almacenamiento Eficiente del Vault

**Documento:** Protocolo operacional para almacenar información sin caos.  
**Versión:** 1.0  
**Fecha:** 17 de septiembre de 2026  
**Aplicable:** Todos los archivos nuevos en el vault después de la migración.

---

## Índice de Reglas

1. [Frontmatter YAML Obligatorio](#regla-1-frontmatter-yaml-obligatorio)
2. [Convención de Nombres](#regla-2-convención-de-nombres)
3. [Archivos Generados por IA](#regla-3-archivos-generados-por-ia)
4. [Gestión de Archivos Grandes](#regla-4-gestión-de-archivos-grandes)
5. [Duplicación y Deduplicación](#regla-5-duplicación-y-deduplicación)
6. [Código Fuente Original — Never Touch](#regla-6-código-fuente-original--never-touch)
7. [Limpieza Trimestral](#regla-7-limpieza-trimestral)
8. [Sincronización con Git](#regla-8-sincronización-con-git)
9. [Wikilinks y Backreferences](#regla-9-wikilinks-y-backreferences)
10. [Actualización de Archivos Existentes](#regla-10-actualización-de-archivos-existentes)

---

## Regla 1: Frontmatter YAML Obligatorio

### Aplica a
Todos los archivos `.md` **excepto:**
- Archivos de config de Obsidian (.obsidian/snippets/...)
- Templates de Obsidian
- Archivos de tools (.opencode/, .agents/, .claude/)

### Estructura Mínima

```yaml
---
type: [note | project-md | review | skill | draft | analysis | code | howto | reference]
project: [nombre del proyecto, o "personal" si no tiene]
priority: [high | medium | low]
status: [active | draft | completed | archived | deprecated]
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Campos Explicados

| Campo | Valores | Obligatorio | Ejemplo |
|-------|--------|------------|---------|
| `type` | note, project-md, review, analysis, code, howto, reference | ✅ Sí | `type: analysis` |
| `project` | Nombre del proyecto o "personal" | ✅ Sí | `project: DM UAMI` |
| `priority` | high, medium, low | ✅ Sí | `priority: high` |
| `status` | active, draft, completed, archived, deprecated | ✅ Sí | `status: active` |
| `tags` | Lista de tags de `Tags-Taxonomy.md` | ✅ Sí (al menos 1) | `tags: [gromacs, cuda]` |
| `created` | Fecha de creación | ✅ Sí | `created: 2026-09-17` |
| `updated` | Última modificación | ✅ Sí | `updated: 2026-09-17` |

### Cómo Completar

**Al crear un archivo nuevo:**

1. Copia este template:
```yaml
---
type: 
project: 
priority: 
status: 
tags: []
created: 2026-09-17
updated: 2026-09-17
---

# Título
```

2. Rellena cada campo:
   - `type` — ¿Qué es esto? (análisis, nota, código, etc.)
   - `project` — ¿A qué proyecto pertenece?
   - `priority` — ¿Qué tan urgente es?
   - `status` — ¿En qué estado está? (active = estoy trabajando, draft = sin terminar, completed = listo)
   - `tags` — ¿Qué palabras clave lo describen? (usa solo de `Tags-Taxonomy.md`)

### Validación

```bash
# Script para verificar que un archivo tiene frontmatter válido
#!/bin/bash
file=$1
if head -1 "$file" | grep -q "^---"; then
  echo "✅ $file tiene frontmatter"
else
  echo "❌ $file NO tiene frontmatter"
fi
```

---

## Regla 2: Convención de Nombres

### Nombres Válidos

| Patrón | Ejemplo | Cuándo usar |
|--------|---------|------------|
| `Descripcion Corta.md` | `DM UAMI Phase 4 Analysis.md` | Archivos sin fecha |
| `YYYYMMDD - Descripcion.md` | `20260917 - Week Review.md` | Notas con fecha |
| `README.md` | Documentación de proyecto | Archivos de alto nivel |
| `VAULT-GUIDE.md` | Documentación del sistema | Archivos críticos |

### Nombres Inválidos (Evitar)

| Patrón | Ejemplo | Por qué |
|--------|---------|---------|
| Con guion bajo | `phase4_analysis.md` | Obsidian ordena mal; usa espacios |
| Prefijo `(C)` | `(C) Analysis.md` | Usa metadato `type:` en frontmatter en su lugar |
| Vago/genérico | `notes.md`, `stuff.md` | No es descriptivo; nadie lo encuentra después |
| Con caracteres especiales | `análisis!.md`, `test@.md` | Problemas en algunos sistemas de archivos |
| Todos mayúsculas | `ANALYSIS.MD` | Excepto archivos críticos (README, CLAUDE.md) |
| Solo fecha | `20260917.md` | Sin descripción, no sabes qué contiene |

### Ejemplos Prácticos

**✅ Bueno:**
```
01 Projects/DM UAMI/04 Documentacion/
├── ADR-001-Fortran-to-CPP.md
├── ADR-002-CUDA-Memory.md
├── Physics/
│   ├── Lennard-Jones-Potential.md
│   └── Ewald-Summation.md
├── README.md
└── How-To-Build.md

03 Operations/Weekly Reviews/
├── 20260917 - Week 37 Review.md
├── 20260910 - Week 36 Review.md
└── 20260903 - Week 35 Review.md
```

**❌ Malo:**
```
01 Projects/DM UAMI/04 Documentacion/
├── (C) phase4_optimization.md
├── (C) PHASE4_ANALYSIS.md
├── physics_analysis_notes.md
├── stuff_2026-09-17.md
└── todo_todo_todo.md
```

### Regex de Validación

Patrón válido para nombres de archivo:
```
^[A-Z0-9][A-Za-z0-9 \-]{0,200}\.md$
```

(Comienza con mayúscula o número, contiene espacios o guiones, termina en `.md`.)

---

## Regla 3: Archivos Generados por IA

### Ubicación

**NO van en raíz.** Siempre van en la carpeta del proyecto correspondiente.

**Carpeta recomendada:**
- Si es código fuente → `01 Projects/[proyecto]/01 CT 901 - Reescritura C++/` (o similar)
- Si es análisis → `01 Projects/[proyecto]/02 Optimizacion/` (o carpeta temática)
- Si es documentación → `01 Projects/[proyecto]/04 Documentacion/`
- Si es script auxiliar → `01 Projects/[proyecto]/06 Scripts Auxiliares/`

### Nomenclatura

**Cambio importante:** Usa metadatos en frontmatter, no prefijo `(C)` en nombre.

**Antes (antiguo):**
```markdown
(C) PHASE4 Energy Analysis.md
```

**Después (nuevo):**
```markdown
---
type: analysis
project: DM UAMI
...
tags: [gromacs, analysis]
---

# PHASE4 Energy Convergence Analysis
```

**Ventajas:**
- El nombre es limpio y descriptivo.
- Puedes filtrar por `type: analysis` en Obsidian.
- Los agentes IA leen frontmatter y evitan duplicar.
- Búsquedas son más fáciles.

### Validación de Contenido Generado

Cuando un archivo es generado por IA (análisis, código, documentación):

1. **Lee y valida el contenido** antes de pushearlo.
2. **Agrega comentarios de revisión** si encuentras errores:
   ```markdown
   > [REVISOR - 2026-09-17]
   > Encontrado error en línea 45: el valor de energía no coincide con referencia.
   > Acción: Corregir en CT 901 y re-correr benchmark.
   ```
3. **Actualiza `updated: YYYY-MM-DD`** en frontmatter después de revisar.
4. **Marca `status: completed`** si el análisis es definitivo, o `status: draft` si aún trabaja en él.

---

## Regla 4: Gestión de Archivos Grandes

### Límites de Tamaño

| Tamaño | Ubicación en Git | Acción |
|--------|-----------------|--------|
| < 500 KB | ✅ Subir directo | Markdown, imágenes, PDFs pequeños |
| 500 KB — 5 MB | ⚠️ Git LFS o .gitignore | Si es final importante, usa LFS; si es temporal, ignora |
| > 5 MB | ❌ .gitignore | Guardar en CT 901 localmente, no en vault |

### Archivos Grandes Comunes en Vault

```bash
# ❌ NUNCA subir a git
01 Projects/DM UAMI/03 Builds & Binarios/
├── phase4_energies.txt              (>5 MB)
├── dm_mx_npt_phase3_BINARY           (1.0 MB)
├── PHASE3_CUDA_FULL/build/           (8.4 MB)
└── PHASE4_CUDA_PINNED/build/         (7.2 MB)

# Actualiza .gitignore:
echo "01 Projects/DM UAMI/03 Builds & Binarios/" >> .gitignore
echo "01 Projects/DM UAMI/**/build/" >> .gitignore
echo "01 Projects/DM UAMI/**/*.o" >> .gitignore
```

### Cómo Manejar Archivos Grandes

**Scenario 1: Benchmark resultado que quieres guardar**

```bash
# Guarda localmente en CT 901
ssh alejandre@192.168.0.52 "cp benchmark_results.csv /project/gromacs/benchmarks/"

# Crea un README.md que apunte a la ubicación
cat > "01 Projects/DM UAMI/02 Optimizacion/Benchmark-Links.md" << 'EOF'
---
type: reference
project: DM UAMI
priority: medium
status: active
tags: [gromacs, benchmark, reference]
created: 2026-09-17
updated: 2026-09-17
---

# Archivos de Benchmark — Ubicación

Los resultados originales se guardan en CT 901 (no en git por tamaño):

```
CT 901: /project/gromacs/benchmarks/
├── phase4_energies.txt
├── phase4_results_20260917.csv
└── README.md
```

Acceder via: `ssh alejandre@192.168.0.52`

Para reproducir: Ver `../../06 Scripts Auxiliares/benchmark.sh`
EOF
```

**Scenario 2: Build o compilado temporal**

```bash
# .gitignore lo ignora automáticamente
# Pero documenta cómo reproducirlo
cat > "01 Projects/DM UAMI/03 Builds & Binarios/README.md" << 'EOF'
# Builds & Binarios

Este directorio contiene artefactos compilados (ignorados en git).

Para reproducir:

```bash
cd /Users/josealejandre/Obsidian/JarvisVault/01\ Projects/DM UAMI/01\ CT\ 901*/
mkdir -p build
cd build
cmake ..
make -j8
```

**Nota:** Si trabajas en CT 901 remotamente, los binarios viven en `/home/alejandre/DM UAMI/Programa_DM_cpp/build/`.
EOF
```

---

## Regla 5: Duplicación y Deduplicación

### Antes de Crear un Archivo Nuevo

**Siempre busca primero:**

```bash
# En Obsidian: Ctrl+Shift+F (búsqueda global)
# Busca el título o palabras clave

# O en terminal:
grep -r "Título de tu nota" /Users/josealejandre/Obsidian/JarvisVault --include="*.md" | head -5
```

**Si encuentras duplicado:**

1. **Archiva el viejo:**
   ```bash
   mv "Nota Vieja.md" "10 Archives/Nota Vieja (deprecated 2026-09-17).md"
   # Actualiza frontmatter: status: archived
   ```

2. **Actualiza wikilinks:**
   ```bash
   # Busca quién referencia al viejo
   grep -r "Nota Vieja" /Users/josealejandre/Obsidian/JarvisVault --include="*.md"
   # Cambia [[Nota Vieja]] a [[Nota Nueva]]
   ```

### Merge de Contenido Duplicado

Si dos archivos similares coexisten con contenido valioso en ambos:

1. **Combina contenido** en el más importante.
2. **Agrega sección "Histórico":**
   ```markdown
   ## Histórico

   _Nota anterior en: 10 Archives/Old-Note.md_
   - Sección X fue añadida de versión antigua
   - Validado el 2026-09-17
   ```
3. **Archiva el viejo** con referencia cruzada.

---

## Regla 6: Código Fuente Original — Never Touch

### Aplica a

`01 Projects/DM UAMI/00 Codigo Fuente Original/` — es la **referencia congelada**.

### Protocolo

**Nunca editar directamente.** Si necesitas cambiar algo:

1. **Copia a rama nueva:**
   ```bash
   cd /Users/josealejandre/Obsidian/JarvisVault
   git checkout -b feature/refactor-kernels
   ```

2. **Edita en `01 CT 901 - Reescritura C++/`** (la versión en desarrollo).

3. **Valida contra original:**
   ```bash
   diff -u "01 Projects/DM UAMI/00 Codigo Fuente Original/forces.f90" \
           "01 Projects/DM UAMI/01 CT 901 - Reescritura C++/forces.cpp"
   ```

4. **Verifica que física no cambié:**
   - Compara benchmarks (energía, fuerzas, velocidades).
   - Prueba con mismo input que original.

5. **Commita con descripción clara:**
   ```bash
   git commit -m "refactor: port LJ forces to C++ (validated against original)"
   ```

6. **Mergea a main** después de revisión.

### Ignorar Original en Git Updates

```bash
# Marca como assume-unchanged (git no hace tracking)
git update-index --assume-unchanged "01 Projects/DM UAMI/00 Codigo Fuente Original/*"
```

---

## Regla 7: Limpieza Trimestral

### Cuándo
Último viernes de cada trimestre (30 de septiembre, 31 de diciembre, 31 de marzo, 30 de junio).

### Qué Hacer

**Paso 1: Auditoría de Archivos Viejos**

```bash
# Encuentra archivos no modificados en > 180 días
find /Users/josealejandre/Obsidian/JarvisVault/04\ Ideas\ \&\ Drafts -mtime +180 -type f -name "*.md"

# Ejemplo de output:
# /Users/.../04 Ideas & Drafts/Nuevas Ideas/Idea-Vieja-2026-03-14.md
# /Users/.../04 Ideas & Drafts/Prototipos/Prototipo-Abandonado-2026-02-01.md
```

**Paso 2: Decisión de Cada Archivo**

Para cada archivo viejo:

- ✅ **Tiene valor** → Copia a `02 Knowledge/` o carpeta temática
- ❌ **No tiene valor** → Elimina o archiva
- ❓ **Puede ser útil después** → Mueve a `10 Archives/Ideas-Abandonadas-Q3-2026/`

**Paso 3: Auditoría de Frontmatter**

```bash
# Verifica que todos los .md tienen frontmatter
find . -name '*.md' -type f ! -path './.git/*' -exec sh -c '
  if ! head -1 "$1" | grep -q "^---"; then
    echo "❌ Sin frontmatter: $1"
  fi
' _ {} \;
```

**Paso 4: Verificar Wikilinks**

```bash
# Busca wikilinks rotos
grep -roh "\[\[[^\]]*\]\]" . --include='*.md' | sort -u | head -30
# Luego verifica si cada uno existe como archivo
```

**Paso 5: Limpiar README.md de Archives**

```bash
# Actualiza /Archives/README.md con resumen de archivos nuevamente archivados
cat >> "10 Archives/README.md" << 'EOF'

### Archivos Archivados — Q3 2026 (2026-09-30)

| Archivo | Razón | Fecha |
|---------|-------|-------|
| Idea-Vieja-2026-03-14.md | Sin progress en 6 meses | 2026-09-30 |
| Prototipo-Abandonado.md | Decisión: no continuar | 2026-09-30 |

EOF
```

### Comando Automático (opcional)

Crea un script `~/cleanup-vault.sh`:

```bash
#!/bin/bash
VAULT="/Users/josealejandre/Obsidian/JarvisVault"
cd "$VAULT"

echo "🧹 Limpieza trimestral del vault"
echo "Buscando archivos no modificados en > 180 días..."

find "04 Ideas & Drafts" -mtime +180 -type f -name "*.md" > /tmp/old_files.txt

echo "Archivos candidatos para archivar:"
cat /tmp/old_files.txt

echo ""
echo "Review manualmente cada archivo. Luego ejecuta:"
echo "mv <archivo> '10 Archives/'"
```

---

## Regla 8: Sincronización con Git

### Rutina Diaria (Automática)

Servidor CT 109, timer `vault-backup.timer` (23:30 CDMX):

```bash
cd /root/JarvisVault
git add -A
git commit -m "Vault backup — $(date +%Y-%m-%d\ %H:%M)"
git push origin main --retry 3
```

### Rutina Semanal (Manual + Automática)

**Domingo ~19:00 CDMX:**

1. **Abre Obsidian**, navega a `03 Operations/Weekly Reviews/`.
2. **Crea archivo nuevo:** `20260917 - Week 37 Review.md`.
3. **Escribe review** (ver template en `00 System/Templates/`).
4. **Ejecuta git:**
   ```bash
   cd /Users/josealejandre/Obsidian/JarvisVault
   git add -A
   git commit -m "Weekly review + vault updates — 2026-09-17"
   git push origin main
   ```

### Antes de Pusheada a Main

**Siempre revisa:**

```bash
git status                          # ¿Qué cambió?
git diff HEAD~1 --stat              # Resumen de cambios
git log --oneline -10               # Últimos 10 commits
```

**Nunca comitees:**
- ❌ Cambios no relacionados (ej: arreglar typo + refactor grande en mismo commit)
- ❌ Archivos sin frontmatter
- ❌ Binarios > 5 MB
- ❌ Wikilinks rotos (si es posible, corrige antes)

---

## Regla 9: Wikilinks y Backreferences

### Crear Wikilinks Correctamente

```markdown
# Sintaxis válida

[[Nombre del Archivo]]              ← Busca "Nombre del Archivo.md"
[[Nombre del Archivo#Sección]]      ← Link a sección específica
[[Nombre|Alias]]                    ← Mostrar "Alias" pero linkea a "Nombre"
```

### Validación de Wikilinks

Antes de pushear, verifica que todos los links funcionan:

```bash
# Busca todos los wikilinks en un archivo
grep -oh "\[\[[^]]*\]\]" "tu-archivo.md" | sed 's/\[\[//' | sed 's/\]\]//'

# Luego verifica si existe como archivo
for link in "Link1" "Link2" "Link3"; do
  find . -name "${link}.md" -type f -not -path './.git/*' || echo "❌ ROTO: [[${link}]]"
done
```

### Refactoring de Links

Si renombras un archivo, **actualiza todos los wikilinks** que lo referencian:

```bash
# Busca referencias al nombre viejo
grep -r "Nombre Viejo" /Users/josealejandre/Obsidian/JarvisVault --include="*.md"

# Reemplaza en todos los archivos
sed -i '' 's/\[\[Nombre Viejo\]\]/[[Nombre Nuevo]]/g' archivo1.md archivo2.md ...
```

### Evitar Wikilinks Rotos

**Antes de crear un wikilink, verifica:**

```bash
# ¿Existe el archivo destino?
ls "01 Projects/DM UAMI/Nombre del Archivo.md"

# Si no existe, crea el archivo o usa otra estructura
```

---

## Regla 10: Actualización de Archivos Existentes

### Procedimiento

Cuando edites un archivo existente:

1. **Abre el archivo** y lee el frontmatter.
2. **Actualiza campo `updated:`** con la fecha actual.
3. **Cambia `status:`** si es necesario:
   - `draft` → `active` (termino de editar, está ready)
   - `active` → `completed` (terminado)
   - `completed` → `archived` (ya no relevante)
4. **Agrega sección "Actualización"** si el cambio es importante:
   ```markdown
   ## Actualización 2026-09-17
   - Corregido error en fórmula (línea 45)
   - Validado contra referencia GROMACS
   - Benchmarks mejorados en 5%
   ```
5. **Commita con mensaje claro:**
   ```bash
   git add "tu-archivo.md"
   git commit -m "docs: update DM UAMI physics explanation (2026-09-17)"
   ```

### Nunca Hagas

- ❌ Editar sin actualizar `updated: YYYY-MM-DD`
- ❌ Cambiar contenido importante sin mencionar en sección "Actualización"
- ❌ Mover archivo manualmente sin actualizar wikilinks
- ❌ Eliminar archivo sin verificar qué lo referencia

### Validación Post-Edición

```bash
# Asegúrate de que no rompiste nada
git diff HEAD tu-archivo.md          # Ver cambios

# Búsqueda visual: ¿hay wikilinks nuevos?
grep -oh "\[\[[^]]*\]\]" tu-archivo.md | sort -u

# Busca referencias externas
grep -r "nombre del archivo" . --include="*.md" | head -10
```

---

## Checklist Rápido (Paste y Úsalo)

Cuando crees o edites un archivo:

```markdown
- [ ] Archivo está en la carpeta correcta (ej: `01 Projects/DM UAMI/...`)
- [ ] Nombre de archivo es descriptivo y sigue convención
- [ ] Frontmatter YAML está completo (type, project, priority, status, tags, created, updated)
- [ ] Tags son válidos (solo de Tags-Taxonomy.md)
- [ ] No hay wikilinks rotos ([[...]] — verifica que exista el archivo)
- [ ] Si es código, se agregó en carpeta de proyecto, no en raíz
- [ ] Si es > 5 MB, está en .gitignore y hay README con ubicación
- [ ] Si edité archivo existente, actualicé "updated:" y sección Actualización
- [ ] Commit message es claro y descriptivo
```

---

## Preguntas Frecuentes

### P: ¿Necesito frontmatter en TODOS los .md?

**R:** Sí. Es la única manera de filtrar, buscar y mantener orden sin caos.

### P: ¿Puedo usar tags personalizados no en Taxonomy?

**R:** No. Solo usa los de `Tags-Taxonomy.md`. Si necesitas uno nuevo, agrégalo a Taxonomy y commita.

### P: ¿Qué pasa si duplico un archivo sin querer?

**R:** Busca `grep -r "contenido único" .` y merge manualmente. Luego archiva el viejo.

### P: ¿Puedo mover un archivo de carpeta?

**R:** Sí, pero después actualiza todos los wikilinks que lo referencian. Mejor usar git:
```bash
git mv "Ruta Vieja/Archivo.md" "Ruta Nueva/Archivo.md"
```

### P: ¿Cómo notifico a otros que archivé algo?

**R:** Actualiza `10 Archives/README.md` con tabla de archivos recientemente archivados.

### P: ¿Puedo comprimir archivos antiguos?

**R:** Sí, si no los necesitas versionados. Mueve a CT 901:
```bash
tar -czf archivo-2026-Q1.tar.gz "10 Archives/Old-Project/"
rsync archivo-2026-Q1.tar.gz alejandre@192.168.0.52:/backups/
```

---

**Fin de Reglas de Almacenamiento — 17 de septiembre de 2026**

Mantén este documento a mano cuando crees archivos nuevos. ¡Preguntas? Reviúe la sección FAQs.
