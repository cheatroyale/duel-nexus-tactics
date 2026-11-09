class_name DB
extends RefCounted

## Static game data.
##
## Everything the game plays with lives here: cards, traits ("stack
## components") and the encounter gauntlet. The rest of the code only reads
## from this file, so adding content means editing dictionaries, not logic.

# --- Traits -----------------------------------------------------------------
#
# A trait is a "stack component": it can be layered several times on one card,
# and on several cards of the same squad. Every stack multiplies its effect.
#
#   "mods"      -> self only
#   "team_mods" -> every living ally, including the carrier (auras stack from
#                  each living ally, so two Pack Leaders add up)
#
# Stat keys understood by CardInstance:
#   atk, hp, shield, thorns, lifesteal, regen, berserk, soul, death_burst

const TRAIT_ORDER := [
	"frenzy",
	"vitality",
	"bulwark",
	"thornmail",
	"bloodthirst",
	"berserker",
	"regeneration",
	"packleader",
	"aegis",
	"soulfeast",
	"deathburst",
]

const TRAITS := {
	"frenzy": {
		"name": "Frenzy",
		"cost": 1,
		"max_stacks": 3,
		"mods": {"atk": 2},
		"text": "This card gains ATK per stack.",
	},
	"vitality": {
		"name": "Vitality",
		"cost": 1,
		"max_stacks": 3,
		"mods": {"hp": 6},
		"text": "This card gains Max HP per stack.",
	},
	"bulwark": {
		"name": "Bulwark",
		"cost": 2,
		"max_stacks": 2,
		"mods": {"shield": 1},
		"text": "Reduce all damage this card takes (minimum 1).",
	},
	"thornmail": {
		"name": "Thornmail",
		"cost": 1,
		"max_stacks": 3,
		"mods": {"thorns": 1},
		"text": "Attackers take damage back.",
	},
	"bloodthirst": {
		"name": "Bloodthirst",
		"cost": 1,
		"max_stacks": 3,
		"mods": {"lifesteal": 1},
		"text": "Heal when this card attacks.",
	},
	"berserker": {
		"name": "Berserker",
		"cost": 1,
		"max_stacks": 3,
		"mods": {"berserk": 3},
		"text": "Extra ATK while at half HP or below.",
	},
	"regeneration": {
		"name": "Regeneration",
		"cost": 2,
		"max_stacks": 2,
		"mods": {"regen": 1},
		"text": "Heal at the start of each round.",
	},
	"packleader": {
		"name": "Pack Leader",
		"cost": 2,
		"max_stacks": 2,
		"team_mods": {"atk": 1},
		"text": "Every living ally gains ATK per stack.",
	},
	"aegis": {
		"name": "Aegis",
		"cost": 3,
		"max_stacks": 1,
		"team_mods": {"shield": 1},
		"text": "Every living ally takes less damage.",
	},
	"soulfeast": {
		"name": "Soul Feast",
		"cost": 2,
		"max_stacks": 2,
		"mods": {"soul": 1},
		"text": "Gain ATK permanently whenever an enemy dies.",
	},
	"deathburst": {
		"name": "Death Burst",
		"cost": 2,
		"max_stacks": 2,
		"mods": {"death_burst": 2},
		"text": "On death, deal damage to every enemy.",
	},
}

const STAT_LABELS := {
	"atk": "ATK",
	"hp": "max HP",
	"shield": "damage reduction",
	"thorns": "thorns damage",
	"lifesteal": "lifesteal",
	"regen": "HP regen",
	"berserk": "ATK at half HP",
	"soul": "ATK per enemy slain",
	"death_burst": "death burst damage",
}

# --- Cards ------------------------------------------------------------------

const CARD_ORDER := [
	"emberling",
	"cinder_knight",
	"storm_herald",
	"frost_sentinel",
	"grove_warden",
	"stone_golem",
	"bone_reaper",
	"bog_witch",
	"wisp",
	"pack_alpha",
]

