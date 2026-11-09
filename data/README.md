# data/

Authored game content that is not code: the things a designer edits without
touching logic.

Today all content lives in one catalog, `scripts/data/db.gd` (const
dictionaries `TRAITS`, `CARDS`, `ENCOUNTERS`), because it is still small and
reads fast. These folders are the intended home once content outgrows one file:

| Folder | Future contents |
| --- | --- |
| `data/traits/` | One `TraitDef` resource per trait (`frenzy.tres`): id, cost, max stacks, `mods`, `team_mods`, trigger hooks. |
| `data/cards/` | One `CardDef` resource per card (`emberling.tres`): stats, element, ability, starting traits. |
| `data/encounters/` | One `EncounterDef` per fight: ordered card blueprints with trait stacks, reward table. |

Rules that hold today and after the migration:

* **Ids are the API.** `emberling` is referenced from cards, encounters, save
  data and art file names. Never rename a shipped id; add a new one.
* A card resource must carry everything needed to rebuild a `CardInstance`
  without code changes.
* Balance numbers (costs, max stacks, HP, ATK) live in the data layer, never in
  UI code.
* Cross-references stay by id (`{"card": "wisp", "traits": {"frenzy": 2}}`),
  so data files never point at each other's file paths.
