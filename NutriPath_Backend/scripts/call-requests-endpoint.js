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

  const email = "nam@gmail.com";
  const member = db.members.find(m => m.email.toLowerCase() === email.toLowerCase());

  if (!member) {
    console.error("Không tìm thấy member.");
    process.exit(1);
  }

  // Let's call the endpoint code directly with mock req and res
  const friendships = db.friendships || [];
  const incoming = [];
  const outgoing = [];

  for (const f of friendships) {
    if (f.status !== "pending") continue;

    if (f.addresseeId === member.id) {
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

  console.log("EXACT ENDPOINT RESPONSE:", JSON.stringify({ incoming, outgoing }, null, 2));
  process.exit(0);
} catch (error) {
  console.error("Lỗi:", error);
  process.exit(1);
}
