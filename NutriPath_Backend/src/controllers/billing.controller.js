import crypto from "node:crypto";

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

  const ZERO_DECIMAL_CURRENCIES = new Set([
    "bif", "clp", "djf", "gnf", "jpy", "kmf", "krw", "mga", "pyg", "rwf",
    "ugx", "vnd", "vuv", "xaf", "xof", "xpf",
  ]);

  function stripeSecretKey() {
    return String(process.env.STRIPE_SECRET_KEY || "").trim();
  }

  function stripePublishableKey() {
    return String(process.env.STRIPE_PUBLISHABLE_KEY || "").trim();
  }

  function stripeWebhookSecret() {
    return String(process.env.STRIPE_WEBHOOK_SECRET || "").trim();
  }

  function requestOrigin(req) {
    const proto = String(req.headers["x-forwarded-proto"] || "http").split(",")[0].trim();
    const host = String(req.headers["x-forwarded-host"] || req.headers.host || "127.0.0.1:8080").split(",")[0].trim();
    return `${proto}://${host}`;
  }

  function stripeReturnUrl(req, path, override) {
    const value = String(override || "").trim();
    if (/^https?:\/\//i.test(value)) return value;
    const configured = String(process.env[path === "success" ? "STRIPE_CHECKOUT_SUCCESS_URL" : "STRIPE_CHECKOUT_CANCEL_URL"] || "").trim();
    if (/^https?:\/\//i.test(configured)) return configured;
    return `${requestOrigin(req)}/api/stripe/checkout/${path}${path === "success" ? "?session_id={CHECKOUT_SESSION_ID}" : ""}`;
  }

  function toStripeMinorAmount(amount, currency) {
    const normalizedCurrency = String(currency || "vnd").toLowerCase();
    const number = Number(amount) || 0;
    return ZERO_DECIMAL_CURRENCIES.has(normalizedCurrency)
      ? Math.round(number)
      : Math.round(number * 100);
  }

  function stripePaymentId(stripeRef, store) {
    const suffix = String(stripeRef || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(-36);
    return suffix ? `pay-${suffix}` : store.nextId("pay", store.db.payments);
  }

  function findProcessedStripePayment(store, stripeRef) {
    const id = stripePaymentId(stripeRef, store);
    return store.db.payments.find((payment) => (
      payment.id === id
      || payment.stripeSessionId === stripeRef
      || payment.stripePaymentIntentId === stripeRef
    ));
  }

  async function stripeRequest(path, params) {
    const key = stripeSecretKey();
    if (!key) serviceUnavailable("Backend chÆ°a cáº¥u hÃ¬nh STRIPE_SECRET_KEY.");
    const response = await fetch(`https://api.stripe.com/v1${path}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params,
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      serviceUnavailable(payload?.error?.message || "Stripe request failed.", {
        status: response.status,
        stripeError: payload?.error || payload,
      });
    }
    return payload;
  }

  async function retrieveStripeCheckoutSession(sessionId) {
    const key = stripeSecretKey();
    if (!key) serviceUnavailable("Backend chÆ°a cáº¥u hÃ¬nh STRIPE_SECRET_KEY.");
    const response = await fetch(`https://api.stripe.com/v1/checkout/sessions/${encodeURIComponent(sessionId)}`, {
      headers: { Authorization: `Bearer ${key}` },
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      serviceUnavailable(payload?.error?.message || "KhÃ´ng thá»ƒ Ä‘á»c Stripe Checkout Session.", {
        status: response.status,
        stripeError: payload?.error || payload,
      });
    }
    return payload;
  }

  async function retrieveStripePaymentIntent(paymentIntentId) {
    const key = stripeSecretKey();
    if (!key) serviceUnavailable("Backend chua cau hinh STRIPE_SECRET_KEY.");
    const response = await fetch(`https://api.stripe.com/v1/payment_intents/${encodeURIComponent(paymentIntentId)}`, {
      headers: { Authorization: `Bearer ${key}` },
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      serviceUnavailable(payload?.error?.message || "Khong the doc Stripe PaymentIntent.", {
        status: response.status,
        stripeError: payload?.error || payload,
      });
    }
    return payload;
  }

  function verifyStripeWebhookSignature(rawBody, signatureHeader) {
    const secret = stripeWebhookSecret();
    if (!secret) serviceUnavailable("Backend chÆ°a cáº¥u hÃ¬nh STRIPE_WEBHOOK_SECRET.");
    if (!rawBody || !signatureHeader) unauthorized("Stripe webhook signature missing.");
    const parts = String(signatureHeader).split(",").reduce((acc, item) => {
      const [key, value] = item.split("=");
      if (!key || !value) return acc;
      acc[key.trim()] = [...(acc[key.trim()] || []), value.trim()];
      return acc;
    }, {});
    const timestamp = Number(parts.t?.[0]);
    if (!Number.isFinite(timestamp)) unauthorized("Stripe webhook timestamp invalid.");
    const toleranceSeconds = Number(process.env.STRIPE_WEBHOOK_TOLERANCE_SECONDS || 300);
    if (Math.abs(Math.floor(Date.now() / 1000) - timestamp) > toleranceSeconds) {
      unauthorized("Stripe webhook timestamp expired.");
    }
    const expected = crypto.createHmac("sha256", secret).update(`${timestamp}.${rawBody}`, "utf8").digest("hex");
    const expectedBuffer = Buffer.from(expected, "hex");
    const signatures = parts.v1 || [];
    const valid = signatures.some((signature) => {
      const signatureBuffer = Buffer.from(signature, "hex");
      return signatureBuffer.length === expectedBuffer.length && crypto.timingSafeEqual(signatureBuffer, expectedBuffer);
    });
    if (!valid) unauthorized("Stripe webhook signature invalid.");
  }

  async function activateMembershipPayment({
    req,
    store,
    member,
    plan,
    body,
    quote,
    paymentMethod,
    stripeSession,
    stripePaymentIntent,
  }) {
    const stripeRef = stripePaymentIntent?.id || stripeSession?.id;
    const existingStripePayment = stripeRef ? findProcessedStripePayment(store, stripeRef) : null;
    if (existingStripePayment) {
      const currentMember = getMember(store.db, existingStripePayment.memberId) || member;
      return {
        payment: existingStripePayment,
        member: currentMember,
        quote,
        alreadyProcessed: true,
      };
    }

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
      id: stripeRef ? stripePaymentId(stripeRef, store) : store.nextId("pay", store.db.payments),
      memberId: member.id,
      invoice: stripeRef ? `STRIPE-${String(stripeRef).slice(-10).toUpperCase()}` : `INV-${now.getFullYear()}-${String(store.db.payments.length + 1).padStart(4, "0")}`,
      planId: plan.id,
      billing: body.billing,
      paymentMethod,
      amount: quote.total,
      currency: quote.currency || "VND",
      status: trialDays ? "trial" : "paid",
      paidAt: now.toISOString(),
      provider: stripeRef ? "stripe" : "demo",
      stripeSessionId: stripeSession?.id,
      stripePaymentIntentId: stripePaymentIntent?.id || stripeSession?.payment_intent,
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
      await store.savePayment(payment);
      await store.saveMember(member);
      await store.saveNotificationsForMember(member.id);
    }

    return { payment, member, quote, alreadyProcessed: false };
  }

  async function fulfillStripeCheckoutSession({ req, store, session }) {
    if (!session?.id) badRequest("Stripe Checkout Session khÃ´ng há»£p lá»‡.");
    const metadata = session.metadata || {};
    const member = getMember(store.db, metadata.memberId);
    if (!member) notFound(req, "Member not found.");
    const plan = getPlan(store.db, metadata.planId);
    if (!plan) notFound(req, "Plan not found.");
    const body = {
      memberId: member.id,
      planId: plan.id,
      billing: metadata.billing,
      discountCode: metadata.discountCode || "",
      trialDays: Number(metadata.trialDays || 0),
    };
    const quote = buildQuote(store.db, body);
    const currency = String(session.currency || quote.currency || "vnd").toLowerCase();
    const expectedAmount = toStripeMinorAmount(quote.total, currency);
    if (Number(session.amount_total) !== expectedAmount) {
      conflict("Stripe amount_total khÃ´ng khá»›p vá»›i bÃ¡o giÃ¡ backend.", {
        expectedAmount,
        stripeAmount: session.amount_total,
        currency,
      });
    }
    const paid = session.payment_status === "paid" || Number(session.amount_total) === 0;
    if (!paid) {
      return {
        status: "pending",
        paymentStatus: session.payment_status || "unpaid",
        quote,
      };
    }
    const result = await activateMembershipPayment({
      req,
      store,
      member,
      plan,
      body,
      quote,
      paymentMethod: "stripe_checkout",
      stripeSession: session,
    });
    return {
      status: "paid",
      paymentStatus: session.payment_status,
      ...result,
    };
  }

  async function fulfillStripePaymentIntent({ req, store, paymentIntent }) {
    if (!paymentIntent?.id) badRequest("Stripe PaymentIntent khong hop le.");
    const metadata = paymentIntent.metadata || {};
    const member = getMember(store.db, metadata.memberId);
    if (!member) notFound(req, "Member not found.");
    const plan = getPlan(store.db, metadata.planId);
    if (!plan) notFound(req, "Plan not found.");
    const body = {
      memberId: member.id,
      planId: plan.id,
      billing: metadata.billing,
      discountCode: metadata.discountCode || "",
      trialDays: Number(metadata.trialDays || 0),
    };
    const quote = buildQuote(store.db, body);
    const currency = String(paymentIntent.currency || quote.currency || "vnd").toLowerCase();
    const expectedAmount = toStripeMinorAmount(quote.total, currency);
    if (Number(paymentIntent.amount) !== expectedAmount) {
      conflict("Stripe PaymentIntent amount khong khop voi bao gia backend.", {
        expectedAmount,
        stripeAmount: paymentIntent.amount,
        currency,
      });
    }
    const paid = paymentIntent.status === "succeeded" && Number(paymentIntent.amount_received || 0) >= expectedAmount;
    if (!paid) {
      return {
        status: "pending",
        paymentStatus: paymentIntent.status || "requires_payment_method",
        quote,
      };
    }
    const result = await activateMembershipPayment({
      req,
      store,
      member,
      plan,
      body,
      quote,
      paymentMethod: "stripe_payment_sheet",
      stripePaymentIntent: paymentIntent,
    });
    return {
      status: "paid",
      paymentStatus: paymentIntent.status,
      ...result,
    };
  }

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
      stripePaymentIntent: link(req, "/api/stripe/payment-intents", "POST"),
      stripeCheckout: link(req, "/api/stripe/checkout-sessions", "POST"),
    },
  }));

  route("POST", "/api/stripe/payment-intents", async ({ req, store, body }) => {
    const { member: sessionMember } = requireSession(req, store);
    const memberId = body.memberId || sessionMember.id;
    let member = getMember(store.db, memberId);
    if (!member) notFound(req, "Member not found.");
    if (sessionMember.id !== member.id && sessionMember.role?.toLowerCase() !== "admin") {
      forbidden("You cannot pay for another member.");
    }
    requireFields(body, ["planId", "billing"]);
    const plan = getPlan(store.db, body.planId);
    if (!plan) notFound(req, "Plan not found.");
    if (plan.id === "free") badRequest("Free plan does not require Stripe payment.");
    const quote = buildQuote(store.db, { ...body, memberId: member.id });
    if (quote.total <= 0) {
      const result = await activateMembershipPayment({
        req,
        store,
        member,
        plan,
        body: { ...body, memberId: member.id },
        quote,
        paymentMethod: "stripe_trial",
      });
      return {
        status: "activated",
        paymentIntentId: null,
        clientSecret: null,
        quote,
        payment: paymentResource(req, result.payment),
        member: memberResource(req, result.member, store.db),
        _links: {
          profile: link(req, `/api/members/${result.member.id}/profile`),
          dashboard: link(req, `/api/members/${result.member.id}/dashboard`),
        },
      };
    }

    const publishableKey = stripePublishableKey();
    if (!publishableKey) serviceUnavailable("Backend chua cau hinh STRIPE_PUBLISHABLE_KEY.");
    const currency = String(quote.currency || "vnd").toLowerCase();
    const params = new URLSearchParams();
    params.set("amount", String(toStripeMinorAmount(quote.total, currency)));
    params.set("currency", currency);
    params.set("payment_method_types[0]", "card");
    params.set("description", `NutriPath ${plan.name} ${quote.billing === "annual" ? "annual" : "monthly"} membership`);
    if (member.email) params.set("receipt_email", member.email);
    params.set("metadata[source]", "payment_sheet");
    params.set("metadata[memberId]", member.id);
    params.set("metadata[planId]", plan.id);
    params.set("metadata[billing]", quote.billing);
    params.set("metadata[discountCode]", quote.discountCode || "");
    params.set("metadata[trialDays]", String(quote.trialDays || 0));
    params.set("metadata[quoteTotal]", String(quote.total));
    params.set("metadata[quoteCurrency]", quote.currency || "VND");

    const paymentIntent = await stripeRequest("/payment_intents", params);
    return {
      status: paymentIntent.status,
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      publishableKey,
      merchantDisplayName: process.env.STRIPE_MERCHANT_DISPLAY_NAME || "NutriPath",
      quote,
      _links: {
        self: link(req, `/api/stripe/payment-intents/${paymentIntent.id}`),
        profile: link(req, `/api/members/${member.id}/profile`),
      },
    };
  });

  route("POST", "/api/stripe/checkout-sessions", async ({ req, store, body }) => {
    const { member: sessionMember } = requireSession(req, store);
    const memberId = body.memberId || sessionMember.id;
    let member = getMember(store.db, memberId);
    if (!member) notFound(req, "Member not found.");
    if (sessionMember.id !== member.id && sessionMember.role?.toLowerCase() !== "admin") {
      forbidden("You cannot pay for another member.");
    }
    requireFields(body, ["planId", "billing"]);
    const plan = getPlan(store.db, body.planId);
    if (!plan) notFound(req, "Plan not found.");
    if (plan.id === "free") badRequest("Free plan does not require Stripe checkout.");
    const quote = buildQuote(store.db, { ...body, memberId: member.id });
    if (quote.total <= 0) {
      const result = await activateMembershipPayment({
        req,
        store,
        member,
        plan,
        body: { ...body, memberId: member.id },
        quote,
        paymentMethod: "stripe_trial",
      });
      return {
        status: "activated",
        checkoutUrl: null,
        sessionId: null,
        quote,
        payment: paymentResource(req, result.payment),
        member: memberResource(req, result.member, store.db),
        _links: {
          profile: link(req, `/api/members/${result.member.id}/profile`),
          dashboard: link(req, `/api/members/${result.member.id}/dashboard`),
        },
      };
    }

    const currency = String(quote.currency || "vnd").toLowerCase();
    const params = new URLSearchParams();
    params.set("mode", "payment");
    params.set("success_url", stripeReturnUrl(req, "success", body.successUrl));
    params.set("cancel_url", stripeReturnUrl(req, "cancel", body.cancelUrl));
    params.set("client_reference_id", `${member.id}:${plan.id}:${Date.now()}`);
    params.set("customer_email", member.email);
    params.set("line_items[0][quantity]", "1");
    params.set("line_items[0][price_data][currency]", currency);
    params.set("line_items[0][price_data][unit_amount]", String(toStripeMinorAmount(quote.total, currency)));
    params.set("line_items[0][price_data][product_data][name]", `NutriPath ${plan.name}`);
    params.set("line_items[0][price_data][product_data][description]", `${quote.billing === "annual" ? "Annual" : "Monthly"} membership`);
    params.set("metadata[memberId]", member.id);
    params.set("metadata[planId]", plan.id);
    params.set("metadata[billing]", quote.billing);
    params.set("metadata[discountCode]", quote.discountCode || "");
    params.set("metadata[trialDays]", String(quote.trialDays || 0));
    params.set("metadata[quoteTotal]", String(quote.total));
    params.set("metadata[quoteCurrency]", quote.currency || "VND");
    params.set("payment_intent_data[metadata][memberId]", member.id);
    params.set("payment_intent_data[metadata][planId]", plan.id);
    params.set("payment_intent_data[metadata][billing]", quote.billing);

    const session = await stripeRequest("/checkout/sessions", params);
    return {
      status: session.status || "open",
      sessionId: session.id,
      checkoutUrl: session.url,
      paymentStatus: session.payment_status,
      quote,
      publishableKey: process.env.STRIPE_PUBLISHABLE_KEY || null,
      _links: {
        self: link(req, `/api/stripe/checkout-sessions/${session.id}`),
        profile: link(req, `/api/members/${member.id}/profile`),
      },
    };
  });

  route("GET", "/api/stripe/payment-intents/:id", async ({ req, store, params }) => {
    const { member: sessionMember } = requireSession(req, store);
    const paymentIntent = await retrieveStripePaymentIntent(params.id);
    const metadata = paymentIntent.metadata || {};
    if (metadata.memberId && sessionMember.id !== metadata.memberId && sessionMember.role?.toLowerCase() !== "admin") {
      forbidden("You cannot view another member's Stripe payment.");
    }
    const result = await fulfillStripePaymentIntent({ req, store, paymentIntent });
    return {
      status: result.status,
      paymentStatus: result.paymentStatus,
      alreadyProcessed: Boolean(result.alreadyProcessed),
      quote: result.quote,
      payment: result.payment ? paymentResource(req, result.payment) : null,
      member: result.member ? memberResource(req, result.member, store.db) : null,
      _links: {
        profile: result.member ? link(req, `/api/members/${result.member.id}/profile`) : undefined,
      },
    };
  });

  route("GET", "/api/stripe/checkout-sessions/:id", async ({ req, store, params }) => {
    const { member: sessionMember } = requireSession(req, store);
    const session = await retrieveStripeCheckoutSession(params.id);
    const metadata = session.metadata || {};
    if (metadata.memberId && sessionMember.id !== metadata.memberId && sessionMember.role?.toLowerCase() !== "admin") {
      forbidden("You cannot view another member's Stripe checkout session.");
    }
    const result = await fulfillStripeCheckoutSession({ req, store, session });
    return {
      status: result.status,
      paymentStatus: result.paymentStatus,
      alreadyProcessed: Boolean(result.alreadyProcessed),
      quote: result.quote,
      payment: result.payment ? paymentResource(req, result.payment) : null,
      member: result.member ? memberResource(req, result.member, store.db) : null,
      _links: {
        profile: result.member ? link(req, `/api/members/${result.member.id}/profile`) : undefined,
      },
    };
  });

  route("POST", "/api/stripe/webhook", async ({ req, store, rawBody }) => {
    verifyStripeWebhookSignature(rawBody, req.headers["stripe-signature"]);
    let event;
    try {
      event = JSON.parse(rawBody);
    } catch {
      badRequest("Invalid Stripe webhook JSON.");
    }
    if (["checkout.session.completed", "checkout.session.async_payment_succeeded"].includes(event.type)) {
      const result = await fulfillStripeCheckoutSession({ req, store, session: event.data?.object });
      return {
        received: true,
        processed: result.status === "paid",
        alreadyProcessed: Boolean(result.alreadyProcessed),
      };
    }
    if (event.type === "payment_intent.succeeded") {
      const paymentIntent = event.data?.object;
      if (paymentIntent?.metadata?.source !== "payment_sheet") {
        return { received: true, ignored: event.type };
      }
      const result = await fulfillStripePaymentIntent({ req, store, paymentIntent });
      return {
        received: true,
        processed: result.status === "paid",
        alreadyProcessed: Boolean(result.alreadyProcessed),
      };
    }
    return { received: true, ignored: event.type };
  });

  route("GET", "/api/stripe/checkout/success", async ({ req, url }) => ({
    status: "success",
    sessionId: url.searchParams.get("session_id"),
    message: "Stripe received the payment. Return to NutriPath and verify the checkout session if needed.",
    _links: { api: link(req, "/api") },
  }));

  route("GET", "/api/stripe/checkout/cancel", async ({ req }) => ({
    status: "canceled",
    message: "Stripe checkout was canceled.",
    _links: { plans: link(req, "/api/plans") },
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
      await store.savePayment(payment);
      await store.saveMember(member);
      await store.saveNotificationsForMember(member.id);
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
