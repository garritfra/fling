import {OpenAPIHono, createRoute, z} from "@hono/zod-openapi";

const HealthSchema = z.object({
  status: z.literal("ok"),
  version: z.string(),
}).openapi("Health");

const healthzRoute = createRoute({
  method: "get",
  path: "/v1/healthz",
  responses: {
    200: {
      description: "Health check",
      content: {"application/json": {schema: HealthSchema}},
    },
  },
});

export const app = new OpenAPIHono();

app.openapi(healthzRoute, (c) =>
  c.json({status: "ok" as const, version: process.env.K_REVISION ?? "dev"}),
);

app.doc("/v1/openapi.json", {
  openapi: "3.0.3",
  info: {title: "Fling API", version: "1.0.0"},
});
