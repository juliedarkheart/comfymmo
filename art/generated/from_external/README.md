# Normalized derivatives of external assets

Resized/cropped/padded sprites derived from verified imports under
`art/external/`. **Originals there are never modified** — derivatives are written
here by `tools/art/` (slicing/normalizing), keyed back to source + license in
`manifest.json`.

Layout:

```text
from_external/
    manifest.json        source file -> derived file(s), size, edits, license
    <source>/<asset>/...  staging derivatives (sliced cells, normalized sprites)
    active/<mirror path>  derivatives that have been promoted for activation
```

`active/<mirror path>` mirrors the generated art path (e.g.
`active/ui/icons/wood.png`). A file here is still **inert** until its id is listed
in `art/active_art_manifest.json` — that manifest, not file presence, decides
what the game uses (so unreviewed packs can't blind-replace the cozy generated
art). See `docs/asset_review_workflow.md`.
