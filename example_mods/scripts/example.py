# Example Python Script for FNF Plus Engine
# This script demonstrates basic Python scripting capabilities
# Note: Some advanced features are reserved for future implementation

def onCreate():
    """Called when the script is first loaded"""
    debugPrint('Python script loaded!', 'GREEN')
    
    # Get some game properties
    songName = getProperty('songName')
    debugPrint(f'Current song: {songName}', 'CYAN')

def onCreatePost():
    """Called after all game objects are created"""
    debugPrint('onCreate finished, now in onCreatePost', 'YELLOW')

def onUpdate(elapsed):
    """Called every frame"""
    # Example: Check health
    health = getHealth()
    
    if health < 0.4:
        # Low health - shake camera
        cameraShake('game', 0.005, 0.1)

def onBeatHit():
    """Called every beat"""
    curBeat = getProperty('curBeat')
    
    # Every 4 beats, flash camera
    if curBeat % 4 == 0:
        cameraFlash('hud', 'WHITE', 0.3)
        debugPrint(f'Beat {curBeat} hit!', 'CYAN')

def onStepHit():
    """Called every step"""
    curStep = getProperty('curStep')
    
    # Example: Change something every 16 steps
    if curStep % 16 == 0:
        pass  # Do something here

def goodNoteHit(id, direction, noteType, isSustainNote):
    """Called when player hits a note"""
    # Add score with Python's powerful operators
    bonusScore = 350 if not isSustainNote else 50
    addScore(bonusScore)
    
    # Play a sound on perfect hits
    if not isSustainNote:
        playSound('scrollMenu', 0.3)

def noteMiss(id, direction, noteType, isSustainNote):
    """Called when player misses a note"""
    debugPrint('Note missed!', 'RED')
    
    # Camera shake on miss
    cameraShake('game', 0.01, 0.2)

def onDestroy():
    """Called when the script is destroyed"""
    debugPrint('Python script destroyed!', 'RED')
    # Clean up resources here

# Helper functions (Python supports this!)
def calculateAccuracy(hits, total):
    """Calculate accuracy percentage"""
    if total == 0:
        return 0
    return (hits / total) * 100

def isEvenBeat():
    """Check if current beat is even"""
    return getProperty('curBeat') % 2 == 0
