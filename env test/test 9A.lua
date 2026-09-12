-- 최상단 즉시 실행 로그 (모듈이 로드만 되어도 무조건 콘솔에 찍힘)
print("🚀 [야메추] 모듈 스크립트 파일 로드 완료")
if log then log("🚀 [야메추] log() 함수 탐색 성공") end

-- 1. onInput 훅 정의
function onInput(triggerId)
    local printLog = log or print
    printLog("🍱 [야메추] onInput 훅 호출 성공! (triggerId: " .. tostring(triggerId) .. ")")
end

-- 2. 최상단 직접 호출 테스트 (훅 미작동 대비)
if onInput then
    onInput("test_trigger_id")
end
