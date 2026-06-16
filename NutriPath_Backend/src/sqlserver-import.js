import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

function sqlArgs(database, query, options = {}) {
  const server = process.env.NUTRIPATH_SQL_SERVER || "localhost";
  const args = ["-S", server, "-d", database, "-y", "0", "-Y", "0", "-Q", `SET NOCOUNT ON; ${query}`];

  if (process.env.NUTRIPATH_SQL_USER && process.env.NUTRIPATH_SQL_PASSWORD) {
    args.splice(2, 0, "-U", process.env.NUTRIPATH_SQL_USER, "-P", process.env.NUTRIPATH_SQL_PASSWORD);
  } else {
    args.splice(2, 0, "-E");
  }

  if (process.env.NUTRIPATH_SQL_TRUST_CERT === "true") {
    args.splice(args.length - 2, 0, "-N", "-C");
  }

  if (options.unicodeOutput) {
    args.splice(args.length - 2, 0, "-u");
  }

  return args;
}

async function queryJson(database, query) {
  const wrappedQuery = `
DECLARE @json NVARCHAR(MAX);
SET @json = (${query.replace(/;\s*$/, "")});
SELECT CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), COALESCE(@json, N'[]')), 2);
`;
  const { stdout } = await execFileAsync("sqlcmd", sqlArgs(database, wrappedQuery), {
    windowsHide: true,
    maxBuffer: 10 * 1024 * 1024,
  });
  const hex = stdout.replace(/\s+/g, "").trim();
  if (!hex) return [];
  const json = Buffer.from(hex, "hex").toString("utf16le");
  if (!json) return [];
  if (json.toUpperCase() === "NULL") return [];
  return JSON.parse(json);
}

async function execSql(database, command) {
  await execFileAsync("sqlcmd", sqlArgs(database, command), {
    windowsHide: true,
    maxBuffer: 10 * 1024 * 1024,
  });
}

export function sqlLiteral(value) {
  if (value === null || value === undefined) return "NULL";
  if (typeof value === "number") return Number.isFinite(value) ? String(value) : "NULL";
  if (typeof value === "boolean") return value ? "1" : "0";
  return `N'${String(value).replace(/'/g, "''")}'`;
}

function parseJsonArray(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function ensureSqlServerAuthSchema() {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await execSql(database, `
IF OBJECT_ID(N'dbo.AuthCredentials', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.AuthCredentials (
    id NVARCHAR(60) NOT NULL PRIMARY KEY,
    member_id NVARCHAR(40) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    password_salt NVARCHAR(255) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_AuthCredentials_Members FOREIGN KEY (member_id) REFERENCES dbo.Members(id)
  );
END;

IF OBJECT_ID(N'dbo.WorkoutEntries', N'U') IS NULL AND OBJECT_ID(N'dbo.MealLogs', N'U') IS NOT NULL
BEGIN
  CREATE TABLE dbo.WorkoutEntries (
    id NVARCHAR(60) NOT NULL PRIMARY KEY,
    meal_log_id NVARCHAR(80) NOT NULL,
    workout_type NVARCHAR(40) NOT NULL,
    label NVARCHAR(160) NOT NULL,
    duration_minutes INT NOT NULL,
    calories INT NOT NULL,
    met DECIMAL(5, 1) NULL,
    intensity NVARCHAR(30) NULL,
    distance_km DECIMAL(8, 2) NULL,
    speed_kmh DECIMAL(8, 2) NULL,
    incline_pct DECIMAL(5, 2) NULL,
    source NVARCHAR(80) NULL,
    confidence NVARCHAR(30) NULL,
    note NVARCHAR(1000) NULL,
    assumptions_json NVARCHAR(MAX) NULL,
    user_notes NVARCHAR(1000) NULL,
    recorded_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_WorkoutEntries_MealLogs FOREIGN KEY (meal_log_id) REFERENCES dbo.MealLogs(id)
  );
END;
`);
}

export async function insertSqlServerAuthMember(member, credential) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await ensureSqlServerAuthSchema();
  await execSql(database, `
BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM dbo.Members WHERE id = ${sqlLiteral(member.id)})
BEGIN
  INSERT INTO dbo.Members (
    id, name, email, initials, role, status, tier, gender, age, weight_kg, height_cm,
    activity_level_id, goal, joined_at, calorie_target, protein_target, carbs_target,
    fat_target, water_target_glasses, member_days, saved_recipes, ai_conversations,
    tracked_calories, streak_days
  )
  VALUES (
    ${sqlLiteral(member.id)}, ${sqlLiteral(member.name)}, ${sqlLiteral(member.email)}, ${sqlLiteral(member.initials)},
    ${sqlLiteral(member.role)}, ${sqlLiteral(member.status)}, ${sqlLiteral(member.tier)}, ${sqlLiteral(member.gender)},
    ${sqlLiteral(member.age)}, ${sqlLiteral(member.weightKg)}, ${sqlLiteral(member.heightCm)}, ${sqlLiteral(member.activityLevel)},
    ${sqlLiteral(member.goal)}, ${sqlLiteral(member.joinedAt)}, ${sqlLiteral(member.calorieTarget)},
    ${sqlLiteral(member.macroTargets.protein)}, ${sqlLiteral(member.macroTargets.carbs)}, ${sqlLiteral(member.macroTargets.fat)},
    ${sqlLiteral(member.waterTargetGlasses)}, 0, 0, 0, 0, 0
  );

  INSERT INTO dbo.Subscriptions (member_id, plan_id, billing, status, started_at, renews_at, days_total, days_remaining)
  VALUES (${sqlLiteral(member.id)}, ${sqlLiteral(member.tier)}, N'monthly', N'active', ${sqlLiteral(member.joinedAt)}, NULL, NULL, NULL);
END;

INSERT INTO dbo.AuthCredentials (id, member_id, email, password_hash, password_salt)
VALUES (${sqlLiteral(credential.id)}, ${sqlLiteral(credential.memberId)}, ${sqlLiteral(credential.email)}, ${sqlLiteral(credential.passwordHash)}, ${sqlLiteral(credential.passwordSalt)});

COMMIT TRANSACTION;
`);
}

