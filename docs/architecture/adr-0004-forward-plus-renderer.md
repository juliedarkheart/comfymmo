# ADR-0004: Forward Plus Renderer for 2D Isometric

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Godot 4.x offers three rendering backends: Forward Plus (default, clustered), Forward Mobile (mobile-optimized), and Compatibility (GLES3 fallback). Hearthvale is a 2D isometric game targeting desktop (Windows) with no mobile or web targets currently. The project.godot config sets `config/features=PackedStringArray("4.6", "Forward Plus")`.

## Decision

Use the Forward Plus renderer exclusively. This is the default Godot 4.x renderer and provides the best desktop 2D rendering performance with full shader support, 2D lights, and post-processing capabilities needed for the cozy visual style.

## Consequences

### Positive
- Best desktop 2D rendering performance with GPU-driven batching
- Full 2D light and shadow support for mood/time-of-day cycle
- Post-processing support for screen-space effects (tint, glow)
- No need to maintain compatibility with mobile rendering limitations
- Supports the Forward Plus feature flag in project configuration

### Negative
- Not compatible with mobile/web export targets (Forward Mobile or Compatibility would be needed)
- Slightly higher GPU memory usage than Compatibility renderer (irrelevant at 2D isometric scale)
- Some 2D-specific optimisations in Forward Mobile are not available

## Options Considered

### Option 1: Forward Plus (Chosen)
Desktop-optimised clustered renderer. Full feature set. Configured in project.godot.

### Option 2: Forward Mobile
Mobile-optimised renderer. Would work but forfeits desktop-specific 2D performance features. No mobile target planned.

### Option 3: Compatibility (GLES3)
Legacy fallback. Lacks advanced 2D features (lights, post-processing). Would limit the visual direction (mood tints, scene transitions).

## ADR Dependencies

Depends on: ADR-0006 (Godot 4.6 as Target Engine — renderer selection is engine-specific)
Used by: None

## Engine Compatibility

Godot 4.6.3 — Forward Plus is the default and preferred renderer. Configured in `project.godot` as `config/features=PackedStringArray("4.6", "Forward Plus")`. Stretch mode: `canvas_items`, aspect: `expand`. Viewport: 1280x720.

## GDD Requirements Addressed

- **Visual Identity** (docs/visual_identity.md): Cozy 2D isometric with mood tints, warm palette, storybook style
- **World Mood** (docs/system_architecture.md): Mood tints via full-screen ColorRect with low alpha, requiring renderer support for overlays
- **UI/HUD** (docs/ui_hud.md): CanvasLayer-based UI rendering over the world

## Performance Implications

Forward Plus provides excellent 2D performance on modern desktop GPUs. The 2D isometric viewport (1280x720, scaled via canvas_items stretch) is well within the renderer's batching capabilities. The mood tint ColorRect and UI CanvasLayers add negligible overhead. No performance concerns at current or near-future scope.
