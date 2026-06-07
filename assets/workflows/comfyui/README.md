# ComfyUI Workflows

Store exported workflow JSON files here for SDXL, Flux, texture, upscale, and
inpaint pipelines used by Hearthvale.

Naming pattern:

```text
wf_{domain}_{purpose}_{model_family}_v{version}.json
```

Examples:

- `wf_concept_homestead_sdxl_v001.json`
- `wf_sprite_avatar_flux_v002.json`
- `wf_texture_ground_sdxl_v001.json`

## See also

The Hearthvale-specific style, per-workflow process, and category prompt templates
live in:

- [`docs/art_pipeline/comfyui_workflows.md`](../../../docs/art_pipeline/comfyui_workflows.md) — the 11 production workflows (concept → extract → bg removal → tile → sheets → upscale → cleanup → import)
- [`docs/art_pipeline/style_guide.md`](../../../docs/art_pipeline/style_guide.md) — the art bible
- [`docs/art_pipeline/asset_import_standards.md`](../../../docs/art_pipeline/asset_import_standards.md) — Godot import standards
- [`assets/prompts/`](../../prompts/) — per-category prompt templates (inherit `hearthvale_master_style.md`)

The two human-pass checklists referenced by the workflow doc also live here:
`10_manual_cleanup.md` and `11_godot_import.md`.

