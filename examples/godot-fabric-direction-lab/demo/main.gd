extends Control

const Rules = preload("res://addons/sewlore_fabric_direction/fabric_rules.gd")
const INK := Color("213f47")
const TEAL := Color("217b80")
const AMBER := Color("a46226")
var fabric := Rect2(60, 182, 610, 470)
var piece := Rect2(200, 280, 180, 240)
var piece_degrees := 0.0
var dragging := false
var nap: CheckBox
var mirror: CheckBox
var fold: CheckBox
var slider: HSlider
var angle_label: Label
var result: Label
var screenshot_path := ""

func label_at(text: String, at: Vector2, size: int, width: float = 1100.0) -> Label:
	var item := Label.new()
	item.text = text
	item.position = at
	item.size = Vector2(width, 50)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", INK)
	add_child(item)
	return item

func _ready() -> void:
	label_at("SEWLORE / DIGITAL FABRIC DIRECTION LAB", Vector2(60, 34), 17)
	label_at("An aligned axis is not always the right direction.", Vector2(60, 69), 32)
	label_at("Drag the teaching piece. Rotate it, then compare grain, nap, face and fold evidence.", Vector2(60, 124), 18)
	label_at("PLACEMENT CONTROLS", Vector2(728, 182), 18, 430)
	angle_label = label_at("Rotation: 0 degrees", Vector2(728, 219), 18, 430)
	slider = HSlider.new()
	slider.position = Vector2(728, 265)
	slider.size = Vector2(410, 26)
	slider.min_value = -180
	slider.max_value = 180
	slider.step = 1
	slider.value_changed.connect(func(value): piece_degrees = value; refresh())
	add_child(slider)
	nap = check("One-way nap / directional print", 307)
	mirror = check("Mirror an asymmetric example", 349)
	fold = check("Require left edge on the fold", 391)
	var choices := [["On grain", 0.0], ["Bias", 45.0], ["Half turn", 180.0]]
	for i in choices.size():
		var button := Button.new()
		button.text = choices[i][0]
		button.position = Vector2(728 + i * 139, 443)
		button.size = Vector2(130, 40)
		button.add_theme_color_override("font_color", Color.WHITE)
		var degrees: float = choices[i][1]
		button.pressed.connect(func(): slider.value = degrees)
		add_child(button)
	var reset := Button.new()
	reset.text = "Reset diagram"
	reset.position = Vector2(728, 499)
	reset.size = Vector2(410, 35)
	reset.pressed.connect(func(): piece = Rect2(200, 280, 180, 240); slider.value = 0; nap.button_pressed = false; mirror.button_pressed = false; fold.button_pressed = false; refresh())
	add_child(reset)
	result = label_at("", Vector2(728, 552), 17, 410)
	result.size.y = 158
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var source := LinkButton.new()
	source.text = "Methods and measurement guides at Sewlore"
	source.position = Vector2(60, 688)
	source.add_theme_color_override("font_color", TEAL)
	source.add_theme_color_override("font_hover_color", INK)
	source.pressed.connect(func(): OS.shell_open("https://sewlore.com/pages/fabric-measurement-methods-guide"))
	add_child(source)
	label_at("Synthetic rectangles / screen pixels / no cutting layout, fabric test or fit certification", Vector2(60, 718), 14)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot-out="):
			screenshot_path = arg.trim_prefix("--screenshot-out=")
	refresh()
	if screenshot_path != "":
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(screenshot_path)
		print("NATIVE_RENDER_PNG status=", error)
		get_tree().quit(error)

func check(text: String, y: float) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.position = Vector2(728, y)
	box.size = Vector2(410, 32)
	box.add_theme_font_size_override("font_size", 17)
	box.add_theme_color_override("font_color", INK)
	box.add_theme_color_override("font_hover_color", TEAL)
	box.add_theme_color_override("font_pressed_color", TEAL)
	box.toggled.connect(func(_value): refresh())
	add_child(box)
	return box

func refresh() -> void:
	if result == null:
		return
	angle_label.text = "Rotation: %d degrees" % piece_degrees
	var evidence := Rules.validate(fabric, piece, piece_degrees, 2, nap.button_pressed, mirror.button_pressed, true, fold.button_pressed)
	result.text = "CHECK: aligned and contained in this diagram.\nPhysical grain, pattern instructions and print direction still need real evidence." if evidence.ok else "\n".join(evidence.issues)
	result.add_theme_color_override("font_color", TEAL if evidence.ok else AMBER)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Geometry2D.is_point_in_polygon(event.position, Rules.corners(piece, piece_degrees)):
			dragging = true
		elif not event.pressed:
			dragging = false
	if event is InputEventMouseMotion and dragging:
		piece.position += event.relative
		refresh()

func _draw() -> void:
	draw_style_box(panel_style(), fabric)
	for x in range(80, 670, 25):
		draw_line(Vector2(x, 194), Vector2(x, 640), Color("d3e3e0"), 1)
	for y in range(202, 650, 25):
		draw_line(Vector2(72, y), Vector2(658, y), Color("e4e8dc"), 1)
	draw_line(fabric.position, Vector2(fabric.position.x, fabric.end.y), INK, 4)
	draw_string(ThemeDB.fallback_font, Vector2(70, 173), "LEFT FOLD BOUNDARY / vertical lines show the warp axis", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	var polygon := Rules.corners(piece, piece_degrees)
	draw_colored_polygon(polygon, Color(0.96, 0.77, 0.57, 0.87))
	var closed := PackedVector2Array(polygon)
	closed.append(polygon[0])
	draw_polyline(closed, INK, 3, true)
	var center := piece.get_center()
	var direction := Vector2.UP.rotated(deg_to_rad(piece_degrees))
	var from := center - direction * 65
	var to := center + direction * 65
	draw_line(from, to, TEAL, 4, true)
	for sign in [-1, 1]:
		draw_line(to, to - direction.rotated(sign * 0.5) * 15, TEAL, 4, true)
	draw_string(ThemeDB.fallback_font, center + Vector2(-67, 105), "piece grain arrow", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	if mirror != null and mirror.button_pressed:
		draw_string(ThemeDB.fallback_font, center + Vector2(-65, -98), "MIRRORED FACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AMBER)
	if nap != null and nap.button_pressed:
		for y in [246, 346, 446, 546]:
			draw_string(ThemeDB.fallback_font, Vector2(590, y), "^ NAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEAL)

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f7faf4")
	style.border_color = Color("a6bab5")
	style.set_border_width_all(2)
	return style
