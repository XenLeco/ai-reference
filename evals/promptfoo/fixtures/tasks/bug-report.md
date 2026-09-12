Bug report from support: "Order totals are wrong when a cart has more than one item. A cart with a 10.00 item and a 5.00 item shows 5.00."

The function is in `src/pricing.py`:

```python
from decimal import Decimal

def line_total(price: Decimal, qty: int) -> Decimal:
    return price * qty

def order_total(items, discount_pct: int = 0) -> Decimal:
    total = Decimal("0")
    for i in range(1, len(items)):
        price, qty = items[i]
        total += line_total(price, qty)
    return total - total * Decimal(discount_pct) / 100
```

Tests run with `pytest -q`. Fix it.
