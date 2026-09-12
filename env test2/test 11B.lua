-- 🍱 [야메추 모듈] 완성본 (print 전용 안전 스크립트)

-- 1. 점수 계산 헬퍼 함수
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

-- 2. onInput 훅 (유저 메시지 제출 시 실행)
function onInput(triggerId)
    print("🍱 [야메추] onInput 훅 실행 시작 (ID: " .. tostring(triggerId) .. ")")

    -- 대화 내역 추출
    local userMsg = ""
    local aiMsg = ""
    
    if getFullChat then
        local chat = getFullChat(triggerId)
        if type(chat) == "table" and #chat > 0 then
            local function extractText(item)
                if type(item) ~= "table" then return tostring(item or "") end
                return item.data or item.message or item.text or item.content or ""
            end
            
            userMsg = extractText(chat[#chat])
            aiMsg = (#chat >= 2) and extractText(chat[#chat - 1]) or ""
            
            print("🔍 [대화 로그] 유저: [" .. userMsg .. "]")
            print("🔍 [대화 로그] AI: [" .. aiMsg .. "]")
        end
    end

    -- DB 상태 복원 (getState)
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

    -- 유저 반응 감지
    for name, item in pairs(db) do
        if type(item) == "table" then
            -- 거절 감지
            if aiMsg ~= "" and string.find(aiMsg, name, 1, true) and 
               (string.find(userMsg, "싫") or string.find(userMsg, "별로") or string.find(userMsg, "다른") or string.find(userMsg, "안먹")) then
                item["refused_count"] = (item["refused_count"] or 0) + 1
                print("🍱 [거절 감지] " .. name .. " (누적: " .. tostring(item["refused_count"]) .. "회)")
            end
            
            -- 섭취 감지
            if userMsg ~= "" and string.find(userMsg, name, 1, true) and 
               (string.find(userMsg, "먹했") or string.find(userMsg, "먹었") or string.find(userMsg, "결정") or string.find(userMsg, "고를게") or string.find(userMsg, "선택") or string.find(userMsg, "먹을")) then
                item["eaten_days_ago"] = 0
                item["refused_count"] = 0
                print("🍱 [섭취 감지] " .. name)
            end
        end
    end

    -- 점수 계산 및 상위 4개 추출
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

    -- 상태 저장 및 프롬프트 변수 주입
    setState(triggerId, "menu_db", db)
    
    local jsonStr = json.encode(top4)
    setChatVar(triggerId, "top_menu_json", jsonStr)
    
    print("🍱 [야메추 완료] top_menu_json: " .. jsonStr)
end
