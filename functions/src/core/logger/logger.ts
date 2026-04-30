import type {RequestContext} from "../context/request_context";

export interface Logger {
  info(msg: string, fields?: Record<string, unknown>): void;
  warn(msg: string, fields?: Record<string, unknown>): void;
  error(msg: string, fields?: Record<string, unknown>): void;
}

function emit(level: "INFO" | "WARN" | "ERROR", msg: string, fields?: Record<string, unknown>): void {
  const line = JSON.stringify({severity: level, message: msg, ...fields});
  if (level === "ERROR") console.error(line);
  else if (level === "WARN") console.warn(line);
  else console.log(line);
}

export const logger: Logger = {
  info: (m, f) => emit("INFO", m, f),
  warn: (m, f) => emit("WARN", m, f),
  error: (m, f) => emit("ERROR", m, f),
};

export function withRequestContext(ctx: RequestContext): Logger {
  const base = {request_id: ctx.requestId, uid: ctx.uid};
  return {
    info: (m, f) => emit("INFO", m, {...base, ...f}),
    warn: (m, f) => emit("WARN", m, {...base, ...f}),
    error: (m, f) => emit("ERROR", m, {...base, ...f}),
  };
}
