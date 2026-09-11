//@name 야메추
//@display-name 🍱 야메추 1.2.0
//@api 3.0
//@version 1.2.0

// 내부 모듈 정의
const 야메추Core = (() => {
  // 1. DB 초기화
  async function initMenuDB() {
    const currentDB = await Risuai.getVar("menu_db");
    if (!currentDB) {
      const initialDB = {
        "짜장면": { category: "중식", is_favorite: false, is_new: false, score_offset: 0, eaten_days_ago: null, refused_count: 0, refused_days_ago: null, disliked: false },
        "김치찌개": { category: "한식", is_favorite: true, is_new: false, score_offset: 0, eaten_days_ago: 8, refused_count: 0, refused_days_ago: null, disliked: false },
        "후라이드치킨": { category: "치킨", is_favorite: true, is_new: false, score_offset: 0, eaten_days_ago: null, refused_count: 0, refused_days_ago: null, disliked: false }
      };
      await Risuai.setVar("menu_db", JSON.stringify(initialDB));
      console.log("🍱 [야메추] 초기 menu_db 생성 완료");
    }
  }

  // 2. 점수 계산 메인 로직
  async function calculateMenuScores() {
    await initMenuDB();
    const dbRaw = await Risuai.getVar("menu_db");
    let db = {};
    try { db = JSON.parse(dbRaw || "{}"); } catch (e) { db = {}; }

    let penalizedCategories = {};
    for (let name in db) {
      if (db[name].eaten_days_ago === 0) penalizedCategories[db[name].category] = -12;
    }

    let calculatedList = [];
    for (let name in db) {
      let item = db[name];
      if (item.disliked) continue;

      let currentScore = 80;
      if (item.is_favorite && item.refused_count === 0) {
        let favDays = item.eaten_days_ago !== null ? Math.max(0, item.eaten_days_ago - 7) : 10;
        currentScore = Math.min(100, 80 + (favDays * 2));
      }

      if (item.eaten_days_ago !== null) {
        if (item.eaten_days_ago === 0) currentScore -= 70;
        else if (item.eaten_days_ago < 8) currentScore = Math.min(90, (currentScore - 70) + (item.eaten_days_ago * 10));
      }

      if (item.eaten_days_ago !== 0 && penalizedCategories[item.category]) {
        currentScore += penalizedCategories[item.category];
      }

      if (item.refused_count > 0) {
        let penalty = item.refused_count * 30;
        let recovery = (item.refused_days_ago || 0) * 5;
        currentScore = Math.min(80, currentScore - penalty + recovery);
      }

      if (item.is_new) currentScore += 5;
      currentScore = Math.max(0, Math.min(100, Math.round(currentScore)));

      calculatedList.push({ name, category: item.category, score: currentScore });
    }

    calculatedList.sort(() => Math.random() - 0.5);
    calculatedList.sort((a, b) => b.score - a.score);

    let top4 = calculatedList.filter(i => i.score > 0).slice(0, 4);
    await Risuai.setVar("top_menu_json", JSON.stringify(top4, null, 2));
    console.log("🍱 [야메추] 점수 계산 완료 / Top 4:", top4);
  }

  // 3. 대화 감지 및 DB 업데이트
  async function onGenerateFinished(arg) {
    console.log("🍱 [야메추] onGenerateFinished 트리거 실행됨");

    const userMsg = (arg && arg.userMessage) ? arg.userMessage : "";
    const aiMsg = (arg && arg.aiMessage) ? arg.aiMessage : "";

    const dbRaw = await Risuai.getVar("menu_db");
    let db = JSON.parse(dbRaw || "{}");
    let updated = false;

    for (let name in db) {
      if (aiMsg.includes(name) && (userMsg.includes("싫") || userMsg.includes("별로") || userMsg.includes("다른"))) {
        db[name].refused_count = (db[name].refused_count || 0) + 1;
        db[name].refused_days_ago = 0;
        updated = true;
        console.log(`🍱 [야메추] 거절 감지: ${name} (횟수: ${db[name].refused_count})`);
      }
      if (userMsg.includes(name) && (userMsg.includes("먹었") || userMsg.includes("결정") || userMsg.includes("고를게") || userMsg.includes("선택"))) {
        db[name].eaten_days_ago = 0;
        db[name].refused_count = 0;
        db[name].refused_days_ago = null;
        updated = true;
        console.log(`🍱 [야메추] 섭취 감지: ${name}`);
      }
    }

    if (updated) {
      await Risuai.setVar("menu_db", JSON.stringify(db));
      console.log("🍱 [야메추] DB 최신화 완료:", db);
      await calculateMenuScores();
    } else {
      console.log("🍱 [야메추] 감지된 메뉴 상태 변경 없음");
    }
  }

  return { initMenuDB, calculateMenuScores, onGenerateFinished };
})();

// 모듈 매니저 호환 등록
Risuai.registerPlugin({
  name: "야메추",
  init: () => 야메추Core.initMenuDB(),
  run: () => 야메추Core.calculateMenuScores(),
  onGenerateFinished: (arg) => 야메추Core.onGenerateFinished(arg)
});