export async function insertSqlServerCredential(credential) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await ensureSqlServerAuthSchema();
  await execSql(database, `
INSERT INTO dbo.AuthCredentials (id, member_id, email, password_hash, password_salt)
VALUES (${sqlLiteral(credential.id)}, ${sqlLiteral(credential.memberId)}, ${sqlLiteral(credential.email)}, ${sqlLiteral(credential.passwordHash)}, ${sqlLiteral(credential.passwordSalt)});
`);
}

export async function updateSqlServerMemberCalorieGoal(memberId, dailyCalorieGoal) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await execSql(database, `
UPDATE dbo.Members
SET calorie_target = ${sqlLiteral(dailyCalorieGoal)}
WHERE id = ${sqlLiteral(memberId)};
`);
}

export async function saveSqlServerMemberNutritionProfile(member, nutritionProfile) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  const macros = nutritionProfile?.results?.macros || [];
  const protein = macros.find((item) => item.name === "Protein") || { grams: 0, calories: 0, pct: 0 };
  const carbs = macros.find((item) => item.name === "Carbs") || { grams: 0, calories: 0, pct: 0 };
  const fat = macros.find((item) => item.name === "Chất béo") || { grams: 0, calories: 0, pct: 0 };

  await execSql(database, `
BEGIN TRANSACTION;

UPDATE dbo.Members
SET age = ${sqlLiteral(member.age)},
  weight_kg = ${sqlLiteral(member.weightKg)},
  height_cm = ${sqlLiteral(member.heightCm)},
  gender = ${sqlLiteral(member.gender)},
  activity_level_id = ${sqlLiteral(member.activityLevel)},
  goal = ${sqlLiteral(member.goal)},
  calorie_target = ${sqlLiteral(member.calorieTarget)},
  protein_target = ${sqlLiteral(member.macroTargets?.protein || 0)},
  carbs_target = ${sqlLiteral(member.macroTargets?.carbs || 0)},
  fat_target = ${sqlLiteral(member.macroTargets?.fat || 0)}
WHERE id = ${sqlLiteral(member.id)};

MERGE dbo.MemberNutritionProfiles AS target
USING (
  SELECT
    ${sqlLiteral(member.id)} AS member_id,
    ${sqlLiteral(nutritionProfile.updatedAt)} AS updated_at,
    ${sqlLiteral(nutritionProfile.input.age)} AS age,
    ${sqlLiteral(nutritionProfile.input.weightKg)} AS weight_kg,
    ${sqlLiteral(nutritionProfile.input.heightCm)} AS height_cm,
    ${sqlLiteral(nutritionProfile.input.gender)} AS gender,
    ${sqlLiteral(nutritionProfile.input.activityLevel)} AS activity_level_id,
    ${sqlLiteral(nutritionProfile.input.goal)} AS goal,
    ${sqlLiteral(nutritionProfile.input.exerciseType)} AS exercise_type_id,
    ${sqlLiteral(nutritionProfile.input.durationMinutes)} AS duration_minutes,
    ${sqlLiteral(nutritionProfile.results.bmr)} AS bmr,
    ${sqlLiteral(nutritionProfile.results.tdee)} AS tdee,
    ${sqlLiteral(nutritionProfile.results.calorieGoal)} AS calorie_goal,
    ${sqlLiteral(nutritionProfile.results.goalDelta)} AS goal_delta,
    ${sqlLiteral(nutritionProfile.results.bmi.value)} AS bmi_value,
    ${sqlLiteral(nutritionProfile.results.bmi.label)} AS bmi_label,
    ${sqlLiteral(protein.grams)} AS protein_grams,
    ${sqlLiteral(protein.calories)} AS protein_calories,
    ${sqlLiteral(protein.pct)} AS protein_pct,
    ${sqlLiteral(carbs.grams)} AS carbs_grams,
    ${sqlLiteral(carbs.calories)} AS carbs_calories,
    ${sqlLiteral(carbs.pct)} AS carbs_pct,
    ${sqlLiteral(fat.grams)} AS fat_grams,
    ${sqlLiteral(fat.calories)} AS fat_calories,
    ${sqlLiteral(fat.pct)} AS fat_pct,
    ${sqlLiteral(nutritionProfile.results.exercise.label)} AS exercise_label,
    ${sqlLiteral(nutritionProfile.results.exercise.burnedCalories)} AS burned_calories,
    ${sqlLiteral(nutritionProfile.results.exercise.fatEquivalentGrams)} AS fat_equivalent_grams
) AS source
ON target.member_id = source.member_id
WHEN MATCHED THEN UPDATE SET
  updated_at = source.updated_at,
  age = source.age,
  weight_kg = source.weight_kg,
  height_cm = source.height_cm,
  gender = source.gender,
  activity_level_id = source.activity_level_id,
  goal = source.goal,
  exercise_type_id = source.exercise_type_id,
  duration_minutes = source.duration_minutes,
  bmr = source.bmr,
  tdee = source.tdee,
  calorie_goal = source.calorie_goal,
  goal_delta = source.goal_delta,
  bmi_value = source.bmi_value,
  bmi_label = source.bmi_label,
  protein_grams = source.protein_grams,
  protein_calories = source.protein_calories,
  protein_pct = source.protein_pct,
  carbs_grams = source.carbs_grams,
  carbs_calories = source.carbs_calories,
  carbs_pct = source.carbs_pct,
  fat_grams = source.fat_grams,
  fat_calories = source.fat_calories,
  fat_pct = source.fat_pct,
  exercise_label = source.exercise_label,
  burned_calories = source.burned_calories,
  fat_equivalent_grams = source.fat_equivalent_grams
WHEN NOT MATCHED THEN INSERT (
  member_id, updated_at, age, weight_kg, height_cm, gender, activity_level_id, goal,
  exercise_type_id, duration_minutes, bmr, tdee, calorie_goal, goal_delta, bmi_value, bmi_label,
  protein_grams, protein_calories, protein_pct, carbs_grams, carbs_calories, carbs_pct,
  fat_grams, fat_calories, fat_pct, exercise_label, burned_calories, fat_equivalent_grams
) VALUES (
  source.member_id, source.updated_at, source.age, source.weight_kg, source.height_cm, source.gender, source.activity_level_id, source.goal,
  source.exercise_type_id, source.duration_minutes, source.bmr, source.tdee, source.calorie_goal, source.goal_delta, source.bmi_value, source.bmi_label,
  source.protein_grams, source.protein_calories, source.protein_pct, source.carbs_grams, source.carbs_calories, source.carbs_pct,
  source.fat_grams, source.fat_calories, source.fat_pct, source.exercise_label, source.burned_calories, source.fat_equivalent_grams
);

COMMIT TRANSACTION;
`);
}

