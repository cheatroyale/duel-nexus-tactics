class_name CardInstance
extends RefCounted

## One card in play (or on the drafting table).
##
## The card's printed numbers come from DB. Traits are layered on top and every
## stack multiplies its effect; auras from living allies add up as well. All of
## that math lives here so the battle and the squad builder agree on it.

var id := ""
var data: Dictionary = {}
var traits: Dictionary = {}

# Battle state.
var max_hp := 0
var hp := 0
var atk_bonus := 0
var alive := true
var has_acted := false
var is_player := true


static func create(card_id: String) -> CardInstance:
	var c := CardInstance.new()
	c.id = card_id
	c.data = DB.card(card_id)
	c.max_hp = c.max_hp_total()
	c.hp = c.max_hp
	return c


## Copy a trait loadout into a fresh, writable dictionary. Const data in DB is
## read-only, so blueprints must be copied rather than referenced.
static func traits_from(source: Dictionary) -> Dictionary:
	var copy: Dictionary = {}
	for key in source:
		copy[String(key)] = int(source[key])
	return copy


## Build a card from an encounter blueprint: {"card": id, "traits": {...}}.
static func from_blueprint(blueprint: Dictionary) -> CardInstance:
	var c := create(String(blueprint.get("card", "")))
	var traits_data: Dictionary = blueprint.get("traits", {})
	c.traits = traits_from(traits_data)
	c.max_hp = c.max_hp_total()
	c.hp = c.max_hp
	return c


func card_name() -> String:
	return String(data.get("name", id))


func element() -> String:
	return String(data.get("element", "Stone"))


func ability() -> Dictionary:
	return data.get("ability", {})


func atk_base() -> int:
	return int(data.get("atk", 0))


func hp_base() -> int:
	return int(data.get("hp", 0))


func trait_stacks(trait_id: String) -> int:
	return int(traits.get(trait_id, 0))


func add_trait(trait_id: String) -> void:
	traits[trait_id] = trait_stacks(trait_id) + 1


func remove_trait(trait_id: String) -> void:
	var stacks := trait_stacks(trait_id)
	if stacks <= 1:
		traits.erase(trait_id)
	else:
		traits[trait_id] = stacks - 1


## Trait ids on this card, in codex order.
func trait_list() -> Array[String]:
	var out: Array[String] = []
	for trait_id in DB.TRAIT_ORDER:
		if trait_stacks(String(trait_id)) > 0:
			out.append(String(trait_id))
	return out


# --- Stacked stat math ------------------------------------------------------

## Sum of this card's own trait modifiers for one stat key.
func self_stat(key: String) -> int:
	var total := 0
	for trait_id in traits:
		var stacks := trait_stacks(String(trait_id))
		if stacks <= 0:
			continue
		var mods: Dictionary = DB.trait(String(trait_id)).get("mods", {})
		total += int(mods.get(key, 0)) * stacks
	return total


## Sum of this card's aura modifiers (it grants these to every living ally).
func aura_stat(key: String) -> int:
	var total := 0
	for trait_id in traits:
		var stacks := trait_stacks(String(trait_id))
		if stacks <= 0:
			continue
		var mods: Dictionary = DB.trait(String(trait_id)).get("team_mods", {})
		total += int(mods.get(key, 0)) * stacks
	return total


## Auras granted to a card by every living ally (including itself).
func team_bonus(key: String, allies: Array) -> int:
	var total := 0
	for ally in allies:
		if ally is CardInstance and ally.alive:
			total += ally.aura_stat(key)
	return total


func max_hp_total() -> int:
	return maxi(1, hp_base() + self_stat("hp"))


func attack_total(allies: Array) -> int:
	var atk := atk_base() + self_stat("atk") + team_bonus("atk", allies) + atk_bonus
	if max_hp > 0 and hp > 0 and hp * 2 <= max_hp:
		atk += self_stat("berserk")
	return maxi(0, atk)


func shield_total(allies: Array) -> int:
	return maxi(0, self_stat("shield") + team_bonus("shield", allies))


func thorns_total(allies: Array) -> int:
	return maxi(0, self_stat("thorns") + team_bonus("thorns", allies))


func lifesteal_total(allies: Array) -> int:
	return maxi(0, self_stat("lifesteal") + team_bonus("lifesteal", allies))


func regen_total(allies: Array) -> int:
	return maxi(0, self_stat("regen") + team_bonus("regen", allies))


func soul_gain() -> int:
	return maxi(0, self_stat("soul"))


func death_burst_damage() -> int:
	return maxi(0, self_stat("death_burst"))
