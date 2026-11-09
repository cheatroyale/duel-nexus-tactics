# assets/

Source art, audio and fonts. Nothing here is loaded by the game yet: the UI is
drawn with theme colours and the default font, so these folders are the runway
for the first real art and audio pass.

| Folder | Put here |
| --- | --- |
| `art/cards/` | Card portraits, one file per card id (`emberling.png`), 512x512 source. |
| `art/ui/` | Frames, element icons, cursors, panels, background textures. |
| `audio/music/` | Menu and battle loops (`.ogg`). |
| `audio/sfx/` | Short one-shots: hits, heals, card plays, UI clicks (`.wav`). |
| `fonts/` | UI and body fonts (`.ttf` / `.otf`) with their `.import` settings. |

Conventions:

* snake_case file names. Card art is named exactly after the card id in
  `scripts/data/db.gd`, so a loader can find art by id with no mapping table.
* Keep sources here and let Godot import them; `.godot/imported/` is generated
  and ignored by git.
* The project icon (`icon.svg`) stays at the project root, which is where
  `project.godot` expects it.
* Empty folders carry a `.gdkeep` so they survive version control.
