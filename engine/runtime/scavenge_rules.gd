class_name ScavengeRules
extends RefCounted
## Scavenging texts and numbers are pack data (`scavenge_rules`); the
## scene runner applies them.


static func rules(game) -> FscParser.Definition:
	var definitions: Dictionary = game.content.all_of("scavenge_rules")
	return null if definitions.is_empty() else definitions.values()[0]


static func text(game, field: String, fallback: String = "") -> String:
	var r := rules(game)
	return fallback if r == null else game.content.typed_value("scavenge_rules", r.id, field, fallback)


## The chance of the generic find, from "generic chance: 3 in 4".
static func chance(game) -> Array:
	var parts := text(game, "generic chance", "3 in 4").split(" in ")
	return [int(parts[0]), int(parts[1])] if parts.size() == 2 else [3, 4]


static func say(game, template: String) -> void:
	if template.strip_edges() == "":
		return
	var compiled := TextTemplate.compile(template)
	if not compiled.has("error"):
		game.emit({"type": "paragraph", "spans": game.render(compiled)})
