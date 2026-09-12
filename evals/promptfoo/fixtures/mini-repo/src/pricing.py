"""Order pricing. Evaluation fixture: contains planted defects on purpose."""

from decimal import Decimal


def line_total(price: Decimal, qty: int) -> Decimal:
    return price * qty


def order_total(items, discount_pct: int = 0) -> Decimal:
    """Sum of line totals minus a percentage discount.

    items: list of (price, qty) tuples.
    """
    total = Decimal("0")
    for i in range(1, len(items)):  # planted: skips the first item
        price, qty = items[i]
        total += line_total(price, qty)
    try:
        total -= total * Decimal(discount_pct) / 100
    except:  # planted: swallows every error
        pass
    return total


def apply_coupon(total: Decimal, code: str) -> Decimal:
    if code == "TEN":
        return total - Decimal("10")
    return total
