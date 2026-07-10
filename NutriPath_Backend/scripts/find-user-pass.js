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

const email = "nam@gmail.com";
console.log(`=== Đang tìm tài khoản: ${email} ===`);

try {
  const store = await createStore();
  const db = store.db;

  const cred = db.authCredentials.find(c => c.email.toLowerCase() === email.toLowerCase());
  if (!cred) {
    console.log("Không tìm thấy thông tin đăng nhập cho email này.");
    process.exit(0);
  }

  console.log("Thông tin đăng nhập tìm thấy:", JSON.stringify(cred, null, 2));
  process.exit(0);
} catch (error) {
  console.error("Lỗi:", error);
  process.exit(1);
}
