# Delve implementation and verification

October 12, 2026. The complete implementation pass has resumed. Foundation and
progression persistence are implemented locally; the existing game flow is
still active. The user requires programmatic checks, actual game playtests,
and review at every serious checkpoint. Do not advance past a checkpoint
without reporting and resolving its missing verification.

## Checkpoint

The user requested a checkpoint before code changes. The default branch is
`master`, and both local and origin heads were already at
`578589eb731f5f74c01db0d36f58530dee254bff`. The annotated tag
`checkpoint/pre-delve-refactor-2026-10-12` was created and pushed; its remote
peeled commit was verified to match. No pending game changes existed in the
main checkout. Local `.agents` skill files were left untouched.

Implementation uses the existing `feat/dungeon-progression-design` worktree,
fast-forwarded to that checkpoint. The default branch remains unchanged.

## Foundation

- `Cubrism/Progression/DelveRules.swift`: hidden Gaussian difficulty sampling,
  decimal power input, accepted rarity curves, best-of-depth distribution,
  item-count rolls, continuation bonuses, performance weights, and rating
  gain/loss calculations. Challenge exponent remains a named tuning input.
- `Cubrism/Progression/DelveRun.swift`: account/run state, ownership of banked
  and at-risk items, checkpoint equipment, clear/continue/extract/death/abandon
  transitions, XP retention/cap/lifetime accounting, resource carryover,
  once-per-floor shield refill, and historical peak-capacity healing.
- `Cubrism/Progression/DelveSaveStore.swift`: a versioned account/run document,
  atomic file replacement, validation before load/write, and transactions
  that publish state only after a successful write. The store currently owns
  progression state on the main actor; background writing and a full combat
  snapshot will be added before connecting high-frequency game events.
- Stable floor IDs reject stale events. XP event IDs and floor phases prevent
  repeated rewards after a model snapshot round trip. Extraction is idempotent
  for the most recently settled run. Old events cannot settle a new run.
- Each checkpoint records all current-floor reward IDs. Loaded rewards must
  match the corresponding run-bag suffix and sampled power, including all
  three drops at later floors. Corrupt, truncated, unsupported, and unreadable
  saves fail without initializing or overwriting an account.
- The same source files are included in the Xcode app target and the root
  Swift package, so the pure model can be tested without SpriteKit or an iOS SDK.

The model accepts normalized performance, generated item records, calculated
capacity changes, and fixed level-up costs from its integration boundary.
Runtime callers should use the provided reward roller to select quantity and
rarity before creating item records, then submit the clear once. Boss XP is
credited before clearing the floor. A production level-100 account supplies
99 fixed level-up costs. The offline calibration remains the place to tune
those costs; this milestone does not choose a new XP economy implicitly.

## Verification

Normal command: `swift test --jobs 2` from the repository root. The package
explicitly selects the new tests, excluding the obsolete placeholder package
and its unrelated tests. Cases cover accepted probability/rating anchors,
Gaussian distribution, long-run quality, loss of all loot on floor-four death,
safe extraction, duplicate/stale events, checkpoint equipment loss, save
round trips, capacity-swap healing, shield refills, XP cap, and invalid inputs.

Also validate the project file with `plutil -lint Cubrism.xcodeproj/project.pbxproj`.

Verification completed on Beep:

- `plutil -lint Cubrism.xcodeproj/project.pbxproj`: passed.
- Swift type-check of both foundation files: passed using a build-local copy
  of the Swift resource directory without the stale duplicate module map.
- A native assertion executable compiled from those exact two source files
  passed probability anchors/sums through Delve 100000, a 20000-draw Gaussian
  distribution check, rating crossovers, floor-four death, loot ownership,
  retained XP/rating gains, snapshot duplicate protection, equipment recovery,
  capacity history, shield refills, extraction, bonus reset, and XP at cap.
  This is targeted runtime evidence, not a successful XCTest suite run.
- `/Users/beep/.codex/skills/autoreview/scripts/autoreview --mode local --no-web-search`:
  clean, no actionable findings. The review covered the foundation source,
  package tests, and Xcode source membership. No findings were rejected.
- `git diff --check`: passed.

Before Xcode installation, `swift test --jobs 2` was blocked by the mixed
command-line toolchain: duplicate `SwiftBridging` definitions, then a manifest
linker error after isolating resources. Native compilation worked without
changing installed compiler/SDK files. That limitation is now resolved by
the user's macOS upgrade and Xcode 27 installation; the full package suite
passed using the installed Xcode toolchain. App verification follows below.

Local evidence is under ignored `build/`: `delve-review.txt/json`,
`DelveSmoke.swift`, `delve-smoke`, and compiler/test logs. The successful
direct compile used:

