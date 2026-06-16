const UNIT_FALLBACK_GRAMS = {
  gram: 1,
  chen: 150,
  bat: 150,
  to: 300,
  muong_ca_phe: 5,
  muong_canh: 15,
  qua: 50,
  mieng: 100,
  lat: 25,
  phan_nho: 80,
  phan_vua: 150,
  phan_lon: 250,
  mot_it: 50,
  nua_qua: 75,
  nam: 30,
};

const UNIT_TEXT_ALIASES = {
  g: "gram",
  gam: "gram",
  gram: "gram",
  grams: "gram",
  chen: "chen",
  chen_com: "chen",
  bat: "bat",
  bat_com: "bat",
  to: "to",
  to_vua: "to",
  muong_ca_phe: "muong_ca_phe",
  muong_cafe: "muong_ca_phe",
  muong_tra: "muong_ca_phe",
  mcf: "muong_ca_phe",
  tsp: "muong_ca_phe",
  teaspoon: "muong_ca_phe",
  muong_canh: "muong_canh",
  muong_soup: "muong_canh",
  mc: "muong_canh",
  tbsp: "muong_canh",
  tablespoon: "muong_canh",
  qua: "qua",
  trai: "qua",
  mieng: "mieng",
  mieng_vua: "mieng",
  long_ban_tay: "mieng",
  bang_long_ban_tay: "mieng",
  lat: "lat",
  phan_nho: "phan_nho",
  phan_vua: "phan_vua",
  phan_lon: "phan_lon",
  mot_it: "mot_it",
  it: "mot_it",
  nua_qua: "nua_qua",
  nua_trai: "nua_qua",
  nam: "nam",
  nam_tay: "nam",
};

export const CUSTOM_FOOD_UNITS = [
  { id: "gram", label: "gram", shortLabel: "g", description: "Nhập khối lượng rõ ràng, độ tin cậy cao" },
  { id: "chen", label: "chén", shortLabel: "chén", description: "Thường dùng cho cơm, bún, rau" },
  { id: "bat", label: "bát", shortLabel: "bát", description: "Tương đương một bát ăn cơm phổ biến" },
  { id: "to", label: "tô", shortLabel: "tô", description: "Tô bún/phở/cháo cỡ vừa" },
  { id: "muong_ca_phe", label: "muỗng cà phê", shortLabel: "mcf", description: "Khoảng 5g dầu, đường hoặc sốt" },
  { id: "muong_canh", label: "muỗng canh", shortLabel: "mc", description: "Khoảng 15g dầu, đường hoặc sốt" },
  { id: "qua", label: "quả", shortLabel: "quả", description: "Trứng hoặc trái cây cỡ vừa" },
  { id: "mieng", label: "miếng", shortLabel: "miếng", description: "Một miếng thịt/cá cỡ lòng bàn tay" },
  { id: "lat", label: "lát", shortLabel: "lát", description: "Bánh mì hoặc lát thực phẩm mỏng" },
  { id: "phan_nho", label: "phần nhỏ", shortLabel: "nhỏ", description: "Khẩu phần nhỏ ước lượng" },
  { id: "phan_vua", label: "phần vừa", shortLabel: "vừa", description: "Khẩu phần vừa ước lượng" },
  { id: "phan_lon", label: "phần lớn", shortLabel: "lớn", description: "Khẩu phần lớn ước lượng" },
  { id: "mot_it", label: "một ít", shortLabel: "ít", description: "Một lượng nhỏ rau/gia vị" },
  { id: "nua_qua", label: "nửa quả", shortLabel: "1/2 quả", description: "Nửa quả cỡ vừa" },
  { id: "nam", label: "nắm", shortLabel: "nắm", description: "Một nắm tay nhỏ" },
];

