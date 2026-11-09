class_name Battle
extends RefCounted

## Turn-based card battle between two squads.
##
## Pure logic: no scene tree access, so the view can be swapped or tested
## without touching the rules. The view calls the player_* methods and then
## end_player_turn(), and listens to log_added to narrate what happened.

signal log_added(text: String)
signal state_changed

const ATTACK_COST := 1
const ENERGY_PER_ROUND := 2
const MAX_ENERGY := 10
const START_ENERGY := 3

var player_team: Array[CardInstance] = []
var enemy_team: Array[CardInstance] = []
var round_number := 1
var player_energy := START_ENERGY
var enemy_energy := START_ENERGY
var is_over := false
var player_won := false
var history: Array[String] = []


func setup(player: Array[CardInstance], enemy: Array[CardInstance]) -> void:
	player_team = player
	enemy_team = enemy
	for c in player_team:
		_prepare(c, true)
	for c in enemy_team:
		_prepare(c, false)
	round_number = 1
	player_energy = START_ENERGY
	enemy_energy = START_ENERGY
	is_over = false
	player_won = false
	history.clear()
	_log("Battle begins. Round 1.")
	state_changed.emit()


func _prepare(c: CardInstance, is_player: bool) -> void:
	c.is_player = is_player
	c.alive = true
	c.has_acted = false
	c.atk_bonus = 0
	c.max_hp = c.max_hp_total()
	c.hp = c.max_hp


# --- Queries ----------------------------------------------------------------

func living(team: Array[CardInstance]) -> Array[CardInstance]:
	var out: Array[CardInstance] = []
	for c in team:
		if c.alive:
			out.append(c)
	return out


func allies_of(c: CardInstance) -> Array[CardInstance]:
	return living(player_team) if c.is_player else living(enemy_team)


func foes_of(c: CardInstance) -> Array[CardInstance]:
	return living(enemy_team) if c.is_player else living(player_team)


# --- Player actions ---------------------------------------------------------

func player_attack(attacker: CardInstance, target: CardInstance) -> bool:
	if is_over or not attacker.alive or attacker.has_acted or not target.alive:
		return false
	if not attacker.is_player:
		return false
	if player_energy < ATTACK_COST:
		_log("Not enough energy for an attack.")
		return false
	player_energy -= ATTACK_COST
	attacker.has_acted = true
	_log("%s attacks %s." % [attacker.card_name(), target.card_name()])
	_deal_damage(attacker, target, attacker.attack_total(allies_of(attacker)), true)
	_check_end()
	state_changed.emit()
	return true


func player_ability(attacker: CardInstance) -> bool:
	if is_over or not attacker.alive or attacker.has_acted or not attacker.is_player:
		return false
	var ability := attacker.ability()
	if ability.is_empty():
		return false
	var cost := int(ability.get("cost", 0))
	if player_energy < cost:
		_log("Not enough energy for %s." % String(ability.get("name", "that ability")))
		return false
	player_energy -= cost
	attacker.has_acted = true
	_use_ability(attacker)
	_check_end()
	state_changed.emit()
	return true


func player_pass(card: CardInstance) -> void:
	if is_over or not card.alive or card.has_acted:
		return
	card.has_acted = true
	_log("%s holds position." % card.card_name())
	state_changed.emit()


func end_player_turn() -> void:
	if is_over:
		return
	enemy_turn()
	if is_over:
		return
	start_round()


# --- Rounds & enemy AI ------------------------------------------------------

func enemy_turn() -> void:
	if is_over:
		return
	_log("Enemy turn.")
	for c in living(enemy_team):
		if is_over:
			break
		if c.alive:
			_ai_act(c)
	_check_end()
	state_changed.emit()


func _ai_act(c: CardInstance) -> void:
	var ability := c.ability()
	var cost := int(ability.get("cost", 0))
	if not ability.is_empty() and enemy_energy >= cost and randf() < 0.45:
		enemy_energy -= cost
		c.has_acted = true
		_use_ability(c)
		return
	var targets := living(player_team)
	if targets.is_empty():
		return
	if enemy_energy < ATTACK_COST:
		_log("%s has no energy to act." % c.card_name())
		return
	enemy_energy -= ATTACK_COST
	c.has_acted = true
	var target: CardInstance = targets[randi() % targets.size()]
	_log("%s attacks %s." % [c.card_name(), target.card_name()])
	_deal_damage(c, target, c.attack_total(allies_of(c)), true)


func start_round() -> void:
	if is_over:
		return
	round_number += 1
	player_energy = mini(MAX_ENERGY, player_energy + ENERGY_PER_ROUND)
	enemy_energy = mini(MAX_ENERGY, enemy_energy + ENERGY_PER_ROUND)
	for c in player_team:
		_begin_round_card(c)
	for c in enemy_team:
		_begin_round_card(c)
	_log("Round %d begins." % round_number)
	state_changed.emit()


