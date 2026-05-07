import {OpenAPIHono, createRoute, z} from "@hono/zod-openapi";
import {requestIdMiddleware, authMiddleware, idempotencyMiddleware} from "../core/middleware";
import {installErrorHandler} from "../core/errors";
import {registerMeRoutes} from "../features/me/module";

const HealthSchema = z.object({
  status: z.literal("ok"),
  version: z.string(),
}).openapi("Health");

const healthzRoute = createRoute({
  method: "get",
  path: "/v1/healthz",
  responses: {
    200: {description: "Health check", content: {"application/json": {schema: HealthSchema}}},
  },
});

export const app = new OpenAPIHono();

installErrorHandler(app);
app.use("*", requestIdMiddleware());

// Public endpoints — registered before the auth middleware so they are accessible without a token.
app.openapi(healthzRoute, (c) =>
  c.json({status: "ok" as const, version: process.env.K_REVISION ?? "dev"}),
);

app.doc("/v1/openapi.json", {
  openapi: "3.0.3",
  info: {title: "Fling API", version: "1.0.0"},
  servers: [
    {url: "https://us-central1-fling-list.cloudfunctions.net/api", description: "Production"},
    {
      url: "http://127.0.0.1:5001/{project}/us-central1/api",
      description: "Local Firebase Functions emulator",
      variables: {
        project: {default: "fling-rules-test", description: "Firebase project id used by the emulator"},
      },
    },
  ],
});

// Authenticated /v1/* routes — auth middleware applies to everything registered after this point.
app.use("/v1/*", authMiddleware());
app.use("/v1/*", idempotencyMiddleware());
registerMeRoutes(app);
