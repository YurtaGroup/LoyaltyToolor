"""Structured request/response logging middleware.

Logs every request with timing, status code, and a unique request ID.
Errors (5xx) get full detail; normal requests get a compact one-liner.
"""

import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("toolor.requests")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())[:8]
        request.state.request_id = request_id

        start = time.perf_counter()
        method = request.method
        path = request.url.path

        # Skip noisy health checks
        if path == "/api/v1/health":
            return await call_next(request)

        try:
            response = await call_next(request)
        except Exception as exc:
            elapsed = (time.perf_counter() - start) * 1000
            logger.error(
                f"[{request_id}] {method} {path} -> 500 ({elapsed:.0f}ms) ERROR: {exc}"
            )
            raise

        elapsed = (time.perf_counter() - start) * 1000
        status = response.status_code

        # Extract user info from auth header if present
        user_hint = ""
        auth = request.headers.get("authorization", "")
        if auth.startswith("Bearer "):
            user_hint = " [authenticated]"

        if status >= 500:
            logger.error(f"[{request_id}] {method} {path} -> {status} ({elapsed:.0f}ms){user_hint}")
        elif status >= 400:
            logger.warning(f"[{request_id}] {method} {path} -> {status} ({elapsed:.0f}ms){user_hint}")
        else:
            logger.info(f"[{request_id}] {method} {path} -> {status} ({elapsed:.0f}ms){user_hint}")

        response.headers["X-Request-ID"] = request_id
        return response
