-- 🍱 [야메추 모듈] RisuAI 공식 API 스펙 적용 최종 코드

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

-- 2. onInput 훅 (유저 입력 시점 자동 실행)
function onInput(triggerId)
    log("🍱 [야메추 모듈] onInput 트리거 실행")

    -- 대화 및 기존 상태 가져오기
    local userMsg = getUserMessage and getUserMessage() or ""
    local aiMsg = getAiMessage and getAiMessage() or ""

    -- setState/getState로 객체 상태 복원 (없으면 기본값 세팅)
    local db = getState(triggerId, "menu_db")
    if not db or type(db) ~= "table" then
        db = {
            ["짜장면"] = { category = "중식", is_favorite = false, is_new = false, eaten_days_ago = nil, refused_count = 0, disliked = false },
            ["김치찌개"] = { category = "한식", is_favorite = true, is_new = false, eaten_days_ago = 8, refused_count = 0, disliked = false },
            ["후라이드치킨"] = { category = "치킨", is_favorite = true, is_new = false, eaten_days_ago = 3, refused_count = 0, disliked = false }
        }
    end

    -- 유저 반응 감지 및 DB 업데이트
    for name, item in pairs(db) do
        if type(item) == "table" then
            -- 거절 반응 감지
            if aiMsg ~= "" and string.find(aiMsg, name, 1, true) and 
               (string.find(userMsg, "싫") or string.find(userMsg, "별로") or string.find(userMsg, "다른") or string.find(userMsg, "안먹")) then
                item["refused_count"] = (item["refused_count"] or 0) + 1
                log("🍱 거절 감지: " .. name)
            end
            
            -- 섭취/선택 반응 감지
            if userMsg ~= "" and string.find(userMsg, name, 1, true) and 
               (string.find(userMsg, "먹했") or string.find(userMsg, "먹었") or string.find(userMsg, "결정") or string.find(userMsg, "고를게") or string.find(userMsg, "선택") or string.find(userMsg, "먹을")) then
                item["eaten_days_ago"] = 0
                item["refused_count"] = 0
                log("🍱 섭취 감지: " .. name)
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

    -- 객체 상태 저장 (getState로 턴 간 유지)
    setState(triggerId, "menu_db", db)

    -- 프롬프트 노출용 채팅 변수 저장 ({{getvar::top_menu_json}} 매크로 치환용)
    local jsonStr = json.encode(top4)
    setChatVar(triggerId, "top_menu_json", jsonStr)

    log("🍱 야메추 갱신 완료: " .. jsonStr)
end
