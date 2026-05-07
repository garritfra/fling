import {z, OpenAPIHono, createRoute} from "@hono/zod-openapi";
import {MeSchema, PatchMeSchema} from "./schemas";
import {getRequestContext} from "../../core/context/request_context";
import * as service from "./service";

const ErrorSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.unknown().optional(),
  }),
}).openapi("ApiError");

const getMeRoute = createRoute({
  method: "get",
  path: "/v1/me",
  tags: ["me"],
  responses: {
    200: {description: "The caller", content: {"application/json": {schema: MeSchema}}},
    401: {description: "Unauthorized", content: {"application/json": {schema: ErrorSchema}}},
    404: {
      description: "User document not found",
      content: {"application/json": {schema: ErrorSchema}},
    },
  },
});

const patchMeRoute = createRoute({
  method: "patch",
  path: "/v1/me",
  tags: ["me"],
  request: {body: {required: true, content: {"application/json": {schema: PatchMeSchema}}}},
  responses: {
    200: {description: "Updated", content: {"application/json": {schema: MeSchema}}},
    400: {description: "Validation error", content: {"application/json": {schema: ErrorSchema}}},
    401: {description: "Unauthorized", content: {"application/json": {schema: ErrorSchema}}},
    404: {
      description: "User document not provisioned yet",
      content: {"application/json": {schema: ErrorSchema}},
    },
    409: {
      description: "Idempotency-Key reused with a different request body",
      content: {"application/json": {schema: ErrorSchema}},
    },
  },
});

export function registerMeRoutes(app: OpenAPIHono): void {
  app.openapi(getMeRoute, async (c) => {
    const me = await service.getMe(getRequestContext(c));
    return c.json(me, 200);
  });

  app.openapi(patchMeRoute, async (c) => {
    const patch = c.req.valid("json");
    const me = await service.patchMe(getRequestContext(c), patch);
    return c.json(me, 200);
  });
}
