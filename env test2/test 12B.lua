-- 🍱 [야메추 모듈] listenEdit 제거 및 onInput 통합 탐색 최종 코드

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

function onInput(triggerId)
    print("🍱 [야메추] onInput 실행 (ID: " .. tostring(triggerId) .. ")")

    -- 1. 대화 내역 가져오기 및 최근 3개 메시지 맥락 통합
    local recentContext = ""
    if getFullChat then
        local chat = getFullChat(triggerId)
        if type(chat) == "table" and #chat > 0 then
            local function extractText(item)
                if type(item) ~= "table" then return tostring(item or "") end
                return item.data or item.message or item.text or item.content or ""
            end
            
            -- 최근 3개 메시지 합치기
            local startIdx = math.max(1, #chat - 2)
            local contextParts = {}
            for i = startIdx, #chat do
                table.insert(contextParts, extractText(chat[i]))
            end
            recentContext = table.concat(contextParts, "\n")
            print("🔍 [최근 대화 맥락 수신 완료] 길이: " .. tostring(#recentContext))
        end
    end

    -- 2. DB 복원 (getState)
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

    -- 3. 통합 맥락 감지 로직
    for name, item in pairs(db) do
        if type(item) == "table" then
            if string.find(recentContext, name, 1, true) then
                -- 거절 키워드 탐색
                if string.find(recentContext, "싫") or string.find(recentContext, "별로") or 
                   string.find(recentContext, "다른") or string.find(recentContext, "안먹") then
                    item["refused_count"] = (item["refused_count"] or 0) + 1
                    print("🍱 [거절 감지 성공] " .. name .. " (누적: " .. tostring(item["refused_count"]) .. "회)")
                end
                
                -- 섭취 키워드 탐색
                if string.find(recentContext, "먹했") or string.find(recentContext, "먹었") or 
                   string.find(recentContext, "결정") or string.find(recentContext, "고를게") or 
                   string.find(recentContext, "선택") or string.find(recentContext, "먹을") then
                    item["eaten_days_ago"] = 0
                    item["refused_count"] = 0
                    print("🍱 [섭취 감지 성공] " .. name)
                end
            end
        end
    end

    -- 4. 점수 계산 및 Top 4 정렬
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

    -- 5. 상태 및 프롬프트 변수 업데이트
    setState(triggerId, "menu_db", db)
    
    local jsonStr = json.encode(top4)
    setChatVar(triggerId, "top_menu_json", jsonStr)
    
    print("🍱 [야메추 완료] {{getvar::top_menu_json}} = " .. jsonStr)
end
