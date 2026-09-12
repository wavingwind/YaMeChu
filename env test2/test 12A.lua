-- 🍱 [야메추 모듈] listenEdit("editInput") 스펙 적용 테스트 코드

local function calculateMenuScore(item)
    if type(item) ~= "table" or item["disliked"] then return 0 end
    
    local currentScore = 80
    local eatenDays = type(item["eaten_days_ago"]) == "number" and item["eaten_days_ago"] or nil
    local refusedCount = type(item["refused_count"]) == "number" and item["refused_count"] or 0

    if item["is_favorite"] and refusedCount == 0 then
        local favDays = (eatenDays ~= nil) and math.max(0, eatenDays - 7) or 10
        currentScore = math.min(100, 80 + (favDays * 2))
    end
    
    if eatenDays ~= nil then
        if eatenDays == 0 then
            currentScore = currentScore - 70
        elseif eatenDays < 8 then
            currentScore = math.min(90, (currentScore - 70) + (eatenDays * 10))
        end
    end
    
    if refusedCount > 0 then
        currentScore = math.min(80, currentScore - (refusedCount * 30))
    end
    
    return math.max(0, math.min(100, math.floor(currentScore + 0.5)))
end

-- 1. onInput 시점: 직전 AI 응답 백업 및 추천 점수 계산
function onInput(triggerId)
    log("🍱 [onInput] 실행 완료 (triggerId: " .. tostring(triggerId) .. ")")

    -- 직전 AI 메시지 추출 (chat[#chat] 사용)
    local aiMsg = ""
    if getFullChat then
        local chat = getFullChat(triggerId)
        if type(chat) == "table" and #chat > 0 then
            local lastItem = chat[#chat]
            aiMsg = type(lastItem) == "table" and (lastItem.data or lastItem.message or lastItem.text or lastItem.content or "") or tostring(lastItem or "")
        end
    end
    
    -- editInput에서 참조 가능하도록 저장
    setState(triggerId, "last_ai_msg", aiMsg)
    log("🔍 [onInput] 백업된 직전 AI 메시지: [" .. aiMsg:sub(1, 40) .. "]")
end

-- 2. listenEdit("editInput"): 유저 실제 입력 수신 및 반응 감지
if listenEdit then
    listenEdit("editInput", function(triggerId, data)
        log("🍱 [editInput] 수신된 유저 입력: [" .. tostring(data) .. "]")

        local userMsg = tostring(data or "")
        local aiMsg = getState(triggerId, "last_ai_msg") or ""

        -- DB 복원
        local db = getState(triggerId, "menu_db")
        if not db or type(db) ~= "table" then
            db = {
                ["짜장면"] = { category = "중식", is_favorite = false, is_new = false, eaten_days_ago = nil, refused_count = 0, disliked = false },
                ["김치찌개"] = { category = "한식", is_favorite = true, is_new = false, eaten_days_ago = 8, refused_count = 0, disliked = false },
                ["후라이드치킨"] = { category = "치킨", is_favorite = true, is_new = false, eaten_days_ago = 3, refused_count = 0, disliked = false },
                ["닭강정"] = { category = "치킨", is_favorite = false, is_new = false, eaten_days_ago = nil, refused_count = 0, disliked = false },
                ["우동"] = { category = "일식", is_favorite = false, is_new = false, eaten_days_ago = nil, refused_count = 0, disliked = false }
            }
        end

        -- 반응 감지 로직
        for name, item in pairs(db) do
            if type(item) == "table" then
                -- 거절 감지 (AI가 언급했고 유저가 거절)
                if aiMsg ~= "" and string.find(aiMsg, name, 1, true) and 
                   (string.find(userMsg, "싫") or string.find(userMsg, "별로") or string.find(userMsg, "다른") or string.find(userMsg, "안먹")) then
                    item["refused_count"] = (item["refused_count"] or 0) + 1
                    log("🍱 [거절 감지 성공] " .. name .. " (누적 거절: " .. tostring(item["refused_count"]) .. "회)")
                end
                
                -- 섭취 감지
                if userMsg ~= "" and string.find(userMsg, name, 1, true) and 
                   (string.find(userMsg, "먹했") or string.find(userMsg, "먹었") or string.find(userMsg, "결정") or string.find(userMsg, "고를게") or string.find(userMsg, "선택") or string.find(userMsg, "먹을")) then
                    item["eaten_days_ago"] = 0
                    item["refused_count"] = 0
                    log("🍱 [섭취 감지 성공] " .. name)
                end
            end
        end

        -- 점수 계산 및 Top 4 정렬
        local calculatedList = {}
        for name, item in pairs(db) do
            local score = calculateMenuScore(item)
            if score > 0 then
                table.insert(calculatedList, { name = name, category = item["category"] or "기타", score = score })
            end
        end

        table.sort(calculatedList, function(a, b) return a.score > b.score end)

        local top4 = {}
        for i = 1, math.min(4, #calculatedList) do
            table.insert(top4, calculatedList[i])
        end

        -- 상태 및 채팅 변수 주입
        setState(triggerId, "menu_db", db)
        
        local jsonStr = json.encode(top4)
        setChatVar(triggerId, "top_menu_json", jsonStr)
        
        log("🍱 [editInput 갱신 완료] {{getvar::top_menu_json}} = " .. jsonStr)

        -- 원본 유저 입력값 보존 반환
        return data
    end)
end
