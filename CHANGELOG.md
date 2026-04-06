# CHANGELOG

## 2026-04-06

### Completed
- Cloned and ran all 21 t_demos: 19/21 passed (2 upstream bugs in model_comparison_with_glance_t and onnx_exchange_t)
- Cloned hello_t package, fixed `sprintf` → `str_join` for T v0.51.2 compatibility, forked to JohnGavin/hello_t with tag v0.1.1
- Built my_t_project pipeline: T (read CSV) → R (dplyr clinical summary) → R (report), with DuckDB anonymization in --network=none OrbStack container as pre-step
- Created GitHub repos: JohnGavin/my_t_project, JohnGavin/hello_t (fork)
- Created `.claude/rules/tlang-reference.md` with full URL table, CLI commands, serializer reference, common gotchas
- Created memory files: `tlang-api-changes.md` (v0.51.2 breaking changes), `tlang-nix-workflow.md` (two-pass flake workflow)
- Documented targets vs T pipelines comparison, PMML vs ONNX comparison

### Failed Approaches
- `nix develop` inside demos fails — demos don't have their own flake.nix. Must use `nix shell github:b-rodrigues/tlang --command t run`. Workaround: two-pass git workflow to generate flake files.
- Docker/DuckDB inside T `shn()` node fails — Nix build sandbox can't access Docker socket. Workaround: run anonymization as pre-step outside the pipeline.
- `t update` leaves `.bak` files that dirty the git working tree, blocking subsequent `t update` calls. Workaround: `rm -f *.bak` between operations.

### Known Limitations
- 2 upstream t_demos broken on v0.51.2: `model_comparison_with_glance_t` (fit_stats type error), `onnx_exchange_t` (dataframe API change)
- hello_t package dependency commented out in my_t_project/tproject.toml — T package import in projects not yet tested end-to-end
- No T language skill created yet (rule + memory only) — premature until regular T development begins
