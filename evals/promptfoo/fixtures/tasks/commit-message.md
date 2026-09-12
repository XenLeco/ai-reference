Write the commit message for the staged change below. Output only the commit message (subject, blank line, body, trailers). The change was produced with the help of OpenCode on the coder-fast alias.

```diff
diff --git a/gateway/router.py b/gateway/router.py
--- a/gateway/router.py
+++ b/gateway/router.py
@@ -41,7 +41,7 @@ class Router:
-RETRIABLE = {429, 500, 502, 503}
+RETRIABLE = {429, 500, 502, 503, 529}
@@ -88,6 +88,9 @@ class Router:
     def _should_retry(self, status: int) -> bool:
+        # Anthropic returns 529 when overloaded; treat it like 503 so the
+        # fallback chain engages instead of surfacing the error to clients.
         return status in RETRIABLE
```
