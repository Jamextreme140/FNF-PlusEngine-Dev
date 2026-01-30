function onCreate()
    -- Criação das sprites já existente
    makeAnimatedLuaSprite('kick', 'kick', -945, -140)
    addAnimationByPrefix('kick', 'kick', 'kick', 12, false);  
    addAnimationByPrefix('kick', 'door', 'door', 12, false);  
    setProperty('kick.alpha', 1) 
    setProperty('kick.scale.x', 1.375) 
    setProperty('kick.scale.y', 1.375)
    addLuaSprite('kick')

    makeAnimatedLuaSprite('bfGetUp', 'bfGetUp', -10, 0)
    addAnimationByPrefix('bfGetUp', 'getup', 'getup', 12, false);  
    addAnimationByPrefix('bfGetUp', 'static', 'static', 12, false);  
    setProperty('bfGetUp.alpha', 1) 
    setProperty('bfGetUp.scale.x', 1)
    setProperty('bfGetUp.scale.y', 1)
    addLuaSprite('bfGetUp')
    setProperty('bfGetUp.x', getProperty('boyfriend.x'))
    setProperty('bfGetUp.y', getProperty('boyfriend.y') + 100)

    makeAnimatedLuaSprite('gfGetUp', 'gfGetUp', -10, 0)
    addAnimationByPrefix('gfGetUp', 'getup', 'getup', 12, false);  
    addAnimationByPrefix('gfGetUp', 'static', 'static', 12, false);  
    setProperty('gfGetUp.alpha', 1)
    setProperty('gfGetUp.scale.x', 0.875)
    setProperty('gfGetUp.scale.y', 0.875)
    addLuaSprite('gfGetUp')
    setProperty('gfGetUp.x', getProperty('gf.x'))
    setProperty('gfGetUp.y', getProperty('gf.y'))

    setProperty('boyfriend.alpha', 0)
    setProperty('gf.alpha', 0)
    setProperty('dad.alpha', 0)
    setProperty('door.alpha', 0)
end

-- Esse evento será chamado quando o countdown começar
function onStartCountdown()
    playAnim('bfGetUp', 'getup', true)
    playAnim('gfGetUp', 'getup', true)
    playAnim('kick', 'door', true)
    return Function_Continue
end

function onStepHit()
    if curStep == 18 then
        playAnim('kick', 'kick', true)
        setProperty('boyfriend.alpha', 1)
        setProperty('gf.alpha', 1)
        setProperty('bfGetUp.alpha', 0)
        setProperty('gfGetUp.alpha', 0)
    end
    if curStep == 27 then
        setProperty('door.alpha', 1)
    end
    if curStep == 38 then
        setProperty('dad.alpha', 1)
        setProperty('kick.alpha', 0)
    end
end