```sh
swiftc -resource-dir "$PWD/build/isolated-toolchain/usr/lib/swift" \
  Cubrism/Progression/DelveRules.swift Cubrism/Progression/DelveRun.swift \
  build/DelveSmoke.swift -o build/delve-smoke
./build/delve-smoke
```

The isolated resource directory is a local copy of the installed `usr/lib/swift`
with its sibling `usr/lib/clang` linked to the installed Clang resources and
only the current `bridging` header plus `bridging.modulemap` in the sibling
`usr/include/swift`. This workaround is a local verification aid, not a game
dependency or a committed toolchain.

## First serious checkpoint: progression persistence

The new persistence suite adds ten scenarios to the eleven foundation tests.
Cases use real temporary files and cover a fresh account, combat reloads,
checkpoint equipment, continuation without repeated shield refill, death on
floor four, transactional boss-XP/clear rollback, deterministic I/O failure,
extraction exactly once, invalid decoded values, unsupported/truncated files,
and corruption of each of three checkpoint rewards.

All 21 scenario methods passed natively on Beep. A build-local assertion
adapter generates a standalone runner from the actual test source, removing
only XCTest/module imports and supplying fatal assertion functions. This
exercises the real production files and scenario bodies but is not XCTest
execution or an app playtest. Source and binary: ignored
`build/delve-native-tests.swift` and `build/delve-native-tests`.

```sh
swiftc -swift-version 5 \
  -resource-dir "$PWD/build/isolated-toolchain/usr/lib/swift" \
  Cubrism/Progression/DelveRules.swift \
  Cubrism/Progression/DelveRun.swift \
  Cubrism/Progression/DelveSaveStore.swift \
  build/delve-native-tests.swift -o build/delve-native-tests
./build/delve-native-tests
```

The persistence autoreview found one accepted issue: checking only the final
two rewards permitted a bad power value on a three-item checkpoint. The
per-floor reward IDs and all-three-items regression scenario fix it. A fresh
review completed cleanly with no actionable findings. No findings were
rejected. Command:
`/Users/beep/.codex/skills/autoreview/scripts/autoreview --mode local --no-web-search`
with checkpoint context and output paths under
`build/delve-persistence-review-final.*`. `git diff --check` and project-file
lint also passed. On resumption, the actual XCTest run passed all 21 tests
with zero failures:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun swift test --jobs 2 \
  --scratch-path /Volumes/BBD-2/CodexBuilds/cubrism-delve/core
