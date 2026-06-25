# Hearthvale Avatar Review Report
**LimeZu Modern Interiors — Character Generator**
Reviewed by Hermes · 2026-06-24

---

## Key Finding Upfront

The **layers align at (0,0) origin** — no offset needed. The previous "blob" failure was a compositor bug, not a spritesheet problem. All layers (Eyes, Hairstyles, Outfits, Accessories) are **896×656 RGBA**. The Body sheets are **927×656** (31px wider, a right-side margin with no meaningful content), but compositing at origin works correctly. This is confirmed by live composite tests that produced clean, properly-formed characters.

Compositing order (per `CHARACTER_GENERATOR.txt`):  
`Body → Eyes → Outfit → Hairstyle → Accessory`

---

## Important: Bodies Are Skin Tones, Not Silhouettes

**All 9 bodies share the same chibi silhouette.** There is no separate "feminine body" or "masculine body." The 9 body variants are purely skin tone options. Gender expression in this system comes entirely from **hairstyle + outfit choice**. This is ideal for Hearthvale's inclusive, cozy-first design.

---

## A. Best Starter Avatar Set

### Bodies (Skin Tones)

| Category | ID | Filename | Description | Gender Read | Enable now? |
|---|---|---|---|---|---|
| Body | Body_01 | `Bodies/16x16/Body_01.png` | Rich deep brown skin tone | Neutral | ✅ Yes |
| Body | Body_04 | `Bodies/16x16/Body_04.png` | Medium warm golden-brown | Neutral | ✅ Yes |
| Body | Body_03 | `Bodies/16x16/Body_03.png` | Light peachy-pink | Neutral | ✅ Yes |

*Additional skin tones available: Body_02 (warm medium peach), Body_05 (olive/golden), Body_06 (very pale cream), Body_07 (light warm), Body_08 (soft pink), Body_09 (light lavender — possibly a fantasy option). All are safe to add to the selector later.*

---

### Hairstyles

Color variant `_01` is used for all style thumbnails, but each style ships with 7 color variants (`_01`–`_07`). In the starter build, expose only `_01` per style to keep scope small.

| Category | ID | Filename | Description | Gender Read | Enable now? |
|---|---|---|---|---|---|
| Hair | Hairstyle_03 | `Hairstyles/16x16/Hairstyle_03_01.png` | Short, clean, slightly swept — very neat | Neutral | ✅ Yes |
| Hair | Hairstyle_07 | `Hairstyles/16x16/Hairstyle_07_01.png` | Short, tidy, minimal shape | Neutral–Masc | ✅ Yes |
| Hair | Hairstyle_09 | `Hairstyles/16x16/Hairstyle_09_01.png` | Short with a small ahoge/cute antenna — very anime-cozy | Neutral–Fem | ✅ Yes |
| Hair | Hairstyle_15 | `Hairstyles/16x16/Hairstyle_15_01.png` | Medium-length, slightly wavy/flowing | Feminine-leaning | ✅ Yes |
| Hair | Hairstyle_22 | `Hairstyles/16x16/Hairstyle_22_01.png` | Long, flowing full hair | Feminine | ✅ Yes |
| Hair | Hairstyle_28 | `Hairstyles/16x16/Hairstyle_28_01.png` | Ponytail or pulled-back style — practical, farm-friendly | Neutral–Fem | ✅ Yes |

*Note: Hairstyles 26–29 have pink/magenta as their `_01` color variant. This is intended — they're expressive styles with bold default colors. Great for personality but add after core set is stable.*

---

### Outfits

Each outfit style ships with multiple color variants (`_01`–`_09` or fewer). Start with `_01` only.

| Category | ID | Filename | Description | Gender Read | Enable now? |
|---|---|---|---|---|---|
| Outfit | Outfit_01 | `Outfits/16x16/Outfit_01_01.png` | Casual everyday top — clean starter look | Neutral | ✅ Yes |
| Outfit | Outfit_05 | `Outfits/16x16/Outfit_05_01.png` | Navy blue casual — practical, clean | Neutral | ✅ Yes |
| Outfit | Outfit_09 | `Outfits/16x16/Outfit_09_01.png` | Green/nature-toned — reads as outdoor/garden | Neutral–Fem | ✅ Yes |
| Outfit | Outfit_14 | `Outfits/16x16/Outfit_14_01.png` | Light/soft casual blouse style | Feminine-leaning | ✅ Yes |
| Outfit | Outfit_15 | `Outfits/16x16/Outfit_15_01.png` | Bright yellow/warm — cheerful, summer-farmer energy | Neutral | ✅ Yes |
| Outfit | Outfit_18 | `Outfits/16x16/Outfit_18_01.png` | Earthy brown tones — work clothes / farmer | Neutral–Masc | ✅ Yes |

---

### Accessories

Always include `None` as a valid option.

