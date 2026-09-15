```mermaid

graph TD
    A[OmniRoute Gateway] -->|routes| B[Cheaper Inference]
    A -->|fallback| C[Gemini]
    A -->|fallback| D[Ollama]
    B -->|42 models| E[Claude/GPT/Gemini/Kimi]
    E -->|$20 budget| F[39 Equipos]
    F -->|auto-routing| G[Tareas]

```
