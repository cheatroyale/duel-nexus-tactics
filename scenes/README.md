# scenes/

`main.tscn` is the boot scene (`project.godot` -> `application/run/main_scene`).
It is a single `Control` with `scripts/ui/screens/main.gd` attached; every
screen below it is currently built in code.

| Folder | For |
| --- | --- |
| `screens/` | `.tscn` files for full screens (`team_builder.tscn`, `battle.tscn`, ...) once a screen outgrows code-built layout. |
| `components/` | Reusable scene pieces (`card_view.tscn`, `hp_bar.tscn`, `trait_chip.tscn`). |

Conventions:

* A screen scene keeps its controller in `scripts/ui/screens/` and only
  declares layout; rules stay out of scenes entirely.
* The boot scene is the only scene the project loads by path. Everything else
  is reached through the router in `scripts/ui/screens/main.gd`.
