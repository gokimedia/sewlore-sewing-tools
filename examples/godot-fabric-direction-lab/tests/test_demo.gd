extends SceneTree
var checks := 0
var failures: Array[String] = []

func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures.append(text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var demo = load("res://demo/main.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	check(demo.result.text.begins_with("CHECK"), "initial valid diagram")
	demo.slider.value = 180
	demo.nap.button_pressed = true
	check(demo.result.text.contains("NAP"), "controls expose half-turn nap warning")
	demo.slider.value = 45
	check(demo.result.text.contains("GRAIN"), "slider refresh shows changed axis")
	demo.slider.value = 0
	demo.nap.button_pressed = false
	demo.mirror.button_pressed = true
	check(demo.result.text.contains("MIRROR"), "mirrored asymmetric warning")
	demo.mirror.button_pressed = false
	demo.fold.button_pressed = true
	check(demo.result.text.contains("FOLD"), "fold checkbox refresh")
	demo.piece.position.x = demo.fabric.position.x
	demo.refresh()
	check(not demo.result.text.contains("FOLD"), "matching fold edge")
	demo.fold.button_pressed = false
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = demo.piece.get_center()
	demo._gui_input(press)
	var movement := InputEventMouseMotion.new()
	movement.relative = Vector2(25, 15)
	demo._gui_input(movement)
	check(demo.piece.position.is_equal_approx(Vector2(85, 295)), "drag moves piece in digital coordinates")
	press.pressed = false
	demo._gui_input(press)
	check(not demo.dragging, "release ends dragging")
	demo.piece.position = Vector2(-100, 0)
	demo.refresh()
	check(demo.result.text.contains("OUTSIDE"), "boundary warning after drag")
	print(JSON.stringify({"demo_checks": checks, "failures": failures, "pass": failures.is_empty()}))
	quit(0 if failures.is_empty() else 1)
