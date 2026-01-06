# Codename Engine - Sistema de States

## Cómo Codename Engine parsea los States

### 1. Sistema de Scripts Automáticos por State

Codename Engine carga automáticamente scripts para cada state desde la carpeta `data/states/`. El sistema funciona así:

```haxe
// En MusicBeatState.hx
function loadScript() {
    var className = Type.getClassName(Type.getClass(this));
    var scriptName = this.scriptName != null ? this.scriptName : 
                     className.substr(className.lastIndexOf(".")+1);
    
    // Para cada mod cargado, busca data/states/[ScriptName]/LIB_[ModName]
    for (i in ModsFolder.getLoadedMods()) {
        var path = Paths.script('data/states/${scriptName}/LIB_$i');
        var script = Script.create(path);
        if (script is DummyScript) continue;
        stateScripts.add(script);
        script.load();
    }
}
```

**Ubicación de scripts:** `mods/yourmod/data/states/MainMenuState/LIB_yourmod.hx`

### 2. Callbacks del Ciclo de Vida

Los scripts reciben callbacks automáticos en estas funciones:

- **`onCreate()`** - Cuando el state se crea (antes de `create()`)
- **`create()`** - Durante la creación del state
- **`postCreate()`** - Después de que el state se crea completamente
- **`preUpdate(elapsed)`** - Antes de cada actualización
- **`update(elapsed)`** - Durante la actualización (cada frame)
- **`postUpdate(elapsed)`** - Después de la actualización
- **`stepHit(curStep)`** - En cada step musical (16th note)
- **`beatHit(curBeat)`** - En cada beat musical (quarter note)
- **`measureHit(curMeasure)`** - En cada measure (bar)
- **`destroy()`** - Cuando el state se destruye

### 3. ModState y ModSubState

Codename tiene clases especiales para states completamente controlados por scripts:

```haxe
// Para crear un state completamente desde un script
class ModState extends MusicBeatState {
    public static var lastName:String = null;
    public static var lastData:Dynamic = null;
    
    public function new(_stateName:String, ?_data:Dynamic) {
        super(true, lastName = _stateName);
        data = _data;
    }
}

// Uso:
FlxG.switchState(new ModState("MyCustomState"));
// Busca en data/states/MyCustomState.hx
```

### 4. Sistema de Transiciones con Scripts

Las transiciones también pueden tener scripts:

```haxe
public static var script:String = Flags.DEFAULT_TRANSITION_SCRIPT;

function startTransition(?newState:FlxState) {
    openSubState(new MusicBeatTransition(newState));
    // Carga el script de transición y lo ejecuta
}
```

**Script de transición:** `data/scripts/transition.hx`

### 5. Eventos y Sistema de Cancelación

Los scripts pueden cancelar eventos:

```haxe
public function event<T:CancellableEvent>(name:String, event:T):T {
    if(stateScripts != null)
        stateScripts.call(name, [event]);
    return event;
}

// En el script:
function onOpenSubState(event) {
    if (someCondition) {
        event.cancelled = true; // Cancela la apertura del substate
    }
}
```

### 6. ScriptPack - Sistema de Múltiples Scripts

Codename usa un sistema de "pack" que agrupa múltiples scripts:

```haxe
class ScriptPack {
    public var scripts:Array<Script> = [];
    
    public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
        var returnValue:Dynamic = null;
        for (script in scripts) {
            if (script == null) continue;
            returnValue = script.call(funcName, args);
        }
        return returnValue;
    }
}
```

### 7. Sistema de Parseo XML

Codename parsea XMLs para configurar states, especialmente para:

- **TitleState:** `data/titlescreen/titlescreen.xml`
- **StoryMenuState:** `data/weeks/weeks/[weekname].xml`
- **Characters:** `data/characters/[character].xml`
- **Stages:** `data/stages/[stage].xml`

Ejemplo de parseo XML:

```haxe
function loadXML() {
    try {
        xml = new Access(Xml.parse(Assets.getText(Paths.xml('titlescreen/titlescreen'))).firstElement());
        
        for(sprNode in xml.nodes.sprites.elements) {
            var spr = XMLUtil.createSpriteFromXML(sprNode);
            add(spr);
        }
    } catch(e) {
        trace('Error loading XML: $e');
    }
}
```

---

## Adaptación a FNF-PlusEngine

### Paso 1: Modificar MusicBeatState.hx

Agregar estas variables y métodos a tu `MusicBeatState`:

