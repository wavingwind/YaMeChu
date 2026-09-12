print("🔍 [API 탐색] 시작")

-- RisuAI의 다양한 변수 세팅 API 후보 호출
if setChatVar then setChatVar("ping", "100") end
if setVar then setVar("ping", "100") end
if setGlobalVar then setGlobalVar("ping", "100") end
if setModuleVar then setModuleVar("ping", "100") end

-- 바인딩된 전역 함수 목록 콘솔 출력
print("🔍 setChatVar 타입: " .. type(setChatVar))
print("🔍 setVar 타입: " .. type(setVar))
print("🔍 setGlobalVar 타입: " .. type(setGlobalVar))
print("🔍 setModuleVar 타입: " .. type(setModuleVar))
print("🔍 set_var 타입: " .. type(set_var))
