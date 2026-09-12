Write the pull request title and description for branch `fix/router-529` against `main`. The work was done with OpenCode on `coder-fast` and reviewed by me. Tests were run with `pytest -q` (all 142 passed) and the gateway smoke test `gateway/scripts/smoke-test.sh` (all checks passed).

Commits:
```
a1b2c3d fix(gateway): treat Anthropic 529 as retriable
d4e5f6a test(gateway): cover 529 fallback path
```

Diff stat:
```
 gateway/router.py            |  5 ++++-
 tests/test_router.py         | 18 ++++++++++++++++++
 docs/02-gateway-litellm.md   |  2 +-
 3 files changed, 23 insertions(+), 2 deletions(-)
```
