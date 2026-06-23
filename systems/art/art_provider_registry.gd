extends RefCounted
class_name ArtProviderRegistry

## Thin selector over the licensed art providers, so a future visual policy can choose
## which ecosystem drives the live game without hardcoding provider checks everywhere.
##
## The live game now runs on LIMEZU — the curated opening slice, actors, and UI re-skin
## to the LimeZu "Modern" ecosystem (see LiveVisualPolicy.live_limezu_slice()). SPROUT
## stays fully integrated as a SECONDARY/comparison provider (registries, docs, and the
## Sprout spike are not removed); it is just no longer the primary live target.
## "generated" is the diagnostic/dev fallback and must not dominate the live view.
## LIVE_PROVIDER is the single switch point for the pivot.

const PROVIDER_SPROUT := "sprout"
const PROVIDER_LIMEZU := "limezu"
const PROVIDER_GENERATED := "generated"

const PROVIDERS: Array[String] = [PROVIDER_SPROUT, PROVIDER_LIMEZU, PROVIDER_GENERATED]

## The live game's active visual provider.
const LIVE_PROVIDER := PROVIDER_LIMEZU

static func providers() -> Array[String]:
	return PROVIDERS.duplicate()

static func is_known(provider_id: String) -> bool:
	return PROVIDERS.has(String(provider_id).strip_edges().to_lower())

static func live_provider() -> String:
	return LIVE_PROVIDER

## Report of provider readiness for the asset-source report / validation.
static func status() -> Dictionary:
	var sprout_status: Dictionary = SproutAssetRequirement.check()
	var limezu_status: Dictionary = LimeZuArtRegistry.readiness()
	return {
		"live": LIVE_PROVIDER,
		"selected_live_provider": _selected_live_provider(limezu_status),
		"sprout_ready": bool(sprout_status.get("ok", false)),
		"sprout_present": SproutAssetRequirement.pack_present(),
		"sprout_optional_required": SproutAssetRequirement.REQUIRED,
		"limezu_available": LimeZuArtRegistry.is_available(),
		"limezu_usable": bool(limezu_status.get("usable_for_live", false)),
		"limezu_readiness_tier": String(limezu_status.get("tier", LimeZuArtRegistry.READINESS_ABSENT)),
		"limezu_resolved_live_count": int(limezu_status.get("resolved_live_count", 0)),
		"limezu_required_live_count": int(limezu_status.get("required_live_count", 0)),
		"limezu_direct_missing_ids": limezu_status.get("direct_missing_ids", []),
		"limezu_missing_ids": limezu_status.get("missing_ids", []),
		"limezu_generator_available": bool(limezu_status.get("generator_available", false)),
		"limezu_packs_present": _limezu_packs_present(),
		"limezu_missing_reason": LimeZuArtRegistry.missing_reason(),
	}

static func _selected_live_provider(limezu_status: Dictionary) -> String:
	if LIVE_PROVIDER == PROVIDER_LIMEZU:
		return PROVIDER_LIMEZU if bool(limezu_status.get("usable_for_live", false)) else PROVIDER_GENERATED
	return LIVE_PROVIDER

static func _limezu_packs_present() -> Array[String]:
	var present: Array[String] = []
	for pack_id in LimeZuArtRegistry.pack_ids():
		if LimeZuArtRegistry.pack_present(pack_id):
			present.append(pack_id)
	return present
