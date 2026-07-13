import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { healthyBeverageFoods, healthyDrinkRecipes, healthyVietnameseFoods, seedData } from "./data/seed.js";
import { loadSqlServerData } from "./sqlserver-import.js";
import { loadSupabaseData, persistSupabaseData, resetSupabaseData } from "./supabase-postgres-store.js";
import {
  deleteSupabaseFood,
  deleteSupabaseFriendship,
  deleteSupabaseMember,
  deleteSupabasePersonalFood,
  deleteSupabaseRecipe,
  loadSupabaseNormalizedData,
  persistSupabaseAuthCredential,
  persistSupabaseCoachPlan,
  persistSupabaseFood,
  persistSupabaseFriendChat,
  persistSupabaseFriendship,
  persistSupabaseMealLog,
  persistSupabaseMember,
  persistSupabaseNormalizedData,
  persistSupabaseNotification,
  persistSupabaseOAuthIdentity,
  persistSupabasePayment,
  persistSupabasePersonalFood,
  persistSupabasePersonalizedRecipe,
  persistSupabaseRecipe,
  persistSupabaseSetting,
  replaceSupabaseAiSafetyLogs,
  replaceSupabaseMemberChatHistory,
  replaceSupabaseMemberNotifications,
  resetSupabaseNormalizedData,
} from "./supabase-normalized-store.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DEFAULT_DB_PATH = path.resolve(__dirname, "../data/db.json");

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function resolveDbPath(customPath) {
  const selected = customPath || process.env.NUTRIPATH_DB || DEFAULT_DB_PATH;
  return path.isAbsolute(selected) ? selected : path.resolve(process.cwd(), selected);
}

async function ensureFile(filePath) {
  if (existsSync(filePath)) return;
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(seedData, null, 2), "utf8");
}

function normalizeCatalogData(db) {
  if (!db || typeof db !== "object") return db;

  if (!Array.isArray(db.friendships)) db.friendships = [];
  if (!Array.isArray(db.friendChats)) db.friendChats = [];
  if (!Array.isArray(db.foods) || db.foods.length === 0) db.foods = clone(seedData.foods);
  const syncedFoods = [...healthyVietnameseFoods, ...healthyBeverageFoods];
  const syncedFoodIds = new Set(syncedFoods.map((food) => food.id));
  const retainedFoods = db.foods.filter((food) => !syncedFoodIds.has(food.id));
  db.foods = [...retainedFoods, ...clone(syncedFoods)];

  if (Array.isArray(db.recipes)) {
    const healthyRecipeIds = new Set(healthyDrinkRecipes.map((recipe) => recipe.id));
    const retainedRecipes = db.recipes.filter((recipe) => !healthyRecipeIds.has(recipe.id));
    db.recipes = [...retainedRecipes, ...clone(healthyDrinkRecipes)];
  }

  if (Array.isArray(db.mealLogs)) {
    for (const log of db.mealLogs) {
      if (log.waterMl === undefined && log.waterGlasses !== undefined) {
        log.waterMl = Math.max(0, Math.round((Number(log.waterGlasses) || 0) * 250));
      }
    }
  }

  return db;
}

function targetedFallback(saveFull) {
  const save = async () => saveFull();
  return {
    saveMember: save,
    deleteMember: save,
    saveFood: save,
    deleteFood: save,
    saveRecipe: save,
    deleteRecipe: save,
    saveMealLog: save,
    savePayment: save,
    saveAuthCredential: save,
    saveOAuthIdentity: save,
    savePersonalFood: save,
    deletePersonalFood: save,
    savePersonalizedRecipe: save,
    saveCoachPlan: save,
    saveFriendship: save,
    deleteFriendship: save,
    saveFriendChat: save,
    saveNotification: save,
    saveChatHistoryForMember: save,
    saveNotificationsForMember: save,
    saveAiSafetyLogs: save,
    saveSetting: save,
  };
}

