import assert from "node:assert/strict";
import { unlink } from "node:fs/promises";
import path from "node:path";
import { createServer } from "../src/app.js";

const dbPath = path.resolve("data/smoke-test-db.json");
const server = await createServer({ dbPath });

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const address = server.address();
const baseUrl = `http://127.0.0.1:${address.port}`;

async function request(pathname, options = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });
  const json = await response.json();
  assert.ok(response.ok, `${options.method || "GET"} ${pathname} failed: ${JSON.stringify(json)}`);
  assert.ok(json._links, `${pathname} should include HATEOAS _links`);
  return json;
}

try {
  const api = await request("/api");
  assert.ok(api._links.members);
  assert.ok(api._links.calorieCalculator);

  const healthWithDoubleSlash = await request("//api/health");
  assert.equal(healthWithDoubleSlash.status, "ok");

  const dashboard = await request("/api/members/mem-001/dashboard?date=2026-03-13");
  assert.equal(dashboard.member.id, "mem-001");
  assert.ok(dashboard.mealLog._links.updateWater);

  const recipes = await request("/api/recipes?tag=Low-cal");
  assert.ok(Array.isArray(recipes._embedded.recipes));
  assert.ok(recipes._embedded.recipes.length > 0);

  const calc = await request("/api/calculations/calorie", {
    method: "POST",
    body: JSON.stringify({
      age: 25,
      weightKg: 65,
      heightCm: 168,
      gender: "female",
      activityLevel: "light",
      goal: "lose",
      exerciseType: "walking",
      durationMinutes: 30,
    }),
  });
  assert.ok(calc.results.bmr > 0);
  assert.ok(calc._links.activityLevels);

  const water = await request("/api/members/mem-001/meal-logs/2026-03-13/water", {
    method: "PATCH",
    body: JSON.stringify({ addWaterMl: 330 }),
  });
  assert.equal(water.waterMl, 1580);
  assert.equal(water.waterGlasses, 6.3);

  const quote = await request("/api/checkout/quote", {
    method: "POST",
    body: JSON.stringify({ planId: "vip", billing: "monthly", discountCode: "NUTRIPATH10" }),
  });
  assert.equal(quote.quote.discountAmount, 9900);

  console.log(`Smoke test passed against ${baseUrl}`);
} finally {
  await new Promise((resolve) => server.close(resolve));
  await unlink(dbPath).catch(() => {});
}