```haxe
// Variables para el sistema de scripts
public var stateScripts:Array<Dynamic> = [];
public var scriptsAllowed:Bool = true;
public var scriptName:String = null;

// Constructor con soporte para scripts
public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
    super();
    this.scriptsAllowed = scriptsAllowed;
    this.scriptName = scriptName;
}

// Carga scripts automáticamente desde data/states/
function loadScript():Void {
    if (!scriptsAllowed) return;
    
    var className:String = Type.getClassName(Type.getClass(this));
    var stName:String = scriptName != null ? scriptName : 
                        className.substr(className.lastIndexOf('.') + 1);
    
    #if LUA_ALLOWED
    var luaFile:String = 'data/states/' + stName + '.lua';
    if (Paths.fileExists(luaFile, TEXT)) {
        var luaScript = new FunkinLua(Paths.modFolders(luaFile));
        stateScripts.push(luaScript);
    }
    #end
    
    #if HSCRIPT_ALLOWED
    for (ext in ['.hx', '.hscript']) {
        var scriptFile:String = 'data/states/' + stName + ext;
        if (Paths.fileExists(scriptFile, TEXT)) {
            var hscript = Iris.fromFile(Paths.modFolders(scriptFile));
            hscript.set('this', this);
            hscript.set('add', add);
            hscript.set('remove', remove);
            stateScripts.push(hscript);
            break;
        }
    }
    #end
}

// Llama funciones en todos los scripts cargados
public function callOnScripts(funcName:String, ?args:Array<Dynamic>):Dynamic {
    var returnValue:Dynamic = null;
    
    for (script in stateScripts) {
        if (script == null) continue;
        
        #if LUA_ALLOWED
        if (Std.isOfType(script, FunkinLua)) {
            var lua:FunkinLua = cast script;
            returnValue = lua.call(funcName, args != null ? args : []);
        }
        #end
        
        #if HSCRIPT_ALLOWED
        if (Std.isOfType(script, Iris)) {
            var hscript:Iris = cast script;
            if (hscript.exists(funcName)) {
                returnValue = hscript.call(funcName, args != null ? args : []);
            }
        }
        #end
    }
    
    return returnValue;
}
```

### Paso 2: Modificar create() y otros métodos

```haxe
override function create() {
    // Cargar scripts antes de crear
    loadScript();
    callOnScripts('onCreate', []);
    
    // Tu código existente...
    var skip:Bool = FlxTransitionableState.skipNextTransOut;
    // ...resto del código...
    
    super.create();
    
    // Llamar después de create
    callOnScripts('create', []);
    callOnScripts('postCreate', []);
}

override function update(elapsed:Float) {
    callOnScripts('preUpdate', [elapsed]);
    
    // Tu código existente...
    super.update(elapsed);
    
    callOnScripts('update', [elapsed]);
    callOnScripts('postUpdate', [elapsed]);
}

override function stepHit():Void {
    // Tu código existente...
    super.stepHit();
    
    callOnScripts('stepHit', [curStep]);
}

override function beatHit():Void {
    // Tu código existente...
    super.beatHit();
    
    callOnScripts('beatHit', [curBeat]);
}

override function destroy() {
    callOnScripts('destroy', []);
    
    // Limpiar scripts
    for (script in stateScripts) {
        #if LUA_ALLOWED
        if (Std.isOfType(script, FunkinLua)) {
            var lua:FunkinLua = cast script;
            lua.stop();
        }
        #end
        
        #if HSCRIPT_ALLOWED
        if (Std.isOfType(script, Iris)) {
            var hscript:Iris = cast script;
            hscript.destroy();
        }
        #end
    }
    stateScripts = [];
    
    super.destroy();
}
```

### Paso 3: Crear un ModState (opcional)

Crea `source/backend/scripting/ModState.hx`:

```haxe
package backend.scripting;

import backend.MusicBeatState;

class ModState extends MusicBeatState {
    public static var lastName:String = null;
    public static var lastData:Dynamic = null;
    public var data:Dynamic = null;
    
    public function new(_stateName:String, ?_data:Dynamic) {
        if(_stateName != null && _stateName != lastName) {
            lastName = _stateName;
            lastData = null;
        }
        
        if(_data != null) lastData = _data;
        data = lastData;
        
        super(true, lastName);
    }
}
```

### Paso 4: Crear tu primer script de state

Crea `mods/yourmod/data/states/MainMenuState.hx`:

```haxe
function onCreate() {
    trace('MainMenu script loaded!');
}

function create() {
    // Agregar elementos personalizados al menú
    var customText = new FlxText(0, 0, 0, 'Custom Text!');
    customText.setFormat(Paths.font('vcr.ttf'), 32, 0xFFFFFF);
    customText.screenCenter();
    this.add(customText);
}

function update(elapsed:Float) {
    // Lógica personalizada
}

function beatHit(curBeat:Int) {
    // Efectos en cada beat
    trace('Beat: ' + curBeat);
}
```

---

## Ventajas del Sistema de Codename

1. **Modularidad:** Cada state puede tener su propio script
2. **Múltiples mods:** Soporta scripts de diferentes mods para el mismo state
3. **No invasivo:** Los scripts se cargan automáticamente sin modificar el código fuente
4. **Callbacks claros:** Sistema de eventos bien definido
5. **Cancelación de eventos:** Los scripts pueden prevenir acciones

## Diferencias con Psych Engine

| Característica | Psych Engine | Codename Engine |
|---|---|---|
| Scripts por state | No (solo PlayState) | Sí (todos los states) |
| Carga automática | Solo PlayState | Automática para todos |
| Múltiples scripts | Uno por categoría | Múltiples por mod |
| Sistema de eventos | Básico | Avanzado con cancelación |
| XML parsing | Limitado | Extensivo |

---

## Recursos Adicionales

- **Repositorio:** https://github.com/CodenameCrew/CodenameEngine
- **Documentación de scripts:** Ver `source/funkin/backend/scripting/`
- **Ejemplos:** Ver estados en `source/funkin/menus/`