function sqlTimeLiteral(value) {
  return sqlLiteral(value || "00:00");
}

export async function saveSqlServerMealLog(log) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await execSql(database, `
BEGIN TRANSACTION;

MERGE dbo.MealLogs AS target
USING (
  SELECT ${sqlLiteral(log.id)} AS id, ${sqlLiteral(log.memberId)} AS member_id, ${sqlLiteral(log.date)} AS log_date,
    ${sqlLiteral(log.waterGlasses || 0)} AS water_glasses,
    ${sqlLiteral(log.activity?.steps || 0)} AS steps,
    ${sqlLiteral(log.activity?.burnedCalories || 0)} AS burned_calories,
    ${sqlLiteral(log.activity?.activeMinutes || 0)} AS active_minutes
) AS source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET
  member_id = source.member_id,
  log_date = source.log_date,
  water_glasses = source.water_glasses,
  steps = source.steps,
  burned_calories = source.burned_calories,
  active_minutes = source.active_minutes
WHEN NOT MATCHED THEN INSERT (id, member_id, log_date, water_glasses, steps, burned_calories, active_minutes)
  VALUES (source.id, source.member_id, source.log_date, source.water_glasses, source.steps, source.burned_calories, source.active_minutes);

DELETE FROM dbo.MealItems WHERE meal_log_id = ${sqlLiteral(log.id)};
DELETE FROM dbo.Goals WHERE meal_log_id = ${sqlLiteral(log.id)};
DELETE FROM dbo.WorkoutEntries WHERE meal_log_id = ${sqlLiteral(log.id)};
DELETE FROM dbo.MealSections WHERE meal_log_id = ${sqlLiteral(log.id)};

${(log.meals || []).map((meal) => `
INSERT INTO dbo.MealSections (id, meal_log_id, name, icon, target_kcal, meal_time)
VALUES (${sqlLiteral(meal.id)}, ${sqlLiteral(log.id)}, ${sqlLiteral(meal.name)}, ${sqlLiteral(meal.icon)}, ${sqlLiteral(meal.targetKcal || 0)}, ${sqlTimeLiteral(meal.time)});
${(meal.items || []).map((item) => `
INSERT INTO dbo.MealItems (id, meal_log_id, meal_section_id, food_id, name, calories, protein, carbs, fat, portion, quantity)
VALUES (${sqlLiteral(item.id)}, ${sqlLiteral(log.id)}, ${sqlLiteral(meal.id)}, ${sqlLiteral(item.foodId)}, ${sqlLiteral(item.name)},
  ${sqlLiteral(item.calories || 0)}, ${sqlLiteral(item.protein || 0)}, ${sqlLiteral(item.carbs || 0)}, ${sqlLiteral(item.fat || 0)},
  ${sqlLiteral(item.portion || "1 phần")}, ${sqlLiteral(item.quantity || 1)});
`).join("\n")}
`).join("\n")}

${(log.goals || []).map((goal) => `
INSERT INTO dbo.Goals (id, meal_log_id, label, done)
VALUES (${sqlLiteral(goal.id)}, ${sqlLiteral(log.id)}, ${sqlLiteral(goal.label)}, ${goal.done ? 1 : 0});
`).join("\n")}

${(log.activity?.workouts || []).map((workout) => `
INSERT INTO dbo.WorkoutEntries (
  id, meal_log_id, workout_type, label, duration_minutes, calories, met, intensity,
  distance_km, speed_kmh, incline_pct, source, confidence, note, assumptions_json, user_notes, recorded_at
)
VALUES (
  ${sqlLiteral(workout.id)}, ${sqlLiteral(log.id)}, ${sqlLiteral(workout.type)}, ${sqlLiteral(workout.label)},
  ${sqlLiteral(workout.durationMinutes || 0)}, ${sqlLiteral(workout.calories || 0)}, ${sqlLiteral(workout.met)},
  ${sqlLiteral(workout.intensity)}, ${sqlLiteral(workout.distanceKm)}, ${sqlLiteral(workout.speedKmh)},
  ${sqlLiteral(workout.inclinePct)}, ${sqlLiteral(workout.source)}, ${sqlLiteral(workout.confidence)},
  ${sqlLiteral(workout.note)}, ${sqlLiteral(JSON.stringify(workout.assumptions || []))},
  ${sqlLiteral(workout.userNotes)}, ${sqlLiteral(workout.recordedAt || new Date().toISOString())}
);
`).join("\n")}

COMMIT TRANSACTION;
`);
}

