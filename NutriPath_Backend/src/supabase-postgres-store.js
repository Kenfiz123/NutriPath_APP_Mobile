import { seedData } from "./data/seed.js";

let poolPromise = null;

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function getConnectionString() {
  const connectionString = process.env.SUPABASE_DATABASE_URL || process.env.DATABASE_URL || process.env.POSTGRES_URL;
  if (!connectionString) {
    throw new Error("Missing SUPABASE_DATABASE_URL, DATABASE_URL, or POSTGRES_URL for Supabase PostgreSQL data source.");
  }
  return connectionString;
}

function quoteIdentifier(identifier) {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(identifier)) {
    throw new Error(`Invalid PostgreSQL identifier: ${identifier}`);
  }
  return `"${identifier.replace(/"/g, '""')}"`;
}

function getTableParts() {
  const configured = process.env.NUTRIPATH_SUPABASE_TABLE || "public.nutripath_app_state";
  const parts = configured.split(".");
  if (parts.length === 1) return { schema: "public", table: parts[0] };
  if (parts.length === 2) return { schema: parts[0], table: parts[1] };
  throw new Error("NUTRIPATH_SUPABASE_TABLE must be a table name or schema.table.");
}

function getTableRef() {
  const { schema, table } = getTableParts();
  return `${quoteIdentifier(schema)}.${quoteIdentifier(table)}`;
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

async function ensureSchema(pool) {
  const { schema } = getTableParts();
  const tableRef = getTableRef();
  await pool.query(`CREATE SCHEMA IF NOT EXISTS ${quoteIdentifier(schema)};`);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${tableRef} (
      id text PRIMARY KEY,
      data jsonb NOT NULL,
      version integer NOT NULL DEFAULT 1,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    );
  `);
}

function withSupabaseMeta(data) {
  const next = clone(data || seedData);
  next.meta = {
    ...(next.meta || {}),
    name: "NutriPath API",
    version: "1.0.0",
    source: "supabase",
    loadedAt: new Date().toISOString(),
  };
  return next;
}

export async function persistSupabaseData(data) {
  const pool = await getPgPool();
  await ensureSchema(pool);
  const tableRef = getTableRef();
  const stateKey = process.env.NUTRIPATH_SUPABASE_STATE_KEY || "default";
  await pool.query(
    `
      INSERT INTO ${tableRef} AS state (id, data)
      VALUES ($1, $2::jsonb)
      ON CONFLICT (id)
      DO UPDATE SET
        data = EXCLUDED.data,
        version = state.version + 1,
        updated_at = now();
    `,
    [stateKey, JSON.stringify(withSupabaseMeta(data))],
  );
}

export async function loadSupabaseData() {
  const pool = await getPgPool();
  await ensureSchema(pool);
  const tableRef = getTableRef();
  const stateKey = process.env.NUTRIPATH_SUPABASE_STATE_KEY || "default";
  const result = await pool.query(`SELECT data FROM ${tableRef} WHERE id = $1;`, [stateKey]);

  if (result.rowCount > 0) {
    return withSupabaseMeta(result.rows[0].data);
  }

  const initial = withSupabaseMeta(seedData);
  await persistSupabaseData(initial);
  return initial;
}

export async function resetSupabaseData() {
  const initial = withSupabaseMeta(seedData);
  await persistSupabaseData(initial);
  return initial;
}

export async function closeSupabasePool() {
  if (!poolPromise) return;
  const pool = await poolPromise;
  await pool.end();
  poolPromise = null;
}
