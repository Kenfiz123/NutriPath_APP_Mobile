export function absoluteUrl(req, path) {
  const proto = req.headers["x-forwarded-proto"] || "http";
  const host = req.headers["x-forwarded-host"] || req.headers.host || "127.0.0.1:8080";
  if (/^https?:\/\//i.test(path)) return path;
  return `${proto}://${host}${path.startsWith("/") ? path : `/${path}`}`;
}

export function link(req, path, method = "GET", title) {
  const value = { href: absoluteUrl(req, path), method };
  if (title) value.title = title;
  return value;
}

export function currentLink(req) {
  return link(req, req.url || "/", req.method || "GET", "Current request");
}

export function apiLinks(req) {
  return {
    self: currentLink(req),
    api: link(req, "/api", "GET", "API root"),
    health: link(req, "/api/health", "GET", "Health check"),
  };
}

export function collectionResponse(req, rel, items, options = {}) {
  const {
    path = req.url || "/",
    itemMapper = (item) => item,
    links = {},
    meta = {},
  } = options;

  return {
    ...meta,
    count: items.length,
    _links: {
      self: link(req, path),
      ...links,
      api: link(req, "/api"),
    },
    _embedded: {
      [rel]: items.map(itemMapper),
    },
  };
}

export function errorResponse(req, status, code, message, details) {
  return {
    status,
    error: {
      code,
      message,
      ...(details ? { details } : {}),
    },
    _links: apiLinks(req),
  };
}
