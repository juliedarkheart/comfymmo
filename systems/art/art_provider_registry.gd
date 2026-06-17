extends RefCounted
class_name ArtProviderRegistry

## Thin selector over the licensed art providers, so a future visual policy can choose
## which ecosystem drives the live game without hardcoding provider checks everywhere.
##
## The live game currently runs on SPROUT (see SproutAssetRequirement / the registries).
## LimeZu is being evaluated in a separate visual spike and is exposed here as an
## available provider, NOT the live one. "generated" is the diagnostic/dev fallback.
## Flipping LIVE_PROVIDER later is the single intended pivot point — no live code paths
## are rerouted by this pass.

const PROVIDER_SPROUT := "sprout"
const PROVIDER_LIMEZU := "limezu"
const PROVIDER_GENERATED := "generated"

const PROVIDERS: Array[String] = [PROVIDER_SPROUT, PROVIDER_LIMEZU, PROVIDER_GENERATED]

## The live game's active provider. LimeZu remains spike-only for now.
const LIVE_PROVIDER := PROVIDER_SPROUT

static func providers() -> Array[String]:
	return PROVIDERS.duplicate()

static func is_known(provider_id: String) -> bool:
	return PROVIDERS.has(String(provider_id).strip_edges().to_lower())

static func live_provider() -> String:
	return LIVE_PROVIDER

## Report of provider readiness for the asset-source report / validation.
static func status() -> Dictionary:
	return {
		"live": LIVE_PROVIDER,
		"sprout_available": SproutAssetRequirement.pack_present(),
		"limezu_available": LimeZuArtRegistry.is_available(),
		"limezu_packs_present": _limezu_packs_present(),
		"limezu_missing_reason": LimeZuArtRegistry.missing_reason(),
	}

static func _limezu_packs_present() -> Array[String]:
	var present: Array[String] = []
	for pack_id in LimeZuArtRegistry.pack_ids():
		if LimeZuArtRegistry.pack_present(pack_id):
			present.append(pack_id)
	return present
