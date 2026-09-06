# Cubrism restoration audit and acceptance plan

Baseline: 74a8822. Work branch: feat/cubrism-finish.

**Current status (September 5, 2026): acceptance passed.** Levels 1 then 2 were
beaten through normal combat with retries on Mac Catalyst, iPhone 16 Pro and
16e simulators. Native WASD/arrows and joystick input were checked separately.
24 focused regressions pass on each platform; iOS Release build passes. No
accepted review findings remain. Xcode 16.4/iOS 18.5 are installed without an OS
upgrade or reboot. Earlier sections below are the chronological audit history.

## Environment and baseline (2026-09-05)

Beep: macOS 15.3.1, Swift command-line compiler 6.1.2. No Xcode app,
no simctl. xcodebuild fails because only CommandLineTools is installed.
Internal volume has about 10 GB free; external volumes have more space.
Current Xcode requires a newer macOS (see Apple's Xcode system requirements).
User has been asked about preparing the OS upgrade/reboot or another Mac.
No gameplay, build, XCTest, or visual acceptance pass has occurred yet.

## Source audit findings

- Saved inventory dictionaries are force-cast directly to Item objects at static initialization.
- Death grants run experience twice, and subsequent contacts can continue damaging a dead player.
- Run experience is not cleared on retry/new floor; world/global level conversion occurs only on first view load and again in drops.
- Health bonuses read shield stats; Special Pulsar attack speed is ignored; cooldown calculation accumulates on refresh.
- Remote legacy constants mutate player/UI from a URLSession callback, can overwrite validated bundled data, and reset health mid-run.
- Room revisits retain dead entity arrays; enemy selection force-casts fractional point costs to Int and can loop without an eligible enemy.
- Enemy and boss death handling lack protection against duplicate lethal contacts.
- Joysticks retain CADisplayLink timers after removal; movement and regen are frame-rate dependent.
- Mac held keys are not reset on app deactivation; centered shooting input leaves shooting state active.
- Fixed view frames and SpriteKit node layouts do not respond consistently to resizing/safe areas.
- Home reset posts notification before deleting saved data and calls viewDidLoad directly.
- Existing UI test is empty; existing unit tests cover only startup/keyboard/level select.

## Implementation sequence

1. Persistence/startup and progression: deterministic bundled constants, correct inventory reconstruction, stable equipment stats, single reward accounting. Regression XCTest coverage.
2. Run lifecycle/combat: reset run state, global floor numbering once, bounded generation, duplicate death protection, cleanup, boss portal and rewards.
3. Input/layout: both sticks together, cardinal and diagonal WASD/arrows, release/cancel/focus, pause/resume; safe areas, small/large iPhone, Mac resizing; menus/vendors/rewards.
4. Runtime acceptance: clean save, beat floor 1 then floor 2 using normal movement/shooting and damage. Record each completion independently, XP before/after, drops, save/relaunch, level 3 unlock.
5. Broader acceptance: all boss variants, enemy variants, death/retry/quit, room revisit, equip/unequip, buy/sell/stacking, reset, offline launch, background/foreground, sustained scene transitions. Focused regression tests and final review.

## Completion gate

Do not report complete until current Xcode builds iOS Simulator and Mac Catalyst,
regression tests pass, first two floors are beaten consecutively with ordinary controls,
and screenshots/runtime evidence substantiate layout and both control schemes.
Source inspection or logic-only tests are not substitutes for playing the game.

## First patch and verification

Implemented an initial patch for inventory initialization, deterministic bundled
constants, equipment health/attack-speed stats, idempotent cooldown calculation,
experience thresholds and duplicate death XP, run reward reset, global floor
numbering, fractional enemy point costs, stale room entities, and repeated lethal
contacts. Added six focused XCTest regressions. These are pending execution.

Checks completed:
- `git diff --check`: passes.
- Swift parser over app, components, entities and unit tests: passes using
  `swiftc -frontend -parse -module-name Cubrism -Xcc -fno-implicit-modules ...`.
  This is syntax validation only, not typechecking/building.
- Asset catalog audit: all 427 filename references exist.
- Bundled property lists: parse successfully.

Additional tooling failure: compiling even the standalone unchanged keyboard
state with the installed CLI SDK fails with duplicate SwiftBridging module maps.
Do not report keyboard runtime tests as passed.

Further source findings to cover in phase 3/5:
- Inventory screens index a fixed 30-slot grid with unbounded inventory count.
  Add paging/scrolling; do not silently discard or hide earned drops.
- Merchant buy/sell saves through addDrop before the currency debit/item removal.
  Persist the completed transaction before the player can background/quit.
- The initial `border` texture name has no catalog entry (normally replaced by
  a world background); verify no missing-texture placeholders on reset/home.

- Project file and Info.plist pass `plutil -lint`.
- First structured review found a later-world normal enemy scaling mismatch;
  fixed to use the room controller's global floor and added a regression test.
  Follow-up structured review passed with no actionable findings.
- Inspect dragon fireball level offset: boss passes its already-scaled level
  into the enemy constructor's level-offset argument.

## Compatible Xcode attempt (2026-09-05)

User selected the older-Xcode route with no OS upgrade/reboot. Xcode 16.4
supports Beep's macOS 15.3.1 (Apple system requirements). Installed xcodes 2.0.3
via Homebrew. Created /Volumes/BBD-2/Cubrism-Developer/{Downloads,Applications}.
`xcodes download 16.4 --directory /Volumes/BBD-2/Cubrism-Developer/Downloads`
requires Apple Account login; no authenticated CLI session was available.
Apple Developer downloads in the in-app browser also redirects to sign-in.
Blocked on Apple authentication or an existing Apple-downloaded Xcode 16.4 .xip.
No OS changes or reboot were performed; gameplay acceptance is still pending.

## Archive downloaded and extracted

User initiated browser download. Confirmed growing Chrome partial, then completed
Xcode_16.4.xip (3,036,085,732 bytes). Moved to external Downloads directory.
`pkgutil --check-signature` reports signed Apple Software. Extracted successfully
with xip into /Volumes/BBD-2/Cubrism-Developer/Applications/Xcode.app.
Used external TMPDIR on retry; final internal free space approximately 6 GB.
First `xcodebuild -version` stalls in `xcodebuild -license status` before output;
stopped the stalled probes. Native UI inspection blocked on pending ChatGPT
Accessibility and Screen Recording permissions. `sudo -n true` requires password.
No build, test, or simulator run has occurred. Need first-launch setup completed
(or native UI access plus any necessary user administrator authentication).

## Native permissions and verified installation (2026-09-05)

Accessibility and screenshot access now confirmed via Finder and System Settings.
First extraction had a .BC temporary symlink in an embedded framework after its
interruption; deep codesign check failed. Re-extracted archive into fresh directory:
/Volumes/BBD-2/Cubrism-Developer/CleanInstall/Xcode.app
Deep strict codesign verification PASSED (valid on disk, designated requirement).
`DEVELOPER_DIR=.../CleanInstall/Xcode.app/Contents/Developer xcodebuild -version`
now reports Xcode 16.4 / Build version 16F6. This is the installation to use.
Xcode GUI launches to Xcode and Apple SDKs Agreement. checkFirstLaunchStatus and
simctl remain license-gated. Asked user for explicit legal agreement acceptance
per Computer Use tool confirmation rule. Permission access itself is resolved.

## Runtime checkpoint — September 5, 2026, 18:02 EDT

- Clean external Xcode 16.4 verified with deep strict codesign; EULA accepted by Brendan and required system components installed successfully, without reboot.
- Mac Catalyst build succeeds. Fifteen unit tests pass on actual Catalyst host after correcting Catalyst test deployment settings and test-host executable path. The old empty UI test runner stalled and was terminated; it is not acceptance evidence.
- iOS 18.5 (22F77) runtime installed successfully. iPhone 16 Pro boot/build/unit tests in progress, evidence `ios-tests-1.log`.
- Mac home screen visibly rendered with severe right-side clipping before fixes. Scene now initialized from safe-area SKView bounds, preserves logical coordinates via aspectFit on resize; arena and pause visible. Vendors now use scene size rather than launch-time screen constants.
- Removed joystick CADisplayLinks; polling occurs in the game frame update. Room update now polls even before first movement to allow joystick startup. Movement and shield regeneration use frame duration; shooting dead zone stops shooting, cardinal aim uses atan2, and vending suppresses movement/shooting.
- Native pause click works. CUA sends very brief key taps and sustained movement has not yet been verified. Do not count keyboard-state unit tests as actual input acceptance. First two levels have not been beaten.
- Remaining: real input/gameplay verification, all overlay resizing (UIKit overlays currently use scene coordinates), death/retry/completion lifecycle, vendor transactions/inventory capacity, remaining enemy/boss edge cases, inactive-input reset, regression tests for recent control fixes, final autoreview.

## Runtime checkpoint — September 5, 2026, 18:49 EDT

Xcode 16.4 and iOS 18.5 are operational. Use the clean installation above;
no reboot or OS upgrade was needed. Build outputs and logs now live under
`/Users/beep/codex-work/cubrism-validation/` because some external-volume build
outputs stalled when opened.

- iPhone 16 Pro actual SpriteKit playthrough passed floors 1 then 2. Floor 1
  cleared on attempt 3, floor 2 on attempt 4, with ordinary combat deaths,
  retained earned XP, movement/shooting, doors, bosses, and exits. No health,
  damage, loot, collision, or completion overrides. Exact single-award XP
  assertions passed: total XP 267 after floor 1 and 655 after floor 2; inventory
  contained 2 then 3 items. Evidence: `ios-playthrough-1.log` and its xcresult.
- The pilot sends movement/shooting vectors on iOS and WASD/arrow states on Mac.
  This is a real engine playthrough, not a manual touchscreen run. Separate
  native UI checks verified joystick drag input and Mac key events.
- Native Mac WASD and all four arrow-key directions verified. Buffered brief
  key events now survive between frames. Native iPhone left-stick movement,
  right-stick firing, home teleporter, bank and shop navigation verified.
- iPhone 16 Pro and smaller 16e landscape: full arena, safe-area margins,
  joysticks, pause/reset confirmation, bank equipment details, shop item details
  and inventory grids fit. Pause panel now scales with the scene. Canceling
  reset returns to the correct home menu. Insufficient-funds feedback is retained.
- 24 focused iOS tests pass (`ios-unit-8.log`), including inventory paging beyond
  30 slots, single-item details, persisted buy/sell balances, frame-rate movement,
  compact-arena spawn/attack generation, inactive-floor reward exclusion, and
  earlier persistence/equipment/progression regressions.
- Fixed duplicate completion rewards from inactive floor observers; room/home
  controller references are weak, and completion is scoped to the active room.
- Gameplay acceptance is opt-in through the `CubrismAcceptance` scheme, with a
  15-minute total deadline. The ordinary suite skips this randomized test.
  Run the acceptance scheme separately per platform; failures are retained as
  evidence and must not be reported as passes. Latest Mac run still pending.
- Remaining closeout: Mac sequential completion, completion-screen visual
  inspection, final focused regressions and structured review. No claim of
  exhaustive all-boss/all-world manual coverage is made.

## Closeout evidence — September 5, 2026, 19:04 EDT

- iPhone 16e sequential acceptance also passed: floor 1 on attempt 1 (147 total
  XP, 2 inventory items), floor 2 on attempt 7 (698 total XP, 3 inventory items).
  `ios-16e-acceptance-final.log` reports TEST SUCCEEDED. Deaths and retries were
  normal gameplay, and both exact single-award assertions passed.
- `ios-presentation.log` passes a separate presentation fixture check with eight
  loot items: scroll content extends beyond the viewport, the scroll view fits
  the safe area, and Continue dismisses completion and floor back to HomeScene.
  Continue was also activated through native accessibility UI. The fixture does
  not count as a combat completion. Native swipe injection did not scroll the
  simulator, so no claim of a successful manual swipe is made.
- Mac native window zoom and restoration preserve the full arena/HUD with
  letterboxing. Native shots and movement remain separately verified.
- iOS Release simulator build passes (`release-ios.log`). Final ordinary iOS
  regression run passes 24 tests; the two opt-in acceptance tests are skipped
  (`ios-regression-final.log`).
- Structured reviews `review-3` and `review-4` returned clean. Final review after
  the presentation test reported a cooldown-sign concern. Rejected with direct
  evidence: `constants.json` player.attack.speed.boostMult is -0.02 and
  Player.readConstants loads it; adding a positive gear bonus times this
  signed multiplier reduces cooldown. The regression explicitly asserts a
  shorter cooldown and passes. Added an explanatory inline comment; no formula
  change was made. No accepted findings remain.

## Mac sequential acceptance — September 5, 2026, 19:07 EDT

`mac-acceptance-final.log` reports TEST SUCCEEDED. From reset progress, floor 1
cleared on attempt 4 (337 total XP, 2 inventory items), followed by floor 2 on
attempt 5 (853 total XP, 3 inventory items). The pilot used WASD/arrow-key states
through the actual SpriteKit simulation. Normal deaths retained earned XP;
health, damage, enemies, drops, collisions and completion were not overridden.
Both exact single-award assertions and global unlock assertions passed.

The earned Mac floor-2 completion screen was inspected natively: 166 XP gained,
853 total XP, Cubrixel × 1, and Armor Core level 2/tier 2. All labels, icons,
progress and Continue fit. This satisfies the first-two-floors acceptance on
Mac Catalyst and both tested iPhone simulators, with native input checks reported
separately above.

Reproduce focused regressions with the Cubrism scheme and
`-only-testing:CubrismTests`. Run the randomized gameplay separately with the
CubrismAcceptance scheme and
`-only-testing:CubrismTests/CubrismPlaythroughTests/testFirstTwoFloorsThroughCombatAndDoors`.
The presentation fixture is a separate opt-in method in that class. Builds use
`CODE_SIGNING_ALLOWED=NO` for local simulator/Catalyst validation; distribution
signing and a newer-OS/Xcode upgrade are outside this compatible-Xcode setup.

Final Mac regression run: 24 passed, 2 opt-in acceptance checks skipped, zero failures (`mac-regression-final.log`). Final diff whitespace check passes. Changes remain uncommitted in the isolated task worktree.

## Completion-screen follow-up — September 6, 2026

The reported screenshot matches the original checkout's fixed-frame completion
screen, not the restored worktree. The restored layout now caps content width at
720 points, keeps Continue pinned within the safe area, and scrolls rewards
independently. Tested 667x375, 844x390, 640x480 and 1440x900 with 2 and 8 loot items.
25 focused tests pass on Mac and iOS; the separate presentation/Continue navigation
check passes on both. Native Mac presentation inspected. Layout render attachments
are under `/Users/beep/codex-work/cubrism-validation/completion-renders-final/`.
`autoreview --mode local` completed clean (`completion-review.txt`).
A verified copy of the updated Mac build is installed at
`/Users/beep/Applications/Cubrism Restored.app`. Source remains in the isolated
`/Users/beep/codex-work/cubrism-finish` worktree; the original checkout is unchanged.

## Arena proportions and green projectile range — September 6, 2026

Home and floor scenes now use a shared 750x375 logical arena. Mac window size
and iPhone safe-area dimensions only affect uniform display scale; they no
longer change enemy-to-arena proportions or available dodging space. Native Mac
normal/zoomed windows and the iPhone landscape viewport were inspected.

Aimed green shots and triple volleys now travel a scene diagonal at their
original speed, with wall contacts removing them. This replaces the fixed
500-point range; triple volley offsets are preserved. Aimed shots use atan2
for vertical aim. Expired volley wrappers are cleaned up as well.

27 focused tests pass on both Mac Catalyst and iPhone 16e, including real
SpriteKit contacts in eight directions (opposite-wall shots exceed 600 points),
projectile wrapper cleanup, and uniform safe-area fit at four window sizes.
Evidence: arena-mac-2.log and arena-ios-2.log under the validation directory.
The installed Cubrism Restored.app executable matches the tested build by
SHA256; native D movement and arrow-key shooting were checked after installation.

The first Mac combat run exhausted ten attempts. The test pilot was adjusted
to prioritize melee clearance over shot alignment and to stop chasing excess
bullet clearance; production combat stats and rules were unchanged. The iPhone
run cleared floor 1 on attempt 9 (472 total XP), then floor 2 on attempt 4
(879 total XP), with single-award, loot and unlock assertions passing
(arena-playthrough-ios.log). The final structured `autoreview --mode local`
returned clean (arena-review-final.txt/json).

Mac sequential acceptance also passed: floor 1 on attempt 10 (478 total XP),
then floor 2 on attempt 3 (760 total XP), with exact single-award, inventory
and unlock assertions passing (arena-playthrough-mac-2.log). Native rendering
was inspected during normal and zoomed combat, including the floor-2 boss.
These were automated pilots using normal movement/shooting controls and normal
retries, with no health, damage, enemy or completion overrides.
