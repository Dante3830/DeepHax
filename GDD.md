# UNIVERSIDAD NACIONAL DEL LITORAL
## Facultad de Ingeniería y Ciencias Hídricas
### Tecnicatura en Diseño y Programación de Videojuegos
**Proyecto Final**

---

# GAME DESIGN DOCUMENT (GDD)

**Nombre del Juego:** DEEP HAX
**Versión:** 1.0.0
**Fecha de actualización:** [30/07/2026]

## Ficha del Grupo
| Apellido y Nombre Completo | Función dentro del grupo |
| :--- | :--- |
| Rizzi, Dante | Game Designer / Artista / Programador / Productor |

---

## 1. High Concept y Visión Inicial

<img width="1920" height="1080" alt="Captura de pantalla 2026-07-30 093958" src="https://github.com/user-attachments/assets/7fd0a55e-0180-41ef-b398-559b2203389d" />

**High Concept:** En *Deep Hax*, sos un agente de ciberpatrullaje que debe escribir unos códigos para rastrear a un peligroso terrorista, mientras cerrás frenéticamente *ventanas-puzzle* que amenazan con interrumpir tu trabajo. Es un juego de habilidad y reflejos donde la velocidad y la precisión son la clave.

---

## 2. Estructura Core del Proyecto

### 2.1 Objetivo del Proyecto
El objetivo principal de este proyecto es desarrollar un videojuego funcional y jugable para PC que sirva como trabajo final de la Tecnicatura. El proyecto busca demostrar las habilidades adquiridas en diseño de juego, programación y arte, creando una experiencia original que combine la temática de hackeo con mecánicas de juego ágiles y desafiantes.

### 2.2 Diseño e investigación
- **Definición de idea:** *Deep Hax* es un simulador de hackeo en el que el jugador debe copiar líneas de código mientras resuelve rápidos minijuegos que aparecen en forma de ventanas emergentes. La presión del tiempo y la creciente dificultad de los puzzles crean una experiencia tensa y adictiva.
- **Género:** Simulación de Hackeo, Puzzle, Arcade.
- **Referencias:**
    - **Gameplay de copiar código:** *Welcome to the Game* (Reflect Studios, 2016). https://youtu.be/rdrwRDxuW3o?t=757
    - **Minijuegos de puzzles:** *Keep Talking and Nobody Explodes* (Steel Crate Games, 2015). https://youtu.be/WhyxPD_PZJU
    - **Sistema de monedas y mejoras:** *Downwell* (Moppin, 2015). https://youtu.be/-NgztqEH4iQ?t=110
    - **Estética:** Cine y cultura de hackers (Matrix, Mr. Robot).
- **Público objetivo:** Jugadores adolescentes a partir de 12 años, de cualquier género, que disfruten de juegos con temática de hackeo, alta dificultad, partidas cortas (menos de 30 minutos) y fáciles de aprender pero difíciles de dominar.
- **Mecánicas principales:**
    1.  **Copiar Código:** El jugador debe escribir en un campo de texto las líneas de código que aparecen en el "Recibidor".
    2.  **Resolver Ventanas-Puzzle:** El jugador debe interactuar con ventanas emergentes que contienen minijuegos para cerrarlas.
    3.  **Gestión de Recursos:** El jugador gana monedas ("Hackoins") al resolver puzzles y puede gastarlas en mejoras entre fases.

### 2.3 Concepto del Juego
El jugador asume el rol de un agente de la Agencia Internacional de Ciberpatrullaje (AIC). Su misión es localizar y capturar a Incognitus, un escurridizo ciberterrorista. Para ello, debe infiltrarse en su sistema y copiar líneas de código críticas que revelarán su ubicación.

El gancho principal del juego reside en la multitarea: el jugador debe equilibrar la precisión al copiar el código con la rapidez para resolver los puzzles de las ventanas. La presión de un temporizador que se renueva con cada acierto, junto a la creciente complejidad de los minijuegos, genera una experiencia intensa y gratificante.

### 2.4 Premisas del Videojuego
1.  **El tiempo es el recurso más valioso.** Todo en el juego gira en torno a la gestión del tiempo.
2.  **La distracción es el enemigo.** Las ventanas-puzzle son el principal obstáculo, no solo por su dificultad, sino por la interrupción que causan.
3.  **La práctica lleva a la maestría.** El juego es fácil de entender pero difícil de dominar; la habilidad del jugador crece con cada partida.
4.  **La estética "Hacker" es fundamental.** La interfaz, los colores y el sonido deben sumergir al jugador en el rol de un hacker.