func _begin_round_card(c: CardInstance) -> void:
	if not c.alive:
		return
	c.has_acted = false
	var regen := c.regen_total(allies_of(c))
	if regen > 0:
		_heal(c, regen, "regeneration")


# --- Abilities --------------------------------------------------------------

func _use_ability(caster: CardInstance) -> void:
	var ability := caster.ability()
	var value := int(ability.get("value", 0))
	_log("%s uses %s." % [caster.card_name(), String(ability.get("name", "an ability"))])
	match String(ability.get("effect", "")):
		"damage_single":
			var target := _weakest(foes_of(caster))
			if target != null:
				_deal_damage(caster, target, value, false)
		"damage_all":
			for foe in foes_of(caster):
				_deal_damage(caster, foe, value, false)
		"heal_lowest":
			var ally := _most_wounded(allies_of(caster))
			if ally != null:
				_heal(ally, value)
		"heal_self":
			_heal(caster, value)
		"drain":
			var drain_target := _weakest(foes_of(caster))
			if drain_target != null:
				_deal_damage(caster, drain_target, value, false)
			_heal(caster, value, "drain")
		"buff_team":
			for ally in allies_of(caster):
				ally.atk_bonus += value
				_log("%s gains +%d ATK." % [ally.card_name(), value])
		"debuff_single":
			var cursed := _strongest(foes_of(caster))
			if cursed != null:
				cursed.atk_bonus -= value
				_log("%s loses %d ATK." % [cursed.card_name(), value])
		_:
			pass


func _weakest(team: Array) -> CardInstance:
	var best: CardInstance = null
	for c in team:
		if not c.alive:
			continue
		if best == null or c.hp < best.hp:
			best = c
	return best


func _strongest(team: Array) -> CardInstance:
	var best: CardInstance = null
	var best_atk := -1
	for c in team:
		if not c.alive:
			continue
		var atk := c.attack_total(team)
		if atk > best_atk:
			best_atk = atk
			best = c
	return best


func _most_wounded(team: Array) -> CardInstance:
	var best: CardInstance = null
	var best_ratio := 2.0
	for c in team:
		if not c.alive:
			continue
		var ratio := float(c.hp) / float(maxi(1, c.max_hp))
		if ratio < best_ratio:
			best_ratio = ratio
			best = c
	return best


# --- Damage, healing, death -------------------------------------------------

func _deal_damage(source: CardInstance, target: CardInstance, amount: int, from_attack: bool) -> void:
	if not target.alive or amount <= 0:
		return
	var blocked := target.shield_total(allies_of(target))
	var dmg := maxi(1, amount - blocked)
	var dealt := mini(dmg, target.hp)
	target.hp = maxi(0, target.hp - dmg)
	if blocked > 0:
		_log("%s takes %d damage (%d blocked, %d/%d)." % [target.card_name(), dealt, blocked, target.hp, target.max_hp])
	else:
		_log("%s takes %d damage (%d/%d)." % [target.card_name(), dealt, target.hp, target.max_hp])

	if target.hp <= 0:
		_kill(target)
		return
	if not from_attack or not source.alive:
		return

	var lifesteal := source.lifesteal_total(allies_of(source))
	if lifesteal > 0:
		_heal(source, lifesteal, "lifesteal")

	var thorns := target.thorns_total(allies_of(target))
	if thorns > 0 and source.alive:
		_log("%s's thorns strike %s." % [target.card_name(), source.card_name()])
		_deal_damage(target, source, thorns, false)


func _heal(card: CardInstance, amount: int, reason: String = "") -> void:
	if not card.alive or amount <= 0:
		return
	var before := card.hp
	card.hp = mini(card.max_hp, card.hp + amount)
	var gained := card.hp - before
	if gained <= 0:
		return
	if reason == "":
		_log("%s heals %d (%d/%d)." % [card.card_name(), gained, card.hp, card.max_hp])
	else:
		_log("%s heals %d from %s (%d/%d)." % [card.card_name(), gained, reason, card.hp, card.max_hp])


func _kill(card: CardInstance) -> void:
	if not card.alive:
		return
	card.alive = false
	card.hp = 0
	card.has_acted = true
	_log("%s falls." % card.card_name())

	var burst := card.death_burst_damage()
	if burst > 0:
		for foe in foes_of(card):
			_deal_damage(card, foe, burst, false)

	for foe in foes_of(card):
		var gain := foe.soul_gain()
		if gain > 0:
			foe.atk_bonus += gain
			_log("%s feasts on %s's soul (+%d ATK)." % [foe.card_name(), card.card_name(), gain])

	_check_end()


func _check_end() -> void:
	if is_over:
		return
	if living(player_team).is_empty():
		is_over = true
		player_won = false
		_log("Your squad has fallen.")
	elif living(enemy_team).is_empty():
		is_over = true
		player_won = true
		_log("Enemy squad wiped out. Victory!")


func _log(text: String) -> void:
	history.append(text)
	log_added.emit(text)