export async function createStore(options = {}) {
  const dataSource = String(options.dataSource || process.env.NUTRIPATH_DATA_SOURCE || "json").toLowerCase();
  if (dataSource === "sqlserver") {
    let cache = normalizeCatalogData(await loadSqlServerData());

    async function saveSqlServerCache() {
      return cache;
    }

    return {
      filePath: "sqlserver:NutriPath",
      dataSource: "sqlserver",
      get db() {
        return cache;
      },
      async reload() {
        cache = normalizeCatalogData(await loadSqlServerData());
        return cache;
      },
      async save() {
        return cache;
      },
      ...targetedFallback(saveSqlServerCache),
      async reset() {
        cache = normalizeCatalogData(await loadSqlServerData());
        return cache;
      },
      nextId(prefix, collection) {
        const next = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
        const id = `${prefix}-${next}`;
        if (!Array.isArray(collection) || !collection.some((item) => item.id === id)) return id;
        return `${prefix}-${next}-${collection.length + 1}`;
      },
    };
  }

  if (["supabase", "postgres", "postgresql", "supabase-normalized", "supabase_normalized"].includes(dataSource)) {
    const storageMode = String(process.env.NUTRIPATH_SUPABASE_STORAGE || "normalized").toLowerCase();
    const useAppState = ["app_state", "app-state", "jsonb", "legacy"].includes(storageMode) && !["supabase-normalized", "supabase_normalized"].includes(dataSource);
    const loadData = useAppState ? loadSupabaseData : loadSupabaseNormalizedData;
    const persistData = useAppState ? persistSupabaseData : persistSupabaseNormalizedData;
    const resetData = useAppState ? resetSupabaseData : resetSupabaseNormalizedData;
    let cache = normalizeCatalogData(await loadData());
    let savePromise = Promise.resolve();

    async function queueSave(operation) {
      const nextSave = savePromise.then(operation);
      savePromise = nextSave.catch(() => {});
      await nextSave;
      return cache;
    }

    function targetOrFull(persistFn, ...args) {
      return queueSave(() => persistFn ? persistFn(...args) : persistData(cache));
    }

    return {
      filePath: useAppState ? "supabase:app-state" : "supabase:normalized",
      dataSource: useAppState ? "supabase" : "supabase-normalized",
      get db() {
        return cache;
      },
      async reload() {
        cache = normalizeCatalogData(await loadData());
        return cache;
      },
      async save() {
        return queueSave(() => persistData(cache));
      },
      async saveMealLog(log) {
        return targetOrFull(useAppState ? null : persistSupabaseMealLog, log);
      },
      async saveMember(member) {
        return targetOrFull(useAppState ? null : persistSupabaseMember, member);
      },
      async deleteMember(memberId) {
        return targetOrFull(useAppState ? null : deleteSupabaseMember, memberId);
      },
      async saveFood(food) {
        return targetOrFull(useAppState ? null : persistSupabaseFood, food);
      },
      async deleteFood(foodId) {
        return targetOrFull(useAppState ? null : deleteSupabaseFood, foodId);
      },
      async saveRecipe(recipe) {
        return targetOrFull(useAppState ? null : persistSupabaseRecipe, recipe);
      },
      async deleteRecipe(recipeId) {
        return targetOrFull(useAppState ? null : deleteSupabaseRecipe, recipeId);
      },
      async savePayment(payment) {
        return targetOrFull(useAppState ? null : persistSupabasePayment, payment);
      },
      async saveAuthCredential(credential) {
        return targetOrFull(useAppState ? null : persistSupabaseAuthCredential, credential);
      },
      async saveOAuthIdentity(identity) {
        return targetOrFull(useAppState ? null : persistSupabaseOAuthIdentity, identity);
      },
      async savePersonalFood(food) {
        return targetOrFull(useAppState ? null : persistSupabasePersonalFood, food);
      },
      async deletePersonalFood(foodId) {
        return targetOrFull(useAppState ? null : deleteSupabasePersonalFood, foodId);
      },
      async savePersonalizedRecipe(recipe) {
        return targetOrFull(useAppState ? null : persistSupabasePersonalizedRecipe, recipe);
      },
      async saveCoachPlan(plan) {
        return targetOrFull(useAppState ? null : persistSupabaseCoachPlan, plan);
      },
      async saveFriendship(friendship) {
        return targetOrFull(useAppState ? null : persistSupabaseFriendship, friendship);
      },
      async deleteFriendship(friendshipId) {
        return targetOrFull(useAppState ? null : deleteSupabaseFriendship, friendshipId);
      },
      async saveFriendChat(message) {
        return targetOrFull(useAppState ? null : persistSupabaseFriendChat, message);
      },
      async saveNotification(notification) {
        return targetOrFull(useAppState ? null : persistSupabaseNotification, notification);
      },
      async saveChatHistoryForMember(memberId) {
        const messages = (cache.chatHistory || []).filter((message) => message.memberId === memberId);
        return targetOrFull(useAppState ? null : replaceSupabaseMemberChatHistory, memberId, messages);
      },
      async saveNotificationsForMember(memberId) {
        const notifications = (cache.notifications || []).filter((notification) => notification.memberId === memberId);
        return targetOrFull(useAppState ? null : replaceSupabaseMemberNotifications, memberId, notifications);
      },
      async saveAiSafetyLogs() {
        return targetOrFull(useAppState ? null : replaceSupabaseAiSafetyLogs, cache.aiSafetyLogs || []);
      },
      async saveSetting(settingKey, data) {
        return targetOrFull(useAppState ? null : persistSupabaseSetting, settingKey, data);
      },
      async reset() {
        cache = normalizeCatalogData(await resetData());
        return cache;
      },
      nextId(prefix, collection) {
        const next = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
        const id = `${prefix}-${next}`;
        if (!Array.isArray(collection) || !collection.some((item) => item.id === id)) return id;
        return `${prefix}-${next}-${collection.length + 1}`;
      },
    };
  }

  const filePath = resolveDbPath(options.dbPath);
  await ensureFile(filePath);

  let cache = normalizeCatalogData(JSON.parse(await readFile(filePath, "utf8")));
  let savePromise = Promise.resolve();

  async function persist() {
    await mkdir(path.dirname(filePath), { recursive: true });
    await writeFile(filePath, JSON.stringify(cache, null, 2), "utf8");
  }

  async function saveJsonCache() {
    const nextSave = savePromise.then(() => persist());
    savePromise = nextSave.catch(() => {});
    await nextSave;
    return cache;
  }

  return {
    filePath,
    get db() {
      return cache;
    },
    async reload() {
      cache = normalizeCatalogData(JSON.parse(await readFile(filePath, "utf8")));
      return cache;
    },
    async save() {
      return saveJsonCache();
    },
    ...targetedFallback(saveJsonCache),
    async reset() {
      cache = normalizeCatalogData(clone(seedData));
      await persist();
      return cache;
    },
    nextId(prefix, collection) {
      const next = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
      const id = `${prefix}-${next}`;
      if (!Array.isArray(collection) || !collection.some((item) => item.id === id)) return id;
      return `${prefix}-${next}-${collection.length + 1}`;
    },
  };
}

export function cloneRecord(value) {
  return clone(value);
}
