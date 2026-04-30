export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class BadRequest extends AppError {
  constructor(message = "Bad request", details?: Record<string, unknown>) {
    super("BAD_REQUEST", message, 400, details);
  }
}

export class Unauthorized extends AppError {
  constructor(message = "Unauthorized") {
    super("UNAUTHORIZED", message, 401);
  }
}

export class Forbidden extends AppError {
  constructor(message = "Forbidden") {
    super("FORBIDDEN", message, 403);
  }
}

export class NotFound extends AppError {
  constructor(message = "Not found") {
    super("NOT_FOUND", message, 404);
  }
}

export class Conflict extends AppError {
  constructor(message = "Conflict", details?: Record<string, unknown>) {
    super("CONFLICT", message, 409, details);
  }
}
