function onCreate()
    -- GRÁFICO COR #94895F COM OPACIDADE 0.5
    makeLuaSprite('grafico', nil, -1500, -1500)
    makeGraphic('grafico', 1280, 720, '6B6345')
    setProperty('grafico.alpha', 0.8)
        scaleLuaSprite('grafico', 5, 5)
    addLuaSprite('grafico', true) -- false = fica atrás dos personagens
	setObjectOrder('grafico', getObjectOrder('bfGetUp') + 99)

    runTimer('dust1', 0.1)

    if not lowQuality then
        makeLuaSprite('dustBack', 'sserafim/dust/dustBack', -2000, -300)
        scaleLuaSprite('dustBack', 6.25, 1.875)
        addLuaSprite('dustBack', true)
        setProperty('dustBack.alpha', 1)

        makeLuaSprite('dustMid', 'sserafim/dust/dustMid', -2000, 300)
        scaleLuaSprite('dustMid', 6.25, 1.875)
        addLuaSprite('dustMid', true)
        setProperty('dustMid.alpha', 1)

        makeLuaSprite('dustFront', 'sserafim/dust/dustFront', -2000, -300)
        scaleLuaSprite('dustFront', 6.25, 1.875)
        addLuaSprite('dustFront', true)
        setProperty('dustFront.alpha', 1)
    end
end

function onTimerCompleted(timer)
    if timer == 'dust1' then
        setProperty('dustBack.velocity.x', 200)
        setProperty('dustFront.velocity.x', 200)
        setProperty('dustMid.velocity.x', -200)
        runTimer('dust2', 2)

    elseif timer == 'dust2' then
        setProperty('dustBack.velocity.x', -200)
        setProperty('dustFront.velocity.x', -200)
        setProperty('dustMid.velocity.x', 200)
        runTimer('dust1', 2)
    end
end

function onStepHit()
    if curStep == 1 then
    doTweenAlpha('fadeDust1', 'dustBack', 0, 15, 'linear') -- 1 segundo de duração
    doTweenAlpha('fadeDust2', 'dustMid', 0, 15, 'linear') -- 1 segundo de duração
    doTweenAlpha('fadeDust3', 'dustFront', 0, 15, 'linear') -- 1 segundo de duração
    doTweenAlpha('fadeDust4', 'grafico', 0, 15, 'linear') -- 1 segundo de duração
    end
    if curStep == 27 then
        setProperty('door.alpha', 1)
end
    if curStep == 38 then
        setProperty('dad.alpha', 1)
        setProperty('kick.alpha', 0)
    end
end
