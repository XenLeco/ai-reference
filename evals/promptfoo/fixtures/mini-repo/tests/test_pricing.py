from decimal import Decimal

from src.pricing import line_total


def test_line_total():
    assert line_total(Decimal("2.50"), 4) == Decimal("10.00")
