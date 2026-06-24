extends SceneTree

## Headless smoke for the LAYERED avatar parts system: the curated manifest loads, layered mode
## is enabled (verified), the Julie default + every starter part resolves to a texture, the shared
## 16x32 frame geometry is correct, and the render signature reflects part choices. Clean-checkout
## safe: when the manifest/pack is absent, layered_ready() is false and the asserts adapt.
##
##   Godot --headless --path . --script res://tools/smoke_avatar_layered_parts.gd

func _initialize() -> void:
	var ok: bool = true
	CharacterPartLibrary.reload()

	var available := CharacterPartLibrary.is_available()
	print("  INFO  is_available = %s, layered_ready = %s" % [available, CharacterPartLibrary.layered_ready()])

	if not available:
		ok = _expect(not CharacterPartLibrary.layered_ready(), "layered_ready false when manifest absent (clean checkout)") and ok
		_report(ok); return

	# --- Manifest present: layered mode is enabled (layout verified) ----------
	ok = _expect(CharacterPartLibrary.layered_ready(), "layered_ready() true (layout verified + body texture loads)") and ok

	# --- Starter categories populated ----------------------------------------
	for cat in ["bodies", "hairstyles", "outfits", "accessories", "eyes"]:
		ok = _expect(CharacterPartLibrary.part_ids_for_category(cat).size() >= 1, "%s part ids present" % cat) and ok

	# --- Every enabled starter part resolves to a texture (or null file for acc_none) ---
	var checked := 0
	for cat in ["bodies", "hairstyles", "outfits", "accessories", "eyes"]:
		for pid in CharacterPartLibrary.part_ids_for_category(cat):
			var entry := CharacterPartLibrary.part_entry(String(pid))
			var file_v: Variant = entry.get("file", "")
			if file_v == null:
				continue  # acc_none has no file (intentional)
			var file := String(file_v)
			if file.is_empty():
				continue
			ok = _expect(CharacterPartLibrary.resolve_texture(file) != null, "texture loads: %s" % pid) and ok
			checked += 1
	ok = _expect(checked >= 15, "resolved >=15 starter part textures (%d)" % checked) and ok

	# --- Julie default resolves to a coherent (non-empty) layer set ----------
	var julie := CharacterAppearance.default_appearance()
	ok = _expect(String(julie.get("hair_style", "")) == "hair_22_04" and String(julie.get("outfit_style", "")) == "outfit_14_03",
		"Julie default uses the approved curated parts") and ok
	var sig := CharacterPartLibrary.render_signature(julie)
	var layer_count := sig.split("|").size()
	ok = _expect(layer_count >= 4, "Julie default composites >=4 layers (body+eyes+outfit+hair+acc) = %d" % layer_count) and ok

	# --- Accessory None removes the accessory layer --------------------------
	var none_look := julie.duplicate(); none_look["accessory"] = "none"
	ok = _expect(CharacterPartLibrary.render_signature(none_look).split("|").size() == layer_count - 1,
		"accessory None drops exactly one layer") and ok

	# --- Shared 16x32 frame geometry (idle down = (0,0)) ----------------------
	var idle_down := CharacterAnimationRegistry.generator_idle_rect("down")
	ok = _expect(idle_down == Rect2i(0, 0, 16, 32), "idle-down cell is (0,0) 16x32 (paste-at-origin)") and ok
	var idle_up := CharacterAnimationRegistry.generator_idle_rect("up")
	ok = _expect(idle_up == Rect2i(16, 0, 16, 32), "idle-up cell is (1,0) 16x32") and ok
	var walk_down := CharacterAnimationRegistry.generator_walk_frames("down")
	ok = _expect(walk_down.size() >= 2, "down walk has >=2 frames") and ok

	# --- Reload idempotent ---------------------------------------------------
	CharacterPartLibrary.reload()
	ok = _expect(CharacterPartLibrary.layered_ready() == true, "reload preserves layered_ready") and ok

	_report(ok)

func _report(ok: bool) -> void:
	if ok:
		print("PASS: smoke_avatar_layered_parts")
	else:
		printerr("FAIL: smoke_avatar_layered_parts")
	quit(0 if ok else 1)

func _expect(condition: bool, label: String) -> bool:
	if condition:
		print("  OK  %s" % label)
	else:
		printerr("  FAIL  %s" % label)
	return condition