export const VIETNAM_NUTRITION_INGREDIENTS = [
  ingredient("ing-com-trang", "Cơm trắng", ["cơm", "cơm trắng", "cơm tẻ"], 130, 2.7, 28.2, 0.3, { chen: 150, bat: 150, nam: 80 }),
  ingredient("ing-bun", "Bún", ["bún", "bún tươi"], 110, 1.7, 25.7, 0.2, { chen: 120, bat: 150, to: 250 }),
  ingredient("ing-pho", "Phở", ["phở", "bánh phở", "phở tươi"], 140, 3.2, 30.5, 0.4, { bat: 160, to: 260 }),
  ingredient("ing-mi", "Mì", ["mì", "mì vắt", "mì trứng", "mì gói"], 138, 4.5, 25, 2.1, { goi: 75, bat: 160, to: 260 }),
  ingredient("ing-banh-mi", "Bánh mì", ["bánh mì", "bánh mì trắng", "ổ bánh mì"], 265, 9, 49, 3.2, { lat: 25, mieng: 40, phan_vua: 90 }),
  ingredient("ing-trung-ga", "Trứng gà", ["trứng", "trứng gà", "trứng luộc", "trứng ốp la"], 155, 13, 1.1, 11, { qua: 50, nua_qua: 25 }),
  ingredient("ing-uc-ga", "Ức gà", ["ức gà", "thịt ức gà", "gà áp chảo"], 165, 31, 0, 3.6, { mieng: 120, phan_vua: 120, phan_nho: 80, phan_lon: 180 }),
  ingredient("ing-dui-ga", "Đùi gà", ["đùi gà", "thịt đùi gà"], 209, 26, 0, 10.9, { mieng: 130, phan_vua: 130 }),
  ingredient("ing-thit-heo-nac", "Thịt heo nạc", ["thịt heo", "thịt nạc", "heo nạc"], 242, 27, 0, 14, { mieng: 100, phan_vua: 120 }),
  ingredient("ing-thit-bo", "Thịt bò", ["thịt bò", "bò", "bò nạc"], 250, 26, 0, 15, { mieng: 100, phan_vua: 120 }),
  ingredient("ing-ca", "Cá", ["cá", "cá kho", "cá hấp"], 160, 23, 0, 7, { mieng: 100, phan_vua: 120 }),
  ingredient("ing-tom", "Tôm", ["tôm", "tôm luộc", "tôm hấp"], 99, 24, 0.2, 0.3, { phan_nho: 80, phan_vua: 120 }),
  ingredient("ing-dau-hu", "Đậu hũ", ["đậu hũ", "đậu phụ", "tàu hũ"], 76, 8, 1.9, 4.8, { mieng: 100, phan_vua: 150 }),
  ingredient("ing-rau-xanh", "Rau xanh", ["rau", "rau xanh", "rau luộc", "xà lách", "rau muống"], 30, 2.2, 5, 0.3, { mot_it: 50, nam: 40, bat: 100, phan_vua: 150 }),
  ingredient("ing-ca-rot", "Cà rốt", ["cà rốt", "carrot"], 41, 0.9, 10, 0.2, { nua_qua: 35, qua: 70, phan_vua: 100 }),
  ingredient("ing-khoai-lang", "Khoai lang", ["khoai lang"], 86, 1.6, 20.1, 0.1, { cu: 130, phan_vua: 150 }),
  ingredient("ing-dau-an", "Dầu ăn", ["dầu ăn", "dầu", "dầu olive", "dầu ô liu"], 884, 0, 0, 100, { muong_ca_phe: 5, muong_canh: 15 }),
  ingredient("ing-bo", "Bơ", ["bơ", "butter"], 717, 0.9, 0.1, 81, { muong_ca_phe: 5, muong_canh: 14 }),
  ingredient("ing-sua", "Sữa", ["sữa", "sữa tươi", "sữa không đường"], 60, 3.2, 4.8, 3.3, { chen: 200, bat: 200 }),
  ingredient("ing-duong", "Đường", ["đường", "đường trắng"], 387, 0, 100, 0, { muong_ca_phe: 4, muong_canh: 12 }),
  ingredient("ing-nuoc-mam", "Nước mắm", ["nước mắm", "mắm"], 35, 5, 3.6, 0, { muong_ca_phe: 5, muong_canh: 15 }),
  ingredient("ing-tuong-ot", "Tương ớt", ["tương ớt"], 120, 1, 28, 0.5, { muong_ca_phe: 6, muong_canh: 18 }),
  ingredient("ing-mayonnaise", "Mayonnaise", ["mayonnaise", "sốt mayonnaise", "mayo"], 680, 1, 1, 75, { muong_ca_phe: 5, muong_canh: 14 }),
];

