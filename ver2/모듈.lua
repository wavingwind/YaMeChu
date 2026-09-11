-- 🍱 [야메추 모듈] 경량 이벤트 감지 스크립트
print("🍱 [야메추 모듈] Lua 트리거 실행됨")

local userMsg = getUserMessage() or ""
local aiMsg = getAiMessage() or ""

-- 감지 대상 메뉴 목록 (필요시 추가)
local menuList = {"짜장면", "김치찌개", "후라이드치킨"}

for _, name in ipairs(menuList) do
    -- [1. 추천 거절 감지] AI가 언급한 메뉴에 대해 유저가 거절 반응을 보일 때
    if string.find(aiMsg, name, 1, true) and 
       (string.find(userMsg, "싫") or string.find(userMsg, "별로") or string.find(userMsg, "다른") or string.find(userMsg, "안먹")) then
        print("🍱 [EVENT:REFUSE] " .. name)
    end

    -- [2. 섭취/선택 감지] 유저가 특정 메뉴를 먹었거나 선택했다고 말할 때
    if string.find(userMsg, name, 1, true) and 
       (string.find(userMsg, "먹했") or string.find(userMsg, "먹었") or string.find(userMsg, "결정") or string.find(userMsg, "고를게") or string.find(userMsg, "선택") or string.find(userMsg, "먹을")) then
        print("🍱 [EVENT:EAT] " .. name)
    end
end
