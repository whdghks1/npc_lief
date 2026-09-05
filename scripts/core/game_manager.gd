## Responsible for starting/ending lives (docs/ARCHITECTURE.md "GameManager").
## Must NOT contain gameplay logic belonging to other systems — it only
## reacts to the player's Health dying, shows the Life Report, and resets
## the world for a new life. Registered as the autoload "GameManager".
##
## The player is a normal child of whatever scene is currently loaded, so a
## fresh one (and a fresh city, citizens, Hero, and police) appears for free
## just by reloading the scene — "the city may reset entirely" is the
## documented Phase 7 simplification for this. Only TimeSystem (an autoload,
## so it survives a scene reload on its own) needs an explicit reset.
extends Node

const LIFE_REPORT_SCENE := "res://scenes/ui/life_report.tscn"

var _life_report: LifeReport = null

## A fresh Player (and Health) appears each time the scene (re)loads, so
## this is re-discovered lazily rather than cached once at startup.
var _connected_health: Health = null


func _process(_delta: float) -> void:
	if _connected_health != null and is_instance_valid(_connected_health):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var health: Health = player.get_node_or_null("Health")
	if health == null:
		return
	if not health.died.is_connected(_on_player_died):
		health.died.connect(_on_player_died)
	_connected_health = health


func _on_player_died(cause: String) -> void:
	if _life_report != null:
		return # already showing one — shouldn't happen, but stay defensive

	var player := get_tree().get_first_node_in_group("player")
	WorldEvents.player_died.emit(player.global_position if player != null else Vector3.ZERO, cause)

	var days_survived := TimeSystem.day
	var money := 0.0
	var job_name := "Unemployed"
	if player != null:
		var wallet: Wallet = player.get_node_or_null("Wallet")
		if wallet != null:
			money = wallet.money
		var job: PlayerJob = player.get_node_or_null("Job")
		if job != null and job.job != null:
			job_name = job.job.job_name

	get_tree().paused = true
	_life_report = load(LIFE_REPORT_SCENE).instantiate()
	add_child(_life_report)
	_life_report.set_stats(days_survived, job_name, money, cause)
	_life_report.new_life_requested.connect(_on_new_life_requested)


func _on_new_life_requested() -> void:
	if _life_report != null:
		_life_report.queue_free()
		_life_report = null
	_connected_health = null
	TimeSystem.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
