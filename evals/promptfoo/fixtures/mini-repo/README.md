# mini-shop (evaluation fixture)

A deliberately defective toy project used by `evals/promptfoo/promptfooconfig.agents.yaml`.
Planted defects: `order_total` skips the first item and swallows errors; `find_order` builds
SQL by string formatting. Do not fix them here; the evals expect them.