export async function saveSqlServerPaymentAndSubscription(member, payment, subscription) {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await execSql(database, `
BEGIN TRANSACTION;

UPDATE dbo.Members
SET tier = ${sqlLiteral(member.tier)}
WHERE id = ${sqlLiteral(member.id)};

MERGE dbo.Subscriptions AS target
USING (
  SELECT
    ${sqlLiteral(member.id)} AS member_id,
    ${sqlLiteral(subscription.planId)} AS plan_id,
    ${sqlLiteral(subscription.billing)} AS billing,
    ${sqlLiteral(subscription.status)} AS status,
    ${sqlLiteral(subscription.startedAt)} AS started_at,
    ${sqlLiteral(subscription.renewsAt)} AS renews_at,
    ${sqlLiteral(subscription.daysTotal)} AS days_total,
    ${sqlLiteral(subscription.daysRemaining)} AS days_remaining
) AS source
ON target.member_id = source.member_id
WHEN MATCHED THEN UPDATE SET
  plan_id = source.plan_id,
  billing = source.billing,
  status = source.status,
  started_at = source.started_at,
  renews_at = source.renews_at,
  days_total = source.days_total,
  days_remaining = source.days_remaining
WHEN NOT MATCHED THEN
  INSERT (member_id, plan_id, billing, status, started_at, renews_at, days_total, days_remaining)
  VALUES (source.member_id, source.plan_id, source.billing, source.status, source.started_at, source.renews_at, source.days_total, source.days_remaining);

INSERT INTO dbo.Payments (id, member_id, invoice, plan_id, billing, payment_method, amount, currency, status, paid_at)
VALUES (
  ${sqlLiteral(payment.id)},
  ${sqlLiteral(payment.memberId)},
  ${sqlLiteral(payment.invoice)},
  ${sqlLiteral(payment.planId)},
  ${sqlLiteral(payment.billing)},
  ${sqlLiteral(payment.paymentMethod)},
  ${sqlLiteral(payment.amount)},
  ${sqlLiteral(payment.currency)},
  ${sqlLiteral(payment.status)},
  ${sqlLiteral(payment.paidAt)}
);

COMMIT TRANSACTION;
`);
}

