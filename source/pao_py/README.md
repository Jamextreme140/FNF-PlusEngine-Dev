# English
# 🐍 Python Scripting System (Hython)

A Python scripting system for FNF Plus Engine using the **Hython** library.

## Features

- ✅ Native Python syntax (def, if, for, list comprehensions, etc.)
- ✅ Game callbacks (onCreate, onUpdate, onBeatHit, etc.)
- ✅ Built-in functions (getProperty, setProperty, debugPrint, etc.)
- ✅ Cross-platform (works on desktop and mobile with optimizations for Android)
- ✅ No native dependencies (only Haxe)

## Basic Usage

### Create a Python Script

Place `.py` files in any mod script folder:

```
mods/
  └── your-mod/
      ├── scripts/          # Global scripts
      ├── stages/           # Stage scripts
      ├── custom_events/    # Event scripts
      └── custom_notetypes/ # Notetype scripts
```

### Simple Example

```python
def onCreate():
    debugPrint('Python script loaded!', 'GREEN')

def onBeatHit():
    beat = getProperty('curBeat')
    if beat % 4 == 0:
        cameraShake('game', 0.01, 0.2)
```

## Available Functions

### Basic Utilities
- `debugPrint(text, color)` - Prints to debug
- `getVar(name)` / `setVar(name, value)` - Global variables
- `getProperty(variable)` / `setProperty(variable, value)` - Game properties

### Camera
- `cameraShake(camera, intensity, duration)`
- `cameraFlash(camera, color, duration, forced)`
- `cameraFade(camera, color, duration, fadeOut)`
- `getCameraZoom(camera)` / `setCameraZoom(camera, zoom)`

### Characters
- `characterPlayAnim(character, anim, forced)`
- `characterDance(character)`
- `setCharacterX(character, x)` / `setCharacterY(character, y)`

### Health & Score
- `getHealth()` / `setHealth(health)` / `addHealth(health)`
- `getScore()` / `setScore(score)` / `addScore(score)`

### Sound
- `playSound(sound, volume, tag)`
- `playMusic(sound, volume, loop)`

### Utilities
- `getRandomInt(min, max)` - Random integer
- `getRandomFloat(min, max)` - Random decimal number
- `getRandomBool(chance)` - Random boolean

## Game Callbacks

```python
def onCreate():
    # Called when the script loads
    pass

def onCreatePost():
    # Called after creating all objects
    pass

def onUpdate(elapsed):
    # Called each frame (elapsed = time passed)
    pass

def onUpdatePost(elapsed):
    # Called after updating everything
    pass

def onBeatHit():
    # Called on each beat
    pass

def onStepHit():
    # Called on each step
    pass

def goodNoteHit(id, direction, noteType, isSustainNote):
    # Called when the player hits a note
    pass

def noteMiss(id, direction, noteType, isSustainNote):
    # Called when the player misses a note
    pass

def onDestroy():
    # Called when the script is destroyed
    pass
```

## Python Features

### List Comprehensions
```python
# Create list of even numbers
evens = [x for x in range(10) if x % 2 == 0]
```

### F-Strings
```python
score = getScore()
debugPrint(f'Current score: {score}', 'CYAN')
```

### Helper Functions
```python
def calculatePercentage(value, total):
    return (value / total) * 100

def isEvenBeat():
    return getProperty('curBeat') % 2 == 0
```

## Android Optimizations

- Reduced recursion limit (50 vs 100 on desktop)
- Heavy functions disabled at low FPS

## Implementation Status

### ✅ Implemented
- Base Python scripting system
- Main game callbacks
- Basic camera, health, score functions
- Get/set properties

### 🚧 Planned for Future
- Custom sprites (makeLuaSprite, addLuaSprite)
- Tweens (doTweenX, doTweenY, etc.)
- Timers (runTimer, cancelTimer)
- Tagged sounds (pauseSound, resumeSound, etc.)

## Notes

- `.py` scripts are loaded automatically alongside `.lua` and `.hx`
- You can use Python, Lua, and HScript simultaneously
- Python errors are logged to the console

## Examples

See `example_mods/scripts/example.py` for a complete example.
# Español
# 🐍 Python Scripting System (Hython)

Sistema de scripting en Python para FNF Plus Engine usando la librería **Hython**.

## Características

