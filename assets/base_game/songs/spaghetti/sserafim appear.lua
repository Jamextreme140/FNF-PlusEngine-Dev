function onCreate()
    setProperty('chaewon.alpha', 0) 
    setProperty('eunchae.alpha', 0) 
    setProperty('kazuha.alpha', 0) 
end
function onStepHit()
    if curStep == 101 then
    setProperty('kazuha.alpha', 1) 
    end
    if curStep == 167 then
    setProperty('chaewon.alpha', 1) 
    end
    if curStep == 227 then
    setProperty('eunchae.alpha', 1) 
    end
end
