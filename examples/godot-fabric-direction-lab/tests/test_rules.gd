extends SceneTree
const Rules = preload("res://addons/sewlore_fabric_direction/fabric_rules.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _initialize() -> void:
	var fabric := Rect2(0, 0, 400, 500)
	var piece := Rect2(80, 100, 100, 160)
	check(Rules.validate(fabric, piece, 0).ok, "contained zero rotation")
	check(Rules.validate(fabric, piece, 180).grain_ok, "grain axis survives half turn")
	check(not Rules.validate(fabric, piece, 180, 2, true).nap_ok, "one-way nap forbids half turn")
	check(Rules.validate(fabric, piece, 360, 2, true).nap_ok, "full turn keeps nap")
	check(not Rules.validate(fabric, piece, 90).grain_ok, "quarter turn changes grain")
	check(Rules.validate(fabric, piece, 45).bias_candidate, "bias candidate")
	check(Rules.validate(fabric, piece, -45).bias_candidate, "negative bias candidate")
	check(Rules.validate(fabric, piece, 1.5).grain_ok, "inclusive tolerance inside")
	check(not Rules.validate(fabric, piece, 2.1).grain_ok, "tolerance outside")
	check(not Rules.validate(fabric, Rect2(-1, 10, 20, 20), 0).inside, "negative boundary")
	check(not Rules.validate(fabric, Rect2(365, 445, 30, 50), 45).inside, "rotated corner beyond bounds")
	check(Rules.validate(fabric, Rect2(0, 100, 50, 80), 0, 2, false, false, false, true).fold_ok, "fold aligned")
	check(not Rules.validate(fabric, piece, 0, 2, false, false, false, true).fold_ok, "fold displaced")
	check(not Rules.validate(fabric, piece, 0, 2, false, true, true).ok, "mirrored asymmetric")
	check(Rules.validate(fabric, piece, 0, 2, false, true, false).ok, "mirroring symmetric example")
	check(is_equal_approx(Rules.axial_difference(181), 1), "wrapped axis")
	var corners := Rules.corners(Rect2(0, 0, 20, 40), 90)
	check(corners.size() == 4 and corners[0].is_equal_approx(Vector2(30, 10)), "rotated geometry")
	print(JSON.stringify({"checks": checks, "failures": failures, "pass": failures.is_empty()}))
	quit(0 if failures.is_empty() else 1)
