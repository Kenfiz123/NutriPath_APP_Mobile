import crypto from "node:crypto";
import { sendOtpEmail } from "../email.js";

export function registerAuthRoutes(ctx) {
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
    ensureMembers,
    ensureOAuthIdentities,
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
    verifyPassword,
    verifySupabaseAccessToken
  } = ctx;

  function queueOtpEmail(email, otpCode) {
    const delayMs = Math.max(0, Number(process.env.OTP_EMAIL_BACKGROUND_DELAY_MS || 3000));
    setTimeout(() => {
      sendOtpEmail({ email, otpCode }).catch((error) => {
        console.error("[EMAIL OTP] Background send failed:", error?.message || error);
      });
    }, delayMs);
  }

  route("POST", "/api/auth/register", async ({ req, store, body }) => {
    requireFields(body, ["name", "email", "password"]);
    const email = normalizeEmail(body.email);
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) badRequest("Email không hợp lệ.");

    const password = String(body.password);
    if (password.length < 6) badRequest("Mật khẩu cần ít nhất 6 ký tự.");

    const credentials = ensureAuthCredentials(store.db);
    const existingCredential = findCredentialByEmail(store.db, email);
    let member = findMemberByEmail(store.db, email);

    if (existingCredential) {
      const existingMember = getMember(store.db, existingCredential.memberId) || member;
      if (existingMember && existingMember.verified === false) {
        existingMember.name = String(body.name || "").trim();
        existingMember.initials = body.initials || initialsFromName(existingMember.name);
        existingMember.gender = body.gender || "female";
        existingMember.age = Number(body.age || 25);
        existingMember.weightKg = Number(body.weightKg || 65);
        existingMember.heightCm = Number(body.heightCm || 168);
        existingMember.activityLevel = body.activityLevel || "light";
        existingMember.goal = body.goal || "maintain";

        const otpCode = String(100000 + Math.floor(Math.random() * 900000));
        const otpExpiry = new Date(Date.now() + 10 * 60 * 1000).toISOString();
        existingMember.otpCode = otpCode;
        existingMember.otpExpiry = otpExpiry;

        const hashed = hashPassword(password);
        existingCredential.passwordHash = hashed.passwordHash;
        existingCredential.passwordSalt = hashed.passwordSalt;

        await store.saveMember(existingMember);
        await store.saveAuthCredential(existingCredential);

        queueOtpEmail(email, otpCode);

        return {
          status: "pending_verification",
          email,
          message: "Mã OTP xác thực mới đã được gửi về email của bạn.",
        };
      } else {
        conflict("Email này đã có tài khoản đăng nhập.");
      }
    }

    const isNewMember = !member;
    if (!member) {
      member = memberFromRegistration(store, { ...body, email, verified: false });
    }

    const otpCode = String(100000 + Math.floor(Math.random() * 900000));
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    member.otpCode = otpCode;
    member.otpExpiry = otpExpiry;

    const hashed = hashPassword(password);
    const credential = {
      id: store.nextId("auth", credentials),
      memberId: member.id,
      email,
      passwordHash: hashed.passwordHash,
      passwordSalt: hashed.passwordSalt,
      createdAt: new Date().toISOString(),
    };

    if (store.dataSource === "sqlserver") {
      if (isNewMember) await insertSqlServerAuthMember(member, credential);
      else await insertSqlServerCredential(credential);
      await store.reload();
      // Update OTP fields on the loaded SQL Server member object
      const sqlMember = getMember(store.db, credential.memberId);
      if (sqlMember) {
        sqlMember.otpCode = otpCode;
        sqlMember.otpExpiry = otpExpiry;
      }
      member = sqlMember || member;
    } else {
      if (isNewMember) store.db.members.push(member);
      credentials.push(credential);
      await store.saveMember(member);
      await store.saveAuthCredential(credential);
    }

    queueOtpEmail(email, otpCode);

    return {
      status: "pending_verification",
      email,
      message: "Mã OTP xác thực đã được gửi về email của bạn.",
    };
  });

  route("POST", "/api/auth/login", async ({ req, store, body }) => {
    requireFields(body, ["email", "password"]);
    const email = normalizeEmail(body.email);
    const credential = findCredentialByEmail(store.db, email);

    if (!credential || !verifyPassword(body.password, credential)) {
      unauthorized("Email hoặc mật khẩu không đúng.");
    }

    const member = getMember(store.db, credential.memberId) || findMemberByEmail(store.db, email);
    if (!member) unauthorized("Tài khoản chưa gắn với hồ sơ thành viên.");

    if (member.verified === false) {
      const errRes = errorResponse(req, 403, "unverified", "Tài khoản chưa được xác thực OTP.");
      errRes.email = member.email;
      return sendJson(req, 403, errRes);
    }

    return authSessionResponse(req, member, store.db);
  });

  route("POST", "/api/auth/verify-otp", async ({ req, store, body }) => {
    requireFields(body, ["email", "otp"]);
    const email = normalizeEmail(body.email);
    const otp = String(body.otp).trim();

    const member = findMemberByEmail(store.db, email);
    if (!member) notFound(req, "Không tìm thấy hồ sơ thành viên.");

    if (!member.otpCode || !member.otpExpiry) {
      badRequest("Không tìm thấy yêu cầu xác thực OTP hoặc mã OTP chưa được tạo.");
    }

    if (new Date().toISOString() > member.otpExpiry) {
      badRequest("Mã OTP đã hết hạn. Vui lòng gửi lại mã.");
    }

    if (member.otpCode !== otp) {
      badRequest("Mã OTP không đúng.");
    }

    member.verified = true;
    member.otpCode = null;
    member.otpExpiry = null;

    await store.saveMember(member);

    console.log(`[EMAIL OTP] Xác thực thành công cho email: ${email}`);

    return authSessionResponse(req, member, store.db);
  });

  route("POST", "/api/auth/resend-otp", async ({ req, store, body }) => {
    requireFields(body, ["email"]);
    const email = normalizeEmail(body.email);

    const member = findMemberByEmail(store.db, email);
    if (!member) notFound(req, "Không tìm thấy hồ sơ thành viên.");

    const otpCode = String(100000 + Math.floor(Math.random() * 900000));
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    member.otpCode = otpCode;
    member.otpExpiry = otpExpiry;

    await store.saveMember(member);

    queueOtpEmail(email, otpCode);

    return {
      success: true,
      message: "Mã OTP mới đã được gửi về email của bạn.",
    };
  });

  route("POST", "/api/auth/supabase", async ({ req, store, body }) => {
    requireFields(body, ["accessToken"]);
    const supabaseUser = await verifySupabaseAccessToken(body.accessToken);
    const email = normalizeEmail(supabaseUser.email);
    if (!supabaseUser.id) badRequest("Supabase user id không hợp lệ.");

    const credential = findCredentialByEmail(store.db, email);
    let member = findMemberByEmail(store.db, email) || (credential ? getMember(store.db, credential.memberId) : null);
    const isNewMember = !member;

    if (!member) {
      member = memberFromRegistration(store, {
        email,
        name: supabaseUser.name,
        goal: "maintain",
      });
    }

    const upsertIdentity = () => {
      const identities = ensureOAuthIdentities(store.db);
      const now = new Date().toISOString();
      const existing = identities.find((identity) => identity.providerUserId === supabaseUser.id)
        || identities.find((identity) => normalizeEmail(identity.email) === email && identity.providerName === supabaseUser.provider);
      const nextIdentity = {
        id: existing?.id || store.nextId("oauth", identities),
        memberId: member.id,
        provider: "supabase",
        providerName: supabaseUser.provider,
        providerUserId: supabaseUser.id,
        email,
        name: supabaseUser.name,
        avatarUrl: supabaseUser.avatarUrl,
        emailConfirmedAt: supabaseUser.emailConfirmedAt,
        lastLoginAt: now,
        createdAt: existing?.createdAt || now,
      };

      if (existing) Object.assign(existing, nextIdentity);
      else identities.push(nextIdentity);
      return nextIdentity;
    };

    if (store.dataSource === "sqlserver") {
      if (isNewMember) {
        const fallbackSecret = crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`;
        const hashed = hashPassword(`supabase-oauth:${supabaseUser.id}:${fallbackSecret}`);
        const oauthCredential = {
          id: store.nextId("auth", ensureAuthCredentials(store.db)),
          memberId: member.id,
          email,
          passwordHash: hashed.passwordHash,
          passwordSalt: hashed.passwordSalt,
          createdAt: new Date().toISOString(),
        };
        await insertSqlServerAuthMember(member, oauthCredential);
        await store.reload();
        member = getMember(store.db, oauthCredential.memberId);
      }
    } else {
      if (isNewMember) ensureMembers(store.db).push(member);
      const identity = upsertIdentity();
      try {
        await store.saveMember(member);
        await store.saveOAuthIdentity(identity);
      } catch (error) {
        console.error("Supabase OAuth member sync failed:", {
          dataSource: store.dataSource,
          message: error?.message,
          code: error?.code,
        });
        serviceUnavailable("Không thể lưu hồ sơ đăng nhập Supabase. Kiểm tra SUPABASE_DATABASE_URL và NUTRIPATH_SUPABASE_TABLE trên backend.");
      }
    }

    if (!member) unauthorized("Không thể đồng bộ tài khoản Supabase với hồ sơ NutriPath.");
    return authSessionResponse(req, member, store.db);
  });

  route("GET", "/api/auth/me", async ({ req, store }) => {
    const { member } = requireSession(req, store);
    return {
      member: memberResource(req, member, store.db),
      _links: {
        self: currentLink(req),
        logout: link(req, "/api/auth/logout", "POST"),
        dashboard: link(req, `/api/members/${member.id}/dashboard`),
        profile: link(req, `/api/members/${member.id}/profile`),
      },
    };
  });

  route("POST", "/api/auth/logout", async ({ req }) => {
    const token = getBearerToken(req);
    if (token) sessions.delete(token);
    return {
      loggedOut: true,
      _links: {
        self: currentLink(req),
        login: link(req, "/api/auth/login", "POST"),
        register: link(req, "/api/auth/register", "POST"),
        api: link(req, "/api"),
      },
    };
  });
}
