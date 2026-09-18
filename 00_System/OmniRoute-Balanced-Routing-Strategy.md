# Estrategia de Ruteo Balanceado de OmniRoute (`satanzote-apex`)
**Autoridad**: Escuadrón BELSEBU `OmniMind` (`omnimind-*`)  
**Fecha de Implementación**: 2026-09-18  
**Gateway Activo**: `http://127.0.0.1:20128/v1` (CT 666 `satanzote`)

---

## 1. El Objetivo Fundamental
Maximizar el rendimiento de tokens y proteger las cuotas limitadas de **Claude Pro**, canalizando el tráfico de forma inteligente para que cada tarea use el modelo exacto con el costo óptimo.

```
       ▲
      / \     NIVEL 2: Claude Pro (Sonnet / Opus) [10-15% del tráfico]
     /   \    » Arquitectura crítica, bugs complejos, razonamiento estratégico.
    /     \
   /       \   NIVEL 1: Antigravity Flash (Gemini 3.7) [85-90% del tráfico]
  /_________\  » Workhorse diario: Tools, bash, archivos, código, resúmenes (0 costo).
 ═════════════  NIVEL 3: CheaperInference (Fallback de Resiliencia) [< 1% de tráfico]
```

---

## 2. Definición del Perfil Balanceado: `combo/satanzote-apex`

| Nivel / Prioridad | Modelo Enrutado | Proveedor | Misión y Rol | Costo / Cuota |
| :--- | :--- | :--- | :--- | :--- |
| **P1 (Principal)** | `agy/gemini-3.7-flash-medium` | `agy` (Antigravity) | Workhorse masivo, ejecución de herramientas, contexto 2M | $0.00 / Cuota Ilimitada |
| **P2 (Failover N1)**| `antigravity/gemini-3.7-flash-high` | `antigravity` | Respaldo inmediato de alta velocidad si P1 satura | $0.00 / Cuota Ilimitada |
| **P3 (Escalación N2)**| `antigravity/claude-sonnet-4-6` | `antigravity` | Precisión de código y razonamiento superior cuando se requiere | Cuota Protegida (Pro) |
| **P4 (Fallback N3)**| `cheaperinference/deepseek-v4-flash` | `cheaperinference` | Red de seguridad final ante caídas externas de conexión | Micro-costo ($/M) |

---

## 3. Reglas de Despacho y Gobierno de Tokens

1. **Protección de Claude Pro**:
   - Nunca usar modelos Claude para operaciones mecánicas (ej. `read_file` de 2,000 líneas, lecturas de logs de systemd o escaneos de red).
   - El escuadrón `omnimind-icebreaker` auditará cualquier consumo desmedido de Claude.

2. **Alineación de Contexto (Prompt Caching)**:
   - El caching TTL de 5 minutos en OmniRoute evita re-enviar la historia del sistema y los SOULs en cada turno, ahorrando hasta un 87% de tokens de entrada.

3. **Monitoreo Automático de Salud (OmniMind Engine)**:
   - La auditoría en cron (`/root/scripts/omni_audit.sh`) corre cada 15 minutos, calculando la proporción de tokens consumidos por tier y alertando si la tasa de uso de Claude excede los límites seguros.
