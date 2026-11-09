# scripts/

Code is grouped by domain, and dependencies point one way:

`autoload` -> `data` -> `cards` -> `battle` -> `ui`

`battle` never touches the scene tree (so it stays unit-testable), and `ui`
never contains rules.

| Folder | Responsibility |
| --- | --- |
| `autoload/` | Singletons registered in `project.godot` (currently `GameState`: saved progress). |
| `data/` | The content catalog `db.gd` and static lookups. No state, no nodes. |
| `cards/` | `CardInstance`: a card's runtime state and its stacked stats (own mods, auras, buffs, shields). |
| `battle/` | `Battle`: energy, turn order, attacks, abilities, deaths, triggers and the enemy AI. |
| `ui/palette.gd` | Colours and widget factories shared by every screen. |
| `ui/components/` | Reusable widgets (`card_view.gd`). |
| `ui/screens/` | Screen controllers (`main.gd` router, `team_builder.gd`, `battle_view.gd`). |

Where new code goes:

* New trait, card or encounter: `data/db.gd`, no new files.
* New stat key or conditional modifier: `cards/card_instance.gd`.
* New trigger, keyword or AI behaviour: `battle/battle.gd`, or a new file in
  `battle/` once it grows (for example `battle/triggers.gd`).
* New screen or widget: `ui/screens/` or `ui/components/`, plus its `.tscn` in
  `scenes/` if it needs one.

Conventions:

* A script that another script refers to by name gets a `class_name`
  (`DB`, `CardInstance`, `Battle`, `CardView`, `TeamBuilder`, `BattleView`,
  `Palette`). Screens and the autoload stay anonymous and are reached by path.
* Teams are `Array[CardInstance]`; everything else is typed where it can be.
* One domain folder per concern rather than a flat `scripts/` dump, so a
  growing game does not end up with thirty files in one list.