| Category | ID | Filename | Description | Fit | Enable now? |
|---|---|---|---|---|---|
| Accessory | None | — | No accessory | Always valid | ✅ Yes |
| Accessory | Acc01_Ladybug | `Accessories/16x16/Accessory_01_Ladybug_01.png` | Tiny red ladybug on the head — nature charm, adorable | Perfect cozy | ✅ Yes |
| Accessory | Acc02_Bee | `Accessories/16x16/Accessory_02_Bee_01.png` | Tiny yellow bee — same energy, different critter | Perfect cozy | ✅ Yes |
| Accessory | Acc11_Beanie | `Accessories/16x16/Accessory_11_Beanie_01.png` | Warm knit beanie hat — cozy winter/autumn feel | Perfect cozy | ✅ Yes |
| Accessory | Acc18_Chef | `Accessories/16x16/Accessory_18_Chef_01.png` | Tall white chef hat — village baker / kitchen identity | Perfect | ✅ Yes |

*Optional additions after starter: Acc15_Glasses (personality), Acc19_Party_Cone (seasonal events), Acc04_Snapback (young farmer), Acc12_Mustache + Acc13_Beard (NPC flavor).*

---

### Eyes

Eyes are very subtle at 16px scale — mostly readable as eye color/expression variations. All 7 are safe; start with 3.

| Category | ID | Filename | Description | Enable now? |
|---|---|---|---|---|
| Eyes | Eyes_01 | `Eyes/16x16/Eyes_01.png` | Default expression | ✅ Yes |
| Eyes | Eyes_02 | `Eyes/16x16/Eyes_02.png` | Slight variant | ✅ Yes |
| Eyes | Eyes_03 | `Eyes/16x16/Eyes_03.png` | Slight variant | ✅ Yes |

*Eyes_04–07 can be added to the selector anytime without risk — they all share the same sheet dimensions and origin.*

---

## B. Julie Default Recommendation

| Slot | Selection | File |
|---|---|---|
| Body | Body_03 (light peach) | `Bodies/16x16/Body_03.png` |
| Hair | Hairstyle_22, color 4 | `Hairstyles/16x16/Hairstyle_22_04.png` |
| Outfit | Outfit_14, color 3 (soft rose/blush) | `Outfits/16x16/Outfit_14_03.png` |
| Eyes | Eyes_02 | `Eyes/16x16/Eyes_02.png` |
| Accessory | Acc01_Ladybug | `Accessories/16x16/Accessory_01_Ladybug_01.png` |

**Palette suggestion:** Warm rose/blush outfit + medium auburn/chestnut hair (color variant 3–4) + the ladybug as a tiny pop of red. Very "cozy main character energy." Soft, warm, inviting — fits the Hearthvale protagonist slot perfectly.

---

## C. Alternate Presets

### Preset 1 — Julie / Neutral-Feminine Cozy
*"A warm, friendly neighbor you'd find tending the flower beds."*

| Slot | Selection |
|---|---|
| Body | Body_03 (light peach) |
| Hair | Hairstyle_15, color 3 (warm brown/auburn) |
| Outfit | Outfit_14, color 2 (soft blue-grey) |
| Eyes | Eyes_02 |
| Accessory | Acc11_Beanie (color 3 — dusty rose) |

---

### Preset 2 — Villager Neutral
*"A friendly shopkeeper or craftsperson, anyone's neighbor."*

| Slot | Selection |
|---|---|
| Body | Body_05 (golden olive) |
| Hair | Hairstyle_07, color 1 (warm brown) |
| Outfit | Outfit_05, color 1 (navy blue) |
| Eyes | Eyes_01 |
| Accessory | Acc15_Glasses (color 1) |

---

### Preset 3 — Farmer Masculine
*"The hardworking farmer who always has a basket of turnips."*

| Slot | Selection |
|---|---|
| Body | Body_04 (medium golden-brown) |
| Hair | Hairstyle_01, color 2 (light brown/sand) |
| Outfit | Outfit_18, color 1 (earthy) |
| Eyes | Eyes_03 |
| Accessory | None |

---

## D. Rejected Parts

| Part | ID | Reason |
|---|---|---|
| Accessory | Acc06_Policeman_Hat | Authority/police theme — wrong for cozy village |
| Accessory | Acc07_Bataclava | Full face mask — threatening/dark aesthetic |
| Accessory | Acc09_Zombie_Brain | Horror — hard reject |
| Accessory | Acc10_Bolt | Frankenstein sci-fi bolt — hard reject |
| Accessory | Acc17_Medical_Mask | Depressing, clinical — wrong tone for Hearthvale |
| Body | Body_09 | Lavender/blue-grey skin — possibly fantasy/non-human. Not rejected outright — hold for "creature/fantasy" player option later. Do not include in human default set. |

*Borderline / hold for later:*
- Acc08_Detective_Hat — quirky but reads "noir," not cozy. Fine as an NPC prop.
- Acc16_Monocle — whimsical, could work for an eccentric villager NPC. Not for player default set.
- Acc04_Snapback — fine for a younger character feel. Add to selector in second pass.
- Hairstyles 26–29 (pink `_01` variants) — not rejected, just expressive. Add after core set is stable.

**Note on sprite sheet animations:** The body sprite sheets include `stab`, `grab_gun`, `gun_idle`, `shoot`, and `punch` animation rows. These are part of the LimeZu standard sheet layout. Simply do not play those states in Hearthvale. The character assets themselves are neutral — no rejection needed.

