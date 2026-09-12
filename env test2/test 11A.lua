function onInput(triggerId)
    log("🍱 [디버그] onInput 훅 진입 성공 (triggerId: " .. tostring(triggerId) .. ")")

    if not getFullChat then
        log("❌ getFullChat 함수가 존재하지 않음")
        return
    end

    local chat = getFullChat(triggerId)
    log("🔍 chat 타입: " .. type(chat) .. " / 길이(#chat): " .. tostring(chat and #chat or 0))

    if type(chat) == "table" and #chat > 0 then
        -- 구조별 필드 추출 헬퍼 (data, message, text, content 순 차례대로 탐색)
        local function extractText(item)
            if type(item) ~= "table" then return tostring(item or "") end
            return item.data or item.message or item.text or item.content or ""
        end

        local userMsg = extractText(chat[#chat])
        local aiMsg = (#chat >= 2) and extractText(chat[#chat - 1]) or ""

        log("🔍 [추출 결과] userMsg: [" .. userMsg .. "]")
        log("🔍 [추출 결과] aiMsg: [" .. aiMsg .. "]")
    end
end