### 2.5 Condiciones del Desarrollo
- **Motor Gráfico/Herramientas:** Godot.
- **Lenguaje de Programación:** GDScript.
- **Control de Versiones:** Git con un repositorio en GitHub.
- **Metodología de Trabajo:** Desarrollo ágil con sprints cortos.
- **Hardware Objetivo:** PC con sistema operativo Windows, MacOS o Linux. Resolución mínima de 1920x1080.
- **Idioma:** Español.

### 2.6 Alcance del proyecto
Este proyecto entregará una **versión jugable y completa del juego**, que incluye:
- Un **menú principal** completamente funcional.
- **Cuatro fases** de juego (con sus respectivas pantallas de transición) más una **fase final contra el jefe**.
- Un **sistema de progresión** que incluye un hub de fases, mejoras comprables con monedas del juego y un perfil de jugador con desbloqueables.
- **Todas las mecánicas** descritas (copiar código, 12 tipos de ventanas-puzzle, 5 condiciones, sistema de combos, etc.).
- **Sistema de guardado** para el progreso, estadísticas y desbloqueos.
- **Paletas de colores y filtros** desbloqueables para personalizar la experiencia visual.

El trabajo finalizará con un producto estable y testeado, listo para ser jugado de principio a fin.

---

## 3. Diseño Detallado del Juego

### 3.1 Elementos del Juego
- **Recibidor:** Caja que muestra la línea de código que el jugador debe copiar.
- **Insertor:** Caja de texto donde el jugador escribe el código.
- **Temporizador:** Barra o número que indica el tiempo restante para la fase.
- **Ventanas-Puzzle:** Ventanas emergentes que contienen un microjuego. Aparecen periódicamente para distraer al jugador.
- **Microjuegos (12 tipos):** Simon Dice, Mantener Pulsado, Laberinto, Contraseña, Conexión de cables, Deslizador, Encuentra la diferencia, Igualar cuadros 3x3, Pulsar repetidamente, Ajustar reloj, Ajustar figura, No pulsar.
- **Condiciones de Ventanas (5 tipos):** Bloqueo de teclado, Acelerador, Desorden visual, Pérdida de hackois, Trampa.
- **Hackoins:** Moneda del juego. Se obtienen al cerrar ventanas-puzzle (más si se hace rápido).
- **Mejoras:** Potenciadores comprables con Hackoins entre fases (ej. Tiempo extra, Proteger combo, Auto-completar, etc.).
- **Combos:** Racha de líneas de código copiadas sin errores. Multiplican las Hackoins al final de la fase.
- **Perfil del Jugador:** Muestra el nivel (1-20), progreso de desbloqueos y estadísticas.

### 3.2 Reglas
1.  **Victoria de Fase:** El jugador debe copiar exitosamente 5 líneas de código en el "Insertor" antes de que el temporizador llegue a 0.
2.  **Derrota de Fase:** El jugador pierde la fase si el temporizador llega a 0 antes de completar las 5 líneas.
3.  **Regla del Temporizador:** Al copiar una línea correctamente, el temporizador se reinicia a su valor máximo (ej. 60 segundos).
4.  **Regla de Interacción de Ventanas:** El jugador debe interactuar con las ventanas-puzzle usando el *click izquierdo* del mouse para cerrarlas.
5.  **Regla de Penalización:** Fallar un microjuego de una ventana-puzzle resulta en una penalización de -5 segundos en el temporizador, pero no cerrará la ventana.
6.  **Regla de Recompensa:** Completar con éxito una ventana-puzzle otorga Hackoins. La cantidad es mayor si se resuelve rápidamente.
7.  **Regla de Combos:** Cada línea de código copiada correctamente suma 1 al combo. Un error al copiar una línea (tecla incorrecta) reinicia el combo a 0.
8.  **Regla de Condiciones:** Las ventanas-puzzle pueden tener una condición que altera el gameplay mientras estén abiertas.
    - *Bloqueo de Teclado:* Inhabilita una tecla aleatoria.
    - *Acelerador:* Aumenta la velocidad del temporizador.
    - *Desorden Visual:* Distorsiona la imagen del "Recibidor".
    - *Pérdida de Hackoins:* Si se ignora, el jugador pierde todas sus Hackoins.
    - *Trampa:* Interactuar con ella en los primeros segundos penaliza con -10 segundos.

