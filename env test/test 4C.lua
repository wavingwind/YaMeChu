print("🧪 [Step 3] 원본 핵심 로직 복원 테스트 시작")

local function recommendMenus(db, userMsg, aiMsg)
    print("🧪 [Step 3] recommendMenus 진입")
    local top4 = {}
    
    for name, item in pairs(db or {}) do
        -- string.find 연산 시 userMsg/aiMsg가 nil이면 여기서 바로 ErrorRun/2 발생!
        if userMsg and string.find(userMsg, name, 1, true) then
            print("🧪 [Step 3] 매칭 성공: " .. name)
        end
    end
    
    return top4
end

local dummyDb = { ["짜장면"] = { category = "중식" } }

-- getUserMessage()가 nil을 반환할 때의 안전 대책 검증
local userMsg = (getUserMessage and getUserMessage()) -- nil일 가능성 높음
print("🧪 [Step 3] userMsg 타입: " .. type(userMsg))

recommendMenus(dummyDb, userMsg, "AI 답변 예시")
print("🧪 [Step 3] recommendMenus 실행 성공")

return { recommendMenus = recommendMenus }
