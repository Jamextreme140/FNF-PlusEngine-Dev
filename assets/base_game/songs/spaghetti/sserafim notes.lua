function onCreate()
    -- Deixar as setas fixas do HUD do oponente invisíveis
    for i = 0, getProperty('opponentStrums.length')-1 do
        setPropertyFromGroup('opponentStrums', i, 'alpha', 0)
    end

    -- Deixar as notas que caem invisíveis
    for i = 0, getProperty('notes.length')-1 do
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'alpha', 0)
        end
    end
end

function onUpdatePost()
    -- Deixar as notas do oponente invisíveis durante o gameplay
    for i = 0, getProperty('notes.length')-1 do
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'alpha', 0)
        end
    end

    -- Deixar as setas HUD estáticas invisíveis
    if getProperty('opponentStrums.length') > 0 then
        for i = 0, getProperty('opponentStrums.length')-1 do
            setPropertyFromGroup('opponentStrums', i, 'alpha', 0)
        end
    end
end
