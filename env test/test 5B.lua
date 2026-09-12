print("🧪 [table.sort 테스트] 시작")

local testList = {
    { name = "짜장면", score = 70 },
    { name = "김치찌개", score = 95 },
    { name = "치킨", score = 85 }
}

print("🧪 [table.sort 수행 전] 항목 수: " .. tostring(#testList))

-- 커스텀 비교 함수 정렬
table.sort(testList, function(a, b)
    return a.score > b.score
end)

print("🧪 [table.sort 수행 완료] 1등: " .. tostring(testList[1].name) .. " (" .. tostring(testList[1].score) .. "점)")
