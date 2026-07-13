export function registerMembersRoutes(ctx) {
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
    createMealLogDraft,
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

  route("GET", "/api/members", async ({ req, store, url }) => {
    const search = (url.searchParams.get("search") || "").toLowerCase();
    const tier = url.searchParams.get("tier");
    const members = store.db.members.filter((member) => {
      const matchSearch = !search || member.name.toLowerCase().includes(search) || member.email.toLowerCase().includes(search);
      const matchTier = !tier || member.tier === tier;
      return matchSearch && matchTier;
    });

    return collectionResponse(req, "members", members, {
      itemMapper: (member) => memberResource(req, member, store.db),
      links: { create: link(req, "/api/members", "POST") },
      meta: { filters: { search, tier } },
    });
  });

  route("POST", "/api/members", async ({ req, store, body }) => {
    requireFields(body, ["name", "email"]);
    const member = {
      id: store.nextId("mem", store.db.members),
      name: body.name,
      email: body.email,
      initials: body.initials || body.name.split(" ").map((part) => part[0]).join("").slice(0, 2).toUpperCase(),
      role: "member",
      status: "active",
      tier: body.tier || "free",
      gender: body.gender || "female",
      age: Number(body.age || 25),
      weightKg: Number(body.weightKg || 65),
      heightCm: Number(body.heightCm || 168),
      activityLevel: body.activityLevel || "light",
      goal: body.goal || "maintain",
      joinedAt: new Date().toISOString().slice(0, 10),
      calorieTarget: Number(body.calorieTarget || 1800),
      macroTargets: body.macroTargets || { protein: 120, carbs: 220, fat: 60 },
      waterTargetGlasses: Number(body.waterTargetGlasses || 8),
      subscription: { planId: body.tier || "free", billing: "monthly", status: "active", startedAt: new Date().toISOString().slice(0, 10), renewsAt: null },
      stats: { memberDays: 0, savedRecipes: 0, aiConversations: 0, trackedCalories: 0, streakDays: 0 },
    };
    store.db.members.push(member);
    await store.saveMember(member);
    return memberResource(req, member, store.db);
  });

  route("GET", "/api/members/:id", async ({ req, store, params }) => {
    const member = getMember(store.db, params.id);
    if (!member) notFound(req, "Member not found.");
    return memberResource(req, member, store.db);
  });

  route("PATCH", "/api/members/:id", async ({ req, store, params, body }) => {
    const { sessionMember, member } = assertMemberSessionAccess(req, store, params.id);
    const isAdmin = sessionMember.role?.toLowerCase() === "admin";
    const allowed = new Set(isAdmin
      ? ["name", "email", "calorieTarget", "waterTargetGlasses", "role", "status", "tier", "subscription", "macroTargets"]
      : ["name", "email", "calorieTarget", "waterTargetGlasses"]);

    if (body.calorieTarget !== undefined) {
      const target = Number(body.calorieTarget);
      if (!Number.isFinite(target) || target < 1200 || target > 5000) badRequest("Mục tiêu calo phải nằm trong khoảng 1200-5000 kcal/ngày.");
      body.calorieTarget = Math.round(target);
    }
    if (body.waterTargetGlasses !== undefined) {
      const target = Number(body.waterTargetGlasses);
      if (!Number.isFinite(target) || target < 2 || target > 20) badRequest("Mục tiêu nước phải nằm trong khoảng 500-5000ml/ngày.");
      body.waterTargetGlasses = Math.round(target * 10) / 10;
    }

    for (const [key, value] of Object.entries(body || {})) {
      if (allowed.has(key)) member[key] = value;
    }
    if (body.name) member.initials = initialsFromName(member.name);
    await store.saveMember(member);
    return memberResource(req, member, store.db);
  });

  route("DELETE", "/api/members/:id", async ({ req, store, params }) => {
    const before = store.db.members.length;
    store.db.members = store.db.members.filter((member) => member.id !== params.id);
    if (store.db.members.length === before) notFound(req, "Member not found.");
    await store.deleteMember(params.id);
    return {
      deleted: params.id,
      _links: {
        collection: link(req, "/api/members"),
        api: link(req, "/api"),
      },
    };
  });

  route("GET", "/api/members/:memberId/profile", async ({ req, store, params }) => {
    const member = getMember(store.db, params.memberId);
    if (!member) notFound(req, "Member not found.");
    const plan = getPlan(store.db, member.subscription?.planId || member.tier);
    const payments = store.db.payments.filter((payment) => payment.memberId === member.id);
    return {
      member: memberResource(req, member, store.db),
      plan: plan ? planResource(req, plan) : null,
      benefits: plan?.features || [],
      billingHistory: payments.map((payment) => paymentResource(req, payment)),
      _links: {
        self: currentLink(req),
        member: link(req, `/api/members/${member.id}`),
        payments: link(req, `/api/members/${member.id}/payments`),
        plans: link(req, "/api/plans"),
        checkout: link(req, "/api/payments", "POST"),
      },
    };
  });

  route("GET", "/api/members/:memberId/notifications", async ({ req, store, params, url }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const notifications = syncMemberNotifications(store, member);
    const unreadOnly = url.searchParams.get("unread") === "true";
    const limit = Math.max(1, Math.min(Number(url.searchParams.get("limit") || 30), 100));
    const visible = notifications
      .filter((notification) => !unreadOnly || !notification.readAt)
      .slice(0, limit);
    return collectionResponse(req, "notifications", visible, {
      itemMapper: (notification) => notificationResource(req, notification),
      links: {
        member: link(req, `/api/members/${member.id}`),
        markAllRead: link(req, `/api/members/${member.id}/notifications/read-all`, "PATCH"),
      },
      meta: {
        unreadCount: notifications.filter((notification) => !notification.readAt).length,
        total: notifications.length,
      },
    });
  });

  route("PATCH", "/api/members/:memberId/notifications/read-all", async ({ req, store, params }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const now = new Date().toISOString();
    const notifications = ensureNotifications(store.db).filter((notification) => notification.memberId === member.id);
    for (const notification of notifications) {
      notification.readAt ||= now;
      notification.updatedAt = now;
    }
    await store.saveNotificationsForMember(member.id);
    return {
      updated: notifications.length,
      unreadCount: 0,
      _links: {
        notifications: link(req, `/api/members/${member.id}/notifications`),
      },
    };
  });

  route("PATCH", "/api/members/:memberId/notifications/:id", async ({ req, store, params, body }) => {
    const { member } = assertMemberSessionAccess(req, store, params.memberId);
    const notification = ensureNotifications(store.db).find((item) => item.memberId === member.id && item.id === params.id);
    if (!notification) notFound(req, "Notification not found.");
    const now = new Date().toISOString();
    if (body.read === false) {
      notification.readAt = null;
    } else {
      notification.readAt = now;
    }
    notification.updatedAt = now;
    await store.saveNotification(notification);
    return notificationResource(req, notification);
  });

  route("GET", "/api/members/:memberId/dashboard", async ({ req, store, params, url }) => {
    const member = getMember(store.db, params.memberId);
    if (!member) notFound(req, "Member not found.");
    const selectedDate = parseDate(url.searchParams.get("date")) || new Date();
    const date = toLocalDateString(selectedDate);
    assertMealLogAccess(member, date);
    const existingLog = store.db.mealLogs.find((entry) => entry.memberId === member.id && entry.date === date);
    const log = existingLog ? ensureMealLog(store, member.id, date) : createMealLogDraft(store, member.id, date);
    const summary = summarizeMealLog(log, member);

    return {
      date,
      greeting: `Xin chào, ${member.name}`,
      member: memberResource(req, member, store.db),
      nutrition: summary,
      mealLog: mealLogResource(req, log, member),
      weeklyProgress: buildWeeklyProgress(store.db, member, selectedDate),
      tips: buildDashboardTips(log, summary),
      achievements: buildDashboardAchievements(store.db, member, log, summary, selectedDate),
      _links: {
        self: currentLink(req),
        member: link(req, `/api/members/${member.id}`),
        mealLog: link(req, `/api/members/${member.id}/meal-logs/${date}`),
        foods: link(req, "/api/foods"),
        recipes: link(req, "/api/recipes"),
        chat: link(req, "/api/chat/messages", "POST"),
      },
    };
  });
}
