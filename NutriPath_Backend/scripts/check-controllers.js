import { readdir } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import path from "node:path";

const controllersDir = path.resolve("src/controllers");
const files = (await readdir(controllersDir))
  .filter((file) => file.endsWith(".js"))
  .sort();

for (const file of files) {
  const fullPath = path.join(controllersDir, file);
  const result = spawnSync(process.execPath, ["--check", fullPath], {
    stdio: "inherit",
    windowsHide: true,
  });
  if (result.status !== 0) process.exit(result.status || 1);
}
