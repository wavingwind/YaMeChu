print("🍱 [야메추 모듈] Lua 트리거 스크립트 실행됨")

-- 1. JSON 인코더/디코더
local function json_encode(val)
    local t = type(val)
    if t == "table" then
        local is_array = (#val > 0)
        local parts = {}
        if is_array then
            for i, v in ipairs(val) do
                table.insert(parts, json_encode(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(parts, string.format('"%s":%s', tostring(k), json_encode(v)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    elseif t == "string" then
        return string.format('"%s"', val)
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    else
        return "null"
    end
end

-- 간단한 JSON 디코더 (PocketRisu 환경용)
local function json_decode(str)
    local ok, res = pcall(function() return load("return " .. str:gsub('null','nil'))() end)
    if ok then return res else return {} end
end

-- 2. 변수 및 대화 데이터 불러오기
local dbRaw = getVar("menu_db") or ""
local userMsg = getUserMessage() or ""
local aiMsg = getAiMessage() or ""

-- 기본 메뉴 DB 정의
local defaultDB = {
    ["짜장면"] = { category = "중식", is_favorite = false, is_new = false, score_offset = 0, eaten_days_ago = nil, refused_count = 0, refused_days_ago = 0, disliked = false },
    ["김치찌개"] = { category = "한식", is_favorite = true, is_new = false, score_offset = 0, eaten_days_ago = 8, refused_count = 0, refused_days_ago = 0, disliked = false },
    ["후라이드치킨"] = { category = "치킨", is_favorite = true, is_new = false, score_offset = 0, eaten_days_ago = nil, refused_count = 0, refused_days_ago = 0, disliked = false }
}

-- DB 초기화
local db = {}
if dbRaw == "" then
    print("⚠️ [야메추 모듈] menu_db 초기 세팅 진행")
    db = defaultDB
    setVar("menu_db", json_encode(db))
else
    db = json_decode(dbRaw)
end

local updated = false

-- 3. 대화 감지 및 DB 상태 업데이트
for name, item in pairs(db) do
    if type(item) == "table" then
        -- [추천 거절 감지]
        if string.find(aiMsg, name, 1, true) and (string.find(userMsg, "싫") or string.find(userMsg, "별로") or string.find(userMsg, "다른") or string.find(userMsg, "안먹")) then
            local currentRefused = type(item["refused_count"]) == "number" and item["refused_count"] or 0
            item["refused_count"] = currentRefused + 1
            item["refused_days_ago"] = 0
            updated = true
            print("🍱 [야메추 모듈] 거절 감지: " .. name .. " (누적: " .. tostring(item["refused_count"]) .. "회)")
        end
        
        -- [메뉴 섭취/선택 감지]
        if string.find(userMsg, name, 1, true) and (string.find(userMsg, "먹었") or string.find(userMsg, "결정") or string.find(userMsg, "고를게") or string.find(userMsg, "선택") or string.find(userMsg, "먹을")) then
            item["eaten_days_ago"] = 0
            item["refused_count"] = 0
            item["refused_days_ago"] = 0
            updated = true
            print("🍱 [야메추 모듈] 섭취/선택 감지: " .. name)
        end
    end
end

-- 변경 사항 저장
if updated then
    setVar("menu_db", json_encode(db))
    print("🍱 [야메추 모듈] DB 최신화 완료")
end

-- 4. 점수 계산 및 Top 4 추천 추출
local calculatedList = {}

for name, item in pairs(db) do
    if type(item) == "table" and not item["disliked"] then
        local currentScore = 80
        
        local eatenDays = type(item["eaten_days_ago"]) == "number" and item["eaten_days_ago"] or nil
        local refusedCount = type(item["refused_count"]) == "number" and item["refused_count"] or 0
        local refusedDays = type(item["refused_days_ago"]) == "number" and item["refused_days_ago"] or 0

        -- [즐겨찾기 보너스]
        if item["is_favorite"] and refusedCount == 0 then
            local favDays = 10
            if eatenDays ~= nil then
                favDays = math.max(0, eatenDays - 7)
            end
            currentScore = math.min(100, 80 + (favDays * 2))
        end
        
        -- [최근 섭취 감점]
        if eatenDays ~= nil then
            if eatenDays == 0 then
                currentScore = currentScore - 70
            elseif eatenDays < 8 then
                currentScore = math.min(90, (currentScore - 70) + (eatenDays * 10))
            end
        end
        
        -- [거절 감점 및 회복]
        if refusedCount > 0 then
            local penalty = refusedCount * 30
            local recovery = refusedDays * 5
            currentScore = math.min(80, currentScore - penalty + recovery)
        end
        
        -- [신규 메뉴 보너스]
        if item["is_new"] then
            currentScore = currentScore + 5
        end
        
        currentScore = math.max(0, math.min(100, math.floor(currentScore + 0.5)))
        
        if currentScore > 0 then
            table.insert(calculatedList, { name = name, category = item["category"] or "기타", score = currentScore })
        end
    end
end

-- 점수 내림차순 정렬
table.sort(calculatedList, function(a, b) return a.score > b.score end)

-- 상위 4개 추출
local top4 = {}
for i = 1, math.min(4, #calculatedList) do
    table.insert(top4, calculatedList[i])
end

setVar("top_menu_json", json_encode(top4))
print("🍱 [야메추 모듈] 추천 목록 갱신 완료")
