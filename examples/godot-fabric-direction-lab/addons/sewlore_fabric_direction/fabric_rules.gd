class_name SewloreFabricRules
extends RefCounted
## Pure geometry helpers for a digital teaching diagram. Units are screen pixels.
## No conversion from pixels to physical pattern dimensions is assumed.

static func corners(rect: Rect2, degrees: float) -> PackedVector2Array:
	var center: Vector2 = rect.get_center()
	var points := PackedVector2Array()
	for local in [Vector2(-rect.size.x / 2, -rect.size.y / 2), Vector2(rect.size.x / 2, -rect.size.y / 2), Vector2(rect.size.x / 2, rect.size.y / 2), Vector2(-rect.size.x / 2, rect.size.y / 2)]:
		points.append(center + local.rotated(deg_to_rad(degrees)))
	return points

static func axial_difference(degrees: float) -> float:
	## An axis is unchanged by a half turn, unlike an oriented nap arrow.
	return absf(fposmod(degrees + 90.0, 180.0) - 90.0)

static func validate(fabric: Rect2, piece: Rect2, rotation: float, grain_tolerance: float = 2.0, one_way_nap: bool = false, mirrored: bool = false, asymmetric: bool = false, on_fold: bool = false) -> Dictionary:
	var issues: Array[String] = []
	var polygon := corners(piece, rotation)
	var inside := true
	for point in polygon:
		if point.x < fabric.position.x or point.x > fabric.end.x or point.y < fabric.position.y or point.y > fabric.end.y:
			inside = false
	if not inside:
		issues.append("OUTSIDE: a rotated corner crosses the digital fabric boundary.")
	var difference := axial_difference(rotation)
	var grain_ok := difference <= grain_tolerance
	if not grain_ok:
		issues.append("GRAIN: arrow is %.1f degrees from the warp axis; this is not an on-grain placement." % difference)
	var nap_ok := not one_way_nap or absf(fposmod(rotation + 180.0, 360.0) - 180.0) <= grain_tolerance
	if not nap_ok:
		issues.append("NAP: an axis-aligned half turn still reverses a one-way design.")
	if mirrored and asymmetric:
		issues.append("MIRROR: this asymmetric teaching piece needs its required face/hand checked.")
	var fold_ok := true
	if on_fold:
		fold_ok = grain_ok and absf(piece.position.x - fabric.position.x) <= 1.0 and absf(fposmod(rotation + 180.0, 360.0) - 180.0) <= grain_tolerance
		if not fold_ok:
			issues.append("FOLD: the labelled fold edge must coincide with the left fold boundary in the unrotated example.")
	return {"inside": inside, "grain_ok": grain_ok, "nap_ok": nap_ok, "fold_ok": fold_ok, "grain_difference_degrees": difference, "bias_candidate": absf(difference - 45.0) <= grain_tolerance, "issues": issues, "ok": issues.is_empty(), "corners": polygon}