### 3.3 Descripción de una sesión de juego
1.  El jugador inicia el juego desde el menú principal y es recibido por una breve cinemática de texto que contextualiza la historia.
2.  Llega al "Hub" o "Pantalla de Fases", donde ve el progreso general (ej. 25% completado si está por empezar la Fase 2) y puede comprar mejoras.
3.  Al presionar "Empezar hackeo", comienza la Fase 1.
4.  El jugador ve el "Recibidor" con la primera línea de código y el "Insertor" donde debe escribirla.
5.  Mientras escribe, comienzan a aparecer ventanas-puzzle en la pantalla. El jugador debe alternar rápidamente entre escribir código y hacer clic en las ventanas para resolver sus minijuegos.
6.  El jugador completa las 5 líneas. Cada línea correcta reinicia el temporizador y suma un combo. Cada ventana resuelta añade Hackoins.
7.  Al completar la fase, el juego muestra un resumen de la victoria y regresa al Hub. El jugador puede entonces comprar mejoras con sus Hackoins.
8.  Este ciclo se repite para las Fases 2, 3 y 4, aumentando la dificultad (más ventanas, menos tiempo, nuevas condiciones).
9.  Tras la Fase 4, el jugador se enfrenta a la Fase Final contra "Incognitus", que requiere un gran combo sin errores.
10. Si el jugador gana, ve el final de la historia. Si pierde en cualquier momento, ve una pantalla de derrota con sus estadísticas y la opción de reintentar empezando por la Fase 1.

### 3.4 Estética y Experiencia del Jugador
- **Experiencia del Jugador:** Se busca crear una sensación de **tensión y urgencia** propia de una situación de alto riesgo. El jugador debe sentirse como un hacker profesional bajo presión, donde cada segundo cuenta. La satisfacción vendrá de dominar la mecánica, mantener un combo alto y superar fases cada vez más difíciles.
- **Estética:**
    - **Visual:** Estética "Dark Hacker". Fondos oscuros, acentos en colores neón (verde, naranja, cian). Interfaz limpia pero con un toque técnico. Las paletas de colores y filtros desbloqueables permitirán personalizar esta experiencia (ej. estilo Matrix o monitor antiguo).
    - **Sonora:** Música electrónica con un ritmo acelerado que aumente la tensión. Efectos de sonido de tecleo, estática y notificaciones digitales pseudo-futuristas para reforzar la inmersión.

---

## 4. Arte, Audio y Bocetos
**Bocetos de Pantalla / UI:**
- **Menú Principal:** Título "DEEP HAX" en una tipografía tecnológica, con los botones: "¡A hackear!", "Historia", "Perfil", "Opciones", "Créditos" y "Salir".
- **Pantalla de Juego (In-Game HUD):**
    - Parte superior: Temporizador.
    - Izquierda superiror: Cantidad de Hackoins conseguidas por el jugador
    - Derecha superior: Combo de líneas bien escritas.
    - Centro: "Recibidor" (caja naranja con texto de código).
    - Parte inferior: "Insertor" (caja amarilla con el texto que escribe el jugador).
    - Izquierda inferior: Tiempo total calculado entre todas las fases.
    - Sobre estos elementos: Ventanas-puzzle emergentes que el jugador debe cerrar.
- **Pantalla de Fases (Hub):** Una interfaz con 4 casillas que representan el progreso del jugador. En la parte inferior, un panel para comprar mejoras.
- **Pantalla de Perfil:** Muestra el nivel del jugador, una barra de progreso y las estadísticas (tiempo total, hackoins totales, etc.).

<img width="1917" height="1078" alt="Titulo" src="https://github.com/user-attachments/assets/8800ca79-0708-4b3b-b1b3-e10c0bc0ae05" />
<img width="1920" height="1080" alt="Captura de pantalla 2026-07-30 093958" src="https://github.com/user-attachments/assets/d8a34a89-3f39-4906-9c5f-84010e83c1bc" />
<img width="1917" height="1078" alt="Captura de pantalla 2026-07-26 231227" src="https://github.com/user-attachments/assets/2b3ec45d-847d-4fe3-81e9-d5b4a93127ed" />

**Estilo Visual y Sonoro:**
- **Paleta de Colores Predeterminada:** Negro (#0a0a0a) como fondo, Verde lima (#39ff14) para el código, Naranja (#ff7b00) para el Recibidor, Amarillo (#ffd700) para el Insertor y Cian (#00ffff) para los acentos de las ventanas.
- **Estilo de Arte:** 2D, con una estética de interfaz de usuario (UI) técnica y limpia. Se usarán formas geométricas, líneas finas y tipografías de estilo "monospace" (como "IBM Plex" o "Fira Code").
- **Audio:** Una banda sonora de música electrónica con ritmos rápidos. Los efectos de sonido serán principalmente digitales: teclas de computadora, pitidos, estática, etc.
