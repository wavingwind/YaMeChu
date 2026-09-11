// 🍱 [야메추 플러그인] JS 연동 및 추천 로직
const DEFAULT_DB = {
  "짜장면": { category: "중식", is_favorite: false, is_new: false, score_offset: 0, refused_count: 0, refused_days_ago: 0, disliked: false },
  "김치찌개": { category: "한식", is_favorite: true, is_new: false, score_offset: 0, eaten_days_ago: 8, refused_count: 0, refused_days_ago: 0, disliked: false },
  "후라이드치킨": { category: "치킨", is_favorite: true, is_new: false, score_offset: 0, refused_count: 0, refused_days_ago: 0, disliked: false }
};

// DB 불러오기 / 초기화
function getMenuDB() {
  const raw = Risuai.getVar("menu_db");
  if (!raw) return { ...DEFAULT_DB };
  try {
    return JSON.parse(raw);
  } catch (e) {
    return { ...DEFAULT_DB };
  }
}

// 점수 계산 및 Top 4 추천 추출
function calculateTopMenu(db) {
  const calculatedList = [];

  for (const [name, item] of Object.entries(db)) {
    if (item.disliked) continue;

    let currentScore = 80;
    const eatenDays = typeof item.eaten_days_ago === 'number' ? item.eaten_days_ago : null;
    const refusedCount = typeof item.refused_count === 'number' ? item.refused_count : 0;
    const refusedDays = typeof item.refused_days_ago === 'number' ? item.refused_days_ago : 0;

    // 즐겨찾기 보너스
    if (item.is_favorite && refusedCount === 0) {
      const favDays = eatenDays !== null ? Math.max(0, eatenDays - 7) : 10;
      currentScore = Math.min(100, 80 + (favDays * 2));
    }

    // 최근 섭취 감점
    if (eatenDays !== null) {
      if (eatenDays === 0) {
        currentScore -= 70;
      } else if (eatenDays < 8) {
        currentScore = Math.min(90, (currentScore - 70) + (eatenDays * 10));
      }
    }

    // 거절 감점 및 회복
    if (refusedCount > 0) {
      const penalty = refusedCount * 30;
      const recovery = refusedDays * 5;
      currentScore = Math.min(80, currentScore - penalty + recovery);
    }

    // 신규 메뉴 보너스
    if (item.is_new) {
      currentScore += 5;
    }

    currentScore = Math.max(0, Math.min(100, Math.round(currentScore)));

    if (currentScore > 0) {
      calculatedList.push({ name, category: item.category || "기타", score: currentScore });
    }
  }

  // 점수 내림차순 정렬 후 Top 4 추출
  calculatedList.sort((a, b) => b.score - a.score);
  return calculatedList.slice(0, 4);
}

// RisuAI 이벤트 훅
onGenerateFinished(async (ctx) => {
  const db = getMenuDB();
  let updated = false;

  // Lua 스크립트 실행 로그 또는 대화 텍스트 기반 감지
  const userMsg = ctx.userMessage || "";
  const aiMsg = ctx.aiMessage || "";

  for (const name of Object.keys(db)) {
    // 거절 감지
    if (aiMsg.includes(name) && ["싫", "별로", "다른", "안먹"].some(k => userMsg.includes(k))) {
      db[name].refused_count = (db[name].refused_count || 0) + 1;
      db[name].refused_days_ago = 0;
      updated = true;
    }

    // 섭취/선택 감지
    if (userMsg.includes(name) && ["먹했", "먹었", "결정", "고를게", "선택", "먹을"].some(k => userMsg.includes(k))) {
      db[name].eaten_days_ago = 0;
      db[name].refused_count = 0;
      db[name].refused_days_ago = 0;
      updated = true;
    }
  }

  // DB 업데이트 및 Top 4 변수 저장
  if (updated) {
    Risuai.setVar("menu_db", JSON.stringify(db));
  }

  const top4 = calculateTopMenu(db);
  Risuai.setVar("top_menu_json", JSON.stringify(top4));
});