export const QUICK_DISH_ESTIMATES = [
  { match: ["cơm gà", "com ga"], dishName: "Cơm gà", caloriesRange: [450, 650], proteinRange: [25, 40] },
  { match: ["cơm trứng", "com trung"], dishName: "Cơm trứng", caloriesRange: [380, 550], proteinRange: [14, 24] },
  { match: ["thịt kho trứng", "thit kho trung"], dishName: "Thịt kho trứng", caloriesRange: [450, 700], proteinRange: [25, 40] },
  { match: ["canh rau"], dishName: "Canh rau", caloriesRange: [50, 150], proteinRange: [2, 8] },
  { match: ["cá kho", "ca kho"], dishName: "Cá kho", caloriesRange: [250, 450], proteinRange: [22, 38] },
  { match: ["bún thịt nướng", "bun thit nuong"], dishName: "Bún thịt nướng", caloriesRange: [500, 750], proteinRange: [25, 40] },
  { match: ["phở bò", "pho bo"], dishName: "Phở bò", caloriesRange: [400, 650], proteinRange: [22, 38] },
  { match: ["mì xào", "mi xao"], dishName: "Mì xào", caloriesRange: [450, 750], proteinRange: [15, 35] },
  { match: ["bánh mì trứng", "banh mi trung"], dishName: "Bánh mì trứng", caloriesRange: [350, 550], proteinRange: [14, 25] },
  { match: ["cháo gà", "chao ga"], dishName: "Cháo gà", caloriesRange: [250, 450], proteinRange: [15, 28] },
  { match: ["cơm tấm", "com tam"], dishName: "Cơm tấm", caloriesRange: [600, 900], proteinRange: [28, 45] },
];

function ingredient(id, name, aliases, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g, defaultUnits) {
  return {
    id,
    name,
    aliases,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    defaultUnits,
  };
}

export function normalizeVietnameseText(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D")
    .toLowerCase()
    .trim();
}

function repairPossibleMojibake(value) {
  const text = String(value || "");
  if (!/[ÃÄÂ]/.test(text)) return text;
  try {
    const repaired = Buffer.from(text, "latin1").toString("utf8");
    return repaired.includes("�") ? text : repaired;
  } catch {
    return text;
  }
}

function normalizeUnitId(value) {
  const repaired = repairPossibleMojibake(value);
  const normalized = normalizeVietnameseText(repaired)
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
  if (!normalized) return "gram";

  const unitId = normalized.replace(/\s+/g, "_");
  if (UNIT_FALLBACK_GRAMS[unitId] || CUSTOM_FOOD_UNITS.some((unit) => unit.id === unitId)) {
    return unitId;
  }

  if (UNIT_TEXT_ALIASES[unitId]) return UNIT_TEXT_ALIASES[unitId];
  if (normalized.includes("muong ca phe") || normalized.includes("muong cafe")) return "muong_ca_phe";
  if (normalized.includes("muong canh") || normalized.includes("muong soup")) return "muong_canh";
  if (normalized.includes("chen")) return "chen";
  if (normalized.includes("bat")) return "bat";
  if (normalized.includes("to")) return "to";
  if (normalized.includes("mieng") || normalized.includes("long ban tay")) return "mieng";
  if (normalized.includes("lat")) return "lat";
  if (normalized.includes("nua") && (normalized.includes("qua") || normalized.includes("trai"))) return "nua_qua";
  if (normalized.includes("mot it") || normalized === "it") return "mot_it";
  if (normalized.includes("nam")) return "nam";
  if (normalized.includes("qua") || normalized.includes("trai")) return "qua";
  if (normalized.includes("phan nho")) return "phan_nho";
  if (normalized.includes("phan lon")) return "phan_lon";
  if (normalized.includes("phan")) return "phan_vua";

  return unitId;
}

