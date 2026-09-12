-- 2. onInput 훅 (유저 입력 시점 자동 실행)
function onInput(triggerId)
    log("🍱 [야메추 모듈] onInput 트리거 실행")

    local userMsg = ""
    local aiMsg = ""
    
    if getFullChat then
        local chat = getFullChat(triggerId)
        log("🔍 [디버그] 전체 대화 길이(#chat): " .. tostring(#chat))

        if type(chat) == "table" and #chat > 0 then
            -- [1] 인덱스별 객체 텍스트 추출 시도 (.data / .message / .text / .content 순차 탐색)
            local function extractText(item)
                if type(item) ~= "table" then return "" end
                return item.data or item.message or item.text or item.content or ""
            end

            -- 후보군 인덱스 로그 출력
            local lastIdx = #chat
            local prevIdx = #chat - 1

            log("🔍 [#chat] 텍스트: [" .. extractText(chat[lastIdx]) .. "]")
            if prevIdx >= 1 then
                log("🔍 [#chat-1] 텍스트: [" .. extractText(chat[prevIdx]) .. "]")
            end

            -- [2] 대화 타임라인 기반 할당
            userMsg = extractText(chat[lastIdx])
            aiMsg = (prevIdx >= 1) and extractText(chat[prevIdx]) or ""
        end
    end

    log("🔍 [최종 매핑] userMsg: [" .. userMsg .. "]")
    log("🔍 [최종 매핑] aiMsg: [" .. aiMsg .. "]")

    -- ... 이하 기존 menu_db 및 스코어링 로직 동일 ...
