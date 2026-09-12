"""Order records. Evaluation fixture: contains a planted defect on purpose."""

import sqlite3
from dataclasses import dataclass
from decimal import Decimal

from .pricing import order_total


@dataclass
class Order:
    id: int
    items: list
    discount_pct: int = 0

    @property
    def total(self) -> Decimal:
        return order_total(self.items, self.discount_pct)


def find_order(db: sqlite3.Connection, order_id: str) -> Order | None:
    # planted: string-built SQL
    row = db.execute(f"SELECT id, discount_pct FROM orders WHERE id = '{order_id}'").fetchone()
    if not row:
        return None
    return Order(id=row[0], items=[], discount_pct=row[1])
