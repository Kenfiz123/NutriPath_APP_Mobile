import fs from 'node:fs';
import crypto from 'node:crypto';
import { createStore } from '../src/store.js';

// Load env variables
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
const newPassword = "123456";

console.log(`=== Bắt đầu đặt lại mật khẩu cho tài khoản: ${email} ===`);

function hashPassword(password, salt = crypto.randomBytes(16).toString("hex")) {
  const passwordHash = crypto.pbkdf2Sync(String(password), salt, 120000, 32, "sha256").toString("hex");
  return { passwordHash, passwordSalt: salt };
}

try {
  const store = await createStore();
  const db = store.db;

  const cred = db.authCredentials.find(c => c.email.toLowerCase() === email.toLowerCase());
  if (!cred) {
    console.error("Lỗi: Không tìm thấy thông tin tài khoản cho email này.");
    process.exit(1);
  }

  const { passwordHash, passwordSalt } = hashPassword(newPassword);
  cred.passwordHash = passwordHash;
  cred.passwordSalt = passwordSalt;

  // Persist back to the storage pool
  console.log("Đang tiến hành lưu lại thay đổi vào cơ sở dữ liệu...");
  await store.save();

  console.log(`=== Đặt lại mật khẩu thành công! Mật khẩu mới là: ${newPassword} ===`);
  process.exit(0);
} catch (error) {
  console.error("Lỗi xảy ra:", error);
  process.exit(1);
}
