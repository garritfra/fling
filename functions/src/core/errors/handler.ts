import type {Hono} from "hono";
import type {OpenAPIHono} from "@hono/zod-openapi";
import {ZodError} from "zod";
import {AppError, BadRequest} from "./app_error";
import {logger} from "../logger";

export function installErrorHandler(app: Hono | OpenAPIHono): void {
  app.onError((err, c) => {
    if (err instanceof ZodError) {
      const wrapped = new BadRequest("Validation failed", {issues: err.issues});
      const {code, message, details} = wrapped;
      return c.json({error: {code, message, details}}, 400);
    }
    if (err instanceof AppError) {
      const body: {error: {code: string; message: string; details?: Record<string, unknown>}} = {
        error: {code: err.code, message: err.message},
      };
      if (err.details) body.error.details = err.details;
      return c.json(body, err.status as 400 | 401 | 403 | 404 | 409 | 418);
    }
    logger.error("Unhandled error", {message: err.message, stack: err.stack});
    return c.json({error: {code: "INTERNAL", message: "Internal server error"}}, 500);
  });
}
