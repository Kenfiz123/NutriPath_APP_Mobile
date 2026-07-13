export function registerRecipesRoutes(ctx) {
  const {
    CUSTOM_FOOD_UNITS,
    VIETNAM_NUTRITION_INGREDIENTS,
    addDays,
    adminColorForMember,
    apiLinks,
    applyChatIntent,
    applyNutritionCalculationToMember,
    applyWaterEquivalent,
    assertMealItemQuota,
    assertMealLogAccess,
    assertMemberSessionAccess,
    assertNumberInRange,
    authSessionResponse,
    badRequest,
    buildAdminOverview,
    buildAdvancedNutritionContext,
    buildCalculationWarnings,
    buildDashboardAchievements,
    buildDashboardTips,
    buildNutritionProfile,
    buildNutritionReport,
    buildPersonalizedRecipePrompt,
    buildQuote,
    buildReportCsv,
    buildSafeChatHistoryContext,
    buildSafeNutritionContext,
    buildSvipCalorieInsightPrompt,
    buildSvipFoodPhotoRefinementPrompt,
    buildWeeklyCoachPlan,
    buildWeeklyProgress,
    calculateCalories,
    callAiProviderForText,
    callGeminiProvider,
    callGeminiVisionProvider,
    callGroqProvider,
    callOpenAiCompatibleProvider,
    canUseAdvancedAiContext,
    cannedChatResponse,
    chatBlockMessage,
    chatHistoryResource,
    collectionResponse,
    conflict,
    countTrackedMealDays,
    csvValue,
    currentLink,
    customFoodResource,
    dateToUtcDay,
    daysBetweenDates,
    earliestDateString,
    enforceSafeChatRateLimit,
    ensureAuthCredentials,
    ensureChatHistory,
    ensureCoachPlans,
    ensureMealLog,
    ensureNotifications,
    ensurePersonalFoods,
    ensurePersonalizedRecipes,
    errorResponse,
    estimateCustomCookedFood,
    estimateFoodPhotoCalories,
    extractGeminiText,
    extractJsonObject,
    extractMillilitersFromPortion,
    findCredentialByEmail,
    findMemberByEmail,
    foodResource,
    forbidden,
    geminiQuotaMessage,
    generatePersonalizedRecipe,
    generateSafeGeminiChatResponse,
    generateSvipCalorieInsight,
    getActiveSession,
    getAdminUsersData,
    getAiProviders,
    getBearerToken,
    getChatAdminKey,
    getClientIp,
    getDrinkWaterEquivalentGlasses,
    getFatPct,
    getFood,
    getGeminiRateState,
    getGoalDelta,
    getMealHistoryDayDelta,
    getMealItemCount,
    getMember,
    getMemberChatHistory,
    getMembershipAccess,
    getNormalizedTier,
    getPersonalizedRecipeQuestions,
    getPlan,
    getPlanPayments,
    getProteinPerKg,
    getRecipe,
    getRecipeImageUrl,
    getSafeCalorieMinimum,
    getSafeChatLimits,
    getSafeChatQuickReplies,
    getSafeChatTier,
    getSubscriptionSnapshot,
    hashPassword,
    initialsFromName,
    insertSqlServerAuthMember,
    insertSqlServerCredential,
    isChatAdminKey,
    isSameLocalDate,
    isTruthyQuery,
    link,
    loadEnvFile,
    localizePersonalizedRecipe,
    localizePersonalizedRecipeText,
    logDangerousChat,
    makeEmptyReportLog,
    matchRoute,
    mealLogResource,
    memberFromRegistration,
    memberResource,
    normalizeChatIntent,
    normalizeEmail,
    normalizeFoodPhotoEstimate,
    normalizeForPolicy,
    normalizeIngredient,
    normalizeMealLogLabels,
    normalizePath,
    normalizePersonalizedRecipe,
    normalizeSvipCalorieInsight,
    normalizeVietnameseText,
    notFound,
    notificationResource,
    paginateItems,
    parseCalorieGoalIntentFromText,
    parseChatIntent,
    parseDate,
    parseFoodPhotoImage,
    paymentResource,
    personalizedRecipeResource,
    planLabel,
    planResource,
    readBody,
    recipeResource,
    redactSensitiveText,
    refineFoodPhotoEstimateForSvip,
    releaseGeminiQuota,
    reportDateRange,
    requireAdminSession,
    requireFields,
    requireSession,
    reserveGeminiQuota,
    roleLabel,
    round,
    route,
    safeCannedChatResponse,
    saveMealLogChanges,
    saveMemberChatMessages,
    saveMemberNutritionProfile,
    savePersonalizedRecipe,
    saveSqlServerMealLog,
    saveSqlServerMemberNutritionProfile,
    saveSqlServerPaymentAndSubscription,
    sendJson,
    serviceUnavailable,
    sessions,
    splitPath,
    startOfWeek,
    summarizeMealLog,
    syncMemberNotifications,
    toLocalDateString,
    tooManyRequests,
    unauthorized,
    updateMemberDailyCalorieGoal,
    updateSqlServerMemberCalorieGoal,
    updateWaterGoalStatus,
    upsertNotification,
    validateSafeChatInput,
    validateSafeChatOutput,
    verifyPassword
  } = ctx;

  route("GET", "/api/members/:memberId/personalized-recipes", async ({ req, store, params }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const recipes = ensurePersonalizedRecipes(store.db)
      .filter((recipe) => recipe.memberId === member.id)
      .sort((a, b) => String(b.savedAt || b.generatedAt || "").localeCompare(String(a.savedAt || a.generatedAt || "")));

    return collectionResponse(req, "recipes", recipes, {
      path: `/api/members/${member.id}/personalized-recipes`,
      itemMapper: (recipe) => personalizedRecipeResource(req, recipe),
      links: {
        member: link(req, `/api/members/${member.id}`),
        generate: link(req, "/api/ai/personalized-recipes", "POST"),
      },
    });
  });

  route("GET", "/api/members/:memberId/personalized-recipes/:recipeId", async ({ req, store, params }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const recipe = ensurePersonalizedRecipes(store.db).find((item) => item.memberId === member.id && item.id === params.recipeId);
    if (!recipe) notFound(req, "Personalized recipe not found.");
    return personalizedRecipeResource(req, recipe);
  });

  route("GET", "/api/recipes", async ({ req, store, url }) => {
    const activeSession = getActiveSession(req, store);
    const access = getMembershipAccess(activeSession?.member || null);
    const search = (url.searchParams.get("search") || "").toLowerCase();
    const tag = url.searchParams.get("tag");
    const maxCalories = Number(url.searchParams.get("maxCalories") || 0);
    const difficulty = Number(url.searchParams.get("difficulty") || 0);
    const filteredRecipes = store.db.recipes.filter((recipe) => {
      const matchSearch = !search || recipe.name.toLowerCase().includes(search)
        || recipe.ingredients.some((ingredient) => ingredient.name.toLowerCase().includes(search));
      const matchTag = !tag || tag === "Tất cả" || recipe.tags.includes(tag);
      const matchCalories = !maxCalories || recipe.calories <= maxCalories;
      const matchDifficulty = !difficulty || recipe.difficulty === difficulty;
      return matchSearch && matchTag && matchCalories && matchDifficulty;
    });
    const accessibleRecipes = access.recipeLimit ? filteredRecipes.slice(0, access.recipeLimit) : filteredRecipes;
    const page = paginateItems(url, accessibleRecipes, { defaultLimit: 24, maxLimit: 100 });
    const tags = [...new Set(store.db.recipes.flatMap((recipe) => recipe.tags))].sort();
    return collectionResponse(req, "recipes", page.items, {
      itemMapper: (recipe) => recipeResource(req, recipe),
      links: { create: link(req, "/api/recipes", "POST") },
      meta: {
        filters: { search, tag, maxCalories: maxCalories || null, difficulty: difficulty || null },
        tags,
        pagination: {
          page: page.page,
          limit: page.limit,
          total: page.total,
          totalPages: page.totalPages,
        },
        access: {
          tier: access.tier,
          recipeLimit: access.recipeLimit,
          totalAvailable: filteredRecipes.length,
          upgradeRequired: Boolean(access.recipeLimit && filteredRecipes.length > accessibleRecipes.length),
        },
      },
    });
  });

  route("POST", "/api/recipes", async ({ req, store, body }) => {
    requireFields(body, ["name", "calories", "timeMinutes", "servings"]);
    const recipe = {
      id: store.nextId("recipe", store.db.recipes),
      name: body.name,
      image: body.image || "",
      timeMinutes: Number(body.timeMinutes),
      calories: Number(body.calories),
      difficulty: Number(body.difficulty || 1),
      tags: Array.isArray(body.tags) ? body.tags : [],
      servings: Number(body.servings),
      ingredients: Array.isArray(body.ingredients) ? body.ingredients : [],
      steps: Array.isArray(body.steps) ? body.steps : [],
      nutrition: body.nutrition || { protein: 0, carbs: 0, fat: 0, fiber: 0 },
    };
    store.db.recipes.push(recipe);
    await store.saveRecipe(recipe);
    return recipeResource(req, recipe);
  });

  route("POST", "/api/ai/personalized-recipes", async ({ req, store, body }) => {
    const active = requireSession(req, store);
    const member = active.member;
    const access = getMembershipAccess(member);
    if (!access.aiCoach) {
      forbidden("Công thức cá nhân hóa do AI tạo chỉ mở cho gói SVIP.", {
        requiredTier: "svip",
        tier: access.tier,
      });
    }

    const prompt = String(body.prompt || "").trim();
    const answers = body.answers && typeof body.answers === "object" ? body.answers : {};
    if (!prompt && Object.keys(answers).length === 0) {
      badRequest("Vui lòng nhập mục tiêu hoặc trả lời câu hỏi cá nhân hóa.");
    }

    const questions = getPersonalizedRecipeQuestions(prompt, answers);
    if (questions.length) {
      return {
        status: "needs_questions",
        questions,
        message: "Mình cần thêm vài thông tin để cá nhân hóa công thức rõ hơn.",
        _links: {
          self: currentLink(req),
          generate: link(req, "/api/ai/personalized-recipes", "POST"),
        },
      };
    }

    const generatedRecipe = await generatePersonalizedRecipe(store, member, prompt, answers);
    const recipe = savePersonalizedRecipe(store, member, generatedRecipe);
    await store.savePersonalizedRecipe(recipe);
    await store.saveMember(member);
    return {
      status: "recipe",
      recipe: personalizedRecipeResource(req, recipe),
      _links: {
        self: currentLink(req),
        recipes: link(req, "/api/recipes"),
        savedRecipes: link(req, `/api/members/${member.id}/personalized-recipes`),
        chat: link(req, "/api/chat/messages", "POST"),
      },
    };
  });

  route("POST", "/api/ai/coach-weekly-plan", async ({ req, store, body }) => {
    const { member } = requireSession(req, store);
    const access = getMembershipAccess(member);
    if (!access.aiCoach) {
      forbidden("AI Coach kế hoạch tuần chỉ dành cho gói SVIP.", {
        requiredTier: "svip",
        tier: access.tier,
      });
    }
    const plan = buildWeeklyCoachPlan(store, member, { startDate: body.startDate, req });
    ensureCoachPlans(store.db).unshift(plan);
    const notification = upsertNotification(store, member.id, "weekly-coach-plan", "AI Coach đã tạo kế hoạch tuần", `Kế hoạch từ ${plan.startDate} đến ${plan.endDate} đã sẵn sàng trên dashboard.`, {
      key: `${member.id}:weekly-coach-plan:${plan.startDate}`,
      actionHref: "/dashboard",
      priority: "high",
    });
    await store.saveCoachPlan(plan);
    await store.saveNotification(notification);
    return {
      plan,
      _links: {
        self: currentLink(req),
        dashboard: link(req, `/api/members/${member.id}/dashboard`),
      },
    };
  });

  route("GET", "/api/members/:memberId/coach-plans", async ({ req, store, params }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const plans = ensureCoachPlans(store.db)
      .filter((plan) => plan.memberId === member.id)
      .sort((a, b) => String(b.generatedAt || "").localeCompare(String(a.generatedAt || "")));
    return collectionResponse(req, "coachPlans", plans, {
      links: {
        create: link(req, "/api/ai/coach-weekly-plan", "POST"),
        member: link(req, `/api/members/${member.id}`),
      },
    });
  });

  route("GET", "/api/recipes/:id", async ({ req, store, params }) => {
    const recipe = getRecipe(store.db, params.id);
    if (!recipe) notFound(req, "Recipe not found.");
    return recipeResource(req, recipe);
  });

  route("PATCH", "/api/recipes/:id", async ({ req, store, params, body }) => {
    const recipe = getRecipe(store.db, params.id);
    if (!recipe) notFound(req, "Recipe not found.");
    Object.assign(recipe, body, { id: recipe.id });
    await store.saveRecipe(recipe);
    return recipeResource(req, recipe);
  });

  route("DELETE", "/api/recipes/:id", async ({ req, store, params }) => {
    const before = store.db.recipes.length;
    store.db.recipes = store.db.recipes.filter((recipe) => recipe.id !== params.id);
    if (store.db.recipes.length === before) notFound(req, "Recipe not found.");
    await store.deleteRecipe(params.id);
    return { deleted: params.id, _links: { collection: link(req, "/api/recipes") } };
  });
}
