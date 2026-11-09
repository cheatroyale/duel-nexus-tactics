# tests/

`Battle` and `CardInstance` are plain `RefCounted` objects with no scene tree
access, so the rules can be tested headlessly.

* Pick one framework and install it into `addons/` (gdUnit4 or GUT); keep the
  plugin folder out of `scripts/`.
* Name test files `*_test.gd` and mirror the code path:
  `tests/cards/card_instance_test.gd`, `tests/battle/battle_test.gd`.
* Highest-value cases: aura stacking when an ally dies, shield minimum damage,
  thorns killing the attacker, death burst chains, soul feast gains, energy per
  round, and a full encounter played to victory and to a loss.
* Balance sweeps can be built on the same seam: play every encounter many times
  with random legal squads and report win rates.

Run headless (command differs per framework version), for example:

```
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests
```
