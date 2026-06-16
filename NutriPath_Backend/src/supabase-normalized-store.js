import { seedData } from "./data/seed.js";

let poolPromise = null;

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function getConnectionString() {
  const connectionString = process.env.SUPABASE_DATABASE_URL || process.env.DATABASE_URL || process.env.POSTGRES_URL;
  if (!connectionString) {
    throw new Error("Missing SUPABASE_DATABASE_URL, DATABASE_URL, or POSTGRES_URL for Supabase normalized data source.");
  }
  return connectionString;
}

function quoteIdentifier(identifier) {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(identifier)) {
    throw new Error(`Invalid PostgreSQL identifier: ${identifier}`);
  }
  return `"${identifier.replace(/"/g, '""')}"`;
}

function getSchema() {
  return process.env.NUTRIPATH_SUPABASE_SCHEMA || "public";
}

function table(name) {
  return `${quoteIdentifier(getSchema())}.${quoteIdentifier(name)}`;
}

function legacyAppStateTable() {
  const configured = process.env.NUTRIPATH_SUPABASE_TABLE || "public.nutripath_app_state";
  const parts = configured.split(".");
  if (parts.length === 1) return `${quoteIdentifier("public")}.${quoteIdentifier(parts[0])}`;
  if (parts.length === 2) return `${quoteIdentifier(parts[0])}.${quoteIdentifier(parts[1])}`;
  throw new Error("NUTRIPATH_SUPABASE_TABLE must be a table name or schema.table.");
}

async function getPgPool() {
  if (!poolPromise) {
    poolPromise = import("pg")
      .then(({ Pool }) => {
        const sslDisabled = process.env.SUPABASE_DATABASE_SSL === "false";
        return new Pool({
          connectionString: getConnectionString(),
          max: Number(process.env.SUPABASE_DATABASE_POOL_MAX || 5),
          ssl: sslDisabled ? false : { rejectUnauthorized: process.env.SUPABASE_DATABASE_SSL_REJECT_UNAUTHORIZED === "true" },
        });
      })
      .catch((error) => {
        if (error?.code === "ERR_MODULE_NOT_FOUND" || /Cannot find package 'pg'/.test(String(error?.message || ""))) {
          throw new Error("Missing backend dependency 'pg'. Run `npm install` in NutriPath_Backend before using Supabase PostgreSQL.");
        }
        throw error;
      });
  }
  return poolPromise;
}