```

The Catalyst app build and 47 app-hosted regression tests subsequently passed,
including two new scene-lifecycle checks. The actual SpriteKit playthrough
also passed both floors through normal movement/shooting, rooms, doors, and
bosses, including deaths/retries and completion reward checks. It took
338 seconds and used no health, damage, collision, or reward overrides.

The first app test attempt exposed a UIKit launch assertion: SDK 27 requires
the scene-based life cycle. See
[Apple's migration documentation](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle).
The scoped fix adds `SceneDelegate`, a single-scene manifest, window-connected
startup via `AppDelegate.configureGame(in:)`, and control reset from
`sceneWillResignActive`. Tests verify a visible, scene-connected home window
and that deactivation clears controls without refilling health/shields.

The lifecycle/progression autoreview completed cleanly with no actionable
findings. Its output is under `build/delve-lifecycle-review.*`. App test and
playthrough logs are `build/delve-catalyst-tests.log` and
`build/delve-live-playthrough.log`. Result bundles are under
`/Volumes/BBD-2/CodexBuilds/cubrism-delve/results/`:

- `foundation-app-tests-20261012-01.xcresult`: initial launch failure.
- `foundation-app-tests-20261012-02.xcresult`: 47 passing app regressions.
- `foundation-live-playthrough-20261012-01.xcresult`: passing two-floor live
  SpriteKit combat playthrough.

The user unlocked the Mac and the hands-on visual/control check completed.
The exact built Catalyst app launched with the expected home art and layout.
Keyboard movement visibly moved and rotated the player; walking to the
entrance opened level selection, selecting floor one opened its safe starting
room with full resource bars, and pause/resume controls worked. No rendering
or navigation issue was observed. Projectile/combat behavior is covered by
the passing live two-floor playthrough above. The game was left paused.

At the user's request, a 12-hour `caffeinate -disu -t 43200` assertion was
started and verified with `pmset -g assertions`. It keeps the system/display
awake and declares user activity during continued playtesting. Its process
is PID 58591 (unified command session 66039); renew it only if the work outlasts
it and stop that process when hands-on work ends. No password requirement was
changed. This resolves the missing first-checkpoint verification.

Initially Beep ran macOS 15.3.1 without Xcode. A proposed Xcode 16.4 download
stopped at Apple ID sign-in and was cancelled without credentials or a
download. The user then upgraded macOS to 27.0.1 and installed Xcode 27.0
(27A266a) at `/Applications/Xcode.app`. Installation was verified from
PackageKit logs, the installed executable, and `xcodebuild -version`.

The user explicitly authorized accepting the displayed Xcode/Apple SDK
agreement. The Agree action was followed by administrator authentication;
computer control could not access SecurityAgent, so the user completed the
prompt. Xcode's required system-component Install action and the official
`xcodebuild -runFirstLaunch` completed successfully. SDK enumeration and
Mac Catalyst destination discovery now work. Swift is Apple Swift 6.4.

Build commands use a per-command `DEVELOPER_DIR`; no manual global toolchain
selection is needed. Large build products go under
`/Volumes/BBD-2/CodexBuilds/cubrism-delve`. The temporary five-minute heartbeat
`resume-cubrism-after-xcode-setup` was paused after setup succeeded and work
resumed, to avoid duplicate continuation. The Catalyst build succeeded; its
log is ignored `build/delve-catalyst-build.log`. No legacy-save cutover has
occurred; the existing acceptance test temporarily creates fresh progress
and restores its saved preference values afterward. Do not label native
assertions as a game playtest.

## Stored floor generation checkpoint

`DelveFloorPlan.swift` generates and stores the whole route, stable room and
spawn IDs, normalized enemy spawn positions, room density, grouping cost,
budget, and one final boss. Starting and continuing a run sample difficulty
once and generate one corresponding plan, preserved by the atomic save.
The required plan changes the foundation-only payload, so the save version
is now 2. Version-1 files are rejected explicitly without overwriting them;
no replacement encounters are silently generated while loading.

The initial planner uses the candidate budget `12*(1+x)^0.1`, grouping
multiplier 0.25, and one/two/three-mob target densities. New encounter variants
become eligible at 1, 11, 21, ... through 101, covering the existing nine
ordinary types and two elite variants. Eligibility does not guarantee a spawn.
The guaranteed boss sits outside the ordinary budget. These are named initial
tunings; no Delve, duration, room-count, or item-power cap was introduced.

`FloorViewController(plan:)` validates and renders stored plans through a
coordinate dictionary, avoiding a quadratic array of unused scenes.
`RoomScene` consumes the exact stored enemy kinds, positions and boss. Normal
and notification-driven navigation share the same door transition. Legacy
selection remains the default until the later account/world/UI cutover.
Continuous stats and XP for this adapter are still subsequent work.

All 26 pure XCTest scenarios pass. Five new planner scenarios traverse 500
floors from Delve 1 through 100000, check point spending/eligibility/one final
boss, compare sparse/dense populations, verify non-guaranteed new enemies,
reject invalid routes/encounters, and preserve plans through reload/continue.

App-hosted verification passed 49 regressions. The exact-plan adapter check
found that SpriteKit's float positions differ slightly from stored Doubles;
it now uses a 0.001-pixel assertion tolerance, while the saved values remain
exact. A direct SpriteKit probe measured 0.000015 pixels of rounding.
Instantiating the existing generator boss also exposed a fractional Retina
size bug: a 333.5-point source became 333.6667 points at 3x rendering.
`GameArt.render` now selects an integer scale that preserves source logical
sizes. A focused regression covers halves, thirds, and whole-point sizes.
All temporary `[DEBUG-floor-art]` instrumentation was removed.

The hands-on fixture loads a plan after an encode/decode round trip and
restores legacy preference values on completion. Native keyboard input moved
from the safe start through its north door into a three-enemy combat room;
locked doors, green ranged projectiles, resource depletion and the death
screen rendered correctly. This was a control/visual inspection, not a
manual full-floor clear. The timed fixture passed. The separate live combat playthrough then cleared
the generated floor on its first normal attempt, including all three combat
rooms, the generator boss, and its exit. It retained 45.3 health, credited 130
XP exactly once, and produced two legacy completion items. The test passed
in 109.334 seconds, including its 20-second final inspection window. No
health/damage/collision/loot/completion overrides were used. XCTest reported the scenario and suite passed, but Xcode then stalled in
XCResultKit finalization on the external drive (sample at
`build/delve-test-finalization-sample.txt`). Its result bundle lacked the final
Info.plist and listing that directory also blocked. The launcher was stopped
after test completion; the same check is being retried with result output on
the internal drive at `build/results/floor-plan-live-playthrough-20261012-02.xcresult`.
The internal result path alone still blocked while reading external DerivedData,
so builds now use `build/DerivedDataDelve` on the internal drive (242 MiB at
this point). The internal repeat finished normally but failed ten attempts
against a golem. The earlier generator clear remains valid evidence, but this
new failure must be diagnosed before the checkpoint is accepted. Current
hypotheses are bot corner kiting, boss collision dimensions, and frame-rate
dependent enemy movement. A focused production movement regression is being
run before changing behavior.
The rewards are still the legacy adapter path,
not the later Delve settlement UI.

Review accepted the schema-version finding and fixed it. A later suggestion
to impose a gameplay ceiling for local scores such as 1e100 was rejected as
an unrealistic save-edit scenario contrary to the accepted uncapped design;
its deliberate policy is recorded beside the shallow budget curve. The final
structured autoreview completed cleanly (exit 0, no actionable findings).
Output: `build/delve-floor-review-complete.txt/json`. `git diff --check` and
project-file lint passed. No pending accepted review findings remain.

Commands use the existing Xcode toolchain and external build directories:

- Pure tests: the `xcrun swift test` command above; log
  `build/delve-floor-tests.log`.
- App regressions: Cubrism scheme, `-only-testing:CubrismTests` and
  `-skip-testing:CubrismTests/CubrismPlaythroughTests`; passing result
  `floor-plan-app-tests-20261012-03.xcresult` (earlier runs stopped at the
  precision/art assertions while XCTest's symbolication stalled).
- Hands-on fixture: CubrismAcceptance scheme,
  `-only-testing:CubrismTests/CubrismPlaythroughTests/testGeneratedFloorHandsOnPreview`;
  result `floor-plan-hands-on-20261012-01.xcresult`.
- Live combat: CubrismAcceptance scheme,
  `-only-testing:CubrismTests/CubrismPlaythroughTests/testGeneratedFloorThroughCombatAndDoors`;
  result `floor-plan-live-playthrough-20261012-01.xcresult`.

## Movement timing and mobile verification

The generated golem check exposed a desktop bot weakness: it prioritized
lining up shots near the room edge until the pursuing boss caught it.
Do not interpret those failed ten-attempt desktop runs as a successful
playthrough. The touched production movement also had an independent,
verified timing defect. The focused real `BossTrackingComponent` test went
red: after one simulated second it moved 45, 90 and 180 units at 30, 60 and
120 Hz. Its collision area was stable. This is not evidence that frame rate
caused the desktop playback failure; the live playback ran near 60 Hz.

`GameScene.frameMovementScale` now converts the authored per-60-Hz-frame
speeds using elapsed frame time. Random/tracking/dash enemies, homing shots,
boss tracking, and moving/rotating golem rocks use that conversion. Three
new app tests cover 30/60/120 Hz movement across those actual production
methods. All 52 app regressions passed with zero failures. The desktop bot
uses test-only waypoints for the golem; the experimental global close-enemy
penalty was removed, and waypoint state resets on each room entry. No
production health, damage, collision or reward override was introduced.

The actual generated golem floor passed on the iOS 27 iPhone 18 Pro simulator
on its second normal attempt, retaining 44.3 health and crediting the expected
XP/items. Test duration was 126.310 seconds, including the final 20-second
inspection window. Command: CubrismAcceptance scheme with
`-destination 'platform=iOS Simulator,id=A755ED47-4805-429A-9DC5-78323E355AF7'`
and `-only-testing:CubrismTests/CubrismPlaythroughTests/testGeneratedFloorAgainstGolem`.
Result: `build/results/generated-golem-ios-20261012-01.xcresult`; log
`build/delve-golem-ios-playthrough.log`. The gameplay input path uses the
normal continuous movement/aiming controls on iOS.

Hands-on inspection used Xcode 27's Device Hub at
`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`. Apple documents
this replacement simulator UI in [Device Hub](https://developer.apple.com/documentation/xcode/device-hub).
The iPhone was rotated into landscape and the timed generated-floor fixture
was brought to the foreground. Both joysticks and resource bars rendered
correctly; touch dragging moved the player and changed its aim. The timed
fixture later ended during a longer input sequence and returned to Home;
remaining gestures opened the simulator's Maps app. Its location request
was declined, and the device was returned Home. Do not count that sequence
as a manual floor clear or a verified mobile pause interaction. Earlier
native Catalyst checks verified generated-room entry, locked doors, incoming
projectiles, resource depletion, death UI, and pause/resume. Automated mobile
combat plus these hands-on checks satisfy this checkpoint's gameplay check.
Future manual fixtures should check their remaining time and observe after
short input sequences.

Large build/test output is now stored internally because finalizing the first
external XCResult bundle stalled. Use `build/DerivedDataDelve` for Catalyst,
`build/DerivedDataDelveIOS` for iOS, and `build/results/` for test results.
The internal drive still had 38 GiB free when switching; Catalyst output was
242 MiB. Both iOS 18.5 and iOS 27 runtimes are installed. A second 12-hour
`caffeinate -m -t 43200` disk-idle assertion is PID 92215 (command session
85362); the original display/system/user-activity assertion remains PID
58591. No authentication setting was changed, and the Mac remained accessible.

Final structured movement review completed cleanly with exit 0 and no
accepted/actionable findings: `build/delve-movement-review-verified.txt/json`.
Earlier advice about mixed CGFloat/Double compilation was contradicted by
real compilation; the assertion was still made explicit for clarity. Earlier
advice about the homing test's branch order was also inaccurate (random
movement was the final fallback); explicit mode selection now makes its
coverage clear. A cache-artifact finding was accepted: generated Python
bytecode was removed and its directory ignored. Temporary debug probes were
removed. `git diff --check` passes. This completes this checkpoint. Continuous
Delve combat/gear/XP scaling and full combat persistence remain outstanding.

## Continuous balance module (October 13)

The pure `DelveBalance` module now calculates fractional item stats, actual
capped character stats, uncapped reference stats, enemy/boss health and damage,
and content-based XP allocations. It uses the accepted reference rarity and
kill-time/survival anchors. Boss raw damage ratios and ordinary enemy authored
ratios remain inputs from their existing definitions. Whole-item rarity scales
every nonzero stat; the reference loadout averages the four attachment types.

The fixed 99 XP costs and reference character levels are generated into
`DelveCalibration.swift`. Reproduce the table with:

```sh
python3 -B docs/calibration/delve_reference.py --swift-output build/DelveCalibration.swift
diff -u Cubrism/Progression/DelveCalibration.swift build/DelveCalibration.swift
```

The generated table matches exactly. All 33 pure scenario methods passed,
including the seven new balance scenarios, a corrupted mob/boss reward-ID
collision, and explicit rejection of schemas 1/2 after adding required balance
to schema 3. All 52 Catalyst app regressions also passed. Evidence:
`build/delve-balance-tests.log`, `build/delve-balance-app-tests.log`, and
`build/results/balance-app-tests-20261012-01.xcresult`. Structured local review
returned clean with no findings: `build/delve-balance-review.txt/json`.

This is the verified math portion, not a completed live-combat checkpoint.
The existing game still uses its legacy Player/enemy stats. The next work is
to connect the single account/run authority, apply these stats to real actors,
and perform the corresponding normal-input combat and hands-on checks before
calling that checkpoint complete. Full combat save/resume and cutover also
remain outstanding.

The user's request to prevent another idle lock is covered by the temporary
display/system/user-activity keep-awake assertion. `pmset -g assertions` verified
it at 23:53 on October 12 with about 9.8 hours remaining. Renew it if required
by continued playtests; do not change password or authentication settings.

## Derived ownership and ordered saves (October 13)

`DelveProgression` now provides the gameplay-facing operations `enterDungeon`,
`characterStats`, `awardKill`, `receiveHit`, `equipItem`, and `finishFloor`.
They derive capacities/armour from owned equipped gear and actual XP level.
Ordinary planned kills receive normalized XP once; summons and early boss IDs
receive none. Boss XP, capacity growth, loot and rating commit together.
The resource-level operations remain for isolated invariant tests.

A fresh account owns seven Delve-1 Common items, including Health/AttackPower
attachments. Its individual stats are 160 health, 140 shield, 40 attack; the
accepted 150/150/37.5 benchmark is the average of all legal attachment pairs.
This choice gives the starter a balanced capacity/offense tradeoff without
changing the ensemble reference used for enemy calibration.

The store stages live combat changes without writing every frame. One serial
background writer orders snapshots and critical transactions by revision.
`prepare` freezes one generated candidate; `commit` publishes only after an
atomic write. Failed critical writes retain the same pending token for retry
and block other mutations. Old tokens cannot undo newer commits. Synchronous
transactions remain for existing foundation tests.

All 42 pure scenario methods passed, including five asynchronous real-file
save scenarios and four derived ownership scenarios. Fifty overlapping
snapshots cannot overwrite a later abandonment. Deterministic write failure
leaves checkpoint state unpublished, retains the prepared loot and permits an
exact retry. Early boss XP is explicitly rejected; this was an accepted review
finding and was fixed before the clean follow-up review.

All 52 Catalyst regressions passed. The first run found zero wall contacts in
the projectile fixture, which used an unattached UIWindow. The fixture now
uses the app's connected UIWindowScene, makes its test window key/visible,
and restores the original window. Its focused test and full suite both pass.
Evidence: `build/delve-owner-tests.log`, `build/delve-owner-app-tests-fixed.log`,
`build/results/owner-app-tests-20261013-03.xcresult`, and clean structured review
`build/delve-owner-review-fixed.txt/json`. No findings were rejected.

These operations are not yet connected to the live scene, and the stored
snapshot still lacks full combat state. Do not label this as a completed
playable-loop or combat-resume checkpoint.

## Combat-resume investigation

Apple's [SKNode documentation](https://developer.apple.com/documentation/spritekit/sknode)
supports coding/decoding nodes, but does not promise preservation of elapsed
action time. A native SpriteKit diagnostic archived a node partway through a
two-second, 200-point movement. It restored the current position and active
action, but the action restarted its duration/distance: after another 1.9
seconds the restored node was near 280 with movement still active, instead of
finishing at the original destination 220. Evidence is the ignored diagnostic
`build/DelveActionArchiveProbe.swift` and its log. This is a diagnostic, not a
gameplay clear or final resume verification.

Use explicit gameplay motion/phase records with logical-clock deadlines and
remaining movement/lifetime. Retain cosmetic SpriteKit animations where they
do not change combat. Do not use opaque node archives as the authoritative
combat save format. This keeps the existing AI/combat patterns while making
their state and scheduled effects restorable.

## Explicit motion checkpoint (October 13)

The combat-state module provides validated Codable movement, travel/lifetime,
delayed-event cursors, a saved SplitMix64 stream, projectile shot accounting,
and performance counters. Movement continues from its saved elapsed time to
the original destination; delayed explosions resume after the last fired
event. In-flight shots are neutral at combat end, each resolved projectile
counts once, and inactive time does not enter the speed metric.

The SpriteKit adapter weakly references its nodes and advances explicit motion
records. Player shots, wall-bound enemy shots, ring/bomb fragments, generator
spray/field telegraphs and dragon breath use a shared movement entry point.
The legacy path still uses SKActions; generated-floor fixtures opt into the
explicit path until the live account/combat integration is ready. This flag is
an implementation seam, not a product setting. Full world persistence and the
remaining bomb/fireball callback conversions are still outstanding.

All 47 pure methods passed. All 54 Catalyst app regressions passed, including
real-node movement save/restore, paused movement, remaining lifetime, and
cleanup after projectiles are removed. The iOS 27 generated floor with the
explicit motion path cleared its generator boss on the first normal-input
attempt, ending alive at 102 health, 130 legacy XP and two legacy rewards.
Test duration was 74.666 seconds including the 20-second inspection window.
This verifies movement/combat compatibility; the new account economy remains
unconnected to that fixture and must not be credited as a Delve-loop test.

Hands-on checks in Device Hub moved/aimed the player, entered the first combat
room, observed locked doors and incoming green projectiles, paused through the
UI, resumed, and observed shield depletion and eventual death. The second
pause click came after death, so do not claim a manual depleted-resource pause
or live-projectile freeze check from it. The real-node programmatic test does
verify paused motion. The 180-second fixture completed normally and restored
the prior game/preferences; no extra gestures were sent after it ended.

Evidence: `build/delve-combat-state-tests.log`,
`build/delve-combat-motion-app-tests.log`,
`build/results/combat-motion-app-tests-20261013-01.xcresult`,
`build/delve-restorable-motion-ios-playthrough.log`,
`build/results/restorable-motion-ios-playthrough-20261013-01.xcresult`, and
`build/results/restorable-motion-ios-hands-on-20261013-01.xcresult`.
Structured local review is clean with no findings:
`build/delve-combat-motion-review.txt/json`. `git diff --check` passes.
The Mac remained awake and accessible throughout these checks.

## Room lifetime checkpoint (October 13)

A real ARC test initially failed for all three weak references: retired enemy,
dragon boss and room. On departure the scene now cancels descendant actions,
disables its contact delegate, retires components/action arrays/entity links,
clears motion records and removes door visual backreferences. Contacts queued
by an inactive room are ignored before accessing retired actors. This keeps
completed rooms reusable while releasing their old combat objects.

Dragon's fireball callback and bomber fuse callbacks weakly capture their
owners. Bomber death cancels fuse actions before detaching nodes. Cancellation
alone still left the removed bomber component alive in the test; weak captures
of both component and bomb fixed that remaining retention. A real SpriteKit
fuse test confirms that all four explosions still execute while alive.

The full 56-test Catalyst suite passed, covering all ten enemy variants,
all three bosses, and an already-dead bomber. The additional focused live-fuse
test passed in 5.524 seconds. A normal-input iOS generated floor/dragon clear
passed after retirement changes in 80.454 seconds, ending alive at 79.375
health with 130 legacy XP/two rewards. These remain compatibility checks for
the existing economy, not the completed Delve account loop.

Evidence: `build/delve-room-lifetime-red.log` (three retained references),
`build/delve-room-lifetime-green.log`,
`build/delve-room-lifetime-app-tests-fixed.log`,
`build/results/room-lifetime-app-tests-20261013-05.xcresult`,
`build/results/room-lifetime-ios-playthrough-20261013-04.xcresult`, and
`build/results/bomber-fuse-behavior-20261013-06.xcresult`.
Final structured review including the added behavioral test is clean:
`build/delve-room-lifetime-review-final.txt/json`. The earlier review identified
the dead-bomber retention but inaccurately said death did not cancel actions;
the source already did. Its underlying retention concern was addressed and
verified rather than applying that inaccurate diagnosis literally.

Full combat integration must capture a value snapshot before tearing down its
scene. The current cleanup does not itself provide combat restoration.

## Combat snapshot checkpoint: October 14

Typed schema-4 combat snapshots now capture and restore all eleven planned
enemy variants, all three bosses, their attack phases and cooldowns, fractional
health/damage, player pose and hit/shot timers, physics state, active projectile
movement/lifetime, summons, and scene RNG. The scene uses a logical clock that
stops while paused and does not absorb wall time on resume. Bomb fuses preserve
their four-event cursor and frozen damage; retirement cancels their owner’s
fuses. Actor order is preserved so random decisions consume draws in the same
order. Restored shots carry damage without requiring the original shooter.

The opt-in floor controller selects the saved room without spawning duplicate
actors, resumes paused, and restores earlier cleared rooms with traversable
doors. All remaining gameplay movement uses explicit timelines in this mode;
cosmetic animations remain SpriteKit actions. Account resources remain outside
the world DTO and are not refilled by controller restoration.

Verification:

- 53 pure scenarios passed: `build/delve-world-resume-pure-final-02.log`.
- 62 Catalyst regression tests passed:
  `build/results/world-resume-app-20261014-03.xcresult` and
  `build/delve-world-resume-app-tests-03.log`. Coverage includes all enemy
  variants; six boss attacks at 0.4, 2.4 and 4.4 seconds; continued boss-shot
  movement/expiry; bomb cursor continuation; missing/malformed saved actors;
  overdue partial rock cleanup; paused controller restore; and actual reentry
  into an earlier cleared room.
- The iOS normal-input playthrough captured/JSON-reloaded a damaged combat room
  and a boss fight, verified equality after one paused second, then completed
  the floor on its first attempt in 82.492 seconds. It retained 103 HP and
  credited the existing 130 XP/two-item reward once. Evidence:
  `build/results/world-reload-play-20261014-02.xcresult` and
  `build/delve-world-reload-play-02.log`. This isolates combat restoration;
  it is not evidence for the new economy or cross-floor loop.
- A 180-second native hands-on fixture passed. Joystick movement entered a
  locked combat room, aiming/firing worked, incoming shots depleted shields,
  death/retry worked, and pause/resume froze and resumed combat. Evidence:
  `build/results/world-resume-hands-on-20261014-01.xcresult` and
  `build/delve-world-resume-hands-on.log`.
- The autoreview helper failed before producing a review because its default
  gpt-5.5 model is unsupported by the current account. The repository’s
  code-review workflow supplied independent Standards and Spec reviews.
  Accepted findings fixed: opaque basic boss-shot motion, cleared-room door
  reconstruction, malformed/overdue golem rock phases, and an absent boss.
  Focused continuation regressions were added; both axes rechecked cleanly.
- Project-file lint and `git diff --check` passed.

Default game flow/economy is still legacy. Remaining work: authoritative live
account/player binding, performance/XP/damage event routing, atomic lifecycle
capture and I/O retry UI, checkpoint/entry screens, and the one-time save reset.
Do not label the complete Delve loop delivered at this checkpoint.

The user’s keep-awake request is currently served by an owned renewing
`caffeinate -disu -t 43200` loop, unified PTY session 9235, shell PID 96552
(initial child 96559). `pmset -g assertions` verified display/system idle sleep
prevention at 10:42 October 14. Current shell PID is in ignored
`build/keep-awake.pid`; children change after each 12-hour renewal. Stop the
owned shell and its current child on completion or explicit pause. No password
settings were changed. Earlier assertions had exited between turns.

## Authorized implementation pass

1. Finish progression/persistence verification and establish one authoritative
   account/run owner for the game's Player/UI adapters.
2. Generate and store whole floor plans: safe starting room, connected combat
   rooms, eligibility thresholds, grouping costs, and a guaranteed final boss.
3. Connect continuous enemy/gear scaling and the tunable XP calibration. Keep
   character cap 100, uncapped Delve/item power, and uncapped endgame reference
   levels. Normalize XP across equivalent-budget encounter layouts.
4. Route gameplay XP, clear, continue, extract, death, abandonment, equipment,
   and performance counters through run transitions.
5. Persist complete combat state: room progress, player/enemy/boss state,
   projectiles, timers/cooldowns, summons, RNG state, and counters. Capture
   consistent snapshots and serialize writes through one ordered owner. Resume
   paused; no encounter redraw, free recovery, revived enemies, or duplicate
   rewards. Replace only gameplay action callbacks that cannot be restored.
6. Build dungeon entry and checkpoint screens, including run-bag risk,
   equipment changes, continuation bonuses, Continue and Extract.
7. Perform the one-time legacy progression reset and verify the complete route
   in a development build before switching the default game entry.

Currency rewards and merchant purchases are deferred from the first Delve
playtest build. New abilities, distinctive rarity effects, extra enemy types,
and visual redesign are outside this pass. Keep changes on the feature
branch; merging and release are outside the active goal.

At each serious checkpoint, run the relevant pure-model/app checks, review
changed code, and play the game. Record the commands, results, observed
behavior, defects/fixes, and remaining verification here. Final acceptance
includes three-floor extraction; fourth-floor death; equipped run-loot loss;
combat/boss/checkpoint/settlement reloads; no capacity-swap healing; one shield
refill per floor; failed/invalid save behavior; no duplicate rewards; and
continued enemy/gear scaling beyond Delve 10000 with character cap 100.

## Following integration

The progression document is not a complete resumable live combat snapshot.
Add stored encounters, projectiles/timers, ordered background writing, and
lifecycle integration before enabling the new loop. Versioned atomic
progression persistence and validation are now implemented. No live saves
have been reset or migrated.

Next, connect floor planning, game events, equipment stat calculation, the
one-time save reset, and checkpoint/dungeon-entry screens. Character/enemy/gear
stat curves and performance normalization remain calibration work. Currency
ownership and merchant generation remain separate unaccepted proposals.

## Live account binding checkpoint: October 14

The main-actor DelveGameSession owns the atomic store, derived Player facade,
frozen authored combat ratios/catalog, and actual-plan HP/reference-DPS
performance target. Contact, kill and regeneration events publish with their
post-physics world. Critical entry/clear/continue/equip/extract/death/abandon
commits retain one prepared token for retry. Periodic snapshots coalesce
requests and drain lifecycle changes; room transitions preserve hit/shot
timers and stop on pending settlement.

All 53 core scenarios and 71 Catalyst regressions passed. Eight session
scenarios cover derived ownership, HP carry/shield refill once, death/loot
loss/XP, extraction, failed-write same-token duplicate retry, frozen scoring
targets, fatal hit-before-kill XP, suspension behind a blocked write, and death
during door navigation. The firing regression verifies 40 shots over two
seconds at 30, 60 and 120 Hz and one immediate shot after idle activation.
Evidence: `build/delve-session-core-tests.log`,
`build/results/session-regressions-20261014-03.xcresult`, and
`build/results/session-owner-20261014-05.xcresult`.

Both Standards and Spec reviews rechecked clean after fixes for fatal-frame
XP, snapshot coalescing, door transitions, cadence, and the critical-save
scheduling guard. The structured autoreview helper remains unavailable
because its default model is unsupported; the repository two-axis review
workflow supplied the reviews. No review was claimed from the failed helper.

Normal-input iOS combat completed three consecutive floors and extraction in
672.528 seconds. Earlier deaths retained XP and discarded the bag; retries
advanced character levels and used legitimate checkpoint equipment choices.
The successful chain advanced rating to 103.365, held six unbanked items,
then extracted them into the account (13 banked total). Reload matched the
settled model. Evidence:
`build/results/session-three-floor-play-20261014-04.xcresult`.
The acceptance counter now resets on death, and its equipment chooser excludes
an item already worn in another slot; no combat balance overrides were used.

Native simulator controls also entered a combat room from the safe start,
aimed and fired, depleted resources, and reached death. The owned scene
correctly froze; the missing settlement presentation belongs to the following
UI milestone. The 180-second fixture then checks durable reload equality.
Evidence: `build/delve-session-hands-on-02.log`.

Default App startup/lifecycle wiring, checkpoint/entry/error UI, and the
one-time legacy reset remain the next milestone. The full goal is unfinished.
Keep the keep-awake loop running during native tests.
