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