async function ensureNormalizedSchema(pool) {
  const schema = quoteIdentifier(getSchema());
  await pool.query(`CREATE SCHEMA IF NOT EXISTS ${schema};`);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${table("nutripath_members")} (
      id text PRIMARY KEY,
      email text UNIQUE NOT NULL,
      name text NOT NULL,
      tier text,
      role text,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_foods")} (
      id text PRIMARY KEY,
      name text NOT NULL,
      category text NOT NULL,
      calories numeric,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_plans")} (
      id text PRIMARY KEY,
      name text NOT NULL,
      monthly_price integer,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_meal_logs")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      log_date date NOT NULL,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now(),
      UNIQUE (member_id, log_date)
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_recipes")} (
      id text PRIMARY KEY,
      name text NOT NULL,
      calories integer,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_personalized_recipes")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      name text NOT NULL,
      generated_at timestamptz,
      saved_at timestamptz,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_payments")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      invoice text UNIQUE,
      status text,
      paid_at timestamptz,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_auth_credentials")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      email text UNIQUE NOT NULL,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_oauth_identities")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      provider text,
      provider_user_id text,
      email text,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_chat_messages")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      sender text,
      message_time timestamptz,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_notifications")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      notification_key text,
      read_at timestamptz,
      created_at timestamptz,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_personal_foods")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      name text NOT NULL,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_coach_plans")} (
      id text PRIMARY KEY,
      member_id text NOT NULL,
      created_at timestamptz,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_ai_safety_logs")} (
      id text PRIMARY KEY,
      created_at timestamptz,
      data jsonb NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_reference_items")} (
      collection text NOT NULL,
      item_id text NOT NULL,
      sort_order integer NOT NULL DEFAULT 0,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (collection, item_id)
    );

    CREATE TABLE IF NOT EXISTS ${table("nutripath_settings")} (
      setting_key text PRIMARY KEY,
      data jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );

    CREATE INDEX IF NOT EXISTS nutripath_foods_category_idx ON ${table("nutripath_foods")} (category);
    CREATE INDEX IF NOT EXISTS nutripath_meal_logs_member_date_idx ON ${table("nutripath_meal_logs")} (member_id, log_date DESC);
    CREATE INDEX IF NOT EXISTS nutripath_payments_member_paid_idx ON ${table("nutripath_payments")} (member_id, paid_at DESC);
    CREATE INDEX IF NOT EXISTS nutripath_chat_messages_member_time_idx ON ${table("nutripath_chat_messages")} (member_id, message_time DESC);
    CREATE INDEX IF NOT EXISTS nutripath_notifications_member_read_idx ON ${table("nutripath_notifications")} (member_id, read_at);
  `);
}

function asJson(value) {
  return JSON.stringify(value ?? null);
}

function requiredText(value, fallback) {
  const text = String(value ?? "").trim();
  return text || fallback;
}

function optionalText(value) {
  const text = String(value ?? "").trim();
  return text || null;
}

function numericOrZero(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
}

function dateOnlyOrNull(value) {
  if (!value) return null;
  const text = String(value);
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return text;
  const date = new Date(text);
  return Number.isNaN(date.getTime()) ? null : date.toISOString().slice(0, 10);
}

function timestampOrNull(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function withColumnValues(data, values) {
  return { ...(data || {}), ...values };
}

function uniqueBy(records, keySelector) {
  const seen = new Set();
  return records.filter((record) => {
    const key = keySelector(record);
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

async function bulkInsert(client, tableName, columns, recordSchema, records) {
  if (!records.length) return;
  const columnList = columns.map(quoteIdentifier).join(", ");
  const selectList = columns.map((column) => `x.${quoteIdentifier(column)}`).join(", ");
  await client.query(
    `INSERT INTO ${table(tableName)} (${columnList}) SELECT ${selectList} FROM jsonb_to_recordset($1::jsonb) AS x(${recordSchema}) ON CONFLICT DO NOTHING;`,
    [JSON.stringify(records)],
  );
}

async function loadRows(pool, tableName, orderBy = "id") {
  const result = await pool.query(`SELECT data FROM ${table(tableName)} ORDER BY ${orderBy};`);
  return result.rows.map((row) => row.data);
}

async function loadReferenceCollections(pool) {
  const result = await pool.query(`SELECT collection, data FROM ${table("nutripath_reference_items")} ORDER BY collection, sort_order, item_id;`);
  const collections = {};
  for (const row of result.rows) {
    collections[row.collection] ??= [];
    collections[row.collection].push(row.data);
  }
  return collections;
}

async function loadSettings(pool) {
  const result = await pool.query(`SELECT setting_key, data FROM ${table("nutripath_settings")};`);
  return Object.fromEntries(result.rows.map((row) => [row.setting_key, row.data]));
}

async function loadLegacyAppState(pool) {
  try {
    const stateKey = process.env.NUTRIPATH_SUPABASE_STATE_KEY || "default";
    const result = await pool.query(`SELECT data FROM ${legacyAppStateTable()} WHERE id = $1;`, [stateKey]);
    return result.rows[0]?.data || null;
  } catch {
    return null;
  }
}

function withMeta(data) {
  const next = clone(data || seedData);
  next.meta = {
    ...(next.meta || {}),
    name: "NutriPath API",
    version: "1.0.0",
    source: "supabase-normalized",
    loadedAt: new Date().toISOString(),
  };
  return next;
}

function normalizeInitialState(data) {
  const next = withMeta(data || seedData);
  next.activityLevels ??= clone(seedData.activityLevels);
  next.exerciseTypes ??= clone(seedData.exerciseTypes);
  next.members ??= [];
  next.foods ??= clone(seedData.foods);
  next.mealLogs ??= [];
  next.weeklyProgress ??= [];
  next.personalizedRecipes ??= [];
  next.recipes ??= clone(seedData.recipes);
  next.plans ??= clone(seedData.plans);
  next.faqs ??= clone(seedData.faqs);
  next.payments ??= [];
  next.authCredentials ??= [];
  next.oauthIdentities ??= [];
  next.chatHistory ??= [];
  next.notifications ??= [];
  next.personalFoods ??= [];
  next.coachPlans ??= [];
  next.aiSafetyLogs ??= [];
  next.chat ??= clone(seedData.chat);
  next.admin ??= clone(seedData.admin);
  return next;
}

export async function loadSupabaseNormalizedData() {
  const pool = await getPgPool();
  await ensureNormalizedSchema(pool);

  const [members, foods, plans] = await Promise.all([
    loadRows(pool, "nutripath_members", "name"),
    loadRows(pool, "nutripath_foods", "category, name"),
    loadRows(pool, "nutripath_plans", "id"),
  ]);

  if (members.length === 0 && foods.length === 0 && plans.length === 0) {
    const initial = normalizeInitialState(await loadLegacyAppState(pool));
    await persistSupabaseNormalizedData(initial);
    return initial;
  }

  const [
    mealLogs,
    recipes,
    personalizedRecipes,
    payments,
    authCredentials,
    oauthIdentities,
    chatHistory,
    notifications,
    personalFoods,
    coachPlans,
    aiSafetyLogs,
    referenceCollections,
    settings,
  ] = await Promise.all([
    loadRows(pool, "nutripath_meal_logs", "log_date, id"),
    loadRows(pool, "nutripath_recipes", "name"),
    loadRows(pool, "nutripath_personalized_recipes", "saved_at DESC NULLS LAST, generated_at DESC NULLS LAST"),
    loadRows(pool, "nutripath_payments", "paid_at DESC NULLS LAST, id"),
    loadRows(pool, "nutripath_auth_credentials", "email"),
    loadRows(pool, "nutripath_oauth_identities", "email"),
    loadRows(pool, "nutripath_chat_messages", "message_time, id"),
    loadRows(pool, "nutripath_notifications", "created_at DESC NULLS LAST, id"),
    loadRows(pool, "nutripath_personal_foods", "updated_at DESC, name"),
    loadRows(pool, "nutripath_coach_plans", "created_at DESC NULLS LAST, id"),
    loadRows(pool, "nutripath_ai_safety_logs", "created_at DESC NULLS LAST, id"),
    loadReferenceCollections(pool),
    loadSettings(pool),
  ]);

  return withMeta({
    meta: settings.meta || seedData.meta,
    activityLevels: referenceCollections.activityLevels || clone(seedData.activityLevels),
    exerciseTypes: referenceCollections.exerciseTypes || clone(seedData.exerciseTypes),
    members,
    foods,
    mealLogs,
    weeklyProgress: referenceCollections.weeklyProgress || [],
    personalizedRecipes,
    recipes,
    plans,
    faqs: referenceCollections.faqs || clone(seedData.faqs),
    payments,
    authCredentials,
    oauthIdentities,
    aiSafetyLogs,
    chatHistory,
    personalFoods,
    coachPlans,
    notifications,
    chat: settings.chat || clone(seedData.chat),
    admin: settings.admin || clone(seedData.admin),
  });
}

async function deleteNormalizedRows(client) {
  const tables = [
    "nutripath_ai_safety_logs",
    "nutripath_coach_plans",
    "nutripath_personal_foods",
    "nutripath_notifications",
    "nutripath_chat_messages",
    "nutripath_oauth_identities",
    "nutripath_auth_credentials",
    "nutripath_payments",
    "nutripath_personalized_recipes",
    "nutripath_recipes",
    "nutripath_meal_logs",
    "nutripath_plans",
    "nutripath_foods",
    "nutripath_members",
    "nutripath_reference_items",
    "nutripath_settings",
  ];
  for (const tableName of tables) await client.query(`DELETE FROM ${table(tableName)};`);
}

async function insertReferenceItems(client, collection, items = []) {
  const records = items.map((item, index) => ({
    collection,
    item_id: requiredText(item.id || item.date || item.day, `${collection}-${index + 1}`),
    sort_order: index,
    data: item,
  }));
  await bulkInsert(
    client,
    "nutripath_reference_items",
    ["collection", "item_id", "sort_order", "data"],
    "collection text, item_id text, sort_order integer, data jsonb",
    uniqueBy(records, (record) => `${record.collection}:${record.item_id}`),
  );
}

export async function persistSupabaseNormalizedData(data) {
  const pool = await getPgPool();
  await ensureNormalizedSchema(pool);
  const state = normalizeInitialState(data);
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    await deleteNormalizedRows(client);

    const members = uniqueBy((state.members || []).map((member, index) => {
      const id = requiredText(member.id, `mem-${index + 1}`);
      const email = requiredText(member.email, `member-${index + 1}@nutripath.local`);
      const name = requiredText(member.name, "NutriPath Member");
      return {
        id,
        email,
        name,
        tier: optionalText(member.tier),
        role: optionalText(member.role),
        data: withColumnValues(member, { id, email, name }),
      };
    }), (member) => member.id);
    await bulkInsert(client, "nutripath_members", ["id", "email", "name", "tier", "role", "data"], "id text, email text, name text, tier text, role text, data jsonb", members);

    const foods = uniqueBy((state.foods || []).map((food, index) => {
      const id = requiredText(food.id, `food-${index + 1}`);
      const name = requiredText(food.name, "Món ăn");
      const category = requiredText(food.category, "Khác");
      const calories = numericOrZero(food.calories);
      return { id, name, category, calories, data: withColumnValues(food, { id, name, category, calories }) };
    }), (food) => food.id);
    await bulkInsert(client, "nutripath_foods", ["id", "name", "category", "calories", "data"], "id text, name text, category text, calories numeric, data jsonb", foods);

    const plans = uniqueBy((state.plans || []).map((plan, index) => {
      const id = requiredText(plan.id, `plan-${index + 1}`);
      const name = requiredText(plan.name, id.toUpperCase());
      const monthly_price = Math.round(numericOrZero(plan.monthlyPrice));
      return { id, name, monthly_price, data: withColumnValues(plan, { id, name, monthlyPrice: monthly_price }) };
    }), (plan) => plan.id);
    await bulkInsert(client, "nutripath_plans", ["id", "name", "monthly_price", "data"], "id text, name text, monthly_price integer, data jsonb", plans);

    const mealLogs = uniqueBy((state.mealLogs || []).map((log, index) => {
      const id = requiredText(log.id, `log-${index + 1}`);
      const member_id = optionalText(log.memberId);
      const log_date = dateOnlyOrNull(log.date);
      if (!member_id || !log_date) return null;
      return { id, member_id, log_date, data: withColumnValues(log, { id, memberId: member_id, date: log_date }) };
    }).filter(Boolean), (log) => `${log.member_id}:${log.log_date}`);
    await bulkInsert(client, "nutripath_meal_logs", ["id", "member_id", "log_date", "data"], "id text, member_id text, log_date date, data jsonb", mealLogs);

    const recipes = uniqueBy((state.recipes || []).map((recipe, index) => {
      const id = requiredText(recipe.id, `recipe-${index + 1}`);
      const name = requiredText(recipe.name, "Công thức healthy");
      const calories = Math.round(numericOrZero(recipe.calories));
      return { id, name, calories, data: withColumnValues(recipe, { id, name, calories }) };
    }), (recipe) => recipe.id);
    await bulkInsert(client, "nutripath_recipes", ["id", "name", "calories", "data"], "id text, name text, calories integer, data jsonb", recipes);

    const personalizedRecipes = uniqueBy((state.personalizedRecipes || []).map((recipe, index) => {
      const id = requiredText(recipe.id, `personalized-recipe-${index + 1}`);
      const member_id = optionalText(recipe.memberId);
      if (!member_id) return null;
      const name = requiredText(recipe.name, "Công thức cá nhân hóa");
      const generated_at = timestampOrNull(recipe.generatedAt);
      const saved_at = timestampOrNull(recipe.savedAt);
      return { id, member_id, name, generated_at, saved_at, data: withColumnValues(recipe, { id, memberId: member_id, name }) };
    }).filter(Boolean), (recipe) => recipe.id);
    await bulkInsert(client, "nutripath_personalized_recipes", ["id", "member_id", "name", "generated_at", "saved_at", "data"], "id text, member_id text, name text, generated_at timestamptz, saved_at timestamptz, data jsonb", personalizedRecipes);

    const payments = uniqueBy((state.payments || []).map((payment, index) => {
      const id = requiredText(payment.id, `payment-${index + 1}`);
      const member_id = optionalText(payment.memberId);
      if (!member_id) return null;
      return {
        id,
        member_id,
        invoice: optionalText(payment.invoice),
        status: optionalText(payment.status),
        paid_at: timestampOrNull(payment.paidAt),
        data: withColumnValues(payment, { id, memberId: member_id }),
      };
    }).filter(Boolean), (payment) => payment.id);
    await bulkInsert(client, "nutripath_payments", ["id", "member_id", "invoice", "status", "paid_at", "data"], "id text, member_id text, invoice text, status text, paid_at timestamptz, data jsonb", payments);

    const authCredentials = uniqueBy((state.authCredentials || []).map((credential, index) => {
      const id = requiredText(credential.id, `cred-${index + 1}`);
      const member_id = optionalText(credential.memberId);
      const email = optionalText(credential.email);
      if (!member_id || !email) return null;
      return { id, member_id, email, data: withColumnValues(credential, { id, memberId: member_id, email }) };
    }).filter(Boolean), (credential) => credential.id);
    await bulkInsert(client, "nutripath_auth_credentials", ["id", "member_id", "email", "data"], "id text, member_id text, email text, data jsonb", authCredentials);

    const oauthIdentities = uniqueBy((state.oauthIdentities || []).map((identity, index) => {
      const id = requiredText(identity.id, `oauth-${index + 1}`);
      const member_id = optionalText(identity.memberId);
      if (!member_id) return null;
      return {
        id,
        member_id,
        provider: optionalText(identity.provider || identity.providerName),
        provider_user_id: optionalText(identity.providerUserId),
        email: optionalText(identity.email),
        data: withColumnValues(identity, { id, memberId: member_id }),
      };
    }).filter(Boolean), (identity) => identity.id);
    await bulkInsert(client, "nutripath_oauth_identities", ["id", "member_id", "provider", "provider_user_id", "email", "data"], "id text, member_id text, provider text, provider_user_id text, email text, data jsonb", oauthIdentities);

    const chatMessages = uniqueBy((state.chatHistory || []).map((message, index) => {
      const id = requiredText(message.id, `chat-${index + 1}`);
      const member_id = optionalText(message.memberId);
      if (!member_id) return null;
      return {
        id,
        member_id,
        sender: optionalText(message.sender),
        message_time: timestampOrNull(message.time),
        data: withColumnValues(message, { id, memberId: member_id }),
      };
    }).filter(Boolean), (message) => message.id);
    await bulkInsert(client, "nutripath_chat_messages", ["id", "member_id", "sender", "message_time", "data"], "id text, member_id text, sender text, message_time timestamptz, data jsonb", chatMessages);

    const notifications = uniqueBy((state.notifications || []).map((notification, index) => {
      const id = requiredText(notification.id, `notification-${index + 1}`);
      const member_id = optionalText(notification.memberId);
      if (!member_id) return null;
      return {
        id,
        member_id,
        notification_key: optionalText(notification.key),
        read_at: timestampOrNull(notification.readAt),
        created_at: timestampOrNull(notification.createdAt),
        data: withColumnValues(notification, { id, memberId: member_id }),
      };
    }).filter(Boolean), (notification) => notification.id);
    await bulkInsert(client, "nutripath_notifications", ["id", "member_id", "notification_key", "read_at", "created_at", "data"], "id text, member_id text, notification_key text, read_at timestamptz, created_at timestamptz, data jsonb", notifications);

    const personalFoods = uniqueBy((state.personalFoods || []).map((food, index) => {
      const id = requiredText(food.id, `personal-food-${index + 1}`);
      const member_id = optionalText(food.memberId);
      if (!member_id) return null;
      const name = requiredText(food.name, "Món cá nhân");
      return { id, member_id, name, data: withColumnValues(food, { id, memberId: member_id, name }) };
    }).filter(Boolean), (food) => food.id);
    await bulkInsert(client, "nutripath_personal_foods", ["id", "member_id", "name", "data"], "id text, member_id text, name text, data jsonb", personalFoods);

    const coachPlans = uniqueBy((state.coachPlans || []).map((plan, index) => {
      const id = requiredText(plan.id, `coach-plan-${index + 1}`);
      const member_id = optionalText(plan.memberId);
      if (!member_id) return null;
      return {
        id,
        member_id,
        created_at: timestampOrNull(plan.createdAt || plan.generatedAt),
        data: withColumnValues(plan, { id, memberId: member_id }),
      };
    }).filter(Boolean), (plan) => plan.id);
    await bulkInsert(client, "nutripath_coach_plans", ["id", "member_id", "created_at", "data"], "id text, member_id text, created_at timestamptz, data jsonb", coachPlans);

    const aiSafetyLogs = uniqueBy((state.aiSafetyLogs || []).map((log, index) => {
      const id = requiredText(log.id, `aisafe-${index + 1}`);
      return { id, created_at: timestampOrNull(log.createdAt || log.time), data: withColumnValues(log, { id }) };
    }), (log) => log.id);
    await bulkInsert(client, "nutripath_ai_safety_logs", ["id", "created_at", "data"], "id text, created_at timestamptz, data jsonb", aiSafetyLogs);

    await insertReferenceItems(client, "activityLevels", state.activityLevels);
    await insertReferenceItems(client, "exerciseTypes", state.exerciseTypes);
    await insertReferenceItems(client, "weeklyProgress", state.weeklyProgress);
    await insertReferenceItems(client, "faqs", state.faqs);

    await client.query(`INSERT INTO ${table("nutripath_settings")} (setting_key, data) VALUES ($1, $2::jsonb), ($3, $4::jsonb), ($5, $6::jsonb);`, [
      "meta",
      asJson(state.meta),
      "chat",
      asJson(state.chat),
      "admin",
      asJson(state.admin),
    ]);

    await client.query("COMMIT");
    return state;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

export async function resetSupabaseNormalizedData() {
  const initial = normalizeInitialState(seedData);
  await persistSupabaseNormalizedData(initial);
  return initial;
}

export async function closeSupabaseNormalizedPool() {
  if (!poolPromise) return;
  const pool = await poolPromise;
  await pool.end();
  poolPromise = null;
}
