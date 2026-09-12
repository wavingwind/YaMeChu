print("🧪 [Step 2] nil/예외 state 주입 테스트 시작")

local function calculateScore(item, state)
    state = state or {}
    -- 만약 state.daysSince가 함수 형태인데 nil이 들어오거나 
    -- 숫자 연산 중 nil + number가 일어나는지 확인
    local lastEaten = state.lastEaten
    print("🧪 [Step 2] lastEaten 값 타입: " .. type(lastEaten))
    
    -- 의도적 예외 상황 테스트 (nil과의 산술 연산 시도)
    -- local failTest = lastEaten + 10 -- 여기서 에러 발생 가능
    return 80
end

print("🧪 [Step 2] 빈 state로 호출")
calculateScore({ name = "김치찌개" }, nil)
print("🧪 [Step 2] 빈 state 호출 성공")

return { calculateScore = calculateScore }
