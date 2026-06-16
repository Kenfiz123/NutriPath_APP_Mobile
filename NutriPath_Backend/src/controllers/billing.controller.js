export function registerBillingRoutes(ctx) {
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

  route("GET", "/api/members/:memberId/payments", async ({ req, store, params }) => {
    const member = getMember(store.db, params.memberId);
    if (!member) notFound(req, "Member not found.");
    const payments = store.db.payments.filter((payment) => payment.memberId === member.id);
    return collectionResponse(req, "payments", payments, {
      itemMapper: (payment) => paymentResource(req, payment),
      links: { create: link(req, "/api/payments", "POST"), member: link(req, `/api/members/${member.id}`) },
    });
  });

  route("GET", "/api/plans", async ({ req, store, url }) => {
    const billing = url.searchParams.get("billing") || "monthly";
    const plans = store.db.plans.map((plan) => {
      const quoted = buildQuote(store.db, { planId: plan.id, billing: billing === "annual" ? "annual" : "monthly" });
      return { ...plan, pricePreview: quoted, _links: planResource(req, plan)._links };
    });
    return collectionResponse(req, "plans", plans, {
      itemMapper: (plan) => plan,
      meta: { billing },
      links: { quote: link(req, "/api/checkout/quote", "POST") },
    });
  });

  route("GET", "/api/plans/:id", async ({ req, store, params }) => {
    const plan = getPlan(store.db, params.id);
    if (!plan) notFound(req, "Plan not found.");
    return planResource(req, plan);
  });

  route("GET", "/api/faqs", async ({ req, store }) => collectionResponse(
    req,
    "faqs",
    store.db.faqs,
    { itemMapper: (faq) => ({ ...faq, _links: { self: link(req, `/api/faqs#${faq.id}`) } }) },
  ));

  route("POST", "/api/checkout/quote", async ({ req, store, body }) => ({
    quote: buildQuote(store.db, body),
    _links: {
      self: currentLink(req),
      plans: link(req, "/api/plans"),
      pay: link(req, "/api/payments", "POST"),
    },
  }));

  route("POST", "/api/payments", async ({ req, store, body }) => {
    const { member: sessionMember } = requireSession(req, store);
    requireFields(body, ["memberId", "planId", "billing", "paymentMethod"]);
    let member = getMember(store.db, body.memberId);
    if (!member) notFound(req, "Member not found.");
    if (sessionMember.id !== member.id && sessionMember.role?.toLowerCase() !== "admin") {
      forbidden("Bạn không được thanh toán thay cho thành viên này.");
    }
    const plan = getPlan(store.db, body.planId);
    if (!plan) notFound(req, "Plan not found.");
    const quote = buildQuote(store.db, body);
    const now = new Date();
    const todayString = toLocalDateString(now);
    const trialDays = quote.trialDays || 0;
    const existingSubscription = getSubscriptionSnapshot(store.db, member);
    const sameActivePlan = existingSubscription.planId === plan.id && ["active", "trialing"].includes(existingSubscription.status);
    const startedAt = sameActivePlan ? (existingSubscription.startedAt || todayString) : todayString;
    const currentRenewal = parseDate(existingSubscription.renewsAt);
    const renewalBase = !trialDays && sameActivePlan && currentRenewal && currentRenewal > parseDate(todayString)
      ? currentRenewal
      : now;
    const renews = new Date(renewalBase);
    if (trialDays) {
      renews.setDate(renews.getDate() + trialDays);
    } else {
      renews.setMonth(renews.getMonth() + (body.billing === "annual" ? 12 : 1));
    }
    const renewsAt = toLocalDateString(renews);
    const daysTotal = daysBetweenDates(startedAt, renewsAt) || trialDays || (body.billing === "annual" ? 365 : 30);
    const daysRemaining = Math.max(0, daysBetweenDates(todayString, renewsAt) ?? daysTotal);
    const payment = {
      id: store.nextId("pay", store.db.payments),
      memberId: member.id,
      invoice: `INV-${now.getFullYear()}-${String(store.db.payments.length + 1).padStart(4, "0")}`,
      planId: plan.id,
      billing: body.billing,
      paymentMethod: body.paymentMethod,
      amount: quote.total,
      currency: "VND",
      status: trialDays ? "trial" : "paid",
      paidAt: now.toISOString(),
    };
    member.tier = plan.id;
    member.subscription = {
      planId: plan.id,
      billing: body.billing,
      status: trialDays ? "trialing" : "active",
      startedAt,
      purchaseAt: startedAt,
      renewsAt,
      daysTotal,
      daysRemaining,
    };
    upsertNotification(store, member.id, "membership-payment", trialDays ? "Đã kích hoạt dùng thử" : "Gói thành viên đã được kích hoạt", `${plan.name} ${body.billing === "annual" ? "năm" : "tháng"} có hiệu lực đến ${renewsAt}.`, {
      key: `${member.id}:membership-payment:${payment.id}`,
      actionHref: "/member",
      priority: "high",
    });

    if (store.dataSource === "sqlserver") {
      await saveSqlServerPaymentAndSubscription(member, payment, member.subscription);
      await store.reload();
      member = getMember(store.db, body.memberId);
    } else {
      store.db.payments.unshift(payment);
      await store.save();
    }

    return {
      payment: paymentResource(req, payment),
      member: memberResource(req, member, store.db),
      quote,
      note: "Card number, CVV and other sensitive payment details are intentionally not stored.",
      _links: {
        self: link(req, `/api/payments/${payment.id}`),
        profile: link(req, `/api/members/${member.id}/profile`),
        dashboard: link(req, `/api/members/${member.id}/dashboard`),
      },
    };
  });

  route("GET", "/api/payments/:id", async ({ req, store, params }) => {
    const payment = store.db.payments.find((item) => item.id === params.id);
    if (!payment) notFound(req, "Payment not found.");
    return paymentResource(req, payment);
  });
}
