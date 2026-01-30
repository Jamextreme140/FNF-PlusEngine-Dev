-- Cutscene de introdução: só toca na primeira vez que entrar na música
local allowCountdown = false

function onCreate()
    -- Se ainda não vimos a cutscene, bloqueia o countdown
    if not seenCutscene then
        allowCountdown = false
    else
        allowCountdown = true
    end
end

function onStartCountdown()
    if not allowCountdown then
        startVideo('sserafim-cutscene') -- nome do vídeo (sem .webm)
        seenCutscene = true -- marca como exibido, para não repetir em retries
        allowCountdown = true
        return Function_Stop
    end
    return Function_Continue
end

function onVideoFinished()
    startCountdown() -- começa a música após o vídeo
end
