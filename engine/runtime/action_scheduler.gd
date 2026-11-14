class_name ActionScheduler
extends RefCounted
## Inform's command-turn timers are separate from three-hour survival turns.


static func schedule(game, scene: String, actions: int) -> void:
	game.state.scheduled.append({"scene": scene, "due": game.state.actions + actions})


## Called once a gameplay action has finished all of its choices/combat/pages.
## Remove due entries before running them so saving at a page cannot repeat one.
static func complete(game) -> Array[String]:
	var ready: Array[String] = []
	if not game.state.action_pending:
		return ready
	game.state.action_pending = false
	game.state.actions += 1
	for entry: Dictionary in game.state.scheduled.duplicate():
		if int(entry.due) <= game.state.actions:
			game.state.scheduled.erase(entry)
			if game.state.ending == "":
				ready.append(entry.scene)
	return ready