function getUnitLabel(unitId) {
  return CUSTOM_FOOD_UNITS.find((unit) => unit.id === unitId)?.label || unitId || "đơn vị";
}

export function findNutritionIngredient(inputName) {
  const normalized = normalizeVietnameseText(inputName);
  if (!normalized) return null;

  const candidates = VIETNAM_NUTRITION_INGREDIENTS
    .map((item) => {
      const terms = [item.name, ...(item.aliases || [])].map(normalizeVietnameseText);
      const exact = terms.some((term) => term === normalized);
      const contains = terms.some((term) => normalized.includes(term) || term.includes(normalized));
      const score = exact ? 3 : contains ? 2 : 0;
      return { item, score, longest: Math.max(...terms.map((term) => term.length)) };
    })
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score || b.longest - a.longest);

  return candidates[0]?.item || null;
}

function resolveGrams(unit, quantity, ingredient) {
  const unitId = normalizeUnitId(unit);
  if (unitId === "gram") return quantity;
  const gramsPerUnit = ingredient.defaultUnits?.[unitId] || UNIT_FALLBACK_GRAMS[unitId];
  if (!gramsPerUnit) return null;
  return quantity * gramsPerUnit;
}

function round(value, digits = 0) {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function nutritionByGrams(ingredient, grams) {
  return {
    calories: round((grams * ingredient.caloriesPer100g) / 100),
    protein: round((grams * ingredient.proteinPer100g) / 100, 1),
    carbs: round((grams * ingredient.carbsPer100g) / 100, 1),
    fat: round((grams * ingredient.fatPer100g) / 100, 1),
  };
}

function findQuickEstimate(dishName, rawText = "") {
  const normalized = normalizeVietnameseText(`${dishName} ${rawText}`);
  return QUICK_DISH_ESTIMATES.find((item) => item.match.some((term) => normalized.includes(normalizeVietnameseText(term)))) || null;
}

function parseVietnameseQuantity(value) {
  const normalized = normalizeVietnameseText(value).replace(",", ".");
  const numeric = Number(normalized);
  if (Number.isFinite(numeric)) return numeric;
  const words = {
    mot: 1,
    hai: 2,
    ba: 3,
    bon: 4,
    tu: 4,
    nam: 5,
    nua: 0.5,
  };
  return words[normalized] || 1;
}

function matchQuantityAndUnit(beforeText) {
  const text = normalizeVietnameseText(beforeText).trim();
  const quantity = "(\\d+(?:[.,]\\d+)?|mot|hai|ba|bon|tu|nam|nua)";
  const patterns = [
    { unit: "muong_ca_phe", regex: new RegExp(`${quantity}\\s+muong\\s+ca\\s+phe\\s*$`) },
    { unit: "muong_canh", regex: new RegExp(`${quantity}\\s+muong\\s+canh\\s*$`) },
    { unit: "chen", regex: new RegExp(`${quantity}\\s+chen\\s*$`) },
    { unit: "bat", regex: new RegExp(`${quantity}\\s+bat\\s*$`) },
    { unit: "to", regex: new RegExp(`${quantity}\\s+to\\s*$`) },
    { unit: "qua", regex: new RegExp(`${quantity}\\s+qua\\s*$`) },
    { unit: "mieng", regex: new RegExp(`${quantity}\\s+mieng\\s*$`) },
    { unit: "lat", regex: new RegExp(`${quantity}\\s+lat\\s*$`) },
    { unit: "nam", regex: new RegExp(`${quantity}\\s+nam\\s*$`) },
    { unit: "gram", regex: new RegExp(`${quantity}\\s*(?:g|gram)\\s*$`) },
    { unit: "mot_it", regex: /mot\s+it\s*$/ },
    { unit: "nua_qua", regex: /nua\s+qua\s*$/ },
  ];

  for (const pattern of patterns) {
    const match = pattern.regex.exec(text);
    if (match) return { quantity: match[1] ? parseVietnameseQuantity(match[1]) : 1, unit: pattern.unit };
  }
  return null;
}

function inferServingsFromRawText(rawText, fallback) {
  const normalized = normalizeVietnameseText(rawText);
  const match = /(?:cho|chia|duoc)\s+(\d+(?:[.,]\d+)?|mot|hai|ba|bon|tu|nam)\s+phan/.exec(normalized);
  if (!match) return fallback;
  return Math.max(1, Math.min(50, parseVietnameseQuantity(match[1])));
}

function inferIngredientsFromRawText(rawText) {
  const normalized = normalizeVietnameseText(rawText);
  if (!normalized) return [];
  const inferred = [];
  const used = new Set();

  for (const ingredient of VIETNAM_NUTRITION_INGREDIENTS) {
    const terms = [ingredient.name, ...(ingredient.aliases || [])]
      .map(normalizeVietnameseText)
      .filter(Boolean)
      .sort((a, b) => b.length - a.length);

    for (const term of terms) {
      let index = normalized.indexOf(term);
      while (index >= 0) {
        const beforeText = normalized.slice(Math.max(0, index - 45), index);
        const match = matchQuantityAndUnit(beforeText);
        if (match && !used.has(ingredient.id)) {
          inferred.push({ name: ingredient.name, quantity: match.quantity, unit: match.unit });
          used.add(ingredient.id);
          break;
        }
        index = normalized.indexOf(term, index + term.length);
      }
      if (used.has(ingredient.id)) break;
    }
  }

  return inferred;
}

export function estimateCustomCookedFood(payload = {}) {
  const dishName = String(payload.name || payload.dishName || "").trim();
  const rawText = String(payload.rawText || "").trim();
  const servings = inferServingsFromRawText(rawText, Math.max(1, Math.min(50, Number(payload.servings || 1))));
  const cookingMethod = String(payload.cookingMethod || "").trim();
  const inputIngredients = Array.isArray(payload.ingredients) && payload.ingredients.length > 0
    ? payload.ingredients
    : inferIngredientsFromRawText(rawText);

  if (!dishName && !rawText) {
    return {
      needsMoreInfo: true,
      question: "Bạn muốn ước tính món gì? Hãy nhập tên món và ít nhất một nguyên liệu.",
      suggestions: ["Ví dụ: Cơm gà áp chảo", "Ví dụ: 1 chén cơm, 1 miếng ức gà, 1 muỗng cà phê dầu ăn"],
    };
  }

  if (inputIngredients.length === 0) {
    const quick = findQuickEstimate(dishName, rawText);
    return {
      needsMoreInfo: true,
      question: "Bạn muốn ước tính nhanh hay nhập chi tiết nguyên liệu?",
      quickEstimate: quick
        ? {
            dishName: quick.dishName,
            caloriesRange: quick.caloriesRange,
            proteinRange: quick.proteinRange,
            confidence: "Thấp",
            note: `${quick.dishName} thường khoảng ${quick.caloriesRange[0]}-${quick.caloriesRange[1]} kcal/phần, có thể dao động theo dầu, sốt và khẩu phần.`,
          }
        : null,
      suggestions: [
        "Ước tính nhanh: chọn món tương tự và dùng khoảng calo tham khảo.",
        "Nhập chi tiết: cơm bao nhiêu chén, thịt/cá bao nhiêu miếng, có dùng dầu hoặc sốt không?",
      ],
    };
  }

  const unresolved = [];
  const recognized = [];

  for (const row of inputIngredients) {
    const inputName = String(row.name || "").trim();
    const unit = normalizeUnitId(row.unit || "gram");
    const quantity = Number(row.quantity || 0);
    const matched = findNutritionIngredient(inputName);

    if (!inputName || !matched || !Number.isFinite(quantity) || quantity <= 0) {
      unresolved.push({
        inputName,
        quantity,
        unit,
        reason: !inputName ? "Thiếu tên nguyên liệu" : !matched ? "Chưa có trong database dinh dưỡng mẫu" : "Thiếu số lượng hợp lệ",
      });
      continue;
    }

    const grams = resolveGrams(unit, quantity, matched);
    if (!grams || !Number.isFinite(grams)) {
      unresolved.push({ inputName, quantity, unit, reason: "Đơn vị này chưa có quy đổi gram phù hợp" });
      continue;
    }

    const nutrition = nutritionByGrams(matched, grams);
    recognized.push({
      inputName,
      matchedName: matched.name,
      quantity,
      unit,
      unitLabel: getUnitLabel(unit),
      grams: round(grams),
      note: String(row.note || "").trim(),
      ...nutrition,
    });
  }

  if (unresolved.length > 0 || recognized.length === 0) {
    return {
      needsMoreInfo: true,
      question: "Một vài nguyên liệu còn thiếu hoặc chưa nhận diện được. Bạn hãy chỉnh lại tên nguyên liệu, số lượng hoặc chọn nguyên liệu gần đúng hơn.",
      unresolved,
      recognized,
      suggestions: [
        "Có thể dùng tên phổ biến như: cơm trắng, ức gà, dầu ăn, trứng gà, rau xanh.",
        "Nếu không biết gram, hãy chọn đơn vị đời thường như chén, miếng, muỗng cà phê, quả.",
      ],
    };
  }

  const totals = recognized.reduce(
    (sum, item) => ({
      calories: sum.calories + item.calories,
      protein: sum.protein + item.protein,
      carbs: sum.carbs + item.carbs,
      fat: sum.fat + item.fat,
    }),
    { calories: 0, protein: 0, carbs: 0, fat: 0 },
  );

  const roundedTotals = {
    calories: round(totals.calories),
    protein: round(totals.protein, 1),
    carbs: round(totals.carbs, 1),
    fat: round(totals.fat, 1),
  };
  const perServing = {
    calories: round(roundedTotals.calories / servings),
    protein: round(roundedTotals.protein / servings, 1),
    carbs: round(roundedTotals.carbs / servings, 1),
    fat: round(roundedTotals.fat / servings, 1),
  };
  const hasOnlyGramUnits = recognized.every((item) => item.unit === "gram");
  const confidence = hasOnlyGramUnits
    ? { level: "high", label: "Cao", reason: "Các nguyên liệu đều nhập bằng gram rõ ràng." }
    : { level: "medium", label: "Trung bình", reason: "Một số nguyên liệu dùng đơn vị đời thường nên gram là quy đổi ước lượng." };

  return {
    needsMoreInfo: false,
    estimate: {
      dishName: dishName || "Món tự nấu",
      servings,
      cookingMethod,
      ingredients: recognized,
      totals: roundedTotals,
      perServing,
      confidence,
      disclaimer: `Món này ước tính khoảng ${perServing.calories} kcal/phần, có thể dao động tùy lượng dầu, nước sốt và kích thước khẩu phần thực tế.`,
      suggestions: [
        "Nếu muốn giảm calo, hãy giảm dầu ăn hoặc dùng nồi chiên không dầu.",
        "Nếu muốn tăng protein, có thể thêm 50g ức gà, cá, tôm hoặc 1 quả trứng.",
      ],
    },
    addableItem: {
      name: dishName || "Món tự nấu",
      calories: perServing.calories,
      protein: perServing.protein,
      carbs: perServing.carbs,
      fat: perServing.fat,
      portion: servings > 1 ? `1 phần trong ${servings} phần` : "1 phần tự nấu",
      quantity: 1,
    },
  };
}
