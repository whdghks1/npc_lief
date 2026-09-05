## Global simulation clock (autoload singleton "TimeSystem").
##
## Owns day/hour/minute and how fast they advance. Other systems (Job,
## Hunger, HUD, and later NPC schedules per docs/ARCHITECTURE.md) read time
## from here and react to its signals instead of tracking time themselves —
## this is the single source of truth for "what time is it."
extends Node

signal minute_passed(hour: int, minute: int)
signal hour_passed(hour: int)
signal day_changed(day: int)

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const WAKE_HOUR := 7

## Normal in-game minutes per real second — the pacing everything else
## (citizen walk speed, traffic speed, hunger decay) is tuned against.
const BASE_TIME_SCALE := 2.0

## In-game minutes that pass per real second. Debug tools may change this
## at runtime to speed up testing.
@export var time_scale: float = BASE_TIME_SCALE

var day: int = 1
var hour: int = WAKE_HOUR
var minute: int = 0

var _minute_accumulator: float = 0.0


func _process(delta: float) -> void:
	_minute_accumulator += delta * time_scale
	while _minute_accumulator >= 1.0:
		_minute_accumulator -= 1.0
		advance_time(1)


## Steps the clock forward minute by minute (rather than jumping the fields
## directly) so anything listening to minute_passed — Hunger's decay, for
## example — reacts correctly even across a large jump like a work shift.
func advance_time(minutes: int) -> void:
	for _i in range(max(minutes, 0)):
		minute += 1
		if minute >= MINUTES_PER_HOUR:
			minute = 0
			hour += 1
			if hour >= HOURS_PER_DAY:
				hour = 0
				day += 1
				day_changed.emit(day)
			hour_passed.emit(hour)
		minute_passed.emit(hour, minute)


## Ends the current day and jumps straight to the next morning. Used by
## sleep — deliberately does not walk through every intervening minute like
## advance_time() does, since nothing needs to react to "asleep" minutes.
func advance_to_next_day(wake_hour: int = WAKE_HOUR) -> void:
	hour = wake_hour
	minute = 0
	day += 1
	day_changed.emit(day)
	minute_passed.emit(hour, minute)


func total_minutes() -> int:
	return hour * MINUTES_PER_HOUR + minute


func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]


func get_day_label() -> String:
	return "DAY %d" % day


## How much faster the world is currently running relative to normal pacing.
## Ambient world movement (citizens, traffic) reads this so a sped-up clock
## actually looks sped up, rather than just making the clock numbers spin
## while everyone keeps walking at their normal real-time pace. The player
## is deliberately NOT scaled by this — they're the one observing time pass,
## not part of what's being fast-forwarded.
func speed_multiplier() -> float:
	return time_scale / BASE_TIME_SCALE
