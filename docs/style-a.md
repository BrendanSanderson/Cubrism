# Stone & Enamel (Option A)

Selected direction: P1 yellow chassis with a separate central green rotating gun; enamel enemies, bosses and equipment; ten distinct level backgrounds; charcoal panels with ivory typography and brass accents. Health and shield retain the stacked capsule, emerald above icy cyan, with icons on the left and no percentages.

## Asset catalog

`Cubrism/GameArt.swift` is the single entry point for named UI images and SpriteKit textures. Existing names and saved equipment identifiers remain stable. Art is cached and rendered at the original logical image size, so high-resolution source images do not enlarge physics bodies or change arena scale.

Production source images live in `Cubrism/Assets.xcassets/StyleA`:

- `StyleEnemies`: 3 × 3 cells, in the order defined by `GameArt.enemies`.
- `StyleBosses`: 2 × 2 cells, in the order defined by `GameArt.bosses`.
- `StylePulsar`, `StyleSpecialPulsar`, `StyleShield`, `StyleArmorCore`,
  `StylePowerCore`, `StyleAttachment`: each a 3 × 2 atlas ordered white, green,
  blue, purple, orange, empty. These replace `StyleItems`.
- `StyleGun`: isolated circular receiver and barrel; chassis is rendered separately.
- `StyleReactorArena`, `StyleCargoArena`, `StyleBioArena`, `StyleFungalArena`, `StyleCoralArena`, `StyleClockworkArena`, `StyleStormArena`, `StyleOrbitalArena`, `StyleHiveArena`, `StyleForgeArena`: continuous floor/border art for local levels 1–10, in that order, repeated in each existing world. Home uses Reactor Arcade. Cargo Hold uses the approved smoother revision; Molten Forge is always level 10. Generation prompts, source filenames and measured opening bounds are in `background-art-sources.json`.
- `StyleFloor`: retained for legacy background-name rendering; active scenes use the ten arena assets above.

`GameArt.arenas` owns each background's name and measured source opening. Runtime
drawing fits that opening to the existing 90% × 80% collision rectangle, with a
750 × 375 logical size and Retina rendering. Each room resolves its
own floor controller's local level, so room changes, reentry and later worlds
keep the selected level's artwork. SpriteKit and UIKit cache the results.
Gameplay, doors and controls remain separate foreground nodes.

Sprite cells require genuine alpha, equal grid cells and transparent gutters. The catalog trims those gutters once. For a replacement, preserve the sheet ordering; for a new family, add its mapping and an original logical size. Legacy images remain as fallbacks and dimensional references. Generated-source provenance is in `art-sources.json`.

Equipment uses proportional fitting and a small transparent inset rather than
stretching wide guns into squares. Its rendered textures retain at least 288px
per side while preserving logical point sizes. Common gear uses the white family
image; higher tiers retain saved cosmetic variant suffixes 0–3 (green, blue,
purple, orange). Inventory, shop and completion rewards share the same resolver.
Equipment generation prompts and approved references are in
`equipment-art-sources.json`. The current asset review and remaining design work
are in [asset-audit.md](asset-audit.md).

Dragon mouth and golem jump frames derive from the new boss art, so attack/movement animations stay in the selected style. Panels, buttons, doors, tier rims, player chassis and HUD are drawn at runtime for crisp scaling. SF Symbols provide interface icons. Health and shield artwork remains at full width while crop masks reveal the current fill. A separate outline preserves the capsule shape at low or zero health.

## Verification

The unit suite covers catalog transparency and original logical sizes, bar fill states, movement/shooting, projectile travel, rewards, persistence and responsive completion layouts. Visual attachments include an asset gallery and completion screens at phone and desktop sizes.

The acceptance scheme runs live combat through floors 1 and 2 in order, via the existing keyboard state on Mac and joystick movement/aim handling on iOS. It does not change enemy damage, grant invulnerability, remove enemies or directly award completion. Failed attempts can earn experience under normal game rules. It checks each completion, earned experience and inventory, then restores the pre-test saved defaults.

Run with Xcode 16.4 and the `CubrismAcceptance` scheme, selecting only `CubrismPlaythroughTests/testFirstTwoFloorsThroughCombatAndDoors`. The regular `Cubrism` scheme skips the long acceptance run. An actual phone touchscreen and physical keyboard remain useful manual device checks; the automated pilot exercises game input handling rather than physical hardware.

