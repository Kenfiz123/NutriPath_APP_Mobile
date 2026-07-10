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

console.log(`=== Test API GET /api/friends/requests cho: ${email} ===`);

function verifyPassword(password, credential) {
  if (!credential?.passwordHash || !credential?.passwordSalt) return false;
  // PBKDF2 verification
  const passwordHash = crypto.pbkdf2Sync(String(password), credential.passwordSalt, 120000, 32, "sha256").toString("hex");
  return credential.passwordHash === passwordHash;
}

try {
  const store = await createStore();
  const db = store.db;

  const member = db.members.find(m => m.email.toLowerCase() === email.toLowerCase());
  const cred = db.authCredentials.find(c => c.email.toLowerCase() === email.toLowerCase());

  if (!member || !cred) {
    console.error("Không tìm thấy member hoặc credentials cho email này.");
    process.exit(1);
  }

  // We can mock requireSession to inspect what the route would return!
  const friendships = db.friendships || [];
  const incoming = [];
  const outgoing = [];

  for (const f of friendships) {
    if (f.status !== "pending") continue;

    if (f.addresseeId === member.id) {
      // Incoming
      const sender = db.members.find(m => m.id === f.requesterId);
      if (sender) {
        incoming.push({
          id: f.id,
          friendId: sender.id,
          name: sender.name,
          initials: sender.initials || "",
          email: sender.email,
          tier: sender.tier || "free",
          createdAt: f.createdAt,
        });
      }
    } else if (f.requesterId === member.id) {
      // Outgoing
      const receiver = db.members.find(m => m.id === f.addresseeId);
      if (receiver) {
        outgoing.push({
          id: f.id,
          friendId: receiver.id,
          name: receiver.name,
          initials: receiver.initials || "",
          email: receiver.email,
          tier: receiver.tier || "free",
          createdAt: f.createdAt,
        });
      }
    }
  }

  console.log("KẾT QUẢ TRẢ VỀ:");
  console.log(JSON.stringify({ incoming, outgoing }, null, 2));
  process.exit(0);
} catch (error) {
  console.error("Lỗi:", error);
  process.exit(1);
}