- ✅ Sintaxis Python nativa (def, if, for, list comprehensions, etc.)
- ✅ Callbacks del juego (onCreate, onUpdate, onBeatHit, etc.)
- ✅ Funciones integradas (getProperty, setProperty, debugPrint, etc.)
- ✅ Multiplataforma (funciona en desktop y mobile con optimizaciones para Android)
- ✅ Sin dependencias nativas (solo Haxe)

## Uso Básico

### Crear un script Python

Coloca archivos `.py` en cualquier carpeta de scripts del mod:

```
mods/
  └── tu-mod/
      ├── scripts/          # Scripts globales
      ├── stages/           # Scripts de stages
      ├── custom_events/    # Scripts de eventos
      └── custom_notetypes/ # Scripts de tipos de notas
```

### Ejemplo Simple

```python
def onCreate():
    debugPrint('¡Script Python cargado!', 'GREEN')

def onBeatHit():
    beat = getProperty('curBeat')
    if beat % 4 == 0:
        cameraShake('game', 0.01, 0.2)
```

## Funciones Disponibles

### Utilidades Básicas
- `debugPrint(text, color)` - Imprime en el debug
- `getVar(name)` / `setVar(name, value)` - Variables globales
- `getProperty(variable)` / `setProperty(variable, value)` - Propiedades del juego

### Cámara
- `cameraShake(camera, intensity, duration)`
- `cameraFlash(camera, color, duration, forced)`
- `cameraFade(camera, color, duration, fadeOut)`
- `getCameraZoom(camera)` / `setCameraZoom(camera, zoom)`

### Personajes
- `characterPlayAnim(character, anim, forced)`
- `characterDance(character)`
- `setCharacterX(character, x)` / `setCharacterY(character, y)`

### Salud y Puntuación
- `getHealth()` / `setHealth(health)` / `addHealth(health)`
- `getScore()` / `setScore(score)` / `addScore(score)`

### Sonido
- `playSound(sound, volume, tag)`
- `playMusic(sound, volume, loop)`

### Utilidades
- `getRandomInt(min, max)` - Número aleatorio entero
- `getRandomFloat(min, max)` - Número aleatorio decimal
- `getRandomBool(chance)` - Booleano aleatorio

## Callbacks del Juego

```python
def onCreate():
    # Llamado al cargar el script
    pass

def onCreatePost():
    # Llamado después de crear todos los objetos
    pass

def onUpdate(elapsed):
    # Llamado cada frame (elapsed = tiempo transcurrido)
    pass

def onUpdatePost(elapsed):
    # Llamado después de actualizar todo
    pass

def onBeatHit():
    # Llamado en cada beat
    pass

def onStepHit():
    # Llamado en cada step
    pass

def goodNoteHit(id, direction, noteType, isSustainNote):
    # Llamado cuando el jugador golpea una nota
    pass

def noteMiss(id, direction, noteType, isSustainNote):
    # Llamado cuando el jugador falla una nota
    pass

def onDestroy():
    # Llamado cuando se destruye el script
    pass
```

## Características de Python

### List Comprehensions
```python
# Crear lista de números pares
evens = [x for x in range(10) if x % 2 == 0]
```

### F-Strings
```python
score = getScore()
debugPrint(f'Puntuación actual: {score}', 'CYAN')
```

### Funciones Helper
```python
def calcularPorcentaje(valor, total):
    return (valor / total) * 100

def esBeatPar():
    return getProperty('curBeat') % 2 == 0
```

## Optimizaciones para Android

- Límite de recursión reducido (50 vs 100 en desktop)
- Funciones pesadas deshabilitadas en FPS bajo

## Estado de Implementación

### ✅ Implementado
- Sistema base de Python scripting
- Callbacks principales del juego
- Funciones básicas de cámara, salud, score
- Propiedades get/set

### 🚧 Reservado para Futuro
- Sprites custom (makeLuaSprite, addLuaSprite)
- Tweens (doTweenX, doTweenY, etc.)
- Timers (runTimer, cancelTimer)
- Sonidos con tags (pauseSound, resumeSound, etc.)

## Notas

- Los scripts `.py` se cargan automáticamente junto a `.lua` y `.hx`
- Puedes usar Python, Lua y HScript simultáneamente
- Los errores de Python se registran en la consola

## Ejemplos

Ver `example_mods/scripts/example.py` para un ejemplo completo.