const CARDS := {
	"emberling": {
		"name": "Emberling",
		"element": "Ember",
		"atk": 5,
		"hp": 14,
		"ability": {"name": "Fireball", "cost": 2, "effect": "damage_single", "value": 6},
	},
	"cinder_knight": {
		"name": "Cinder Knight",
		"element": "Ember",
		"atk": 5,
		"hp": 18,
		"ability": {"name": "Cleave", "cost": 3, "effect": "damage_all", "value": 5},
	},
	"storm_herald": {
		"name": "Storm Herald",
		"element": "Storm",
		"atk": 5,
		"hp": 15,
		"ability": {"name": "Static Field", "cost": 3, "effect": "damage_all", "value": 3},
	},
	"frost_sentinel": {
		"name": "Frost Sentinel",
		"element": "Frost",
		"atk": 4,
		"hp": 20,
		"ability": {"name": "Chill", "cost": 2, "effect": "debuff_single", "value": 2},
	},
	"grove_warden": {
		"name": "Grove Warden",
		"element": "Verdant",
		"atk": 3,
		"hp": 22,
		"ability": {"name": "Mend", "cost": 2, "effect": "heal_lowest", "value": 8},
	},
	"stone_golem": {
		"name": "Stone Golem",
		"element": "Stone",
		"atk": 3,
		"hp": 26,
		"ability": {"name": "Fortify", "cost": 1, "effect": "heal_self", "value": 6},
	},
	"bone_reaper": {
		"name": "Bone Reaper",
		"element": "Hollow",
		"atk": 6,
		"hp": 12,
		"ability": {"name": "Reap", "cost": 3, "effect": "damage_all", "value": 4},
	},
	"bog_witch": {
		"name": "Bog Witch",
		"element": "Hollow",
		"atk": 3,
		"hp": 16,
		"ability": {"name": "Curse", "cost": 2, "effect": "debuff_single", "value": 3},
	},
	"wisp": {
		"name": "Wisp",
		"element": "Spirit",
		"atk": 4,
		"hp": 13,
		"ability": {"name": "Drain", "cost": 2, "effect": "drain", "value": 4},
	},
	"pack_alpha": {
		"name": "Pack Alpha",
		"element": "Wild",
		"atk": 6,
		"hp": 16,
		"ability": {"name": "Rally", "cost": 2, "effect": "buff_team", "value": 2},
	},
}

# --- Encounters -------------------------------------------------------------
#
# "traits" maps trait id -> stacks. The enemy team is built straight from these
# blueprints, so an encounter is just a squad the designer pre-assembled.

const ENCOUNTERS := [
	{
		"name": "Ashen Pack",
		"desc": "Three beasts that share a single pack instinct. Fast, fragile.",
		"team": [
			{"card": "emberling", "traits": {"frenzy": 2}},
			{"card": "pack_alpha", "traits": {"packleader": 1}},
			{"card": "wisp", "traits": {"bloodthirst": 1}},
		],
	},
	{
		"name": "Hollow Choir",
		"desc": "Something that punishes every hit you land, and does not stay dead quietly.",
		"team": [
			{"card": "bone_reaper", "traits": {"deathburst": 1}},
			{"card": "bog_witch", "traits": {"thornmail": 2}},
			{"card": "wisp", "traits": {"bloodthirst": 1, "vitality": 1}},
			{"card": "frost_sentinel", "traits": {"bulwark": 1}},
		],
	},
	{
		"name": "Titan's Court",
		"desc": "Four veterans with maxed stacking. Auras on auras. Bring a plan.",
		"team": [
			{"card": "stone_golem", "traits": {"bulwark": 2, "thornmail": 1}},
			{"card": "grove_warden", "traits": {"regeneration": 2}},
			{"card": "cinder_knight", "traits": {"frenzy": 2, "berserker": 1}},
			{"card": "frost_sentinel", "traits": {"aegis": 1, "vitality": 2}},
		],
	},
]


static func card(card_id: String) -> Dictionary:
	return CARDS.get(card_id, {})


static func trait(trait_id: String) -> Dictionary:
	return TRAITS.get(trait_id, {})


static func encounter(index: int) -> Dictionary:
	if index < 0 or index >= ENCOUNTERS.size():
		return {}
	return ENCOUNTERS[index]


## Short rules text for an ability dictionary, for tooltips.
static func ability_summary(ability: Dictionary) -> String:
	if ability.is_empty():
		return "No ability."
	var value := int(ability.get("value", 0))
	match String(ability.get("effect", "")):
		"damage_single":
			return "Deal %d damage to the weakest enemy." % value
		"damage_all":
			return "Deal %d damage to every enemy." % value
		"heal_lowest":
			return "Heal %d to the most wounded ally." % value
		"heal_self":
			return "Heal %d to this card." % value
		"drain":
			return "Deal %d damage to the weakest enemy, then heal %d to this card." % [value, value]
		"buff_team":
			return "Every living ally permanently gains +%d ATK." % value
		"debuff_single":
			return "The strongest enemy permanently loses %d ATK." % value
	return "Unknown effect."


## A one-line description of what `stacks` of a trait actually do right now.
static func trait_summary(trait_id: String, stacks: int) -> String:
	var data := trait(trait_id)
	var parts := ""
	parts = _append_mods(parts, data.get("mods", {}), stacks, "")
	parts = _append_mods(parts, data.get("team_mods", {}), stacks, "all allies ")
	var text := String(data.get("text", ""))
	if parts == "":
		return text
	return "%s (%s)" % [text, parts]


static func _append_mods(parts: String, mods: Dictionary, stacks: int, prefix: String) -> String:
	for key in mods:
		var amount := int(mods[key]) * stacks
		if amount == 0:
			continue
		var label := String(STAT_LABELS.get(key, String(key)))
		if parts != "":
			parts += ", "
		parts += "%s+%d %s" % [prefix, amount, label]
	return parts