---

## E. Layout Risk Notes

### ✅ Layers align at (0,0) origin — confirmed by live composite test

The previous "blob" failure was a compositor error, not a spritesheet issue. The fix is straightforward.

**Specific findings:**

| Finding | Detail |
|---|---|
| All non-body layers | 896×656px, RGBA. Body is 927×656px (31px wider). |
| Width difference | Body has a right-side margin/extra reference strip. Compositingthe other layers at x=0 is correct — confirmed visually. |
| Frame layout | Each row = one animation state. Each cell = ~16px wide per frame (16x16 folder). Row starting at y=32 = idle animation. |
| Animation states available | idle, walk, sleep, sit (×2), phone, read/swim, push cart, pick up, gift, lift, throw, hit, punch, stab, grab gun, gun idle, shoot, hurt |
| Alignment verdict | **Clean**. Hair sits on head. Outfit layers over body. Eyes appear in correct face region. Accessories mount on head or back correctly. |
| Facing-forward vs facing-back | The sprite sheet renders all 4 directions across rows. The top-down "idle facing away" view confirms natural isometric perspective. Looks correct for Hearthvale's camera angle. |
| Kids folder | Separate `Bodies_kids`, `Hairstyles_kids`, `Outfits_kids`, `Eyes_kids` exist. Not evaluated in this review — separate pass needed. |

---

## F. Next Engineering Instructions

> Do not commit changes until Julie approves the composite previews.

### Step 1 — Update the curated avatar manifest

Create or update `systems/content/avatar_manifest.tres` (or equivalent) with the approved starter IDs:

```
# Starter skin tones
bodies: [Body_01, Body_04, Body_03]

# Starter hairstyles (color _01 only for now)
hairstyles: [Hairstyle_03, Hairstyle_07, Hairstyle_09, Hairstyle_15, Hairstyle_22, Hairstyle_28]

# Starter outfits (color _01 only)
outfits: [Outfit_01, Outfit_05, Outfit_09, Outfit_14, Outfit_15, Outfit_18]

# Starter eyes
eyes: [Eyes_01, Eyes_02, Eyes_03]

# Starter accessories
accessories: [None, Acc01_Ladybug, Acc02_Bee, Acc11_Beanie, Acc18_Chef]

# Julie default
default_body: Body_03
default_hair: Hairstyle_22_04
default_outfit: Outfit_14_03
default_eyes: Eyes_02
default_accessory: Acc01_Ladybug_01
```

All paths are relative to:  
`licensed_assets/limezu/modern_interiors/extracted/moderninteriors-win/2_Characters/Character_Generator/`  
Use the `16x16/` subfolder for all runtime sprites.

---

### Step 2 — Create preview composites

For each starter combination, generate a preview PNG showing the idle-facing-front frame (or all 4 directions if preferred):

```python
# Composite order (per CHARACTER_GENERATOR.txt):
body → eyes → outfit → hairstyle → accessory
# All pasted at offset (0, 0)
# Body is 927px wide; paste all other layers at x=0, they will be 896px — this is correct
```

Save previews to `assets/avatar_previews/` for use in the character select UI.

---

### Step 3 — Verify offsets before enabling layered mode

Before turning on the live in-game compositor:

1. Generate the **Julie default composite** as a static PNG
2. Display it in-engine and verify head/hair/outfit/eyes all register correctly at the isometric camera angle
3. Check the accessory layer — Ladybug should appear as a small element at the back of the head (top-down perspective)
4. Do the same for the Beanie (should cap the top of the head) and Chef hat (tall white hat, clearly above the head)

---

### Step 4 — Keep `LAYOUT_VERIFIED = false` until confirmed

In the avatar compositor code, maintain:

```gdscript
const LAYOUT_VERIFIED := false  # Set true only after Julie approves live composite

func compose_avatar(config: AvatarConfig) -> Texture2D:
    if not LAYOUT_VERIFIED:
        push_warning("Avatar compositor: LAYOUT_VERIFIED is false. Returning placeholder.")
        return PLACEHOLDER_TEXTURE
    # ... actual compositor logic
```

Only set `LAYOUT_VERIFIED = true` after Julie visually approves the in-engine composite.

---

### Step 5 — Enable UI controls selectively

Enable only the controls whose layers render correctly in the composite test:

| Control | Enable? | Notes |
|---|---|---|
| Skin tone selector | ✅ Yes | Pure body swap, no alignment risk |
| Hair style selector | ✅ Yes | Confirmed aligned |
| Hair color selector | ✅ Yes (1–7 per style) | Color swaps only |
| Outfit selector | ✅ Yes | Confirmed aligned |
| Outfit color selector | ✅ Yes | Color swaps only |
| Eyes selector | ✅ Yes | Confirmed aligned |
| Accessory selector | ✅ Yes, starter set only | Verify Beanie + Chef hat in-engine before adding more |
| Kids outfits | ❌ Not yet | Separate review needed |

---

*Report generated by Hermes · Do not commit · Await Julie approval*
