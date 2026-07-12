const activeClients = [];

export function registerFriendsRoutes(ctx) {
  const {
    route,
    requireFields,
    badRequest,
    notFound,
    conflict,
    forbidden,
    requireSession,
    getMember,
    collectionResponse,
    link,
  } = ctx;

  function ensureFriendships(db) {
    if (!db.friendships) db.friendships = [];
    return db.friendships;
  }

  function getFriendshipStatus(friendships, userId, otherId) {
    const f = friendships.find(
      (x) =>
        (x.requesterId === userId && x.addresseeId === otherId) ||
        (x.requesterId === otherId && x.addresseeId === userId)
    );
    if (!f) return "none";
    if (f.status === "accepted") return "friends";
    if (f.requesterId === userId) return "pending_sent";
    return "pending_received";
  }

  // GET /api/friends - List active friends
  route("GET", "/api/friends", async ({ req, store }) => {
    const { member } = requireSession(req, store);
    const friendships = ensureFriendships(store.db);

    const activeFriends = [];
    for (const f of friendships) {
      if (f.status !== "accepted") continue;
      let friendId = null;
      if (f.requesterId === member.id) friendId = f.addresseeId;
      else if (f.addresseeId === member.id) friendId = f.requesterId;

      if (friendId) {
        const friend = getMember(store.db, friendId);
        if (friend) {
          activeFriends.push({
            id: friend.id,
            name: friend.name,
            initials: friend.initials || "",
            email: friend.email,
            tier: friend.tier || "free",
            goal: friend.goal || "maintain",
            calorieTarget: friend.calorieTarget || 2000,
            waterTargetGlasses: friend.waterTargetGlasses || 8,
          });
        }
      }
    }

    return collectionResponse(req, "friends", activeFriends, {
      path: "/api/friends",
      links: {
        self: link(req, "/api/friends"),
      },
    });
  });

  // GET /api/friends/search - Search users
  route("GET", "/api/friends/search", async ({ req, store, url }) => {
    const { member } = requireSession(req, store);
    const queryVal = url.searchParams.get("query") || "";
    const searchTerm = String(queryVal).trim().toLowerCase();
    if (!searchTerm) {
      return collectionResponse(req, "friends", [], {
        path: "/api/friends/search?query=",
      });
    }

    const friendships = ensureFriendships(store.db);
    const results = [];

    for (const m of store.db.members || []) {
      if (m.id === member.id) continue; // Exclude self
      const nameMatch = String(m.name || "").toLowerCase().includes(searchTerm);
      const emailMatch = String(m.email || "").toLowerCase().includes(searchTerm);

      if (nameMatch || emailMatch) {
        const status = getFriendshipStatus(friendships, member.id, m.id);
        results.push({
          id: m.id,
          name: m.name,
          initials: m.initials || "",
          email: m.email,
          tier: m.tier || "free",
          friendshipStatus: status,
        });
      }
    }

    return collectionResponse(req, "friends", results, {
      path: `/api/friends/search?query=${encodeURIComponent(queryVal)}`,
    });
  });

  // POST /api/friends/request - Send friend request
  route("POST", "/api/friends/request", async ({ req, store, body }) => {
    const { member } = requireSession(req, store);
    requireFields(body, ["friendId"]);
    const friendId = body.friendId;

    if (friendId === member.id) {
      badRequest("Bạn không thể kết bạn với chính mình.");
    }

    const target = getMember(store.db, friendId);
    if (!target) notFound(req, "Không tìm thấy người dùng.");

    const friendships = ensureFriendships(store.db);
    const existing = friendships.find(
      (x) =>
        (x.requesterId === member.id && x.addresseeId === friendId) ||
        (x.requesterId === friendId && x.addresseeId === member.id)
    );

    if (existing) {
      if (existing.status === "accepted") {
        conflict("Hai người đã là bạn bè.");
      } else {
        conflict("Yêu cầu kết bạn đã tồn tại hoặc đang chờ xử lý.");
      }
    }

    const id = store.nextId("friend", friendships);
    const newFriendship = {
      id,
      requesterId: member.id,
      addresseeId: friendId,
      status: "pending",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    friendships.push(newFriendship);
    await store.saveFriendship(newFriendship);

    return {
      success: true,
      message: "Đã gửi lời mời kết bạn thành công.",
      friendship: newFriendship,
    };
  });

  // GET /api/friends/requests - List pending requests
  route("GET", "/api/friends/requests", async ({ req, store }) => {
    const { member } = requireSession(req, store);
    const friendships = ensureFriendships(store.db);

    const incoming = [];
    const outgoing = [];

    for (const f of friendships) {
      if (f.status !== "pending") continue;

      if (f.addresseeId === member.id) {
        // Incoming
        const sender = getMember(store.db, f.requesterId);
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
        const receiver = getMember(store.db, f.addresseeId);
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

    return { incoming, outgoing };
  });

  // POST /api/friends/respond - Accept or Decline request
  route("POST", "/api/friends/respond", async ({ req, store, body }) => {
    const { member } = requireSession(req, store);
    requireFields(body, ["friendId", "accept"]);
    const { friendId, accept } = body;

    const friendships = ensureFriendships(store.db);
    const idx = friendships.findIndex(
      (x) => x.requesterId === friendId && x.addresseeId === member.id && x.status === "pending"
    );

    if (idx === -1) {
      notFound(req, "Không tìm thấy yêu cầu kết bạn chờ xử lý.");
    }

    if (accept) {
      friendships[idx].status = "accepted";
      friendships[idx].updatedAt = new Date().toISOString();
      await store.saveFriendship(friendships[idx]);
    } else {
      // Remove friendship record if declined or cancelled
      const [deleted] = friendships.splice(idx, 1);
      await store.deleteFriendship(deleted.id);
    }

    return {
      success: true,
      message: accept ? "Đã đồng ý kết bạn." : "Đã từ chối lời mời kết bạn.",
    };
  });

  // POST /api/friends/remove - Unfriend or Cancel request
  route("POST", "/api/friends/remove", async ({ req, store, body }) => {
    const { member } = requireSession(req, store);
    requireFields(body, ["friendId"]);
    const friendId = body.friendId;

    const friendships = ensureFriendships(store.db);
    const idx = friendships.findIndex(
      (x) =>
        ((x.requesterId === member.id && x.addresseeId === friendId) ||
          (x.requesterId === friendId && x.addresseeId === member.id))
    );

    if (idx === -1) {
      notFound(req, "Không tìm thấy mối quan hệ bạn bè.");
    }

    const [deleted] = friendships.splice(idx, 1);
    await store.deleteFriendship(deleted.id);

    return {
      success: true,
      message: "Đã hủy kết bạn / hủy lời mời.",
    };
  });

  // GET /api/friends/profile/:memberId - View public profile of another user
  route("GET", "/api/friends/profile/:memberId", async ({ req, store, params }) => {
    const { member } = requireSession(req, store);
    const targetId = params.memberId;

    const target = getMember(store.db, targetId);
    if (!target) notFound(req, "Không tìm thấy hồ sơ người dùng.");

    const friendships = ensureFriendships(store.db);
    const status = getFriendshipStatus(friendships, member.id, target.id);

    return {
      id: target.id,
      name: target.name,
      initials: target.initials || "",
      email: target.email,
      tier: target.tier || "free",
      gender: target.gender || "secret",
      age: target.age || 25,
      calorieTarget: target.calorieTarget || 2000,
      waterTargetGlasses: target.waterTargetGlasses || 8,
      goal: target.goal || "maintain",
      friendshipStatus: status,
    };
  });

  function ensureFriendChats(db) {
    if (!db.friendChats) db.friendChats = [];
    return db.friendChats;
  }

  // GET /api/friends/chats/:friendId - Get messages history
  route("GET", "/api/friends/chats/:friendId", async ({ req, store, params }) => {
    const { member } = requireSession(req, store);
    const friendId = params.friendId;
    const friendChats = ensureFriendChats(store.db);

    const list = friendChats.filter(
      (c) =>
        (c.senderId === member.id && c.receiverId === friendId) ||
        (c.senderId === friendId && c.receiverId === member.id)
    );

    return collectionResponse(req, "chats", list, {
      path: `/api/friends/chats/${friendId}`,
    });
  });

  // POST /api/friends/chats/:friendId - Send a chat message
  route("POST", "/api/friends/chats/:friendId", async ({ req, store, params, body }) => {
    const { member } = requireSession(req, store);
    const friendId = params.friendId;
    requireFields(body, ["text"]);

    const friendships = ensureFriendships(store.db);
    const isFriend = friendships.some(
      (x) =>
        x.status === "accepted" &&
        ((x.requesterId === member.id && x.addresseeId === friendId) ||
          (x.requesterId === friendId && x.addresseeId === member.id))
    );

    if (!isFriend) {
      forbidden("Bạn chỉ có thể gửi tin nhắn cho bạn bè.");
    }

    const friendChats = ensureFriendChats(store.db);
    const id = store.nextId("fchat", friendChats);
    const newMessage = {
      id,
      senderId: member.id,
      receiverId: friendId,
      text: body.text,
      createdAt: new Date().toISOString(),
    };

    friendChats.push(newMessage);
    await store.saveFriendChat(newMessage);

    // Broadcast to active SSE clients matching this conversation
    const targetClients = activeClients.filter(
      (c) =>
        (c.memberId === member.id && c.friendId === friendId) ||
        (c.memberId === friendId && c.friendId === member.id)
    );
    for (const client of targetClients) {
      try {
        client.res.write(`data: ${JSON.stringify(newMessage)}\n\n`);
      } catch (e) {
        // Ignored
      }
    }

    return newMessage;
  });

  // GET /api/friends/chats/:friendId/stream - Server-Sent Events stream for instant chat updates
  route("GET", "/api/friends/chats/:friendId/stream", async ({ req, res, store, params }) => {
    const { member } = requireSession(req, store);
    const friendId = params.friendId;

    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "Access-Control-Allow-Origin": "*",
    });

    const client = { memberId: member.id, friendId, res };
    activeClients.push(client);

    req.on("close", () => {
      const idx = activeClients.indexOf(client);
      if (idx !== -1) {
        activeClients.splice(idx, 1);
      }
    });

    res.write("data: connected\n\n");
    return { __isSSE__: true };
  });
}
