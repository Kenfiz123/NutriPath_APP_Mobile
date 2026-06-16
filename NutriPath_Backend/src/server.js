import { createServer } from "./app.js";

const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || "0.0.0.0";

const server = await createServer();

server.listen(port, host, () => {
  console.log(`NutriPath API listening on ${host}:${port}`);
  if (host === "0.0.0.0") {
    console.log(`Local URL: http://127.0.0.1:${port}`);
    console.log(`Android emulator URL: http://10.0.2.2:${port}`);
  }
});

function shutdown(signal) {
  console.log(`${signal} received, shutting down NutriPath API...`);
  server.close(() => process.exit(0));
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
