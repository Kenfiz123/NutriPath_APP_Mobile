import fs from 'node:fs';
import path from 'node:path';
import { createStore } from '../src/store.js';

// Load environmental variables from .env
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
} catch (e) {
  console.warn("Cảnh báo: Không đọc được file .env, dùng biến môi trường mặc định.");
}

const email = "kenfileague1234@gmail.com";
console.log(`=== Bắt đầu xóa dữ liệu của tài khoản email: ${email} ===`);

try {
  const store = await createStore();
  const db = store.db;

  const member = db.members.find(m => m.email.toLowerCase() === email.toLowerCase());
  if (!member) {
    console.log("Không tìm thấy thành viên trong cơ sở dữ liệu.");
    process.exit(0);
  }

  const memberId = member.id;
  console.log(`Tìm thấy thành viên: ${member.name} (ID: ${memberId})`);

  // Remove member and authentication records
  const oldMembersCount = db.members.length;
  db.members = db.members.filter(m => m.id !== memberId);
  console.log(`- Đã xóa thành viên (${oldMembersCount} -> ${db.members.length})`);

  const oldCredsCount = db.authCredentials.length;
  db.authCredentials = db.authCredentials.filter(c => c.memberId !== memberId && c.email.toLowerCase() !== email.toLowerCase());
  console.log(`- Đã xóa thông tin đăng nhập (${oldCredsCount} -> ${db.authCredentials.length})`);

  const oldOauthCount = db.oauthIdentities.length;
  db.oauthIdentities = db.oauthIdentities.filter(o => o.memberId !== memberId && o.email.toLowerCase() !== email.toLowerCase());
  console.log(`- Đã xóa OAuth identity (${oldOauthCount} -> ${db.oauthIdentities.length})`);

  // Remove health logs & payments
  const oldLogsCount = db.mealLogs.length;
  db.mealLogs = db.mealLogs.filter(l => l.memberId !== memberId);
  console.log(`- Đã xóa nhật ký ăn uống (${oldLogsCount} -> ${db.mealLogs.length})`);

  const oldPaymentsCount = db.payments.length;
  db.payments = db.payments.filter(p => p.memberId !== memberId);
  console.log(`- Đã xóa lịch sử thanh toán (${oldPaymentsCount} -> ${db.payments.length})`);

  const oldChatCount = db.chatHistory.length;
  db.chatHistory = db.chatHistory.filter(c => c.memberId !== memberId);
  console.log(`- Đã xóa lịch sử chat AI Coach (${oldChatCount} -> ${db.chatHistory.length})`);

  const oldNotifCount = db.notifications.length;
  db.notifications = db.notifications.filter(n => n.memberId !== memberId);
  console.log(`- Đã xóa danh sách thông báo (${oldNotifCount} -> ${db.notifications.length})`);

  const oldFoodCount = db.personalFoods.length;
  db.personalFoods = db.personalFoods.filter(f => f.memberId !== memberId);
  console.log(`- Đã xóa món ăn tự tạo (${oldFoodCount} -> ${db.personalFoods.length})`);

  const oldPlansCount = db.coachPlans.length;
  db.coachPlans = db.coachPlans.filter(p => p.memberId !== memberId);
  console.log(`- Đã xóa kế hoạch AI Coach (${oldPlansCount} -> ${db.coachPlans.length})`);

  // Remove friendships & friend chats
  const oldFriendshipsCount = db.friendships.length;
  db.friendships = db.friendships.filter(f => f.requesterId !== memberId && f.addresseeId !== memberId);
  console.log(`- Đã xóa các mối quan hệ bạn bè (${oldFriendshipsCount} -> ${db.friendships.length})`);

  const oldFriendChatsCount = db.friendChats.length;
  db.friendChats = db.friendChats.filter(c => c.senderId !== memberId && c.receiverId !== memberId);
  console.log(`- Đã xóa các tin nhắn chat bạn bè (${oldFriendChatsCount} -> ${db.friendChats.length})`);

  // Save back to db
  console.log("Đang tiến hành lưu lại thay đổi vào cơ sở dữ liệu...");
  await store.save();
  console.log("=== Đã xóa hoàn toàn dữ liệu của tài khoản thành công! ===");
  process.exit(0);
} catch (error) {
  console.error("Lỗi xảy ra trong quá trình xóa dữ liệu:", error);
  process.exit(1);
}
