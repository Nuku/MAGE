class_name TitleScreen
extends Control
## The main menu: background art, the game's logo and the menu.
##
## It only draws and reports choices through `chosen`; the main screen
## decides what each choice does. The title, subtitle, logo, background and
## footer come from the loaded content (`set_branding`); without them the
## menu shows the project's name on plain colours.

signal chosen(action: String)

var _continue_button: Button
var _background: TextureRect
var _logo: TextureRect
var _title: Label
var _subtitle: Label
var _footer: Label
var _continue_info: Label
var _message: Label
var _menu: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = FsTheme.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	_background = TextureRect.new()
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_background)
	# Darken the left side, where the menu is, so it reads on any art.
	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(FsTheme.BG, 0.94))
	gradient.set_color(1, Color(FsTheme.BG, 0.0))
	gradient.set_offset(0, 0.25)
	gradient.set_offset(1, 0.75)
	var gt := GradientTexture2D.new()
	gt.gradient = gradient
	gt.width = 256
	gt.height = 4
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 110)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.custom_minimum_size = Vector2(480, 0)
	col.size_flags_horizontal = SIZE_SHRINK_BEGIN
	margin.add_child(col)
	_logo = TextureRect.new()
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_logo.visible = false
	col.add_child(_logo)
	_title = FsTheme.label(str(ProjectSettings.get_setting("application/config/name", "")), 58, FsTheme.ACCENT)
	_title.add_theme_font_override("font", FsTheme.strong_font())
	col.add_child(_title)
	_subtitle = FsTheme.heading("", 14, FsTheme.ACCENT)
	col.add_child(_subtitle)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	col.add_child(gap)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 2)
	col.add_child(_menu)
	_continue_button = _button("continue", "Continue")
	_continue_info = FsTheme.label("", 14, FsTheme.TEXT_DIM)
	var indent := StyleBoxEmpty.new()
	indent.content_margin_left = 18
	indent.content_margin_bottom = 8
	_continue_info.add_theme_stylebox_override("normal", indent)
	_continue_info.custom_minimum_size = Vector2(380, 0)
	_menu.add_child(_continue_info)
	for spec in [["new", "New game"], ["load", "Load game"], ["settings", "Settings"], ["credits", "Credits"], ["quit", "Quit"]]:
		_button(spec[0], spec[1])
	_message = FsTheme.label("", 15, FsTheme.BAD)
	col.add_child(_message)
	var fill := Control.new()
	fill.size_flags_vertical = SIZE_EXPAND_FILL
	col.add_child(fill)
	_footer = FsTheme.label("", 13, FsTheme.TEXT_FAINT)
	col.add_child(_footer)


## Title, subtitle, logo and background textures and footer text from the
## content; empty values keep the defaults.
func set_branding(title: String, subtitle: String, logo: Texture2D, background: Texture2D, footer: String) -> void:
	if title != "":
		_title.text = title
	_subtitle.text = subtitle.to_upper()
	_subtitle.visible = subtitle != ""
	_background.texture = background
	_logo.texture = logo
	_logo.visible = logo != null
	_title.visible = logo == null
	if logo != null:
		_logo.custom_minimum_size = Vector2(480, 480.0 * logo.get_height() / logo.get_width())
	_footer.text = footer
	_footer.visible = footer != ""


func _button(action: String, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(340, 50)
	b.add_theme_font_override("font", FsTheme.strong_font())
	b.add_theme_font_size_override("font_size", 22)
	# Menu entries are text on the art; hover and focus add a panel and an amber edge.
	var rest := FsTheme.box(Color.TRANSPARENT, FsTheme.RADIUS, Color.TRANSPARENT, 18)
	b.add_theme_stylebox_override("normal", rest)
	b.add_theme_stylebox_override("hover", FsTheme.edged(Color(FsTheme.SURFACE_2, 0.85), FsTheme.ACCENT, 3, 18))
	b.add_theme_stylebox_override("pressed", FsTheme.edged(Color(FsTheme.ACCENT_DIM, 0.9), FsTheme.ACCENT, 3, 18))
	b.add_theme_stylebox_override("focus", FsTheme.edged(Color.TRANSPARENT, FsTheme.ACCENT, 3, 18))
	b.size_flags_horizontal = SIZE_SHRINK_BEGIN
	b.pressed.connect(func(): chosen.emit(action))
	_menu.add_child(b)
	return b


## Shows or hides Continue with a line about the newest save.
func set_continue(info: String) -> void:
	_continue_button.visible = info != ""
	_continue_info.visible = info != ""
	_continue_info.text = info
	(_continue_button if info != "" else _menu.get_child(2) as Button).grab_focus.call_deferred()


func show_message(text: String) -> void:
	_message.text = text
