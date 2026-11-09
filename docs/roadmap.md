# Roadmap

Ordered by how much Siralim-like depth each item adds per unit of work.

## 1. Fusion (next)

Two cards become one: stats averaged or weighted, both trait loadouts merged,
the result keeps a lineage record. It plugs straight into
`CardInstance.traits` and the blueprint format in `data/`; the UI needs a
two-slot picker screen in `scripts/ui/screens/`.

Decisions to make: stack cap after a merge, whether fused cards inherit
abilities, and how the fusion cost scales.

## 2. Trait slots and a trigger table

* Give each card `slots` and a per-card point budget instead of one squad budget.
* Replace the per-effect `match` in `Battle._use_ability` with a trigger table:
  `on_attack`, `on_hit`, `on_kill`, `on_death`, `on_round_start`, each mapping
  to a small effect object in a new `scripts/battle/triggers.gd`. New traits
  then need data, not code.

## 3. Conditional auras

`team_bonus` already sums auras. Add a `condition` field to the trait
definition ("while this card is at full HP", "while another Hollow ally lives",
"per dead ally") and evaluate it in `CardInstance.aura_stat`.

## 4. Collection and progression

* Owned cards with levels / ranks; encounters drop cards and trait shards.
* Expand the save file: `GameState` becomes a real profile (`cards`, `squad`,
  `unlocked`) with a version field from day one.
* Encounter resources in `data/encounters/` gain reward tables.

## 5. Deckbuilding layer (optional direction)

Squad becomes a deck: draw a hand, pay energy to place cards on the board, traits
are attached to cards in the deck. `Battle` already owns the energy economy, so
this is mostly a new `scripts/battle/hand.gd` and a board layout pass.

## 6. Presentation

* Art pipeline: `assets/art/cards/<card_id>.png` loaded by `CardView`.
* Audio: `Battle` emits structured log lines today; add event signals
  (`damaged`, `died`, `healed`) and let an audio director listen.
* Juice: tween HP bars, hit flashes, card hover lift in `CardView`.

## 7. Engineering hygiene

* Git repository plus CI (headless Godot run + unit tests) once the layout is in
  place.
* Export presets for desktop and mobile (`project.godot` uses the mobile
  renderer).
* Balance sweep script in `tests/` that plays every encounter N times with
  random legal squads and reports win rates.