function byId(items) {
  return new Map(items.map((item) => [item.id, item]));
}

export async function loadSqlServerData() {
  const database = process.env.NUTRIPATH_SQL_DATABASE || "NutriPath";
  await ensureSqlServerAuthSchema();

  const [
    activityLevels,
    exerciseTypes,
    plans,
    planFeatures,
    membersRaw,
    subscriptions,
    foods,
    mealLogsRaw,
    mealSections,
    mealItems,
    goals,
    workoutEntries,
    weeklyProgress,
    recipesRaw,
    recipeTags,
    recipeIngredients,
    recipeSteps,
    paymentsRaw,
    faqsRaw,
    quickRepliesRaw,
    cannedResponsesRaw,
    adminUsers,
    adminKpis,
    systemServices,
    aiSettingsRows,
    securityRows,
    loginActivity,
    authCredentialsRaw,
    nutritionProfilesRaw,
  ] = await Promise.all([
    queryJson(database, "SELECT id, label, description, multiplier FROM dbo.ActivityLevels FOR JSON PATH;"),
    queryJson(database, "SELECT id, label, calories_per_minute AS caloriesPerMinute FROM dbo.ExerciseTypes FOR JSON PATH;"),
    queryJson(database, "SELECT id, name, monthly_price AS monthlyPrice, period, description FROM dbo.Plans FOR JSON PATH;"),
    queryJson(database, "SELECT plan_id AS planId, label, CAST(included AS bit) AS included FROM dbo.PlanFeatures FOR JSON PATH;"),
    queryJson(database, `SELECT id, name, email, initials, role, status, tier, gender, age,
      weight_kg AS weightKg, height_cm AS heightCm, activity_level_id AS activityLevel, goal,
      CONVERT(varchar(10), joined_at, 23) AS joinedAt, calorie_target AS calorieTarget,
      protein_target AS proteinTarget, carbs_target AS carbsTarget, fat_target AS fatTarget,
      water_target_glasses AS waterTargetGlasses, member_days AS memberDays, saved_recipes AS savedRecipes,
      ai_conversations AS aiConversations, tracked_calories AS trackedCalories, streak_days AS streakDays
      FROM dbo.Members FOR JSON PATH;`),
    queryJson(database, `SELECT member_id AS memberId, plan_id AS planId, billing, status,
      CONVERT(varchar(10), started_at, 23) AS startedAt, CONVERT(varchar(10), renews_at, 23) AS renewsAt,
      days_total AS daysTotal, days_remaining AS daysRemaining FROM dbo.Subscriptions FOR JSON PATH;`),
    queryJson(database, "SELECT id, name, category, calories, protein, carbs, fat, portion FROM dbo.Foods FOR JSON PATH;"),
    queryJson(database, `SELECT id, member_id AS memberId, CONVERT(varchar(10), log_date, 23) AS date,
      water_glasses AS waterGlasses, steps, burned_calories AS burnedCalories, active_minutes AS activeMinutes
      FROM dbo.MealLogs FOR JSON PATH;`),
    queryJson(database, `SELECT id, meal_log_id AS mealLogId, name, icon, target_kcal AS targetKcal,
      CONVERT(varchar(5), meal_time, 108) AS time FROM dbo.MealSections FOR JSON PATH;`),
    queryJson(database, `SELECT id, meal_log_id AS mealLogId, meal_section_id AS mealSectionId,
      food_id AS foodId, name, calories, protein, carbs, fat, portion, quantity
      FROM dbo.MealItems FOR JSON PATH;`),
    queryJson(database, "SELECT id, meal_log_id AS mealLogId, label, CAST(done AS bit) AS done FROM dbo.Goals FOR JSON PATH;"),
    queryJson(database, `SELECT id, meal_log_id AS mealLogId, workout_type AS type, label,
      duration_minutes AS durationMinutes, calories, met, intensity, distance_km AS distanceKm,
      speed_kmh AS speedKmh, incline_pct AS inclinePct, source, confidence, note,
      assumptions_json AS assumptionsJson, user_notes AS userNotes,
      CONVERT(varchar(33), recorded_at, 126) AS recordedAt
      FROM dbo.WorkoutEntries FOR JSON PATH;`),
    queryJson(database, `SELECT member_id AS memberId, CONVERT(varchar(10), progress_date, 23) AS date,
      day_label AS day, consumed, target FROM dbo.WeeklyProgress FOR JSON PATH;`),
    queryJson(database, `SELECT id, name, image_url AS image, time_minutes AS timeMinutes, calories,
      difficulty, servings, protein, carbs, fat, fiber FROM dbo.Recipes FOR JSON PATH;`),
    queryJson(database, "SELECT recipe_id AS recipeId, tag FROM dbo.RecipeTags FOR JSON PATH;"),
    queryJson(database, "SELECT recipe_id AS recipeId, name, amount, sort_order AS sortOrder FROM dbo.RecipeIngredients FOR JSON PATH;"),
    queryJson(database, "SELECT recipe_id AS recipeId, step_order AS stepOrder, instruction FROM dbo.RecipeSteps FOR JSON PATH;"),
    queryJson(database, `SELECT id, member_id AS memberId, invoice, plan_id AS planId, billing,
      payment_method AS paymentMethod, amount, currency, status, CONVERT(varchar(33), paid_at, 126) AS paidAt
      FROM dbo.Payments ORDER BY paid_at DESC FOR JSON PATH;`),
    queryJson(database, "SELECT id, question, answer FROM dbo.Faqs FOR JSON PATH;"),
    queryJson(database, "SELECT text FROM dbo.ChatQuickReplies ORDER BY id FOR JSON PATH;"),
    queryJson(database, "SELECT prompt, response FROM dbo.ChatCannedResponses FOR JSON PATH;"),
    queryJson(database, "SELECT id, name, email, role, status, CONVERT(varchar(10), joined_at, 23) AS joined, plan_name AS [plan] FROM dbo.AdminUsers FOR JSON PATH;"),
    queryJson(database, "SELECT id, label, value, change_text AS change FROM dbo.AdminKpis FOR JSON PATH;"),
    queryJson(database, "SELECT id, name, status, uptime, latency_ms AS latencyMs FROM dbo.AdminSystemServices FOR JSON PATH;"),
    queryJson(database, `SELECT model, CAST(auto_portion_recommendation AS bit) AS autoPortionRecommendation,
      CAST(smart_meal_suggestions AS bit) AS smartMealSuggestions, CAST(nutrition_validation AS bit) AS nutritionValidation,
      confidence_threshold AS confidenceThreshold, calorie_formula AS calorieFormula FROM dbo.AdminAiSettings WHERE id = 1 FOR JSON PATH;`),
    queryJson(database, `SELECT CAST(two_factor_enabled AS bit) AS twoFactorEnabled, min_password_length AS minPasswordLength,
      CAST(require_special_char AS bit) AS requireSpecialChar, CAST(require_uppercase AS bit) AS requireUppercase,
      CAST(require_number AS bit) AS requireNumber FROM dbo.AdminSecuritySettings WHERE id = 1 FOR JSON PATH;`),
    queryJson(database, "SELECT ip, device, location, CONVERT(varchar(33), login_time, 126) AS time, status FROM dbo.LoginActivity FOR JSON PATH;"),
    queryJson(database, "SELECT id, member_id AS memberId, email, password_hash AS passwordHash, password_salt AS passwordSalt, CONVERT(varchar(33), created_at, 126) AS createdAt FROM dbo.AuthCredentials FOR JSON PATH;"),
    queryJson(database, `SELECT member_id AS memberId, CONVERT(varchar(33), updated_at, 126) AS updatedAt,
      age, weight_kg AS weightKg, height_cm AS heightCm, gender, activity_level_id AS activityLevel, goal,
      exercise_type_id AS exerciseType, duration_minutes AS durationMinutes, bmr, tdee, calorie_goal AS calorieGoal,
      goal_delta AS goalDelta, bmi_value AS bmiValue, bmi_label AS bmiLabel, protein_grams AS proteinGrams,
      protein_calories AS proteinCalories, protein_pct AS proteinPct, carbs_grams AS carbsGrams,
      carbs_calories AS carbsCalories, carbs_pct AS carbsPct, fat_grams AS fatGrams,
      fat_calories AS fatCalories, fat_pct AS fatPct, exercise_label AS exerciseLabel,
      burned_calories AS burnedCalories, fat_equivalent_grams AS fatEquivalentGrams
      FROM dbo.MemberNutritionProfiles FOR JSON PATH;`),
  ]);

  const planMap = byId(plans);
  for (const feature of planFeatures) {
    const plan = planMap.get(feature.planId);
    if (plan) {
      plan.features ??= [];
      plan.features.push({ label: feature.label, included: Boolean(feature.included) });
    }
  }

  const members = membersRaw.map((member) => ({
    id: member.id,
    name: member.name,
    email: member.email,
    initials: member.initials,
    role: member.role,
    status: member.status,
    tier: member.tier,
    gender: member.gender,
    age: member.age,
    weightKg: Number(member.weightKg),
    heightCm: Number(member.heightCm),
    activityLevel: member.activityLevel,
    goal: member.goal,
    joinedAt: member.joinedAt,
    calorieTarget: member.calorieTarget,
    macroTargets: {
      protein: Number(member.proteinTarget),
      carbs: Number(member.carbsTarget),
      fat: Number(member.fatTarget),
    },
    waterTargetGlasses: member.waterTargetGlasses,
    nutritionProfile: nutritionProfilesRaw
      .filter((item) => item.memberId === member.id)
      .map((item) => ({
        updatedAt: item.updatedAt,
        input: {
          age: Number(item.age),
          weightKg: Number(item.weightKg),
          heightCm: Number(item.heightCm),
          gender: item.gender,
          activityLevel: item.activityLevel,
          goal: item.goal,
          exerciseType: item.exerciseType,
          durationMinutes: Number(item.durationMinutes),
        },
        results: {
          bmr: Number(item.bmr),
          tdee: Number(item.tdee),
          calorieGoal: Number(item.calorieGoal),
          goalDelta: Number(item.goalDelta),
          bmi: {
            value: Number(item.bmiValue),
            label: item.bmiLabel,
          },
          macros: [
            { name: "Protein", grams: Number(item.proteinGrams), calories: Number(item.proteinCalories), pct: Number(item.proteinPct) },
            { name: "Carbs", grams: Number(item.carbsGrams), calories: Number(item.carbsCalories), pct: Number(item.carbsPct) },
            { name: "Chất béo", grams: Number(item.fatGrams), calories: Number(item.fatCalories), pct: Number(item.fatPct) },
          ],
          exercise: {
            label: item.exerciseLabel,
            burnedCalories: Number(item.burnedCalories),
            fatEquivalentGrams: Number(item.fatEquivalentGrams),
          },
        },
      }))
      .at(0) || null,
    subscription: subscriptions.find((subscription) => subscription.memberId === member.id) ?? null,
    stats: {
      memberDays: member.memberDays,
      savedRecipes: member.savedRecipes,
      aiConversations: member.aiConversations,
      trackedCalories: member.trackedCalories,
      streakDays: member.streakDays,
    },
  }));

  const mealLogs = mealLogsRaw.map((log) => {
    const workouts = workoutEntries
      .filter((workout) => workout.mealLogId === log.id)
      .map((workout) => ({
        id: workout.id,
        type: workout.type,
        label: workout.label,
        durationMinutes: Number(workout.durationMinutes),
        calories: Number(workout.calories),
        met: workout.met === null || workout.met === undefined ? null : Number(workout.met),
        intensity: workout.intensity,
        distanceKm: workout.distanceKm === null || workout.distanceKm === undefined ? null : Number(workout.distanceKm),
        speedKmh: workout.speedKmh === null || workout.speedKmh === undefined ? null : Number(workout.speedKmh),
        inclinePct: workout.inclinePct === null || workout.inclinePct === undefined ? null : Number(workout.inclinePct),
        source: workout.source,
        confidence: workout.confidence,
        note: workout.note,
        assumptions: parseJsonArray(workout.assumptionsJson),
        userNotes: workout.userNotes,
        recordedAt: workout.recordedAt,
      }));
    const workoutCalories = workouts.reduce((sum, workout) => sum + (Number(workout.calories) || 0), 0);
    const workoutMinutes = workouts.reduce((sum, workout) => sum + (Number(workout.durationMinutes) || 0), 0);
    return {
      id: log.id,
      memberId: log.memberId,
      date: log.date,
      waterGlasses: log.waterGlasses,
      activity: {
        steps: log.steps,
        burnedCalories: log.burnedCalories,
        activeMinutes: log.activeMinutes,
        manualBurnedCalories: Math.max(0, Number(log.burnedCalories || 0) - workoutCalories),
        manualActiveMinutes: Math.max(0, Number(log.activeMinutes || 0) - workoutMinutes),
        workoutCalories,
        workoutMinutes,
        workouts,
      },
      goals: goals
        .filter((goal) => goal.mealLogId === log.id)
        .map((goal) => ({ id: goal.id, label: goal.label, done: Boolean(goal.done) })),
      meals: mealSections
        .filter((section) => section.mealLogId === log.id)
        .map((section) => ({
          id: section.id,
          name: section.name,
          icon: section.icon,
          targetKcal: section.targetKcal,
          time: section.time,
          items: mealItems
            .filter((item) => item.mealLogId === log.id && item.mealSectionId === section.id)
            .map((item) => ({
              id: item.id,
              foodId: item.foodId,
              name: item.name,
              calories: Number(item.calories),
              protein: Number(item.protein),
              carbs: Number(item.carbs),
              fat: Number(item.fat),
              portion: item.portion,
              quantity: Number(item.quantity),
            })),
        })),
    };
  });

  const recipes = recipesRaw.map((recipe) => ({
    id: recipe.id,
    name: recipe.name,
    image: recipe.image,
    timeMinutes: recipe.timeMinutes,
    calories: recipe.calories,
    difficulty: recipe.difficulty,
    servings: recipe.servings,
    tags: recipeTags.filter((item) => item.recipeId === recipe.id).map((item) => item.tag),
    ingredients: recipeIngredients
      .filter((item) => item.recipeId === recipe.id)
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map((item) => ({ name: item.name, amount: item.amount })),
    steps: recipeSteps
      .filter((item) => item.recipeId === recipe.id)
      .sort((a, b) => a.stepOrder - b.stepOrder)
      .map((item) => item.instruction),
    nutrition: {
      protein: Number(recipe.protein),
      carbs: Number(recipe.carbs),
      fat: Number(recipe.fat),
      fiber: Number(recipe.fiber),
    },
  }));

  const cannedResponses = {};
  for (const item of cannedResponsesRaw) cannedResponses[item.prompt] = item.response;

  return {
    meta: {
      name: "NutriPath API",
      version: "1.0.0",
      source: "sqlserver",
      loadedAt: new Date().toISOString(),
    },
    activityLevels,
    exerciseTypes,
    members,
    foods,
    mealLogs,
    weeklyProgress,
    recipes,
    plans,
    faqs: faqsRaw,
    payments: paymentsRaw,
    authCredentials: authCredentialsRaw,
    chat: {
      quickReplies: quickRepliesRaw.map((item) => item.text),
      cannedResponses,
    },
    admin: {
      users: adminUsers,
      kpis: adminKpis,
      systemServices,
      aiSettings: aiSettingsRows[0] ?? {},
      security: {
        twoFactorEnabled: Boolean(securityRows[0]?.twoFactorEnabled),
        passwordPolicy: {
          minLength: securityRows[0]?.minPasswordLength ?? 8,
          requireSpecialChar: Boolean(securityRows[0]?.requireSpecialChar),
          requireUppercase: Boolean(securityRows[0]?.requireUppercase),
          requireNumber: Boolean(securityRows[0]?.requireNumber),
        },
        loginActivity,
      },
    },
  };
}
