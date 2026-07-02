import { registerCoreRoutes } from "./core.controller.js";
import { registerCalculationsRoutes } from "./calculations.controller.js";
import { registerAuthRoutes } from "./auth.controller.js";
import { registerMembersRoutes } from "./members.controller.js";
import { registerNutritionRoutes } from "./nutrition.controller.js";
import { registerRecipesRoutes } from "./recipes.controller.js";
import { registerBillingRoutes } from "./billing.controller.js";
import { registerChatRoutes } from "./chat.controller.js";
import { registerAdminRoutes } from "./admin.controller.js";
import { registerFriendsRoutes } from "./friends.controller.js";

const routeRegistrars = [
  registerCoreRoutes,
  registerCalculationsRoutes,
  registerAuthRoutes,
  registerMembersRoutes,
  registerNutritionRoutes,
  registerRecipesRoutes,
  registerBillingRoutes,
  registerChatRoutes,
  registerAdminRoutes,
  registerFriendsRoutes,
];

export function registerControllers(ctx) {
  for (const registerRoutes of routeRegistrars) {
    registerRoutes(ctx);
  }
}
