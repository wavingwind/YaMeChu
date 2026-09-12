print("🧪 [종합 검증] 테스트 스크립트 시작")

---------------------------------------------------------
-- 검증 2: JSON 라이브러리(dkjson / cjson / json) 내장 여부 확인
---------------------------------------------------------
local json_lib = nil
if pcall(function() json_lib = require("json") end) then
    print("✅ 내장 json 라이브러리 존재함")
elseif pcall(function() json_lib = require("cjson") end) then
    print("✅ 내장 cjson 라이브러리 존재함")
elseif json and type(json.encode) == "function" then
    json_lib = json
    print("✅ 전역 json 객체 존재함")
else
    print("ℹ️ 내장 JSON 라이브러리 없음 (순수 Lua 함수 사용 필요)")
end

---------------------------------------------------------
-- 검증 2-2: setChatVar/getChatVar의 JSON 긴 문자열 보존 테스트
---------------------------------------------------------
local dummy_db = {
    ["짜장면"] = { category = "중식", score = 80, eaten_days_ago = 0, refused_count = 2 },
    ["김치찌개"] = { category = "한식", score = 95, eaten_days_ago = 8, refused_count = 0 },
    ["후라이드치킨"] = { category = "치킨", score = 90, eaten_days_ago = 3, refused_count = 0 }
}

-- 간단한 직렬화 테스트 (내장 라이브러리가 없으면 테스트용 구문 작성)
local json_str = ""
if json_lib and json_lib.encode then
    json_str = json_lib.encode(dummy_db)
else
    -- 수동 직렬화 테스트용 복합 JSON 문자열
    json_str = '{"짜장면":{"category":"중식","eaten_days_ago":0,"refused_count":2,"score":80},"김치찌개":{"category":"한식","eaten_days_ago":8,"refused_count":0,"score":95},"후라이드치킨":{"category":"치킨","eaten_days_ago":3,"refused_count":0,"score":90}}'
end

-- 변수 저장
setChatVar("test_menu_db", json_str)
print("💾 [JSON 저장 성공] 입력 길이: " .. tostring(#json_str))

-- 변수 복원 및 무결성 확인
local restored_str = getChatVar("test_menu_db") or ""
print("📖 [JSON 복원 성공] 출력 길이: " .. tostring(#restored_str))

if json_str == restored_str then
    print("✅ JSON 문자열 완벽 일치 (데이터 손실 없음)")
else
    print("❌ JSON 문자열 불일치 발생")
end

---------------------------------------------------------
-- 검증 1: 최상단 테이블 반환(return {table}) 에러 유발 검증
-- ⚠️ 주의: 아래 주석을 해제하면 Wasmoon 런타임 에러가 발생하는지 확인 가능합니다.
---------------------------------------------------------
print("🧪 [최상단 return 테스트] 진입")

-- return {
--     testFunc = function() return "ok" end
-- }
