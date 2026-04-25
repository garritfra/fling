import { writeFileSync, mkdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { app } from "../src/api/app";

const out = resolve(__dirname, "../../openapi/openapi.json");
mkdirSync(dirname(out), { recursive: true });

const doc = app.getOpenAPIDocument({
  openapi: "3.0.3",
  info: { title: "Fling API", version: "1.0.0" },
});

writeFileSync(out, JSON.stringify(doc, null, 2) + "\n");
console.log(`Wrote ${out}`);
