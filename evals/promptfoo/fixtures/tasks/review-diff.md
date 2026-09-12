Review this diff. The file is `src/pricing.py`. Report in your standard shape.

```diff
diff --git a/src/pricing.py b/src/pricing.py
--- a/src/pricing.py
+++ b/src/pricing.py
@@ -1,12 +1,22 @@
 from decimal import Decimal
+import logging
+
+log = logging.getLogger(__name__)
 
 
 def line_total(price: Decimal, qty: int) -> Decimal:
     return price * qty
 
 
-def order_total(items):
-    return sum(line_total(p, q) for p, q in items)
+def order_total(items, discount_pct: int = 0) -> Decimal:
+    total = Decimal("0")
+    for i in range(1, len(items)):
+        price, qty = items[i]
+        total += line_total(price, qty)
+    try:
+        total -= total * Decimal(discount_pct) / 100
+    except:
+        pass
+    return total
```