## Validation on 2026-09-06

- Mac Catalyst: 32 regression tests passed on the final code; live floor 1 then floor 2 combat also passed.
- iPhone 16e / iOS 18.5 simulator: 32 regression tests plus reward-page presentation/Continue passed. The final-art live combat run cleared floor 1 on attempt 4 and floor 2 on attempt 1, with normal progression between attempts.
- Final recorded rewards: floor 1 awarded 141 XP (289 total); floor 2 awarded 224 XP (513 total), with inventory assertions passing after each clear.
- Visual review: catalog gallery, HUD at full/partial/empty states, completion layouts at phone and desktop sizes, and live combat video. Generated assets with opaque checkerboard backgrounds were rejected before delivery.
- Structured code review: no actionable findings in the final review.

The video uses an automated pilot through the game's input handling. It retains failed attempts; only simulator footage after the final result is trimmed. It does not substitute a completion-screen fixture for a combat victory. Physical device input testing is not claimed.

## Follow-up on 2026-09-07

Restored the original bundled ammunition and projectile effect artwork, including the tracking bullet. Replaced the level picker with an explicit two-row page layout, reusable readable tiles, lock/cleared labels and Previous/Next world controls. Pages retain their position through layout updates; unlocking still uses global progress while labels remain 1–10 within each world. Catalyst consumes gameplay keys while the menu is open and clears them on return.

Validation: 34 checks passed on Mac Catalyst and iPhone simulator, including exact original projectile image comparisons, page geometry, and presenting the menu, rejecting a locked choice and launching the selected unlocked world/floor. Final structured review had no actionable findings.

## Reactor Arcade follow-up on 2026-10-01

Applied the approved Reactor Arcade direction to world 1, including its home
scene. The blue floor, teal pipes, orange collars and corner reactors form one
continuous image. Native foreground nodes supply all controls, characters and
doors; none are baked into the asset. The painted opening is fitted to the
existing collision rectangle, preserving the 750 × 375 arena and sprite scale.

Validation: the catalog, responsive arena-size and wall-bound projectile checks
passed on iPhone 16e / iOS 18.5 and Mac Catalyst. Temporary native layer exports
were visually inspected on both platforms. The installed Mac app was refreshed,
its ad-hoc signature verified, and the home scene checked in the running app.
`autoreview --mode local --no-web-search` returned no findings; none were accepted
or rejected. Results and full-resolution previews are retained under
`/Users/beep/codex-work/cubrism-validation/reactor-arena/`. This art pass did not
repeat the earlier complete floor 1–2 playthrough.

## Ten-background rollout on 2026-10-01

All ten approved arenas now follow local levels 1–10 in every world. The asset
catalog contains 145 image sets, including the revised Cargo Hold. All ten
production PNGs match their approved generated originals byte for byte.

Final targeted regression runs passed on iPhone 16e / iOS 18.5 (7 tests) and
Mac Catalyst (6 tests). They cover all ten background selections, room reentry,
world changes, logical arena size, wall-bound green shots and platform controls.
The iOS run also checks the restored projectile art and level-picker paging.
Both platforms rendered all ten scenes with the player, enemy samples, doors
and HUD for visual inspection. These galleries are render fixtures, not combat
victories. An initial fractional-scale pixel-rounding issue was corrected by
using an integer Retina scale; the final images retain exactly 750 × 375 points.

The fresh iPhone simulator acceptance run cleared floor 1 on attempt 1 and
floor 2 on attempt 4 through normal combat and door traversal (203 seconds).
Recorded totals were 141 XP / 2 inventory entries after floor 1 and 436 XP /
3 entries after floor 2, including normal progression from failed attempts.
The separate menu test also launched the selected unlocked floor successfully.
The automated pilot exercised joystick input handling; physical input testing
is not claimed.

`autoreview --mode local --no-web-search` returned no actionable findings; none
were accepted or rejected. The installed Mac app was refreshed, its ad-hoc
signature verified and its home scene checked after launch. Logs, result
bundles, review output and the iPhone/Mac preview galleries are retained under
`/Users/beep/codex-work/cubrism-validation/ten-backgrounds/`.
