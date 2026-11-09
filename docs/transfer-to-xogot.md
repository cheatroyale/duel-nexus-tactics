# Moving this project into Xogot

This chat writes to **one** project folder, inside this app's own storage:

```
…/Documents/UserProjects/Duel Nexus Tactics
```

Xogot keeps its projects in **Xogot's** app storage. iOS gives each app its own
container, so this chat cannot read or write Xogot's copy, and Xogot cannot see
this one. That is why nothing done here shows up there. There is no path this
chat can hand Xogot — the code has to be transferred once, by one of the routes
below.

The project's source is committed on `main` in this folder, so whatever leaves
it is exactly the game that was written. This document is also readable in-game
from the main menu's **Docs** button, alongside **Sync check**
(`SYNC-CHECK.md` at the project root), which is the quickest way to tell whether
Xogot opens this folder or a different copy.

## Route A — GitHub (done)

The project is published at
**https://github.com/cheatroyale/duel-nexus-tactics** on branch `main`, and this
folder pushes there.

1. On the device, open the repo and use **Code → Download ZIP** (or `git clone`
   on a computer).
2. In Xogot: project manager → import the unzipped folder (or copy it into
   Xogot's project folder and open it). `project.godot` sits at the folder root,
   which is what Xogot needs to see.
3. Open the project and press Play. `scenes/main.tscn` is the boot scene.

Keeping Xogot up to date after that is `git pull`, and later changes in this
chat can be pushed to the same repo.

## Route B — manual copy

If the app's own project browser (not the iOS Files app) can show or share this
project, that browser is the only place the folder appears. Copy the files in
this order — the folder names matter, the `.gdkeep` files are only there to keep
empty folders alive and can be skipped.

```
project.godot
icon.svg
icon.svg.import
.editorconfig
.gitattributes
.gitignore
README.md
docs/architecture.md
docs/roadmap.md
assets/README.md
data/README.md
scenes/README.md
scenes/main.tscn
scripts/README.md
scripts/autoload/game_state.gd
scripts/data/db.gd
scripts/cards/card_instance.gd
scripts/battle/battle.gd
scripts/ui/palette.gd
scripts/ui/components/card_view.gd
scripts/ui/screens/main.gd
scripts/ui/screens/team_builder.gd
scripts/ui/screens/battle_view.gd
tests/README.md
```

Two files contain absolute script paths. If you rebuild the tree by hand, check
them:

* `project.godot` → `GameState="*res://scripts/autoload/game_state.gd"`
* `scenes/main.tscn` → `[ext_resource … path="res://scripts/ui/screens/main.gd" …]`

Every other reference between scripts is by `class_name` (`DB`, `CardInstance`,
`Battle`, `CardView`, `TeamBuilder`, `BattleView`, `Palette`), so files can sit
in any folder as long as those two paths are right.

## What must not be copied

`.godot/` — that is Godot's generated import cache and editor state. Xogot
rebuilds it on first open. Copying a stale one from another editor causes
exactly the "my files are not there" confusion. `.git/` is only needed for
Route A.

## Why Xogot may look stale even after the copy

Xogot caches a project's file list when it opens it. After files arrive from
outside, close the project and reopen it (or use its reload/rescan action).
Asset imports (`.import`) are regenerated on that first open, which can take a
moment.
