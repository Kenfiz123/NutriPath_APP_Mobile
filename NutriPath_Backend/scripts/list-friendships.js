import fs from 'node:fs';
import { createStore } from '../src/store.js';

try {
  const envContent = fs.readFileSync('.env', 'utf8');
  for (const line of envContent.split('\n')) {
    const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
    if (match) {
      const key = match[1];
      let val = match[2] || '';
      val = val.trim().replace(/^['"]|['"]$/g, '');
      if (process.env[key] === undefined) {
        process.env[key] = val;
      }
    }
  }
} catch (e) {}

try {
  const store = await createStore();
  const db = store.db;

  console.log("=== DANH SÁCH TẤT CẢ FRIENDSHIPS TRONG DB ===");
  console.log(JSON.stringify(db.friendships, null, 2));
  console.log("=========================================");

  console.log("\n=== DANH SÁCH THÀNH VIÊN (MEMBERS) ===");
  const membersBrief = db.members.map(m => ({ id: m.id, name: m.name, email: m.email }));
  console.log(JSON.stringify(membersBrief, null, 2));
  console.log("========================================");
  process.exit(0);
} catch (error) {
  console.error("Lỗi:", error);
  process.exit(1);
}
