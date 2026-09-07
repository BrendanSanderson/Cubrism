# Stone & Enamel (Option A)

Selected direction: P1 yellow chassis with a separate central green rotating gun; enamel enemies, bosses and equipment; quiet stone floor; charcoal panels with ivory typography and brass accents. Health and shield retain the stacked capsule, emerald above icy cyan, with icons on the left and no percentages.

## Asset catalog

`Cubrism/GameArt.swift` is the single entry point for named UI images and SpriteKit textures. Existing names and saved equipment identifiers remain stable. Art is cached and rendered at the original logical image size, so high-resolution source images do not enlarge physics bodies or change arena scale.

Production source images live in `Cubrism/Assets.xcassets/StyleA`:

- `StyleEnemies`: 3 × 3 cells, in the order defined by `GameArt.enemies`.
- `StyleBosses`: 2 × 2 cells, in the order defined by `GameArt.bosses`.
- `StyleItems`: 3 × 2 cells, in the order defined by `GameArt.items`.
- `StyleGun`: isolated circular receiver and barrel; chassis is rendered separately.
- `StyleFloor`: full-bleed sandstone floor, tinted per world.

Sprite cells require genuine alpha, equal grid cells and transparent gutters. The catalog trims those gutters once. For a replacement, preserve the sheet ordering; for a new family, add its mapping and an original logical size. Legacy images remain as fallbacks and dimensional references. Generated-source provenance is in `art-sources.json`.

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
