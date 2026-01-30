function onCreate()
    makeLuaSprite('blackout','',0,0)
    makeGraphic('blackout',1920,1080,'#000000')
    setObjectCamera('blackout', 'camHUD')
    setObjectOrder('blackout', '0')
	setObjectOrder('blackout', getObjectOrder('RedFlash') - 1)
    setProperty('blackout.alpha', 0) -- começa invisível
    addLuaSprite('blackout')

    makeLuaSprite('collab','collab', -305, -190)
    setObjectCamera('collab', 'camOTHER')
    setProperty('collab.alpha', 0) -- começa invisível
    setProperty('collab.scale.x', 0.7) -- tamanho ajustado
    setProperty('collab.scale.y', 0.7)
    addLuaSprite('collab', true)

    makeLuaSprite('week8','week8', -350, -190)
    setObjectCamera('week8', 'camOTHER')
    setProperty('week8.alpha', 0) -- começa invisível
    setProperty('week8.scale.x', 0.7) -- tamanho ajustado
    setProperty('week8.scale.y', 0.7)
    addLuaSprite('week8', true)
end

function onStepHit()
    if curStep == 463 then
    setProperty('blackout.visible', true)
        setProperty('blackout.alpha', 1)
    end

    if curStep == 465 then
        setProperty('blackout.alpha', 0) -- garante que esteja invisível
    end

    if curStep == 476 then
        setProperty('blackout.alpha', 1)
    end
    if curStep == 479 then
        setProperty('blackout.alpha', 0) -- garante que esteja invisível
    end
    if curStep == 1244 then
    setProperty('collab.alpha', 1) -- começa invisível
    end
    if curStep == 1273 then
    setProperty('week8.alpha', 1) -- começa invisível
    end
end
