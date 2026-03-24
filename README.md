# PepeGrilloMVP (Ray-Ban Meta companion/mentor)

MVP iOS (SwiftUI) estilo **companion/mentor**:
- El usuario define un **objetivo** antes de iniciar (entrevista, reunión, social, etc.)
- La app entra en **modo escucha** (micrófono / speech-to-text)
- Cada cierto tiempo genera **sugerencias**: “puntos para tocar”, “preguntas”, “respuestas rápidas”, “datos para impresionar”, etc.
- Opcional: lee sugerencias en voz alta (TTS) para que salgan por los lentes si están conectados por Bluetooth como headset.
- Al final genera un **resumen tipo Granola**: notas + próximos pasos.

## Importante sobre Ray-Ban Meta Gen 2
- Sin SDK oficial ampliamente disponible para iOS, el MVP asume que los lentes se usan como **audio Bluetooth** (mic/earphones).
- Esto ya permite: capturar audio desde el micrófono seleccionado + reproducir TTS al output (si el usuario eligió los lentes).
- Si luego quieres acceso a cámara/sensores específicos del device, habría que evaluar el **Meta Wearables Device Access Toolkit** (developer preview) y su disponibilidad.

## Cómo correr (Xcode)
1) Abre el proyecto:
   - `PepeGrillo.xcodeproj`
2) Selecciona un simulador (p. ej. cualquier **iPhone** en iOS Simulator).
3) Build & Run (⌘R).

### Permisos requeridos
El proyecto ya incluye en `PepeGrillo/Info.plist`:
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

> TODO: Si quieres que funcione con pantalla apagada o en background real, habrá que evaluar Background Modes. Para el MVP en simulador no es necesario.

## Config (LLM)
El MVP usa OpenAI **si detecta** `OPENAI_API_KEY` en el environment del scheme de Xcode. Si no existe, cae a modo **mock**.

### Opción recomendada (rápida)
En Xcode → Scheme → Run → Arguments → Environment Variables:
- `OPENAI_API_KEY` = tu llave

Esto queda guardado **localmente** en tu proyecto de Xcode (no se sube a git).

Notas:
- No hardcodear llaves.
- No commitear llaves.

### Más adelante (producción)
- Edge Functions / Supabase Secrets / env vars en CI, etc.

## UX del MVP
- Pantalla 1: objetivo + modo (Entrevista/Reunión/Social) + “Start Session”
- Pantalla 2: transcript en vivo + sugerencias + botón “Speak” (opcional)
- Pantalla 3: summary de sesión

## Próximos upgrades
- “Cluely mode”: sugerencias ultra breves, de baja latencia, con throttle agresivo.
- Detección de turnos de conversación y *topic shifts*.
- “Granola mode”: resumen estructurado + action items + follow-ups.
- Perfiles: *job interview*, *sales call*, *first date*, *networking*, etc.
