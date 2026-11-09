# Architecture

## Layers

```
ui (Control scripts)
  -> battle (Battle)
    -> cards (CardInstance)
      -> data (DB)
```

* `scripts/data/db.gd` — `const` dictionaries only. Read-only content: traits,
  cards, encounters, and the text helpers that describe them.
* `scripts/cards/card_instance.gd` — one card's state and *all* of its stat math.
  Nothing else computes ATK / max HP / shield / thorns, so the squad builder and
  the battle always show the same numbers.
* `scripts/battle/battle.gd` — the rules. Signals: `log_added(text)`,
  `state_changed`. Public player API: `player_attack`, `player_ability`,
  `player_pass`, `end_player_turn`. Everything else is internal.
* `scripts/ui/*` — screens and widgets. They read battle state and call that
  player API; they never mutate `CardInstance` during a fight.

`autoload/game_state.gd` sits beside the stack: it only owns out-of-battle
progress, so no battle code depends on a singleton.

## Why the split

* Rules are `RefCounted` with no `get_tree()` anywhere, so they can be unit
  tested and simulated headlessly. That is the seam for balance sweeps, replays
  and (later) AI tuning.
* Screens are code-built `Control`s. No `.tscn` merge conflicts while layout is
  still moving; scene files can be introduced screen by screen later, in
  `scenes/screens/` and `scenes/components/`.
* Content is one catalog file today. It is deliberately isolated in `data/` so
  it can become Resource files in `data/traits/`, `data/cards/`,
  `data/encounters/` without touching rules or UI.

## Data flow of one action

1. `BattleView` creates `Battle.new()` and calls `battle.setup(player, enemy)`.
2. A click becomes `battle.player_attack(attacker, target)` (or
   `player_ability`).
3. `Battle` spends energy, marks `has_acted`, computes
   `attacker.attack_total(allies)`, applies shield / thorns / lifesteal / death
   triggers, and emits log lines.
4. `BattleView` re-renders from the battle object; it keeps only UI state
   (`selected_card`, `targeting`, `busy`).

## Conventions

* A script that another script refers to by name gets a `class_name` (`DB`,
  `CardInstance`, `Battle`, `CardView`, `TeamBuilder`, `BattleView`, `Palette`).
  Screens and the autoload stay anonymous and are reached by path.
* Teams are typed (`Array[CardInstance]`); parameters and returns are typed
  wherever the types are stable.
* No magic numbers in UI: costs, max stacks and budgets live in data or in
  `Battle`'s constants.
* Every folder that exists for future content has a short `README.md` saying
  what belongs there, so the structure explains itself.
