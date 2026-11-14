class_name SaveStore
extends RefCounted
## Saved games on disk: named slots, an autosave and a quicksave.
##
## Each save is one JSON file, `<id>.json`, holding the game's save data
## (Game.save_dict) plus a "meta" block shown in the save list: the name,
## when it was saved, and where the player is. An optional `<id>.png` is a
## thumbnail supplied by the interface. Only files are used here, so the
## store works headless and in tests (pass another folder).

const AUTOSAVE := "autosave"
const QUICKSAVE := "quicksave"
const KINDS := {AUTOSAVE: "Autosave", QUICKSAVE: "Quicksave"}

var root: String
var last_error := ""


func _init(folder: String = "user://saves") -> void:
	root = folder


func _path(id: String, ext: String = "json") -> String:
	return root.path_join("%s.%s" % [id, ext])


static func valid_id(id: String) -> bool:
	return id != "" and id.is_valid_filename() and not id.begins_with(".") and not " " in id


## A new ID for a manual save, from the current time; never an existing one.
func new_id() -> String:
	var t := Time.get_datetime_dict_from_system()
	var base := "save-%04d%02d%02d-%02d%02d%02d" % [t.year, t.month, t.day, t.hour, t.minute, t.second]
	var id := base
	var n := 2
	while FileAccess.file_exists(_path(id)):
		id = "%s-%d" % [base, n]
		n += 1
	return id


## Writes the game to a slot. `name` defaults to the player and place.
func write(id: String, game: Game, name: String = "", thumbnail: PackedByteArray = PackedByteArray()) -> bool:
	last_error = ""
	if not valid_id(id):
		last_error = "'%s' is not a valid save name." % id
		return false
	DirAccess.make_dir_recursive_absolute(root)
	var data := game.save_dict()
	var meta := game.save_summary()
	meta.id = id
	meta.kind = KINDS.get(id, "Save")
	meta.name = name if name.strip_edges() != "" else "%s, %s" % [meta.player, meta.location]
	meta.saved_at = int(Time.get_unix_time_from_system())
	data.meta = meta
	var f := FileAccess.open(_path(id) + ".tmp", FileAccess.WRITE)
	if f == null:
		last_error = "Could not write the save (%s)." % error_string(FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	# Replace the old file only once the new one is complete.
	var dir := DirAccess.open(root)
	if dir.file_exists("%s.json" % id):
		dir.remove("%s.json" % id)
	dir.rename("%s.json.tmp" % id, "%s.json" % id)
	if not thumbnail.is_empty():
		var t := FileAccess.open(_path(id, "png"), FileAccess.WRITE)
		if t != null:
			t.store_buffer(thumbnail)
	elif FileAccess.file_exists(_path(id, "png")):
		DirAccess.remove_absolute(_path(id, "png"))
	return true


## The saved data of a slot, or {} with last_error set.
func read(id: String) -> Dictionary:
	last_error = ""
	if not valid_id(id) or not FileAccess.file_exists(_path(id)):
		last_error = "That save does not exist."
		return {}
	var data := _parse(FileAccess.get_file_as_string(_path(id)))
	if data.is_empty():
		last_error = "That save file is damaged."
	return data


## Parses a JSON object quietly; {} if the text is not one.
static func _parse(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	return json.data


## Loads a slot into a game. On failure the game is unchanged.
func load_into(id: String, game: Game) -> bool:
	var data := read(id)
	if data.is_empty():
		return false
	if not game.load_dict(data):
		last_error = game.warnings[-1] if not game.warnings.is_empty() else "The save could not be loaded."
		return false
	return true


func delete(id: String) -> bool:
	if not valid_id(id) or not FileAccess.file_exists(_path(id)):
		return false
	DirAccess.remove_absolute(_path(id))
	if FileAccess.file_exists(_path(id, "png")):
		DirAccess.remove_absolute(_path(id, "png"))
	return true


func rename(id: String, name: String) -> bool:
	var data := read(id)
	if data.is_empty() or name.strip_edges() == "":
		return false
	var meta: Dictionary = data.get("meta", {})
	meta.name = name.strip_edges()
	data.meta = meta
	var f := FileAccess.open(_path(id), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	return true


func thumbnail_path(id: String) -> String:
	return _path(id, "png") if FileAccess.file_exists(_path(id, "png")) else ""


## All saves, newest first: their meta blocks plus "id" and "thumbnail".
## Damaged files are listed with "damaged": true so they can be deleted.
func list() -> Array:
	var out: Array = []
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var id := f.get_basename()
		var data := read(id)
		var meta: Dictionary = data.get("meta", {}) if not data.is_empty() else {}
		if meta.is_empty():
			meta = {"name": id, "kind": KINDS.get(id, "Save"), "saved_at": FileAccess.get_modified_time(_path(id)), "damaged": data.is_empty()}
		meta.id = id
		meta.thumbnail = thumbnail_path(id)
		out.append(meta)
	out.sort_custom(func(a, b): return int(a.get("saved_at", 0)) > int(b.get("saved_at", 0)))
	return out


## The newest save that is not damaged, or {}.
func latest() -> Dictionary:
	for meta in list():
		if not meta.get("damaged", false):
			return meta
	return {}


## Moves a save from the old single-file location into the store as the quicksave.
func import_legacy(path: String = "user://quicksave.json") -> bool:
	if not FileAccess.file_exists(path) or FileAccess.file_exists(_path(QUICKSAVE)):
		return false
	DirAccess.make_dir_recursive_absolute(root)
	var data := _parse(FileAccess.get_file_as_string(path))
	if data.is_empty():
		return false
	if not data.has("meta"):
		data.meta = {"name": "Quicksave (from an earlier version)", "kind": KINDS[QUICKSAVE],
			"saved_at": FileAccess.get_modified_time(path), "player": "", "location": str(data.get("state", {}).get("location", ""))}
	var f := FileAccess.open(_path(QUICKSAVE), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	DirAccess.remove_absolute(path)
	return true
