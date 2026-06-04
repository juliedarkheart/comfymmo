# Asset Pipeline

Hearthvale uses an AI-assisted local art pipeline built around reproducible asset
bundles. The goal is to keep generation fast without losing authorship history,
workflow traceability, or import discipline.

## Principles

- Generate locally through ComfyUI workflows.
- Treat every useful output as part of an asset bundle, not a loose image.
- Keep concept art, production sprites, and textures in separate lanes.
- Promote assets through review stages instead of editing files in place.
- Store only the metadata needed to reproduce, review, and ship the asset.

## Folder Layout

```text
assets/
  concepts/
    generated/    Raw local concept generations and bundle manifests
    approved/     Chosen concept directions for downstream production
  sprites/
    generated/    Character, prop, and building sprite bundle candidates
    sheets/       Packed or hand-curated sprite sheets
    approved/     Production-ready sprite outputs for import
  textures/
    generated/    Raw texture outputs from SDXL, Flux, or node-based workflows
    tiles/        Tileable textures prepared for world use
    materials/    Ground, wall, roof, fabric, and surface variants
  lora/
    datasets/     Curated training inputs and captions
    checkpoints/  Local LoRA outputs and evaluation notes
  workflows/
    comfyui/      Exported workflow JSON files and shared notes
  imports/
    staging/      Files awaiting Godot import review
    reviewed/     Files accepted for engine-side use
  metadata/
    templates/    Bundle manifest templates and reference examples
  published/      Asset bundles that are approved as current production versions
```

## Asset Bundle Standard

Each shippable or reviewable asset lives in its own folder:

```text
assets/sprites/generated/sprite_avatar_farmer_idle_v001/
  asset.json
  preview.png
  output.png
  workflow.json
  notes.md
```

Minimum bundle contents:

- `asset.json`: metadata and provenance
- `preview.*`: quick visual review image
- `output.*`: primary generation output
- `workflow.json`: ComfyUI workflow snapshot used for the result

Optional bundle contents:

- mask files
- inpaint inputs
- upscaled outputs
- alternate variants
- prompt notes

## Naming Convention

Use lowercase `snake_case` and stable nouns. Avoid spaces, dates in filenames,
and names that only make sense for one experiment session.

Pattern:

```text
{kind}_{subject}_{variant}_v{version}
```

Examples:

```text
concept_homestead_cottage_exterior_v001
sprite_avatar_farmer_idle_v003
texture_ground_dirt_packed_v002
texture_roof_thatch_clean_v001
```

Rules:

- `kind`: `concept`, `sprite`, `texture`, `sheet`, `lora`
- `subject`: thing represented, such as `avatar`, `cottage`, `ground_dirt`
- `variant`: pose, biome, mood, surface, or use-case
- `version`: three-digit revision counter starting at `v001`

## Metadata Convention

Each bundle uses `asset.json` based on the template in
`assets/metadata/templates/asset_manifest.template.json`.

Required fields:

- `asset_id`
- `display_name`
- `kind`
- `domain`
- `status`
- `version`
- `canonical_file`
- `workflow_file`
- `generator`
- `model_family`
- `created_at`
- `tags`

Recommended fields:

- `prompt_summary`
- `negative_prompt_summary`
- `seed`
- `resolution`
- `upstream_concept`
- `training_candidate`
- `import_target`
- `review_notes`

Metadata should explain how the asset was created without requiring full prompt
dumping into filenames.

## Workflow Ownership

ComfyUI workflows should be exported into `assets/workflows/comfyui/`.

Naming:

```text
wf_{domain}_{purpose}_{model_family}_v{version}.json
```

Examples:

```text
wf_concept_homestead_sdxl_v001.json
wf_sprite_avatar_flux_v002.json
wf_texture_ground_sdxl_v001.json
```

The asset bundle should reference the exact workflow filename it used. If a
workflow changes materially, increment the workflow version instead of silently
overwriting the old one.

## Concept Workflow

Use `assets/concepts/generated/` for wide exploration and
`assets/concepts/approved/` for chosen directions.

Flow:

1. Generate multiple concepts from a stable workflow.
2. Save the chosen bundle with `asset.json`, `preview`, `output`, and `workflow`.
3. Promote approved concepts into `assets/concepts/approved/`.
4. Reference the approved concept ID from downstream sprite or texture bundles.

Concept art is for direction-setting, not engine import. Keep it out of
production folders unless it becomes a direct source for a shippable asset.

## Sprite Workflow

Use `assets/sprites/generated/` for candidates and `assets/sprites/approved/`
for import-ready outputs.

Flow:

1. Start from an approved concept or a tightly scoped gameplay request.
2. Generate isolated character, creature, prop, or building imagery.
3. Normalize scale, silhouette, and viewpoint before approval.
4. Pack animation or state variants into `assets/sprites/sheets/` only after the
   individual frames are accepted.
5. Move import-ready outputs into `assets/imports/staging/`.

Sprite expectations:

- consistent isometric angle
- predictable feet or base contact point
- transparent background for import targets
- review notes for readability at gameplay zoom

## Texture Workflow

Use `assets/textures/generated/` for raw outputs, then curate them into either
`tiles/` or `materials/`.

Flow:

1. Generate surface candidates with seamless or near-seamless settings.
2. Review for tiling quality, noise repetition, and style match.
3. If needed, create cleaned tileable variants as a new version.
4. Promote approved textures into `assets/textures/tiles/` or `materials/`.
5. Move import-ready files into `assets/imports/staging/`.

Texture expectations:

- tileability noted in metadata
- readable at game camera distance
- restrained detail for repeated surfaces
- domain tags like `terrain`, `roof`, `wood`, `stone`, `fabric`

## Import Workflow

Engine import should happen from curated files, not directly from raw generation
folders.

Flow:

1. Keep generation bundles in their domain folder.
2. Copy only approved output files into `assets/imports/staging/`.
3. Review scale, alpha, readability, and intended target in Godot.
4. Move accepted files into `assets/imports/reviewed/`.
5. From there, place the final engine-facing files where gameplay scenes expect them.

This separation keeps generation history intact while preventing prototype scenes
from depending on unreviewed outputs.

## Versioning Workflow

Do not overwrite prior versions of successful bundles.

Rules:

- small prompt or seed changes that matter visually become a new asset version
- workflow graph changes become a new workflow version
- cleanup passes that change ship quality become a new asset version
- published production assets should point to one canonical current version

Promotion path:

`generated -> approved -> imports/staging -> imports/reviewed -> published`

## LoRA Preparation

Future LoRA work should keep datasets and checkpoints separate from production
art. Training data belongs in `assets/lora/datasets/` with captions or metadata
that explain source ownership and intended style target.

Recommended dataset notes:

- source bundle IDs
- caption policy
- exclusion notes
- training objective
- evaluation summary

## Godot Import Guidance

- Let Godot generate `.import` data locally.
- Do not hand-edit generated import metadata.
- Keep source-of-truth provenance in `asset.json`, not in Godot import files.
- When an imported production asset changes, create a new bundle version first.

## Automation

Two local helper scripts support the pipeline:

- `tools/new_asset_bundle.ps1`: creates a new bundle folder from the template
- `tools/validate_asset_manifests.ps1`: checks naming and required metadata keys
