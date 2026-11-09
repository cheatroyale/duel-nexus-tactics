# Duel Nexus Tactics

*A card tactics academy RPG.*

A team-building card battler in Godot 4. Cards are creatures you draft into a
squad of five; traits are the "stack components" you layer on them, Siralim-style
— every stack multiplies the effect, and auras from different cards add up.

Open `project.godot` in Godot 4 and press Play. The boot scene is
`scenes/main.tscn`.

## How to play

1. **Build a Squad** — pick up to five cards from the roster, then click a card
   in *Your Squad* to select it and click `+1` on a trait in the codex to stack
   it. Click a trait chip on a card to remove one stack.
2. **Pick an encounter** in the footer and press *Begin Battle*.
3. **Fight** — click one of your cards, then *Attack (1)* and an enemy, or use
   its ability. Each card acts once per round; *End Turn* runs the enemy turn and
   starts the next round (both sides gain 2 energy, regeneration ticks).

## The stacking rules

* The squad shares **12 trait points**; a trait costs its price *per stack*.
* `mods` in a trait are **self** buffs; `team_mods` are **auras** granted to
  every living ally (the carrier included).
* Auras are summed across the team, so two Pack Leaders give the whole squad
  +2 ATK. Auras switch off the moment their carrier dies.
* Card stats are recomputed from scratch on every read (`CardInstance`), so
  trait stacks, buffs, debuffs and aura changes never drift out of sync.

## Folder map

```
assets/          art, audio, fonts (source files; see assets/README.md)
data/            authored content resources (see data/README.md)
docs/            architecture, roadmap, transfer notes (read in-game via Docs)
SYNC-CHECK.md    marker doc: is Xogot opening this folder? (Docs -> Sync check)
scenes/
  main.tscn      the boot scene
  screens/       future .tscn screens
  components/    future .tscn widgets
scripts/
  autoload/      game_state.gd          saved progress (autoload)
  data/          db.gd                  all content: traits, cards, encounters
  cards/         card_instance.gd       runtime card + stacked stat math
  battle/        battle.gd              turn-based rules, no scene tree
  ui/            palette.gd             colours + shared widget factories
    components/  card_view.gd           the card widget
    screens/     main.gd, team_builder.gd, battle_view.gd
tests/           future headless rule tests (see tests/README.md)
```

Dependencies point one way: `autoload` -> `data` -> `cards` -> `battle` -> `ui`.
Details in [docs/architecture.md](docs/architecture.md); what to build next in
[docs/roadmap.md](docs/roadmap.md).

## Adding content

**A card** — add an entry to `DB.CARDS` in `scripts/data/db.gd` and its id to
`DB.CARD_ORDER`:

```gdscript
"my_card": {
    "name": "My Card",
    "element": "Ember",          # palette colour key
    "atk": 5,
    "hp": 15,
    "ability": {"name": "Blast", "cost": 2, "effect": "damage_single", "value": 7},
},
```

Ability effects understood by `Battle._use_ability`: `damage_single`,
`damage_all`, `heal_lowest`, `heal_self`, `drain`, `buff_team`,
`debuff_single`.

**A trait** — add to `DB.TRAITS` and `DB.TRAIT_ORDER`. Stat keys the engine reads:
`atk`, `hp`, `shield`, `thorns`, `lifesteal`, `regen`, `berserk`, `soul`,
`death_burst`. A new key needs a reader in `CardInstance` and a use in `Battle`.

**An encounter** — add to `DB.ENCOUNTERS`; each entry is a list of
`{"card": id, "traits": {trait_id: stacks}}` blueprints, so enemy teams are
designed with the same stacking rules the player uses.

Ids are the API: card art, encounter blueprints and save data all point at them
by id, so never rename a shipped one.

## Deliberate scope of this first slice

* Enemy AI always attacks a random living card (and uses its ability ~45% of the
  time when it can afford it). Player abilities auto-target: damage hits the
  weakest enemy, heals go to the most wounded ally, curses hit the strongest
  enemy. Only basic attacks are manually targeted.
* All three encounters are unlocked from the start (sandbox for tuning);
  cleared progress is saved only as a counter.
* No persistence of squads, no card collection/fusion, no creature levels yet.
