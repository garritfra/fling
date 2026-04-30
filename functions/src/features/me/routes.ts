import {OpenAPIHono, createRoute} from "@hono/zod-openapi";
import {MeSchema, PatchMeSchema} from "./schemas";
import {getRequestContext} from "../../core/context/request_context";
import * as service from "./service";

const getMeRoute = createRoute({
  method: "get",
  path: "/v1/me",
  tags: ["me"],
  responses: {
    200: {description: "The caller", content: {"application/json": {schema: MeSchema}}},
  },
});

const patchMeRoute = createRoute({
  method: "patch",
  path: "/v1/me",
  tags: ["me"],
  request: {body: {required: true, content: {"application/json": {schema: PatchMeSchema}}}},
  responses: {
    200: {description: "Updated", content: {"application/json": {schema: MeSchema}}},
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
