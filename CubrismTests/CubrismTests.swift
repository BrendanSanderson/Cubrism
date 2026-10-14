//
//  CubrismTests.swift
//  CubrismTests
//
//  Created by Brendan Sanderson on 3/3/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import XCTest
import UIKit
import SpriteKit
@testable import Cubrism

private func completionView(_ root: UIView, id: String) -> UIView? {
    if root.accessibilityIdentifier == id { return root }
    return root.subviews.lazy.compactMap { completionView($0, id: id) }.first
}

class CubrismTests: XCTestCase {

    @MainActor func testApplicationLaunchConnectsHomeWindowToScene() throws {
        let app = try XCTUnwrap(UIApplication.shared.delegate as? AppDelegate)
        let window = try XCTUnwrap(app.window)
        let scene = try XCTUnwrap(window.windowScene)
        XCTAssertTrue(scene.delegate is SceneDelegate)
        XCTAssertTrue(window.rootViewController is HomeViewController)
        XCTAssertFalse(window.isHidden)
    }

    #if targetEnvironment(macCatalyst)
    @MainActor func testSceneDeactivationClearsControlsWithoutRefillingResources() throws {
        let app = try XCTUnwrap(UIApplication.shared.delegate as? AppDelegate)
        let windowScene = try XCTUnwrap(app.window?.windowScene)
        let delegate = try XCTUnwrap(windowScene.delegate as? SceneDelegate)
        let previousScene = Player.currentScene
        let previousHealth = Player.currentHealth
        let previousShield = Player.currentShield
        defer {
            Player.currentScene = previousScene
            Player.currentHealth = previousHealth
            Player.currentShield = previousShield
        }
        let game = GameScene(size: GameScene.arenaSize)
        Player.currentScene = game
        Player.currentHealth = 30
        Player.currentShield = 5
        game.keyboardControls.press(.d)
        game.keyboardControls.press(.right)
        XCTAssertTrue(game.keyboardControls.isMoving)
        XCTAssertTrue(game.keyboardControls.isShooting)
        delegate.sceneWillResignActive(windowScene)
        XCTAssertFalse(game.keyboardControls.isMoving)
        XCTAssertFalse(game.keyboardControls.isShooting)
        XCTAssertEqual(Player.currentHealth, 30)
        XCTAssertEqual(Player.currentShield, 5)
    }
    #endif

    func testArenaBackgroundsFollowLevelAcrossWorldsAndRoomReentry() throws {
        var seen = Set<ObjectIdentifier>()
        let ranges: [(ClosedRange<Int>, String)] = [
            (1...5, "StyleReactorArena"), (6...10, "StyleCargoArena"),
            (11...15, "StyleBioArena"), (16...20, "StyleFungalArena"),
            (21...25, "StyleCoralArena"), (26...30, "StyleClockworkArena"),
            (31...35, "StyleStormArena"), (36...40, "StyleOrbitalArena"),
            (41...45, "StyleHiveArena"), (46...50, "StyleForgeArena")
        ]
        for globalLevel in 1...50 {
            let expectedAsset = try XCTUnwrap(ranges.first { $0.0.contains(globalLevel) }?.1)
            let expectedTexture = GameArt.texture(expectedAsset)
            let floor = FloorViewController(min: 4, max: 5,
                level: (globalLevel - 1) % 10 + 1, world: (globalLevel - 1) / 10 + 1)
            let first = RoomScene(size: GameScene.arenaSize)
            first.viewController = floor
            first.createGrid()
            let background = try XCTUnwrap(first.children.first { $0.zPosition == -25 } as? SKSpriteNode)
            let texture = try XCTUnwrap(background.texture)
            XCTAssertTrue(texture === expectedTexture, "Background for global level \(globalLevel)")
            XCTAssertEqual(first.arenaGlobalLevel, globalLevel)
            seen.insert(ObjectIdentifier(texture))
            XCTAssertEqual(background.size, GameScene.arenaSize)
            XCTAssertNotNil(first.physicsBody)
            let image = try XCTUnwrap(GameArt.image(expectedAsset))
            XCTAssertEqual(image.size.width, 750, accuracy: 0.01)
            XCTAssertEqual(image.size.height, 375, accuracy: 0.01)
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(image.cgImage).width, 1700)
            let nextRoom = RoomScene(size: GameScene.arenaSize)
            nextRoom.viewController = floor
            nextRoom.createGrid()
            let nextBackground = try XCTUnwrap(nextRoom.children.first { $0.zPosition == -25 } as? SKSpriteNode)
            XCTAssertTrue(nextBackground.texture === texture, "The floor keeps its theme across rooms")
            first.removeAllChildren()
            first.createGrid()
            XCTAssertTrue((first.children.first { $0.zPosition == -25 } as? SKSpriteNode)?.texture === texture)
        }
        XCTAssertEqual(seen.count, 10, "All ten backgrounds must appear across the fifty levels")
        XCTAssertEqual(GameArt.arena(forGlobalLevel: 50).title, "Molten Forge")
        XCTAssertEqual(HomeScene(size: GameScene.arenaSize).arenaGlobalLevel, 1)
    }

    func testTenArenaBackgroundsWithGameplayOverlay() throws {
        let oldController = Player.currentViewController
        let oldScene = Player.currentScene
        let oldEntity = Player.entity
        defer {
            Player.currentViewController = oldController
            Player.currentScene = oldScene
            Player.entity = oldEntity
        }
        var captures = [UIImage]()
        let view = SKView(frame: CGRect(origin: .zero, size: GameScene.arenaSize))
        for globalLevel in stride(from: 1, through: 46, by: 5) {
            let controller = FloorViewController(min: 4, max: 5,
                level: (globalLevel - 1) % 10 + 1, world: (globalLevel - 1) / 10 + 1)
            Player.currentViewController = controller
            let scene = RoomScene(size: GameScene.arenaSize)
            scene.viewController = controller
            scene.name = "startRoom"
            scene.startPosition = CGPoint(x: 375, y: 187.5)
            scene.doors = [DoorEntity(scene: scene, direction: 0, type: "challenge"),
                           DoorEntity(scene: scene, direction: 3, type: "challenge")]
            view.presentScene(scene)
            scene.isPaused = true
            // Fixed samples make contrast comparable across all ten backgrounds.
            for (index, name) in GameArt.enemies.enumerated() {
                let sprite = GameArt.sprite(name)
                sprite.size = CGSize(width: 32, height: 32)
                sprite.position = CGPoint(x: 135 + CGFloat(index % 5) * 115,
                                          y: index < 5 ? 265 : 110)
                scene.addChild(sprite)
            }
            let capture = UIImage(cgImage: try XCTUnwrap(view.texture(from: scene,
                crop: CGRect(origin: .zero, size: scene.size))).cgImage())
            captures.append(capture)
            if globalLevel == 6 || globalLevel == 46 {
                let attachment = XCTAttachment(image: capture)
                attachment.name = "Arena-\(globalLevel)-\(GameArt.arena(forGlobalLevel: globalLevel).title)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            view.presentScene(nil)
        }
        let gallery = GameArt.render(CGSize(width: 1500, height: 2075), scale: 1) { rect in
            GameArt.ink.setFill(); UIRectFill(rect)
            for (index, capture) in captures.enumerated() {
                let x = CGFloat(index % 2) * 750, y = CGFloat(index / 2) * 415
                let firstLevel = index * 5 + 1
                let title = "\(firstLevel)–\(firstLevel + 4). \(GameArt.arena(forGlobalLevel: firstLevel).title)"
                (title as NSString).draw(at: CGPoint(x: x + 12, y: y + 9), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: GameArt.ivory])
                capture.draw(in: CGRect(x: x, y: y + 40, width: 750, height: 375))
            }
        }
        let attachment = XCTAttachment(image: gallery)
        attachment.name = "Ten-arenas-with-gameplay-overlay"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testRestorableGameplayMotionKeepsPositionPauseAndRemainingLifetime() throws {
        let original = RestorableMotionTestScene(size: GameScene.arenaSize)
        let node = SKNode()
        node.position = CGPoint(x: 20, y: 100)
        original.addChild(node)
        original.moveGameplayNode(node, to: CGPoint(x: 220, y: 100), duration: 2, linger: 0.05)
        original.advanceGameplayMotions(seconds: 0.7)
        let state = try XCTUnwrap(original.gameplayMotionSnapshot.first)
        XCTAssertEqual(node.position.x, 90, accuracy: 0.001)
        let saved = try JSONDecoder().decode(DelveMotionState.self, from: JSONEncoder().encode(state))
        let resumed = RestorableMotionTestScene(size: GameScene.arenaSize)
        let restoredNode = SKNode()
        resumed.addChild(restoredNode)
        try resumed.restoreGameplayMotion(saved, on: restoredNode)
        resumed.isPaused = true
        resumed.advanceGameplayMotions(seconds: 10000)
        XCTAssertEqual(resumed.gameplayMotionSnapshot, [saved])
        resumed.isPaused = false
        resumed.advanceGameplayMotions(seconds: 0.4)
        XCTAssertEqual(restoredNode.position.x, 130, accuracy: 0.001)
        resumed.advanceGameplayMotions(seconds: 0.9)
        XCTAssertEqual(restoredNode.position.x, 220, accuracy: 0.001)
        XCTAssertNotNil(restoredNode.parent)
        resumed.advanceGameplayMotions(seconds: 0.05)
        XCTAssertNil(restoredNode.parent)
        XCTAssertTrue(resumed.gameplayMotionSnapshot.isEmpty)
    }

    @MainActor func testRemovedProjectileMotionsCannotKeepNodesOrEmptyWrappersAlive() throws {
        let scene = RestorableMotionTestScene(size: GameScene.arenaSize)
        let wrapper = ShotNode()
        let sprite = SKSpriteNode()
        scene.addChild(wrapper)
        wrapper.addChild(sprite)
        scene.moveGameplayNode(sprite, to: CGPoint(x: 200, y: 100), duration: 1)
        XCTAssertEqual(scene.liveMotions.count, 1)
        sprite.removeFromParent()
        scene.advanceGameplayMotions(seconds: 0.01)
        XCTAssertEqual(scene.liveMotions.count, 0)
        XCTAssertNil(wrapper.parent)
    }

    @MainActor func testRetiringCombatRoomsReleasesActorsAndComponents() throws {
        let kinds = ["Range", "Melee", "Suicide", "Dash", "RangeTracking", "RangeTripple", "Sludge", "Bomber", "RangeRing", "DragonFireball"]
        let bosses = [("dragon", "dragonBoss"), ("generator", "generatorBoss"), ("golem", "golemBoss")]
        for (index, kind) in kinds.enumerated() {
        weak var retiredRoom: RoomScene?
        weak var retiredEnemy: EnemyEntity?
        weak var retiredBoss: BossEntity?
        autoreleasepool {
            let controller = FloorViewController(min: 4, max: 5, level: 1, world: 1)
            let room = RoomScene(size: GameScene.arenaSize)
            room.viewController = controller
            room.doors = [DoorEntity(scene: room, direction: 1, type: "challenge")]
            let enemy = EnemyEntity(scene: room, eType: kind, lev: 1, elite: false,
                                     position: CGPoint(x: 100, y: 100))
            let bossType = bosses[index % bosses.count]
            let boss = BossEntity(scene: room, properties: ["name": bossType.0, "image": bossType.1, "size": 100, "position": "center"])
            room.entites = [enemy, boss]
            retiredRoom = room
            retiredEnemy = enemy
            retiredBoss = boss
            room.willMove(from: SKView())
        }
        XCTAssertNil(retiredEnemy, "Enemy owner/component cycles must be released")
        XCTAssertNil(retiredBoss, "Boss callbacks cannot retain the retired room")
        XCTAssertNil(retiredRoom, "Completed rooms must not accumulate across floors")
        }
    }

    @MainActor func testDeadBomberReleasesItsCancelledFuseCallbacks() {
        weak var removedComponent: EnemyBombDroppingComponent?
        autoreleasepool {
            let controller = FloorViewController(min: 4, max: 5, level: 1, world: 1)
            let room = RoomScene(size: GameScene.arenaSize)
            room.viewController = controller
            let enemy = EnemyEntity(scene: room, eType: "Bomber", lev: 1, elite: false,
                                     position: CGPoint(x: 100, y: 100))
            room.entites = [enemy]
            let bomber = enemy.component(ofType: EnemyBombDroppingComponent.self)!
            removedComponent = bomber
            bomber.drop()
            enemy.damageEnemy(enemy.health)
            room.willMove(from: SKView())
        }
        XCTAssertNil(removedComponent, "Cancelled fuses cannot retain their component through an orphan bomb")
    }

    @MainActor func testLiveBomberFuseStillFiresAllFourExplosions() throws {
        let applicationWindow = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let window = UIWindow(windowScene: try XCTUnwrap(applicationWindow.windowScene))
        window.frame = CGRect(origin: .zero, size: GameScene.arenaSize)
        let controller = UIViewController()
        window.rootViewController = controller
        let view = SKView(frame: window.bounds)
        controller.view.addSubview(view)
        window.makeKeyAndVisible()
        let scene = GameScene(size: GameScene.arenaSize)
        view.presentScene(scene)
        let enemy = EnemyEntity()
        enemy.sprite.position = CGPoint(x: 100, y: 100)
        let bomber = BombCallbackTestComponent(scene: scene, entity: enemy)
        defer {
            bomber.nodes.forEach { $0.removeAllActions(); $0.parent?.removeFromParent() }
            view.presentScene(nil)
            window.isHidden = true
            applicationWindow.makeKeyAndVisible()
        }
        bomber.drop()
        let finished = expectation(description: "All four fuse effects execute")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) { finished.fulfill() }
        wait(for: [finished], timeout: 7)
        XCTAssertEqual(bomber.explosions, Array(repeating: CGPoint(x: 100, y: 100), count: 4))
    }

    @MainActor func testLiveEnemyWorldRoundTripPreservesAllVariantsAndBombRemainder() throws {
        let previousScene = Player.currentScene, previousEntity = Player.entity
        let previousController = Player.currentViewController
        defer { Player.currentScene = previousScene; Player.entity = previousEntity; Player.currentViewController = previousController }
        for kind in DelveEnemyKind.allCases {
            let (plan, catalog) = combatBridgeFixture(enemy: kind)
            let controller = try FloorViewController(plan: plan, restorableCombat: true)
            controller.buildMaze()
            let room = try XCTUnwrap(controller.room(at: CGPoint(x: 1, y: 0)))
            controller.scene = room; Player.currentViewController = controller
            room.startPosition = CGPoint(x: 120, y: 170)
            room.addPlayer()
            room.time = 100; room.started = true
            guard case .combat(let spawns) = room.plannedRoom?.encounter else { throw DelveError.invalidTransition }
            let enemy = EnemyEntity(scene: room, eType: kind.gameType, lev: kind.isElite ? 5 : 1, elite: kind.isElite,
                                    position: CGPoint(x: 470, y: 210), spawnID: spawns[0].id, stats: catalog.enemies[kind])
            room.entites = [enemy]
            enemy.currentHealth *= 0.55
            enemy.act(100)
            room.advanceGameplayMotions(seconds: 0.3)
            if kind == .bomber { room.advanceBombFuses(seconds: 4.4) }
            let metrics = try DelveCombatMetrics(targetSeconds: 60, entryCapacity: 300)
            let state = try DelveWorldBridge.capture(room: room, floorID: UUID(), completed: [plan.rooms[0].id], stats: catalog, metrics: metrics)
            try state.validate(plan: plan)
            let decoded = try JSONDecoder().decode(DelveWorldState.self, from: JSONEncoder().encode(state))
            let restored = try restoreBridgeFixture(decoded, plan: plan)
            defer { room.willMove(from: SKView()); restored.willMove(from: SKView()) }
            let recaptured = try DelveWorldBridge.capture(room: restored, floorID: state.floorID,
                completed: state.completedRoomIDs, stats: catalog, metrics: metrics)
            XCTAssertEqual(recaptured, state, "Variant \(kind)")
            var originalRandom = state.random
            XCTAssertEqual(restored.combatRandom.next(), originalRandom.next())
            restored.combatRandom = state.random
            XCTAssertTrue(restored.isPaused)
            restored.advanceBombFuses(seconds: 100)
            XCTAssertEqual(restored.liveFuses.count, state.fuses.count)
            if kind == .bomber {
                XCTAssertEqual(state.fuses[0].events.nextIndex, 2)
                restored.isPaused = false
                let originalClock = restored.time
                restored.update(9000)
                XCTAssertEqual(restored.time, originalClock, "Wall time must not advance a just-resumed simulation")
                let before = restored.children.compactMap { $0 as? ShotNode }.filter { $0.rangeDamage > 0 }.count
                restored.advanceBombFuses(seconds: 0.3)
                XCTAssertEqual(restored.liveFuses.values.first?.state.events.nextIndex, 3)
                let after = restored.children.compactMap { $0 as? ShotNode }.filter { $0.rangeDamage > 0 }.count
                XCTAssertEqual(after - before, 1, "Only the next burst may fire, with saved damage")
                restored.advanceBombFuses(seconds: 0.4)
                XCTAssertTrue(restored.liveFuses.isEmpty)
            }
        }
    }

    @MainActor func testLiveBossWorldRoundTripPreservesEveryAttackPhaseAndProjectileDamage() throws {
        let previousScene = Player.currentScene, previousEntity = Player.entity
        let previousController = Player.currentViewController
        defer { Player.currentScene = previousScene; Player.entity = previousEntity; Player.currentViewController = previousController }
        let phases: [(DelveBossKind, String)] = [(.dragon, "breathe"), (.dragon, "fireball"),
            (.generator, "spray"), (.generator, "electric"), (.golem, "drop"), (.golem, "rocks")]
        for (kind, attack, elapsed) in phases.flatMap({ phase in [0.4, 2.4, 4.4].map { (phase.0, phase.1, $0) } }) {
            let (plan, catalog) = combatBridgeFixture(boss: kind)
            let controller = try FloorViewController(plan: plan, restorableCombat: true)
            controller.buildMaze()
            let room = try XCTUnwrap(controller.room(at: CGPoint(x: 2, y: 0)))
            controller.scene = room; Player.currentViewController = controller
            room.startPosition = CGPoint(x: 450, y: 180); room.addPlayer()
            room.time = 100; room.started = true; room.combatStats = catalog
            let image = kind == .dragon ? "dragonBoss" : (kind == .generator ? "generatorBoss" : "golemBoss")
            let boss = BossEntity(scene: room, properties: ["name": kind.rawValue, "image": image, "size": 100, "position": "center"],
                                  stats: catalog.bosses[kind], combatID: plan.rooms.last!.id)
            room.entites = [boss]; boss.currentHealth *= 0.6
            boss.firstAttack = false; boss.lastShot = 100
            boss.attack = try XCTUnwrap(boss.actions.first { DelveBehaviourBridge.capture($0)?.key == attack })
            boss.attack.action(100)
            for step in stride(from: 0.2, through: elapsed, by: 0.2) { boss.attack.action(100 + step) }
            for action in boss.constantActions { action.action(100 + elapsed) }
            if kind != .golem, !room.liveMotions.values.contains(where: { $0.state.movement.duration == 4 }) {
                boss.component(ofType: BossShotTargetingComponent.self)?.fire()
            }
            room.time = 100 + elapsed
            room.advanceGameplayMotions(seconds: 0.2)
            let metrics = try DelveCombatMetrics(targetSeconds: 80, entryCapacity: 300)
            let state = try DelveWorldBridge.capture(room: room, floorID: UUID(), completed: Set(plan.rooms.dropLast().map(\.id)), stats: catalog, metrics: metrics)
            try state.validate(plan: plan)
            let decoded = try JSONDecoder().decode(DelveWorldState.self, from: JSONEncoder().encode(state))
            let restored = try restoreBridgeFixture(decoded, plan: plan)
            defer { room.willMove(from: SKView()); restored.willMove(from: SKView()) }
            let recaptured = try DelveWorldBridge.capture(room: restored, floorID: state.floorID,
                completed: state.completedRoomIDs, stats: catalog, metrics: metrics)
            XCTAssertEqual(recaptured, state, "Phase \(kind)/\(attack) at \(elapsed)s")
            let restoredBoss = try XCTUnwrap(restored.entites.first as? BossEntity)
            XCTAssertEqual(restoredBoss.currentHealth, 600)
            XCTAssertEqual(DelveBehaviourBridge.capture(restoredBoss.attack)?.key, attack)
            for saved in state.containers where saved.rangeDamage > 0 || saved.effectDamage > 0 {
                let node = try XCTUnwrap(restored.children.compactMap { $0 as? ShotNode }.first { DelveSpriteBridge.id($0) == saved.id })
                XCTAssertNil(node.bossShooter, "In-flight damage cannot require a living original boss")
                XCTAssertEqual(node.rangeDamage, saved.rangeDamage)
                XCTAssertEqual(node.effectDamage, saved.effectDamage)
                XCTAssertEqual(node.removesContainerOnHit, saved.removesContainerOnHit)
            }
            if kind != .golem {
                let savedShot = try XCTUnwrap(state.sprites.first { $0.movement?.movement.duration == 4 }, "Missing basic shot for \(kind)/\(attack)/\(elapsed)")
                let managed = try XCTUnwrap(restored.liveMotions[savedShot.id])
                let projectile = try XCTUnwrap(managed.node)
                restored.isPaused = false
                restored.advanceGameplayMotions(seconds: 0.1)
                XCTAssertNotEqual(projectile.position, DelveSpriteBridge.cgPoint(savedShot.pose.position), "Basic boss shots must continue moving after reload")
                XCTAssertEqual(managed.state.movement.elapsed, savedShot.movement!.movement.elapsed + 0.1, accuracy: 1e-10)
                // Expiry is checked after attack-phase continuation below.
            }
            restored.isPaused = false
            restored.time = state.clock + 0.25
            restoredBoss.attack.action(restored.time)
            if attack == "fireball" {
                XCTAssertEqual(restored.entites.filter { ($0 as? EnemyEntity)?.type == "DragonFireball" }.count, 1)
                restoredBoss.attack.action(restored.time + 0.15)
                XCTAssertEqual(restored.entites.filter { ($0 as? EnemyEntity)?.type == "DragonFireball" }.count, 1)
            }
            if kind != .golem {
                let id = try XCTUnwrap(state.sprites.first { $0.movement?.movement.duration == 4 }, "Missing basic shot for \(kind)/\(attack)/\(elapsed)").id
                let projectile = try XCTUnwrap(restored.liveMotions[id]?.node)
                restored.advanceGameplayMotions(seconds: 4)
                XCTAssertNil(projectile.parent, "Basic boss shots must retain their remaining lifetime")
            }
        }
    }

    @MainActor func testFloorControllerResumesTheSavedRoomPausedWithoutDuplicateEnemiesOrRecovery() throws {
        let previousScene = Player.currentScene, previousEntity = Player.entity
        let previousController = Player.currentViewController
        let previousHealth = Player.currentHealth, previousShield = Player.currentShield
        let (plan, catalog) = combatBridgeFixture(enemy: .range)
        let originalController = try FloorViewController(plan: plan, restorableCombat: true)
        originalController.buildMaze()
        let original = try XCTUnwrap(originalController.room(at: CGPoint(x: 1, y: 0)))
        originalController.scene = original; Player.currentViewController = originalController
        original.startPosition = CGPoint(x: 120, y: 170); original.addPlayer()
        original.combatStats = catalog; original.addEnemies()
        (original.entites[0] as? EnemyEntity)?.currentHealth = 550
        original.time = 57; original.started = true
        let metrics = try DelveCombatMetrics(targetSeconds: 60, entryCapacity: 300)
        let saved = try DelveWorldBridge.capture(room: original, floorID: UUID(), completed: [plan.rooms[0].id], stats: catalog, metrics: metrics)
        let resumed = try FloorViewController(plan: plan, restorableCombat: true, world: saved)
        defer {
            original.willMove(from: SKView()); resumed.skView.presentScene(nil)
            Player.currentScene = previousScene; Player.entity = previousEntity; Player.currentViewController = previousController
            Player.currentHealth = previousHealth; Player.currentShield = previousShield
        }
        Player.currentHealth = 61.25; Player.currentShield = 12.5
        resumed.loadViewIfNeeded()
        resumed.startNewRun()
        let room = try XCTUnwrap(resumed.scene)
        XCTAssertNil(room.restoreError)
        XCTAssertEqual(room.plannedRoom?.id, saved.currentRoomID)
        XCTAssertEqual(room.entites.count, 1)
        XCTAssertEqual((room.entites[0] as? EnemyEntity)?.currentHealth, 550)
        XCTAssertEqual(room.time, 57)
        XCTAssertTrue(room.isPaused)
        XCTAssertEqual(Player.currentHealth, 61.25)
        XCTAssertEqual(Player.currentShield, 12.5)
        XCTAssertEqual(room.gameplayMotionSnapshot.count, saved.sprites.compactMap(\.movement).count)
        XCTAssertThrowsError(try DelveWorldBridge.restore(saved, plan: plan, room: room), "Restoring onto living actors must be rejected")
    }

    @MainActor func testDecodedOverduePartialRockAttackCleansUpWithoutIndexingMissingSprites() throws {
        let previousScene = Player.currentScene, previousEntity = Player.entity
        let previousController = Player.currentViewController
        let (plan, catalog) = combatBridgeFixture(boss: .golem)
        let controller = try FloorViewController(plan: plan, restorableCombat: true)
        controller.buildMaze()
        let room = try XCTUnwrap(controller.room(at: CGPoint(x: 2, y: 0)))
        controller.scene = room; Player.currentViewController = controller
        room.startPosition = CGPoint(x: 450, y: 180); room.addPlayer()
        room.combatStats = catalog; room.addBoss()
        let boss = try XCTUnwrap(room.entites[0] as? BossEntity)
        boss.firstAttack = false
        boss.attack = try XCTUnwrap(boss.component(ofType: BossGolemRockShoot.self))
        boss.attack.action(100)
        room.time = 106; room.started = true
        let metrics = try DelveCombatMetrics(targetSeconds: 80, entryCapacity: 300)
        let state = try DelveWorldBridge.capture(room: room, floorID: UUID(), completed: Set(plan.rooms.dropLast().map(\.id)), stats: catalog, metrics: metrics)
        let decoded = try JSONDecoder().decode(DelveWorldState.self, from: JSONEncoder().encode(state))
        let restored = try restoreBridgeFixture(decoded, plan: plan)
        defer {
            room.willMove(from: SKView()); restored.willMove(from: SKView())
            Player.currentScene = previousScene; Player.entity = previousEntity; Player.currentViewController = previousController
        }
        let resumedBoss = try XCTUnwrap(restored.entites[0] as? BossEntity)
        let rocks = try XCTUnwrap(resumedBoss.component(ofType: BossGolemRockShoot.self))
        XCTAssertEqual(rocks.shots, 0)
        XCTAssertTrue(rocks.sprites.isEmpty)
        restored.isPaused = false
        rocks.action(restored.time)
        XCTAssertFalse(rocks.acting)
        XCTAssertTrue(rocks.sprites.isEmpty)
        XCTAssertTrue(rocks.angle.isEmpty)
    }

    @MainActor func testPreviouslyClearedRoomsRemainUnlockedWhenReenteredAfterReload() throws {
        let previousScene = Player.currentScene, previousEntity = Player.entity
        let previousController = Player.currentViewController
        let (plan, catalog) = combatBridgeFixture(boss: .generator)
        let originalController = try FloorViewController(plan: plan, restorableCombat: true)
        originalController.buildMaze()
        let original = try XCTUnwrap(originalController.room(at: CGPoint(x: 2, y: 0)))
        originalController.scene = original; Player.currentViewController = originalController
        original.startPosition = CGPoint(x: 120, y: 170); original.addPlayer()
        original.combatStats = catalog; original.addBoss()
        let metrics = try DelveCombatMetrics(targetSeconds: 80, entryCapacity: 300)
        let state = try DelveWorldBridge.capture(room: original, floorID: UUID(), completed: Set(plan.rooms.dropLast().map(\.id)), stats: catalog, metrics: metrics)
        let resumed = try FloorViewController(plan: plan, restorableCombat: true, world: state)
        defer {
            original.willMove(from: SKView()); resumed.skView.presentScene(nil)
            Player.currentScene = previousScene; Player.entity = previousEntity; Player.currentViewController = previousController
        }
        resumed.loadViewIfNeeded(); resumed.startNewRun()
        let cleared = try XCTUnwrap(resumed.room(at: CGPoint(x: 1, y: 0)))
        resumed.scene.children.compactMap { $0 as? PopUpNode }.first?.play(nil)
        resumed.scene = cleared
        resumed.skView.presentScene(cleared)
        XCTAssertTrue(cleared.completed)
        XCTAssertTrue(cleared.entites.isEmpty)
        XCTAssertEqual(cleared.doors.count, 2)
        XCTAssertTrue(cleared.doors.allSatisfy { $0.sprite.physicsBody?.categoryBitMask == Constants.doorCategory }, "Both doors must remain traversable without another enemy kill")
        XCTAssertTrue(cleared.doors.allSatisfy { $0.type == "completed" || $0.type == "bossCompleted" })
    }

    private func combatBridgeFixture(enemy: DelveEnemyKind = .range, boss: DelveBossKind = .dragon) -> (DelveFloorPlan, DelveFloorCombatStats) {
        let spawn = DelveEnemySpawn(id: UUID(), kind: enemy, position: DelveSpawnPoint(x: 0.65, y: 0.6))
        let plan = DelveFloorPlan(difficulty: 101, budget: enemy.points, groupingMultiplier: 0.25, density: .sparse,
            rooms: [DelveRoomPlan(id: UUID(), position: DelveRoomPosition(x: 0, y: 0), encounter: .start),
                    DelveRoomPlan(id: UUID(), position: DelveRoomPosition(x: 1, y: 0), encounter: .combat([spawn])),
                    DelveRoomPlan(id: UUID(), position: DelveRoomPosition(x: 2, y: 0), encounter: .boss(boss))])
        let stats = DelveEnemyStats(health: 1000, rangeAttackPower: 30.75, meleeAttackPower: 12.25, effectAttackPower: 0)
        let bossStats = DelveEnemyStats(health: 1000, rangeAttackPower: 45.75, meleeAttackPower: 22.25, effectAttackPower: 10.5)
        return (plan, DelveFloorCombatStats(enemies: Dictionary(uniqueKeysWithValues: DelveEnemyKind.allCases.map { ($0, stats) }),
            bosses: Dictionary(uniqueKeysWithValues: DelveBossKind.allCases.map { ($0, bossStats) }), fireball: stats))
    }

    private func restoreBridgeFixture(_ state: DelveWorldState, plan: DelveFloorPlan) throws -> RoomScene {
        let controller = try FloorViewController(plan: plan, restorableCombat: true)
        controller.buildMaze()
        let position = try XCTUnwrap(plan.rooms.first { $0.id == state.currentRoomID }).position
        let room = try XCTUnwrap(controller.room(at: CGPoint(x: position.x, y: position.y)))
        // The production controller owns its rooms. Keep that owner alive for this isolated fixture.
        Player.currentViewController = controller; controller.scene = room
        room.startPosition = CGPoint(x: 120, y: 170); room.addPlayer()
        try DelveWorldBridge.restore(state, plan: plan, room: room)
        return room
    }

    func testRenderedArtPreservesFractionalRetinaLogicalSizes() {
        for size in [CGSize(width: 333.5, height: 333.5), CGSize(width: 100.0 / 3, height: 20.5), CGSize(width: 32, height: 32)] {
            let image = GameArt.render(size) { rect in UIColor.white.setFill(); UIRectFill(rect) }
            XCTAssertEqual(image.size.width, size.width, accuracy: 1e-9)
            XCTAssertEqual(image.size.height, size.height, accuracy: 1e-9)
        }
    }

    func testStyleCatalogPreservesLogicalSizesAndHasTransparentSprites() throws {
        let animationNames = (1...4).map { "dragonMouth\($0)" } + (0...8).map { "golemJump\($0)" }
        let names = GameArt.enemies + GameArt.items + GameArt.bosses + ["playerIcon", "playerCannon"] + animationNames
        for name in names {
            let image = try XCTUnwrap(GameArt.image(name), name)
            XCTAssertEqual(image.size, try XCTUnwrap(UIImage(named: name)).size, name)
            XCTAssertTrue(GameArt.texture(name) === GameArt.texture(name), "Textures should be cached")
        }
        for name in animationNames {
            XCTAssertNotEqual(GameArt.image(name)?.pngData(), UIImage(named: name)?.pngData(),
                              "Animation frames must not fall back to the old artwork: \(name)")
        }
        for name in ["StyleGun", "StyleEnemies", "StyleBosses"] + GameArt.items.map({ "Style" + $0.replacingOccurrences(of: " ", with: "") }) {
            let cg = try XCTUnwrap(UIImage(named: name)?.cgImage)
            XCTAssertNotEqual(cg.alphaInfo, .none, name)
            XCTAssertNotEqual(cg.alphaInfo, .noneSkipLast, name)
        }
    }

    func testEnemyDamagePreservesSilhouetteAndReadableFace() throws {
        let atlas = try XCTUnwrap(UIImage(named: "StyleDamageFine")?.cgImage)
        XCTAssertEqual(atlas.width, atlas.height * 3, "Each approved tier occupies one square cell")
        var previousCoverage = 0
        for (column, name) in ["damaged75", "damaged50", "damaged25"].enumerated() {
            let image = try XCTUnwrap(GameArt.image(name))
            let original = try XCTUnwrap(UIImage(named: name))
            XCTAssertEqual(image.size, original.size)
            XCTAssertNotEqual(image.pngData(), original.pngData())
            let cg = try XCTUnwrap(image.cgImage)
            // Match the approved option A cell, including its intentional transparent margins.
            // Trimming or recentering would shift the cracks over the enemy's symbol.
            let crop = try XCTUnwrap(atlas.cropping(to: CGRect(x: column * atlas.height, y: 0,
                                                               width: atlas.height, height: atlas.height)))
            let expected = GameArt.render(image.size, scale: image.scale) { UIImage(cgImage: crop).draw(in: $0) }
            XCTAssertEqual(image.pngData(), expected.pngData(), "Use the approved tier without shifting its layout")
            let pixels = rgbaPixels(cg)
            let coverage = stride(from: 3, to: pixels.count, by: 4).filter { pixels[$0] > 24 }.count
            XCTAssertGreaterThan(coverage, previousCoverage, "Each tier adds visible fractures")
            XCTAssertLessThan(coverage, cg.width * cg.height / 3, "Most of the colored face must remain visible")
            previousCoverage = coverage
        }
        let scene = SKScene(size: CGSize(width: 240, height: 160))
        let host = SKView(frame: CGRect(x: 0, y: 0, width: 240, height: 160))
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        window.rootViewController?.view.addSubview(host)
        defer { host.presentScene(nil); host.removeFromSuperview() }
        host.presentScene(scene)
        let enemy = EnemyEntity()
        enemy.node.entity = enemy
        enemy.health = 100
        enemy.currentHealth = 100
        enemy.sprite = GameArt.sprite("meleeEnemy")
        enemy.sprite.position = CGPoint(x: 120, y: 80)
        enemy.sprite.addChild(enemy.statusNode)
        scene.addChild(enemy.sprite)
        let size = enemy.sprite.size
        for name in ["damaged75", "damaged50", "damaged25"] {
            enemy.damageEnemy(25)
            XCTAssertTrue(enemy.statusNode.texture === GameArt.texture(name))
            XCTAssertEqual(enemy.sprite.size, size)
            XCTAssertEqual(enemy.statusNode.size, size)
            XCTAssertNotNil(enemy.sprite.action(forKey: "damageFlash"))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertNil(enemy.sprite.action(forKey: "damageFlash"), "Repeated hits must not leave a permanent tint")
        XCTAssertEqual(enemy.sprite.colorBlendFactor, 0, accuracy: 0.001)
        XCTAssertEqual(enemy.currentHealth, 25)
    }

    func testDragonTrackingFireballUsesRoundDamageThroughDestruction() throws {
        let floor = FloorViewController(min: 4, max: 5, level: 10, world: 1)
        let room = RoomScene(size: GameScene.arenaSize)
        room.viewController = floor
        room.doors = [DoorEntity(scene: room, direction: 1, type: "bossChallenge")]
        let fireball = EnemyEntity(scene: room, eType: "DragonFireball", lev: 1, elite: false)
        let tracking = try XCTUnwrap(fireball.component(ofType: EnemyTrackingComponent.self))
        let body = try XCTUnwrap(fireball.sprite.physicsBody)
        let size = fireball.sprite.size
        let initialPosition = fireball.sprite.position
        tracking.action(0)
        XCTAssertNotEqual(fireball.sprite.position, initialPosition, "The damaged projectile must still home toward the player")
        var previousCoverage = 0
        for remaining in [75, 50, 25] {
            let targetHealth = fireball.health * Double(remaining) / 100
            fireball.damageEnemy(fireball.currentHealth - targetHealth)
            let name = "dragonDamaged\(remaining)"
            XCTAssertEqual(fireball.currentHealth, targetHealth)
            XCTAssertTrue(fireball.statusNode.texture === GameArt.texture(name))
            XCTAssertTrue(fireball.component(ofType: EnemyTrackingComponent.self) === tracking)
            XCTAssertTrue(fireball.sprite.physicsBody === body)
            XCTAssertEqual(fireball.statusNode.size, size)
            XCTAssertEqual(fireball.sprite.size, size)
            XCTAssertTrue(fireball.sprite.texture === GameArt.texture("bossDragonFireball"))
            let image = try XCTUnwrap(GameArt.image(name))
            XCTAssertEqual(image.size, size)
            let cg = try XCTUnwrap(image.cgImage)
            let pixels = rgbaPixels(cg)
            var coverage = 0
            var interiorCoverage = 0
            for y in 0..<cg.height {
                for x in 0..<cg.width {
                    let alpha = pixels[(y * cg.width + x) * 4 + 3]
                    if alpha > 24 { coverage += 1 }
                    let dx = (Double(x) + 0.5) / Double(cg.width) - 0.5
                    let dy = (Double(y) + 0.5) / Double(cg.height) - 0.5
                    if hypot(dx, dy) < 0.2 && alpha > 24 { interiorCoverage += 1 }
                    if hypot(dx, dy) > 0.49 || (remaining != 25 && hypot(dx, dy) < 0.08) {
                        XCTAssertLessThan(alpha, 8, "Fireball damage must stay inside its round footprint")
                    }
                }
            }
            XCTAssertGreaterThan(coverage, previousCoverage)
            if remaining == 25 {
                XCTAssertGreaterThan(interiorCoverage, cg.width * cg.height / 100, "Heavy damage must fracture the fireball interior")
                XCTAssertLessThan(coverage, cg.width * cg.height / 2, "The red orb must remain visible between fissures")
            }
            previousCoverage = coverage
        }
        fireball.damageEnemy(fireball.currentHealth)
        XCTAssertNil(fireball.sprite.physicsBody)
        XCTAssertNil(fireball.component(ofType: EnemyTrackingComponent.self))
        XCTAssertNotNil(fireball.component(ofType: EnemyDyingComponent.self))
        XCTAssertEqual(room.killedEnemies, 0, "Destroying a dragon projectile must not count as clearing an enemy")
        XCTAssertEqual(floor.levelExp, 0)
    }

    func testEnemyDamageVisualGallery() throws {
        let gallery = GameArt.render(CGSize(width: 1100, height: 810), scale: 2) { rect in
            GameArt.ink.setFill(); UIRectFill(rect)
            ("ORIGINAL CRACK LAYOUTS · UPDATED ENAMEL FINISH" as NSString).draw(at: CGPoint(x: 24, y: 20), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 21), .foregroundColor: GameArt.ivory])
            ("Original and updated overlays on the same current enemy artwork. Large previews plus 32-point gameplay size." as NSString).draw(at: CGPoint(x: 24, y: 54), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13), .foregroundColor: GameArt.ivory.withAlphaComponent(0.7)])
            for (tier, title) in ["LIGHT", "MEDIUM", "HEAVY"].enumerated() {
                let x = 140 + tier * 320
                (title as NSString).draw(at: CGPoint(x: x + 90, y: 92), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 17), .foregroundColor: GameArt.ivory])
                for (column, label) in ["Original", "Updated"].enumerated() {
                    (label as NSString).draw(at: CGPoint(x: x + column * 148 + 27, y: 122), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14), .foregroundColor: column == 0 ? GameArt.ivory : GameArt.ice])
                }
            }
            let rows = [("Cracks", ""), ("Melee", "meleeEnemy"), ("Ranged", "rangeEnemy"),
                        ("Tracking", "rangeTrackingEnemy"), ("Bomber", "bomberEnemy")]
            for (row, entry) in rows.enumerated() {
                let y = CGFloat(157 + row * 124)
                (entry.0 as NSString).draw(at: CGPoint(x: 24, y: y + 40), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14), .foregroundColor: GameArt.ivory])
                for (tier, stage) in ["75", "50", "25"].enumerated() {
                    for column in 0..<2 {
                        let overlay = column == 0 ? UIImage(named: "damaged" + stage) : GameArt.image("damaged" + stage)
                        for (offset, size) in [(CGFloat(0), CGFloat(96)), (CGFloat(104), CGFloat(32))] {
                            let frame = CGRect(x: CGFloat(140 + tier * 320 + column * 148) + offset,
                                               y: y + 96 - size, width: size, height: size)
                            if entry.1.isEmpty {
                                UIColor(white: 0.35, alpha: 1).setFill(); UIRectFill(frame)
                            } else {
                                GameArt.image(entry.1)?.draw(in: frame)
                            }
                            overlay?.draw(in: frame)
                        }
                    }
                }
            }
        }
        let attachment = XCTAttachment(image: gallery)
        attachment.name = "Original-cracks-and-updated-art-at-gameplay-size"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEquipmentAtlasCellsHaveRealTransparencyAndNoClippedEdges() throws {
        for family in GameArt.items {
            let sheet = "Style" + family.replacingOccurrences(of: " ", with: "")
            let image = try XCTUnwrap(UIImage(named: sheet)?.cgImage, sheet)
            let width = image.width / 3, height = image.height / 2
            for cell in 0..<6 {
                let crop = try XCTUnwrap(image.cropping(to: CGRect(x: cell % 3 * width, y: cell / 3 * height,
                                                                   width: width, height: height)))
                let pixels = rgbaPixels(crop)
                let visible = stride(from: 3, to: pixels.count, by: 4).filter { pixels[$0] > 24 }
                if cell == 5 {
                    XCTAssertTrue(visible.isEmpty, "Unused atlas cell must be empty: \(family)")
                } else {
                    XCTAssertGreaterThan(visible.count, width * height / 10, "Missing art: \(family), \(cell)")
                    XCTAssertLessThan(visible.count, width * height * 9 / 10, "Opaque background: \(family), \(cell)")
                    for index in visible {
                        let x = (index / 4) % width, y = (index / 4) / width
                        XCTAssertTrue(x > 0 && x < width - 1 && y > 0 && y < height - 1,
                                      "Art touches a crop boundary: \(family), \(cell)")
                    }
                }
            }
        }
    }

    func testEquipmentColorsSizesAndSilhouettes() throws {
        for family in GameArt.items {
            var variants = Set<Data>()
            for (color, suffix) in ["", "0", "1", "2", "3"].enumerated() {
                let name = family + suffix
                let image = try XCTUnwrap(GameArt.image(name), name)
                XCTAssertEqual(image.size, try XCTUnwrap(UIImage(named: name)).size, name)
                variants.insert(try XCTUnwrap(image.pngData()))
                let cg = try XCTUnwrap(image.cgImage)
                XCTAssertGreaterThanOrEqual(cg.width, 288, "Detail views need full-resolution art: \(name)")
                XCTAssertGreaterThanOrEqual(GameArt.texture(name).cgImage().width, 288,
                                            "SpriteKit must retain the same item resolution: \(name)")
                let pixels = rgbaPixels(cg)
                var colored = [Int](repeating: 0, count: 4)
                var opaque = 0
                var minX = cg.width, maxX = 0, minY = cg.height, maxY = 0
                for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 180 {
                    let r = Double(pixels[index]), g = Double(pixels[index + 1]), b = Double(pixels[index + 2])
                    opaque += 1
                    if g > r * 1.3 && g > b * 1.2 { colored[0] += 1 }
                    if b > r * 1.3 && b > g * 1.1 { colored[1] += 1 }
                    if r > g * 1.3 && b > g * 1.3 { colored[2] += 1 }
                    if r > g * 1.2 && g > b * 1.4 { colored[3] += 1 }
                    let x = index / 4 % cg.width, y = index / 4 / cg.width
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
                XCTAssertGreaterThan(opaque, 0, name)
                XCTAssertEqual(pixels[3], 0, "Inventory icons need transparent corners: \(name)")
                if color == 0 {
                    XCTAssertLessThan(colored.reduce(0, +), opaque / 8, "White should stay neutral: \(name)")
                } else {
                    XCTAssertGreaterThan(colored[color - 1], opaque / 8, "Variant must color the item, not just a badge: \(name)")
                    if color != 1 { XCTAssertLessThan(colored[0], opaque / 50, "Green leaked into \(name)") }
                }
                let aspect = Double(maxX - minX + 1) / Double(maxY - minY + 1)
                if family.contains("Pulsar") { XCTAssertGreaterThan(aspect, 1.2, "Do not squash guns into squares") }
                if family == "Power Core" { XCTAssertEqual(aspect, 1, accuracy: 0.08, "Core must remain circular") }
            }
            XCTAssertEqual(variants.count, 5, "Five distinct colorways required for \(family)")
        }
    }

    func testRewardAndInventoryUseTheSameSavedEquipmentAppearance() throws {
        for family in GameArt.items {
            for tier in 1...4 {
                for variant in 0...3 {
                    let equipment = Equipment(t: family, lev: 3, tie: tier, st: "", v: variant)
                    let restored = Equipment(dic: equipment.toDictionary())
                    let expectedName = tier == 1 ? family : family + String(variant)
                    let node = ItemNode(i: restored)
                    XCTAssertTrue(node.texture === GameArt.texture(expectedName))
                    XCTAssertEqual(node.size, CGSize(width: 32, height: 32))
                    let controller = CompletedViewController()
                    controller.drops = [restored]
                    controller.loadViewIfNeeded()
                    let scroll = try XCTUnwrap(completionView(controller.view, id: "completion.rewards") as? UIScrollView)
                    let stack = try XCTUnwrap(scroll.subviews.compactMap { $0 as? UIStackView }.first)
                    let row = try XCTUnwrap(stack.arrangedSubviews.last as? UIStackView)
                    let reward = try XCTUnwrap((row.arrangedSubviews.first as? UIImageView)?.image)
                    XCTAssertEqual(reward.pngData(), GameArt.image(expectedName)?.pngData(), expectedName)
                }
            }
        }
        XCTAssertEqual(GameArt.imageName(for: Item(t: "Cubrixel")), "Cubrixel")
    }

    func testEquipmentCatalogVisualGallery() throws {
        let gallery = GameArt.render(CGSize(width: 820, height: 790)) { rect in
            GameArt.ink.setFill(); UIRectFill(rect)
            for (column, color) in ["White", "Green", "Blue", "Purple", "Orange"].enumerated() {
                (color as NSString).draw(at: CGPoint(x: 160 + column * 130, y: 8), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.white])
            }
            for (row, family) in GameArt.items.enumerated() {
                (family as NSString).draw(at: CGPoint(x: 8, y: 80 + row * 125), withAttributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
                for (column, suffix) in ["", "0", "1", "2", "3"].enumerated() {
                    let image = GameArt.image(family + suffix)
                    image?.draw(in: CGRect(x: 150 + column * 130, y: 35 + row * 125, width: 88, height: 88))
                    image?.draw(in: CGRect(x: 242 + column * 130, y: 90 + row * 125, width: 32, height: 32))
                }
            }
        }
        let attachment = XCTAttachment(image: gallery)
        attachment.name = "Equipment-all-30-large-and-32pt"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEquipmentShopAndBankPreviews() throws {
        let inventory = Player.inventory
        let merchant = Constants.merchantInventory
        defer { Player.inventory = inventory; Constants.merchantInventory = merchant }
        let samples = GameArt.items.flatMap { family in
            (0..<5).map { Equipment(t: family, lev: 3, tie: $0 == 0 ? 1 : 2, st: "", v: max(0, $0 - 1)) }
        }
        Player.inventory = samples
        Constants.merchantInventory = Array(samples.prefix(15))
        let scene = GameScene(size: GameScene.arenaSize)
        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let bank = BankPopUpNode(scene: scene)
        let shop = ShopPopUpNode(scene: scene)
        for node in [bank as SKNode, shop as SKNode] {
            scene.addChild(node)
            let texture = try XCTUnwrap(view.texture(from: node))
            let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
            attachment.name = node === bank ? "Equipment-bank" : "Equipment-shop"
            attachment.lifetime = .keepAlways
            add(attachment)
            node.removeFromParent()
        }
        XCTAssertEqual(bank.pageItems.count, 30)
        XCTAssertEqual(shop.pageItems.count, 30)
    }

    func testRemainingAssetAuditGalleries() throws {
        let projectiles = ["playerShot", "enemyShot", "enemyTrackingShot", "enemyTrippleShot", "enemyRingShot",
                           "enemySludge", "bomberShot", "bombLit1", "bombLit2", "bombLit3", "bossGeneratorShot",
                           "bossEnergyShot", "bossGolemRock", "bossDragonFireball"] + (0...3).map { "bossDragonShot\($0)" }
        let doors = ["horizontal", "vertical"].flatMap { orientation in
            ["", "Lock", "Unlock", "BossLock", "BossUnlock"].map { orientation + "Door" + $0 }
        }
        let interface = ["bank", "merchant", "Cubrixel", "noEquipment", "pauseButton", "backButton", "closeButton", "popUp",
                         "healthBarTop", "healthBarBottom", "shieldBarTop", "shieldBarBottom", "bossBarTop", "bossBarBottom", "experienceFill"] + (1...4).map { "tier\($0)" }
        let animation = (1...4).map { "dragonMouth\($0)" } + (0...8).map { "golemJump\($0)" }
        let surfaces = (1...5).flatMap { ["background\($0)", "backgroundInner\($0)", "background\($0)Cell"] } + ["lockedCell", "loadingScreen"]
        for (group, names) in [("projectiles", projectiles), ("doors-and-controls", doors + interface),
                               ("damage-and-animation", ["damaged25", "damaged50", "damaged75", "golemBlock"] + animation),
                               ("world-surfaces", surfaces)] {
            var resolved = [UIImage]()
            for name in names { resolved.append(try XCTUnwrap(GameArt.image(name), "Missing live image: \(name)")) }
            let image = GameArt.render(CGSize(width: 720, height: ((names.count + 4) / 5) * 115)) { rect in
                GameArt.ink.setFill(); UIRectFill(rect)
                for (index, name) in names.enumerated() {
                    let box = CGRect(x: 10 + index % 5 * 142, y: 10 + index / 5 * 115, width: 120, height: 82)
                    let source = resolved[index]
                    let scale = min(box.width / source.size.width, box.height / source.size.height)
                    let size = CGSize(width: source.size.width * scale, height: source.size.height * scale)
                    source.draw(in: CGRect(x: box.midX - size.width / 2, y: box.midY - size.height / 2,
                                           width: size.width, height: size.height))
                    (name as NSString).draw(at: CGPoint(x: box.minX, y: box.maxY + 3), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.white])
                }
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Audit-" + group
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    private func rgbaPixels(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = CGContext(data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8,
                                bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }

    func testStyleCatalogVisualGallery() throws {
        let names = ["playerIcon", "playerCannon"] + GameArt.enemies + GameArt.bosses + GameArt.items
        let image = GameArt.render(CGSize(width: 720, height: 320)) { rect in
            GameArt.ink.setFill(); UIRectFill(rect)
            for (index, name) in names.enumerated() {
                let box = CGRect(x: 12 + (index % 8) * 88, y: 12 + (index / 8) * 100, width: 64, height: 64)
                GameArt.image(name)?.draw(in: box)
                (name as NSString).draw(at: CGPoint(x: box.minX, y: box.maxY + 2), withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.white])
            }
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "StyleA-catalog"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testBarsKeepTheirTexturesAndLeftCapsWhileDepleting() throws {
        let scene = GameScene(size: GameScene.arenaSize)
        let bars = HealthBarComponent(scene: scene, playerNode: SKNode(), sprite: SKSpriteNode())
        let xp = ExpBarComponent(scene: scene)
        let boss = BossBarComponent(scene: scene)
        let sprites = [bars.healthCropSprite, bars.shieldCropSprite, xp.expCropSprite!, boss.healthCropSprite!]
        let sizes = sprites.map { $0.size }
        let textures = sprites.map { $0.texture }
        for fraction in [1.0, 0.75, 0.5, 0.25, 0.05, 0, -0.2, 1.2] {
            bars.updateBars(Player.shield * fraction, health: Player.health * fraction)
            xp.updateBars(Int(Double(Player.expToLevel(Player.level)) * fraction))
            // The boss removes its HUD on death, so exercise zero via the fill helper.
            updateBarFill(boss.healthCropSprite, value: fraction * 100, maximum: 100)
            for (index, sprite) in sprites.enumerated() {
                XCTAssertEqual(sprite.size, sizes[index], "Do not rescale cap or border pixels")
                XCTAssertTrue(sprite.texture === textures[index])
                XCTAssertEqual(sprite.anchorPoint, .zero)
                let crop = try XCTUnwrap(sprite.parent as? SKCropNode)
                let mask = try XCTUnwrap(crop.maskNode as? SKSpriteNode)
                XCTAssertEqual(mask.anchorPoint, .zero)
                XCTAssertEqual(mask.position, .zero)
                XCTAssertEqual(mask.size.height, sizes[index].height)
                XCTAssertGreaterThanOrEqual(mask.size.width, 0)
                XCTAssertLessThanOrEqual(mask.size.width, sizes[index].width)
                if index != 2 {
                    XCTAssertEqual(mask.size.width, sizes[index].width * CGFloat(min(1, max(0, fraction))), accuracy: 0.001)
                }
                XCTAssertEqual(crop.isHidden, fraction <= 0)
            }
        }
        updateBarFill(bars.shieldCropSprite, value: 1, maximum: 0)
        XCTAssertTrue(bars.shieldCropSprite.parent!.isHidden)
        boss.updateBars(0, totalHealth: 100)
        XCTAssertNil(boss.healthCropSprite.parent?.parent)
    }

    func testBarFillVisualStates() throws {
        let scene = GameScene(size: GameScene.arenaSize)
        let gallery = SKNode()
        scene.addChild(gallery)
        for (row, fraction) in [1.0, 0.75, 0.5, 0.25, 0.05, 0].enumerated() {
            let bars = HealthBarComponent(scene: scene, playerNode: SKNode(), sprite: SKSpriteNode())
            bars.healthNode.removeFromParent()
            bars.shieldNode.removeFromParent()
            gallery.addChild(bars.healthNode)
            gallery.addChild(bars.shieldNode)
            let y = CGFloat(5 - row) * 45
            bars.healthNode.position = CGPoint(x: 70, y: y)
            bars.shieldNode.position = CGPoint(x: 70, y: y)
            bars.updateBars(Player.shield * fraction, health: Player.health * fraction)

        }
        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: gallery))
        let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
        attachment.name = "Health-and-shield-100-75-50-25-5-0-percent"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testArenaScaleIsIndependentOfWindowSize() {
        let floor = FloorViewController(min: 4, max: 5, level: 1, world: 1)
        floor.loadViewIfNeeded()
        floor.buildMaze()
        XCTAssertTrue(floor.maze.flatMap { $0 }.allSatisfy { $0.size == GameScene.arenaSize })
        let scene = GameScene(size: floor.arenaSize)
        floor.skView.presentScene(scene)
        defer { floor.skView.presentScene(nil) }
        for size in [CGSize(width: 667, height: 375), CGSize(width: 844, height: 390),
                     CGSize(width: 640, height: 480), CGSize(width: 1440, height: 900)] {
            floor.view.frame = CGRect(origin: .zero, size: size)
            floor.viewDidLayoutSubviews()
            XCTAssertEqual(scene.size, CGSize(width: 750, height: 375))
            XCTAssertEqual(floor.skView.bounds.size, scene.size)
            XCTAssertEqual(floor.skView.transform.a, floor.skView.transform.d)
            XCTAssertTrue(floor.view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: -0.1, dy: -0.1)
                .contains(floor.skView.frame))
        }
    }

    @MainActor func testGreenShotsReachEveryWallAndCleanUp() throws {
        let scene = WallShotTestScene(size: GameScene.arenaSize)
        let controller = UIViewController()
        let applicationWindow = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let window = UIWindow(windowScene: try XCTUnwrap(applicationWindow.windowScene))
        window.frame = CGRect(origin: .zero, size: GameScene.arenaSize)
        window.rootViewController = controller
        let skView = SKView(frame: window.bounds)
        controller.view.addSubview(skView)
        window.makeKeyAndVisible()
        skView.presentScene(scene)
        let previousPosition = Player.entity.sprite.position
        defer {
            Player.entity.sprite.position = previousPosition
            skView.presentScene(nil)
            window.isHidden = true
            applicationWindow.makeKeyAndVisible()
        }
        // Right/left shots travel over 600 points, reproducing the old 500-point expiry.
        let angles: [CGFloat] = [0, .pi, .pi / 2, -.pi / 2,
                                 .pi / 4, -.pi / 4, .pi * 0.75, -.pi * 0.75]
        for (index, angle) in angles.enumerated() {
            let enemy = EnemyEntity()
            enemy.sprite.position = CGPoint(x: cos(angle) >= 0 ? 80 : 670,
                                            y: sin(angle) >= 0 ? 80 : 295)
            Player.entity.sprite.position = CGPoint(x: enemy.sprite.position.x + cos(angle) * 10,
                                                     y: enemy.sprite.position.y + sin(angle) * 10)
            EnemyShotTargetingComponent(scene: scene, entity: enemy).fire()
            scene.children.last?.children.first?.name = "test-shot-\(index)"
        }
        let finished = expectation(description: "Projectiles reach walls and wrappers expire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { finished.fulfill() }
        wait(for: [finished], timeout: 6)
        XCTAssertEqual(scene.wallHits.count, 8)
        XCTAssertEqual(scene.children.compactMap { $0 as? ShotNode }.count, 0)
        let walls = CGRect(x: 37.5, y: 37.5, width: 675, height: 300)
        for point in scene.wallHits {
            XCTAssertLessThan([abs(point.x - walls.minX), abs(point.x - walls.maxX),
                               abs(point.y - walls.minY), abs(point.y - walls.maxY)].min()!, 15)
        }
    }

    func testCompletionShowsTwoRewardsWithoutScrollingOnShortLandscapePhones() throws {
        func images(in view: UIView) -> [UIImageView] {
            if view is UIProgressView { return [] }
            return view.subviews.flatMap { ($0 as? UIImageView).map { [$0] } ?? images(in: $0) }
        }
        for size in [CGSize(width: 568, height: 320), CGSize(width: 667, height: 375),
                     CGSize(width: 844, height: 390)] {
            let completed = CompletedViewController()
            completed.expGained = 144
            completed.drops = [Item(t: "Cubrixel", q: 4, s: true),
                               Equipment(t: "Special Pulsar", lev: 1, tie: 1, st: "")]
            completed.loadViewIfNeeded()
            completed.view.frame = CGRect(origin: .zero, size: size)
            completed.view.layoutIfNeeded()
            let scroll = try XCTUnwrap(completionView(completed.view, id: "completion.rewards") as? UIScrollView)
            let rewardImages = images(in: scroll)
            XCTAssertEqual(rewardImages.count, 2)
            for image in rewardImages {
                XCTAssertTrue(scroll.bounds.contains(image.convert(image.bounds, to: scroll)),
                              "Both normal drops must be fully visible before scrolling at \(size)")
            }
            let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: completed.view.bounds).image {
                completed.view.layer.render(in: $0.cgContext)
            })
            attachment.name = "Completion-initial-\(Int(size.width))x\(Int(size.height))"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testCompletionLayoutKeepsContinueVisibleAndLootReachable() throws {
        for size in [CGSize(width: 667, height: 375), CGSize(width: 844, height: 390),
                     CGSize(width: 640, height: 480), CGSize(width: 1440, height: 900)] {
            for count in [2, 8] {
            let completed = CompletedViewController()
            completed.drops = (0..<count).map { Equipment(t: "Power Core", lev: $0 + 1, tie: 1, st: "") }
            completed.loadViewIfNeeded()
            completed.view.frame = CGRect(origin: .zero, size: size)
            completed.view.layoutIfNeeded()
            let content = try XCTUnwrap(completionView(completed.view, id: "completion.panel"))
            let scroll = try XCTUnwrap(content.subviews.compactMap { $0 as? UIScrollView }.first)
            let button = try XCTUnwrap(content.subviews.compactMap { $0 as? UIButton }.first)
            let buttonFrame = button.convert(button.bounds, to: completed.view)
            XCTAssertTrue(completed.view.safeAreaLayoutGuide.layoutFrame.contains(buttonFrame))
            XCTAssertGreaterThanOrEqual(buttonFrame.height, 48)
            XCTAssertLessThanOrEqual(content.bounds.width, 960)
            XCTAssertLessThanOrEqual(scroll.frame.maxY, button.frame.minY - 12)
            if count == 8 && size.height < 500 {
                XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
            }
            scroll.setContentOffset(CGPoint(x: 0, y: max(0, scroll.contentSize.height - scroll.bounds.height)), animated: false)
            let stack = try XCTUnwrap(scroll.subviews.first as? UIStackView)
            let lastLoot = try XCTUnwrap(stack.arrangedSubviews.last)
            let pixel = 1 / completed.view.contentScaleFactor
            XCTAssertTrue(scroll.bounds.insetBy(dx: -pixel, dy: -pixel).contains(lastLoot.convert(lastLoot.bounds, to: scroll)),
                          "Last reward must remain visible at \(size), count \(count)")
            let renderer = UIGraphicsImageRenderer(bounds: completed.view.bounds)
            let attachment = XCTAttachment(image: renderer.image { completed.view.layer.render(in: $0.cgContext) })
            attachment.name = "Completion-\(Int(size.width))x\(Int(size.height))-\(count)-items-scrolled"
            attachment.lifetime = .keepAlways
            add(attachment)
            }
        }
    }

    func testBundledConstantsCanPopulateEnemyDictionary() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "constants", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])

        Constants.jsonDict = json
        EnemyEntity.enemyDict = nil
        EnemyEntity.refreshEnemyDictionary()

        XCTAssertNotNil(EnemyEntity.enemyDict?["component"] as? [String: Any])
    }

    func testNewPlayerEntityStartsStationary() {
        let player = PlayerEntity()

        XCTAssertFalse(player.moving)
        XCTAssertFalse(player.shooting)
    }

    func testPlayerEntityStopControlsClearsInputFlags() {
        let player = PlayerEntity()
        player.moving = true
        player.shooting = true

        player.stopControls()

        XCTAssertFalse(player.moving)
        XCTAssertFalse(player.shooting)
    }

    func testLevelSelectUsesOneFullWidthPagePerWorld() {
        let controller = LevelSelectCollectionViewController()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        controller.view.layoutIfNeeded()
        controller.collectionView.collectionViewLayout.invalidateLayout()
        controller.collectionView.layoutIfNeeded()

        let pageCount = CGFloat(controller.numberOfSections(in: controller.collectionView))
        let expectedWidth = controller.collectionView.bounds.width * pageCount

        XCTAssertEqual(controller.collectionView.collectionViewLayout.collectionViewContentSize.width, expectedWidth, accuracy: 1.0)
    }

    func testOriginalProjectileArtAndMenuPaging() throws {
        for name in ["playerShot", "enemyShot", "enemyTrackingShot", "enemyTrippleShot", "bossDragonFireball", "bombLit1"] {
            XCTAssertEqual(try XCTUnwrap(GameArt.image(name)).pngData(), try XCTUnwrap(UIImage(named: name)).pngData(), name)
        }
        for size in [CGSize(width: 844, height: 390), CGSize(width: 1440, height: 900)] {
            let controller = LevelSelectCollectionViewController()
            controller.loadViewIfNeeded()
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.viewDidLayoutSubviews()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            controller.collectionView.layoutIfNeeded()
            controller.pageControl.currentPage = 2
            controller.pageControlChanged(controller.pageControl)
            controller.collectionView.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let offset = CGPoint(x: controller.collectionView.bounds.width * 2, y: 0)
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            XCTAssertEqual(controller.collectionView.bounds.origin, offset, "Layout must not reset paging")
            let layout = controller.collectionView.collectionViewLayout
            for item in 0..<10 {
                let frame = try XCTUnwrap(layout.layoutAttributesForItem(at: IndexPath(item: item, section: 2))).frame
                XCTAssertTrue(CGRect(x: offset.x, y: 0, width: controller.collectionView.bounds.width, height: controller.collectionView.bounds.height).contains(frame), "offset=\(offset) bounds=\(controller.collectionView.bounds) frame=\(frame)")
            }
            controller.pageControl.currentPage = 0
            controller.pageControlChanged(controller.pageControl)
            controller.collectionView.layoutIfNeeded()
            let image = UIGraphicsImageRenderer(size: size).image { context in
                controller.view.layer.render(in: context.cgContext)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Level selection \(Int(size.width))x\(Int(size.height))"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testLevelSelectUnlocksUsingGlobalLevelNumber() {
        let controller = LevelSelectCollectionViewController()

        XCTAssertEqual(controller.levelNumber(for: IndexPath(item: 0, section: 1)), 10)
        XCTAssertFalse(controller.isLevelUnlocked(at: IndexPath(item: 0, section: 1), completedLevel: 0))
        XCTAssertTrue(controller.isLevelUnlocked(at: IndexPath(item: 0, section: 1), completedLevel: 10))
    }

    func testWASDKeysDriveMovementVelocityOnly() {
        var controls = KeyboardControlState()

        controls.press(.w)
        controls.press(.d)

        XCTAssertTrue(controls.isMoving)
        XCTAssertFalse(controls.isShooting)
        XCTAssertEqual(controls.movementVelocity.x, KeyboardControlState.velocity / sqrt(2), accuracy: 0.001)
        XCTAssertEqual(controls.movementVelocity.y, KeyboardControlState.velocity / sqrt(2), accuracy: 0.001)
        XCTAssertEqual(controls.shootingVelocity, .zero)
    }

    func testArrowKeysDriveShootingVelocityOnly() {
        var controls = KeyboardControlState()

        controls.press(.up)
        controls.press(.left)

        XCTAssertFalse(controls.isMoving)
        XCTAssertTrue(controls.isShooting)
        XCTAssertEqual(controls.shootingVelocity.x, -KeyboardControlState.velocity / sqrt(2), accuracy: 0.001)
        XCTAssertEqual(controls.shootingVelocity.y, KeyboardControlState.velocity / sqrt(2), accuracy: 0.001)
        XCTAssertEqual(controls.movementVelocity, .zero)
    }

    func testReleasedKeysStopDrivingVelocity() {
        var controls = KeyboardControlState()

        controls.press(.s)
        controls.press(.right)
        controls.finishFrame()
        controls.release(.s)
        controls.release(.right)

        XCTAssertFalse(controls.isMoving)
        XCTAssertFalse(controls.isShooting)
        XCTAssertEqual(controls.movementVelocity, .zero)
        XCTAssertEqual(controls.shootingVelocity, .zero)
    }

    func testOppositeKeysCancelEachOther() {
        var controls = KeyboardControlState()

        controls.press(.a)
        controls.press(.d)
        controls.press(.up)
        controls.press(.down)

        XCTAssertEqual(controls.movementVelocity, .zero)
        XCTAssertEqual(controls.shootingVelocity, .zero)
    }

    func testBriefKeyTapSurvivesUntilOneFrameConsumesIt() {
        var controls = KeyboardControlState()
        controls.press(.w)
        controls.release(.w)
        XCTAssertTrue(controls.isMoving)
        controls.finishFrame()
        XCTAssertFalse(controls.isMoving)
    }

    func testResetClearsHeldKeys() {
        var controls = KeyboardControlState()

        controls.press(.w)
        controls.press(.right)
        controls.reset()

        XCTAssertFalse(controls.isMoving)
        XCTAssertFalse(controls.isShooting)
        XCTAssertEqual(controls.movementVelocity, .zero)
        XCTAssertEqual(controls.shootingVelocity, .zero)
    }

    func testEquipmentRefreshDoesNotAccumulateCooldownOrUseShieldForHealth() {
        let oldGear = Player.gear
        defer { Player.gear = oldGear; Player.updateEquipment(); Player.updatePlayer() }
        Player.gear = oldGear
        let armor = Equipment(t: "Armor Core", lev: 5, tie: 2, st: "", v: 0)
        let pulsar = Equipment(t: "Special Pulsar", lev: 5, tie: 2, st: "", v: 0)
        Player.gear["Armor Core"] = armor
        Player.gear["Special Pulsar"] = pulsar
        Player.updateEquipment()
        let expectedHealth = Player.gear["Power Core"]!.health + armor.health
            + Player.gear["Attachment 1"]!.health + Player.gear["Attachment 2"]!.health
        XCTAssertEqual(Player.healthBoost, expectedHealth, accuracy: 0.001)
        XCTAssertEqual(pulsar.attackSpeed, 0.4, accuracy: 0.001)
        Player.updatePlayer()
        let cooldown = Player.shotCoolDownSeconds
        Player.updatePlayer()
        XCTAssertEqual(Player.shotCoolDownSeconds, cooldown, accuracy: 0.001)
        XCTAssertLessThan(cooldown, Player.shotCoolDownBase)
        XCTAssertGreaterThan(cooldown, 0)
    }

    func testTotalExperienceThresholdMatchesIndividualLevelCosts() {
        XCTAssertEqual(Player.totalExpToLevel(1), 0)
        for level in 2...20 {
            XCTAssertEqual(Player.totalExpToLevel(level),
                           (1..<level).reduce(0) { $0 + Player.expToLevel($1) })
        }
    }

    func testInventoryReconstructsSavedEquipmentAndStackableItems() {
        let oldInventory = Player.inventory
        let oldDictionary = Player.inventoryDict
        defer { Player.inventory = oldInventory; Player.inventoryDict = oldDictionary }
        let equipment = Equipment(t: "Attachment", lev: 2, tie: 2, st: "Health", v: 3)
        Player.inventoryDict = [Item(t: "Cubrixel", q: 17, s: true).toDictionary(),
                                equipment.toDictionary()]
        Player.updateInventory()
        XCTAssertEqual(Player.inventory.count, 2)
        XCTAssertEqual(Player.inventory[0].quantity, 17)
        XCTAssertTrue(Player.inventory[0].stackable)
        let restored = Player.inventory[1] as? Equipment
        XCTAssertEqual(restored?.level, 2)
        XCTAssertEqual(restored?.tier, 2)
        XCTAssertEqual(restored?.subType, "Health")
        XCTAssertEqual(restored?.variant, 3)
    }

    func testDropsUseGlobalFloorExactlyOnce() {
        let controller = FloorViewController(min: 4, max: 5, level: 2, world: 2)
        XCTAssertEqual(controller.globalLevel, 12)
        for _ in 0..<100 {
            let drops = controller.getDrops()
            XCTAssertTrue(drops.first?.type == "Cubrixel")
            XCTAssertTrue(drops.contains { $0 is Equipment })
            for equipment in drops.compactMap({ $0 as? Equipment }) {
                XCTAssertEqual(equipment.level, 12)
            }
        }
    }

    func testEnemyGenerationHandlesFractionalCosts() {
        let controller = FloorViewController(min: 4, max: 5, level: 1, world: 1)
        for _ in 0..<100 {
            let room = RoomScene(size: CGSize(width: 1024, height: 768))
            room.viewController = controller
            room.enemyPoints = 4
            room.addEnemies()
            XCTAssertGreaterThan(room.enemies, 0)
            XCTAssertEqual(room.enemies, room.entites.count)
            XCTAssertLessThanOrEqual(room.enemies, 4)
        }
    }

    func testNormalEnemiesUseSelectedGlobalFloor() {
        let controller = FloorViewController(min: 4, max: 5, level: 2, world: 2)
        let room = RoomScene(size: CGSize(width: 1024, height: 768))
        room.viewController = controller
        let enemy = EnemyEntity(scene: room, eType: "Melee", lev: 1, elite: false)
        XCTAssertEqual(enemy.level, 12)
    }

    func testStoredFloorAdapterUsesTheExactRouteAndSpawnRecords() throws {
        let oldEntity = Player.entity
        let oldScene = Player.currentScene
        defer { Player.entity = oldEntity; Player.currentScene = oldScene }
        var random = SystemRandomNumberGenerator()
        let plan = try DelveFloorPlanner().generate(difficulty: 854, using: &random)
        let controller = try FloorViewController(plan: plan, restorableCombat: true)
        controller.buildMaze()
        XCTAssertEqual(controller.plannedRooms.count, plan.rooms.count)
        XCTAssertTrue(controller.maze.isEmpty, "Planned floors should not allocate a square of unused scenes")
        for roomPlan in plan.rooms {
            let room = try XCTUnwrap(controller.plannedRooms[roomPlan.position])
            XCTAssertEqual(room.plannedRoom, roomPlan)
            XCTAssertEqual(room.doors.count, plan.doors(for: roomPlan.id).count)
            if case .combat(let mobs) = roomPlan.encounter {
                room.addPlayer()
                room.addEnemies()
                let enemies = room.entites.compactMap { $0 as? EnemyEntity }
                XCTAssertEqual(enemies.count, mobs.count)
                for (enemy, mob) in zip(enemies, mobs) {
                    XCTAssertEqual(enemy.delveSpawnID, mob.id)
                    XCTAssertEqual(enemy.type, mob.kind.gameType)
                    // SpriteKit stores node positions with float precision.
                    XCTAssertEqual(enemy.sprite.position.x, mob.position.x * Double(room.size.width), accuracy: 0.001)
                    XCTAssertEqual(enemy.sprite.position.y, mob.position.y * Double(room.size.height), accuracy: 0.001)
                }
            } else if case .boss(let kind) = roomPlan.encounter {
                room.addBoss()
                XCTAssertEqual((room.entites.first as? BossEntity)?.type, kind.rawValue)
            }
        }
    }

    func testShopTradesPersistBothInventoryAndFinalBalance() {
        let oldInventory = Player.inventory
        let oldStock = Constants.merchantInventory
        defer { Player.inventory = oldInventory; Constants.merchantInventory = oldStock; Player.saveItems() }
        let equipment = Equipment(t: "Pulsar", lev: 2, tie: 2, st: "")
        Constants.merchantInventory = [equipment]
        Player.inventory = [Item(t: "Cubrixel", q: equipment.price * 2 + 7, s: true)]
        XCTAssertTrue(Player.buy(equipment))
        XCTAssertEqual(Player.inventory[0].quantity, 7)
        XCTAssertFalse(Player.buy(equipment), "An item cannot be purchased twice")
        XCTAssertEqual(Player.inventoryDict[0]["quantity"] as? Int, 7)
        XCTAssertTrue(Player.sell(equipment))
        XCTAssertEqual(Player.inventory[0].quantity, equipment.price + 7)
        XCTAssertEqual(Player.inventory.count, 1)
        XCTAssertFalse(Player.sell(equipment), "An item cannot be sold twice")
        Player.updateInventory()
        XCTAssertEqual(Player.inventory[0].quantity, equipment.price + 7)
    }

    func testInactiveFloorCannotGrantCompletionRewards() {
        let oldController = Player.currentViewController
        let oldScene = Player.currentScene
        defer { Player.currentViewController = oldController; Player.currentScene = oldScene }
        let inactive = FloorViewController()
        inactive.scene = RoomScene(size: CGSize(width: 800, height: 400))
        inactive.scene.viewController = inactive
        inactive.levelExp = 100
        Player.currentViewController = FloorViewController()
        let xp = Player.totalExp
        inactive.goToCompletedViewController(Notification(name: Notification.Name("GoToCompletedViewController"), object: inactive.scene))
        XCTAssertEqual(Player.totalExp, xp)
        XCTAssertFalse(inactive.rewardsGranted)
    }

    func testSingleStackableItemCanDisplayDetails() {
        let popup = VendorPopUpNode()
        popup.selectedNode = ItemNode(i: Item(t: "Cubrixel", q: 1, s: true))
        popup.updateLabels()
        XCTAssertEqual(popup.labels[1].text, "x 1")
    }

    func testMovementDistanceIsIndependentOfRefreshRate() {
        let oldEntity = Player.entity
        defer { Player.entity = oldEntity }
        for fps in [30, 60, 120] {
            let scene = GameScene(size: CGSize(width: 1200, height: 800))
            Player.entity = PlayerEntity(scene: scene, position: CGPoint(x: 100, y: 400))
            let movement = Player.entity.component(ofType: PlayerMovementComponent.self)!
            scene.frameDuration = 1 / Double(fps)
            movement.startMoving()
            for _ in 0..<fps { movement.move(with: CGPoint(x: 50, y: 0)) }
            XCTAssertEqual(Player.entity.sprite.position.x, 550, accuracy: 0.001)
            XCTAssertEqual(Player.entity.cannonSprite.zRotation, 0, accuracy: 0.001)
            scene.vending = true
            movement.move(with: CGPoint(x: 50, y: 0))
            XCTAssertEqual(Player.entity.sprite.position.x, 550, accuracy: 0.001)
        }
    }

    func testBossTrackingMovementIsIndependentOfRefreshRate() throws {
        let oldEntity = Player.entity
        let oldScene = Player.currentScene
        defer { Player.entity = oldEntity; Player.currentScene = oldScene }
        let path = try XCTUnwrap(Bundle.main.path(forResource: "bosses", ofType: "plist"))
        let properties = try XCTUnwrap((NSArray(contentsOfFile: path) as? [NSDictionary])?.first { $0["name"] as? String == "golem" })
        for fps in [30, 60, 120] {
            let controller = FloorViewController()
            let room = RoomScene(size: CGSize(width: 1200, height: 800))
            room.viewController = controller
            room.startPosition = CGPoint(x: 1050, y: 400)
            room.addPlayer()
            let boss = BossEntity(scene: room, properties: properties)
            boss.sprite.position = CGPoint(x: 100, y: 400)
            let tracking = try XCTUnwrap(boss.component(ofType: BossTrackingComponent.self))
            room.frameDuration = 1 / Double(fps)
            for frame in 0..<fps { tracking.action(Double(frame) / Double(fps)) }
            XCTAssertEqual(boss.sprite.position.x, 190, accuracy: 0.001)
        }
    }

    func testEnemyMovementAndHomingShotsKeepTheirSpeedAcrossRefreshRates() throws {
        let oldEntity = Player.entity
        let oldScene = Player.currentScene
        defer { Player.entity = oldEntity; Player.currentScene = oldScene }
        for fps in [30, 60, 120] {
            let controller = FloorViewController()
            let room = RoomScene(size: CGSize(width: 2000, height: 2000))
            room.viewController = controller
            room.startPosition = CGPoint(x: 1800, y: 1800)
            room.addPlayer()
            room.frameDuration = 1 / Double(fps)
            for type in ["Range", "Melee", "Dash", "RangeTracking"] {
                let enemy = EnemyEntity(scene: room, eType: type, lev: 1, elite: false,
                                        position: CGPoint(x: 100, y: 100))
                let node: SKNode
                let speed: Double
                let step: (Double) -> Void
                switch type {
                case "Range":
                    let movement = try XCTUnwrap(enemy.component(ofType: EnemyRandomMovementComponent.self))
                    movement.moving = true
                    movement.moveTo = CGPoint(x: 1800, y: 1800)
                    node = enemy.sprite; speed = movement.moveSpeed; step = movement.action
                case "Melee":
                    let movement = try XCTUnwrap(enemy.component(ofType: EnemyTrackingComponent.self))
                    node = enemy.sprite; speed = movement.moveSpeed; step = movement.action
                case "Dash":
                    let movement = try XCTUnwrap(enemy.component(ofType: EnemyDashMovementComponent.self))
                    movement.moving = true
                    movement.moveTo = CGPoint(x: 1800, y: 1800)
                    movement.finishedMove = -2
                    node = enemy.sprite; speed = movement.moveSpeed; step = movement.action
                default:
                    let shooting = try XCTUnwrap(enemy.component(ofType: EnemyShotTrackingComponent.self))
                    shooting.fire()
                    node = shooting.bullet; speed = shooting.speed
                    step = { _ in shooting.followPath() }
                }
                let origin = node.position
                for frame in 0..<fps { step(Double(frame) / Double(fps)) }
                let distance = Double(hypot(node.position.x - origin.x, node.position.y - origin.y))
                XCTAssertEqual(distance, speed * 60, accuracy: 0.01,
                               "\(type) at \(fps) Hz")
            }
        }
    }

    func testGolemRocksKeepTranslationAndRotationAcrossRefreshRates() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "bosses", ofType: "plist"))
        let properties = try XCTUnwrap((NSArray(contentsOfFile: path) as? [NSDictionary])?.first { $0["name"] as? String == "golem" })
        for fps in [30, 60, 120] {
            let controller = FloorViewController()
            let room = RoomScene(size: CGSize(width: 2000, height: 2000))
            room.viewController = controller
            room.frameDuration = 1 / Double(fps)
            let boss = BossEntity(scene: room, properties: properties)
            let shooting = try XCTUnwrap(boss.component(ofType: BossGolemRockShoot.self))
            shooting.angle = [.pi / 4]
            shooting.velocity = [3]
            let rock = SKSpriteNode(color: .white, size: CGSize(width: 32, height: 32))
            rock.position = CGPoint(x: 200, y: 200)
            for _ in 0..<fps { shooting.followPath(rock, shotNum: 0) }
            XCTAssertEqual(hypot(rock.position.x - 200, rock.position.y - 200), 180, accuracy: 0.01)
            XCTAssertEqual(rock.zRotation, 180.0 / 64, accuracy: 0.001)
        }
    }

    func testShootingStopsInJoystickDeadZoneAndAimsCardinally() {
        let oldEntity = Player.entity
        defer { Player.entity = oldEntity }
        let scene = GameScene(size: CGSize(width: 800, height: 400))
        Player.entity = PlayerEntity(scene: scene)
        let shooting = Player.entity.component(ofType: PlayerShootComponent.self)!
        shooting.shoot(with: CGPoint(x: 0, y: -50), currentTime: 1)
        XCTAssertTrue(Player.entity.shooting)
        XCTAssertEqual(Player.entity.cannonSprite.zRotation, -.pi / 2, accuracy: 0.001)
        shooting.shoot(with: CGPoint(x: 3, y: 4), currentTime: 2)
        XCTAssertFalse(Player.entity.shooting)
        scene.vending = true
        shooting.shoot(with: CGPoint(x: 50, y: 0), currentTime: 3)
        XCTAssertFalse(Player.entity.shooting)
    }

    func testInventoryPagesReachEveryItemBeyondThirtySlots() {
        let oldInventory = Player.inventory
        defer { Player.inventory = oldInventory }
        Player.inventory = (0..<65).map { Equipment(t: "Pulsar", lev: $0 + 1, tie: 1, st: "") }
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        var seen = [Item]()
        for page in 0..<3 {
            let bank = BankPopUpNode(scene: scene, page: page)
            let shop = ShopPopUpNode(scene: scene, page: page)
            XCTAssertEqual(bank.pageItems.count, page == 2 ? 5 : 30)
            XCTAssertEqual(shop.pageItems.count, bank.pageItems.count)
            seen += bank.pageItems
        }
        XCTAssertEqual(seen.count, 65)
        XCTAssertTrue(zip(seen, Player.inventory).allSatisfy { $0.0 === $0.1 })
    }

    func testBossAttackPointsStayInsideCompactArena() {
        let size = CGSize(width: 100, height: 80)
        for _ in 0..<36 {
            let point = bossAttackPosition(in: size, awayFrom: CGPoint(x: 50, y: 40),
                                           padding: CGSize(width: 30, height: 30))
            XCTAssertTrue(CGRect(origin: .zero, size: size).contains(point))
        }
    }

    func testSpawningTerminatesInSmallArena() {
        let controller = FloorViewController(min: 4, max: 5, level: 1, world: 1)
        let room = RoomScene(size: CGSize(width: 120, height: 100))
        room.viewController = controller
        let enemy = EnemyEntity(scene: room, eType: "Melee", lev: 1, elite: false)
        let position = enemy.getNewCenterPosition(CGPoint(x: 60, y: 50))
        XCTAssertTrue(position.x.isFinite && position.y.isFinite)
        XCTAssertTrue(CGRect(origin: .zero, size: room.size).contains(position))
    }

}

/// Runs the actual SpriteKit simulation with platform-appropriate control inputs.
/// No health, damage, collision, loot, enemy, or completion overrides are used.
class CubrismPlaythroughTests: XCTestCase {
    /// A timed fixture for native visual/control inspection, not an automated
    /// combat pass. Restore preferences even if hands-on combat earns rewards.
    @MainActor func testGeneratedFloorHandsOnPreview() async throws {
        guard ProcessInfo.processInfo.environment["CUBRISM_ACCEPTANCE"] == "1" else {
            throw XCTSkip("Run the CubrismAcceptance scheme for hands-on inspection")
        }
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let original = window.rootViewController
        let defaults = UserDefaults.standard
        let keys = ["Level", "Experience", "TotalExperience", "LevelCompleted", "Gear", "Inventory"]
        let saved = keys.map { defaults.object(forKey: $0) }
        var random = SystemRandomNumberGenerator()
        let generated = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        let plan = try JSONDecoder().decode(DelveFloorPlan.self, from: JSONEncoder().encode(generated))
        let controller = try FloorViewController(plan: plan, restorableCombat: true)
        defer {
            controller.skView.presentScene(nil)
            window.rootViewController = original
            for (key, value) in zip(keys, saved) {
                if let value = value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()
        if controller.needsNewRun { controller.startNewRun() }
        print("HANDS-ON READY: restored generated floor, \(plan.combatRooms.count) combat rooms, \(plan.enemies.count) enemies")
        try await Task.sleep(nanoseconds: 180_000_000_000)
        XCTAssertEqual(controller.floorPlan, plan)
    }

    /// Presentation fixtures only; this does not count as a combat completion.
    @MainActor func testRewardPageScrollingAndContinueNavigation() async throws {
        guard ProcessInfo.processInfo.environment["CUBRISM_ACCEPTANCE"] == "1" else {
            throw XCTSkip("Run the CubrismAcceptance scheme for presentation validation")
        }
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let home = try XCTUnwrap(window.rootViewController as? HomeViewController)
        let floor = home.floorView!
        floor.needsNewRun = true
        home.present(floor, animated: false)
        try await Task.sleep(nanoseconds: 200_000_000)
        floor.skView.presentScene(nil)
        let completed = CompletedViewController()
        completed.expGained = 147
        // Ensure overflow even when Catalyst restores a tall desktop window.
        let dropCount = max(8, Int(window.bounds.height / 48) + 1)
        completed.drops = (0..<dropCount).map { Equipment(t: "Power Core", lev: $0 + 1, tie: 2, st: "", v: $0 % 4) }
        completed.modalPresentationStyle = .fullScreen
        floor.present(completed, animated: false)
        try await Task.sleep(nanoseconds: 200_000_000)
        let scroll = try XCTUnwrap(completionView(completed.view, id: "completion.rewards") as? UIScrollView)
        XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
        XCTAssertTrue(completed.view.safeAreaLayoutGuide.layoutFrame.contains(scroll.convert(scroll.bounds, to: completed.view)))
        print("PRESENTATION READY: reward page scroll and Continue")
        // Yield to the application's event loop so native mouse/touch input works during inspection.
        try await Task.sleep(nanoseconds: 30_000_000_000)
        if completed.presentingViewController != nil {
            let button = try XCTUnwrap(completionView(completed.view, id: "completion.continue") as? UIButton)
            button.sendActions(for: .touchUpInside)
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(home.presentedViewController)
        XCTAssertTrue(home.skView.scene is HomeScene)
        XCTAssertNil(Player.currentViewController)
    }

    func testLevelSelectionStartsChosenFloor() throws {
        guard ProcessInfo.processInfo.environment["CUBRISM_ACCEPTANCE"] == "1" else { throw XCTSkip("Acceptance scheme required") }
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let home = try XCTUnwrap(window.rootViewController as? HomeViewController)
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: "LevelCompleted")
        defer {
            home.dismiss(animated: false)
            if let saved = saved { defaults.set(saved, forKey: "LevelCompleted") }
            else { defaults.removeObject(forKey: "LevelCompleted") }
        }
        defaults.set(10, forKey: "LevelCompleted")
        let menu = try XCTUnwrap(home.levelSelectView)
        home.present(menu, animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        menu.collectionView(menu.collectionView, didSelectItemAt: IndexPath(item: 1, section: 1))
        XCTAssertTrue(home.presentedViewController === menu, "Locked floor must not start")
        menu.collectionView(menu.collectionView, didSelectItemAt: IndexPath(item: 0, section: 1))
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertTrue(home.presentedViewController === home.floorView)
        XCTAssertEqual(home.floorView.world, 2)
        XCTAssertEqual(home.floorView.level, 1)
        XCTAssertNotNil(home.floorView.scene)
    }

    func testFirstTwoFloorsThroughCombatAndDoors() throws {
        try playFloors()
    }

    func testGeneratedFloorThroughCombatAndDoors() throws {
        var random = SystemRandomNumberGenerator()
        let plan = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        try playFloors(plan: plan)
    }

    func testRestorableGeneratedFloorThroughCombatAndDoors() throws {
        var random = SystemRandomNumberGenerator()
        let plan = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        try playFloors(plan: plan, restorableCombat: true)
    }

    func testGeneratedFloorAgainstGolem() throws {
        var random = SystemRandomNumberGenerator()
        let generated = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        let last = try XCTUnwrap(generated.rooms.last)
        let rooms = Array(generated.rooms.dropLast()) + [DelveRoomPlan(id: last.id, position: last.position, encounter: .boss(.golem))]
        let plan = DelveFloorPlan(difficulty: generated.difficulty, budget: generated.budget,
                                 groupingMultiplier: generated.groupingMultiplier, density: generated.density, rooms: rooms)
        try playFloors(plan: plan)
    }

    func testStoredWorldReloadThroughCombatAndDoors() throws {
        var random = DelveRandom(seed: 854)
        let generated = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        let last = try XCTUnwrap(generated.rooms.last)
        let rooms = Array(generated.rooms.dropLast()) + [DelveRoomPlan(id: last.id, position: last.position, encounter: .boss(.dragon))]
        let plan = DelveFloorPlan(difficulty: generated.difficulty, budget: generated.budget,
            groupingMultiplier: generated.groupingMultiplier, density: generated.density, rooms: rooms)
        try playFloors(plan: plan, restorableCombat: true, reloadCombat: true)
    }

    private func playFloors(plan: DelveFloorPlan? = nil, restorableCombat: Bool = false, reloadCombat: Bool = false) throws {
        guard ProcessInfo.processInfo.environment["CUBRISM_ACCEPTANCE"] == "1" else {
            throw XCTSkip("Run the CubrismAcceptance scheme for the live gameplay check")
        }
        let acceptanceDeadline = Date().addingTimeInterval(15 * 60)
        let defaults = UserDefaults.standard
        let keys = ["Level", "Experience", "TotalExperience", "LevelCompleted", "Gear", "Inventory"]
        let saved = keys.map { defaults.object(forKey: $0) }
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let original = window.rootViewController
        defer {
            window.rootViewController = original
            for (key, value) in zip(keys, saved) {
                if let value = value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        Player.resetProgress()
        for floor in 1...(plan == nil ? 2 : 1) {
            var cleared = false
            for attempt in 1...10 {
            guard Date() < acceptanceDeadline else { break }
            print("PLAYTHROUGH ATTEMPT floor=\(floor) attempt=\(attempt) playerLevel=\(Player.level)")
            let xpBeforeAttempt = Player.totalExp
            var controller: FloorViewController
            if let plan = plan { controller = try FloorViewController(plan: plan, restorableCombat: restorableCombat) }
            else { controller = FloorViewController(min: UInt32(floor + 3), max: UInt32(floor + 4), level: floor, world: 1) }
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.loadViewIfNeeded()
            controller.view.layoutIfNeeded()
            if controller.needsNewRun { controller.startNewRun() }
            let end = min(Date().addingTimeInterval(180), acceptanceDeadline)
            var reloadedCombat = false, reloadedBoss = false
            var visited = Set<ObjectIdentifier>()
            var lastRoom: RoomScene?
            var lastReport = Date.distantPast
            var golemWaypoint = 0
            var golemWaypointStarted = Date()
            while Date() < end && !controller.rewardsGranted && Player.alive {
                RunLoop.main.run(until: Date().addingTimeInterval(1.0 / 60.0))
                guard let room = controller.scene, room.view != nil else { continue }
                if room !== lastRoom {
                    visited.insert(ObjectIdentifier(room))
                    lastRoom = room
                    golemWaypoint = 0
                    golemWaypointStarted = Date()
                    print("PLAYTHROUGH floor=\(floor) room=\(room.name ?? "?") visited=\(visited.count)")
                }
                if reloadCombat, let plan = plan, !room.completed,
                   (room.name == "room" && !reloadedCombat) || (room.name == "bossRoom" && !reloadedBoss) {
                    let partialHealth = room.entites.contains {
                        if let enemy = $0 as? EnemyEntity { return enemy.currentHealth > 0 && enemy.currentHealth < enemy.health }
                        if let boss = $0 as? BossEntity { return boss.currentHealth > 0 && boss.currentHealth < boss.health * 0.7 }
                        return false
                    }
                    if partialHealth && !room.gameplayMotionSnapshot.isEmpty {
                        room.isPaused = true; Player.entity.stopControls()
                        let catalog = legacyCombatCatalog(level: controller.globalLevel)
                        let metrics = try DelveCombatMetrics(targetSeconds: 80, entryCapacity: Player.health + Player.shield)
                        let completed = Set(controller.plannedRooms.values.filter(\.completed).compactMap { $0.plannedRoom?.id })
                        let snapshot = try DelveWorldBridge.capture(room: room, floorID: UUID(), completed: completed, stats: catalog, metrics: metrics)
                        try snapshot.validate(plan: plan)
                        let data = try JSONEncoder().encode(snapshot)
                        let restored = try JSONDecoder().decode(DelveWorldState.self, from: data)
                        let hp = Player.currentHealth, shield = Player.currentShield
                        let accumulatedXP = controller.levelExp
                        let old = controller
                        let next = try FloorViewController(plan: plan, restorableCombat: true, world: restored)
                        old.skView.presentScene(nil)
                        controller = next; window.rootViewController = next
                        next.loadViewIfNeeded(); next.view.layoutIfNeeded()
                        if next.needsNewRun { next.startNewRun() }
                        next.levelExp = accumulatedXP
                        let resumedRoom = try XCTUnwrap(next.scene)
                        XCTAssertNil(resumedRoom.restoreError)
                        RunLoop.main.run(until: Date().addingTimeInterval(1))
                        XCTAssertTrue(resumedRoom.isPaused)
                        XCTAssertEqual(Player.currentHealth, hp)
                        XCTAssertEqual(Player.currentShield, shield)
                        let check = try DelveWorldBridge.capture(room: resumedRoom, floorID: snapshot.floorID,
                            completed: snapshot.completedRoomIDs, stats: catalog, metrics: metrics)
                        XCTAssertEqual(check, snapshot, "A live SpriteKit floor must reload exactly before accepting input")
                        print("PLAYTHROUGH RESTORED room=\(room.name ?? "?") hp=\(hp) shield=\(shield) actors=\(snapshot.actors.count) projectiles=\(snapshot.sprites.count)")
                        let popup = try XCTUnwrap(resumedRoom.children.compactMap { $0 as? PopUpNode }.first)
                        popup.play(nil)
                        if room.name == "room" { reloadedCombat = true } else { reloadedBoss = true }
                        visited = Set(next.plannedRooms.values.filter(\.completed).map(ObjectIdentifier.init))
                        lastRoom = nil
                        continue
                    }
                }
                let player = Player.entity.sprite.position
                let enemies: [CGPoint] = room.entites.compactMap {
                    if let enemy = $0 as? EnemyEntity, enemy.currentHealth > 0 { return enemy.sprite.position }
                    if let boss = $0 as? BossEntity, boss.currentHealth > 0 { return boss.sprite.position }
                    return nil
                }
                var movement = CGPoint.zero
                var aim = CGPoint.zero
                if let enemy = enemies.min(by: { hypot($0.x-player.x, $0.y-player.y) < hypot($1.x-player.x, $1.y-player.y) }) {
                    let dx = enemy.x - player.x, dy = enemy.y - player.y
                    aim = CGPoint(x: dx, y: dy)
                    let hazards = room.children.flatMap { [$0] + $0.children }.compactMap { node -> CGPoint? in
                        guard let category = node.physicsBody?.categoryBitMask,
                              category == Constants.enemyShotCategory || category == Constants.enemyTrackingShotCategory || category == Constants.enemyStatusShotCategory else { return nil }
                        return node.convert(.zero, to: room)
                    }
                    var bestScore = -CGFloat.infinity
                    for x in -1...1 { for y in -1...1 {
                        let length = max(1, hypot(CGFloat(x), CGFloat(y)))
                        let step = CGPoint(x: CGFloat(x)/length, y: CGFloat(y)/length)
                        let next = CGPoint(x: player.x + step.x * 40, y: player.y + step.y * 40)
                        func outsideArena(_ point: CGPoint) -> CGFloat {
                            max(0, room.size.width * 0.10 - point.x)
                                + max(0, point.x - room.size.width * 0.90)
                                + max(0, room.size.height * 0.15 - point.y)
                                + max(0, point.y - room.size.height * 0.85)
                        }
                        // Door entries start near a wall; allow steps back into the combat area.
                        let outside = outsideArena(next)
                        guard outside == 0 || outside < outsideArena(player) else { continue }
                        let tx = enemy.x - next.x, ty = enemy.y - next.y
                        let angle = (atan2(ty, tx) / (.pi/4)).rounded() * (.pi/4)
                        let error = abs(-sin(angle) * tx + cos(angle) * ty)
                        let enemyClearance = enemies.map { hypot($0.x-next.x, $0.y-next.y) }.min() ?? 300
                        let shotClearance = hazards.map { hypot($0.x-next.x, $0.y-next.y) }.min() ?? 300
                        #if targetEnvironment(macCatalyst)
                        let aimPenalty = error * 0.8
                        #else
                        let aimPenalty: CGFloat = 0
                        #endif
                        // Prioritize escaping melee range over lining up a shot, and
                        // stop chasing extra clearance once bullets are safely distant.
                        let score = -aimPenalty - abs(hypot(tx, ty) - 200) * 0.08
                            + min(150, enemyClearance) * 3 + min(100, shotClearance) * 3
                        if score > bestScore { bestScore = score; movement = step }
                    }}
                    if room.entites.contains(where: { ($0 as? BossEntity)?.type == "golem" }) {
                        // Kite the pursuing boss around the room rather than
                        // backing into a corner to hold a perfect firing line.
                        let corners = [CGPoint(x: room.size.width * 0.15, y: room.size.height * 0.20),
                                       CGPoint(x: room.size.width * 0.85, y: room.size.height * 0.20),
                                       CGPoint(x: room.size.width * 0.85, y: room.size.height * 0.80),
                                       CGPoint(x: room.size.width * 0.15, y: room.size.height * 0.80)]
                        let goal = corners[golemWaypoint]
                        if hypot(goal.x - player.x, goal.y - player.y) < 30
                            || Date().timeIntervalSince(golemWaypointStarted) > 3 {
                            golemWaypoint = (golemWaypoint + 1) % corners.count
                            golemWaypointStarted = Date()
                        }
                        let target = corners[golemWaypoint]
                        let distance = max(1, hypot(target.x - player.x, target.y - player.y))
                        movement = CGPoint(x: (target.x - player.x) / distance, y: (target.y - player.y) / distance)
                        if let hazard = hazards.min(by: { hypot($0.x-player.x, $0.y-player.y) < hypot($1.x-player.x, $1.y-player.y) }) {
                            let clearance = max(1, hypot(hazard.x - player.x, hazard.y - player.y))
                            if clearance < 65 {
                                movement.x += (player.x - hazard.x) / clearance
                                movement.y += (player.y - hazard.y) / clearance
                            }
                        }
                    }
                } else {
                    let destination: CGPoint
                    if room.name == "bossRoom" && room.completed {
                        destination = CGPoint(x: room.size.width/2, y: room.size.height/2)
                    } else if let door = room.doors.first(where: {
                        guard let destination = controller.room(at: $0.pointer) else { return false }
                        return !visited.contains(ObjectIdentifier(destination))
                    }) {
                        destination = door.position
                    } else { break }
                    movement = CGPoint(x: destination.x-player.x, y: destination.y-player.y)
                    if abs(movement.x) < 4 { movement.x = 0 }
                    if abs(movement.y) < 4 { movement.y = 0 }
                }
                #if targetEnvironment(macCatalyst)
                room.keyboardControls.reset()
                func drive(_ vector: CGPoint, left: KeyboardControlState.Key, right: KeyboardControlState.Key,
                           up: KeyboardControlState.Key, down: KeyboardControlState.Key) {
                    let length = hypot(vector.x, vector.y)
                    guard length > 0 else { return }
                    if vector.x / length > 0.38 { room.keyboardControls.press(right) }
                    if vector.x / length < -0.38 { room.keyboardControls.press(left) }
                    if vector.y / length > 0.38 { room.keyboardControls.press(up) }
                    if vector.y / length < -0.38 { room.keyboardControls.press(down) }
                }
                drive(movement, left: .a, right: .d, up: .w, down: .s)
                drive(aim, left: .left, right: .right, up: .up, down: .down)
                #else
                let moveComponent = Player.entity.component(ofType: PlayerMovementComponent.self)!
                let shootComponent = Player.entity.component(ofType: PlayerShootComponent.self)!
                let moveLength = max(1, hypot(movement.x, movement.y))
                moveComponent.startMoving()
                moveComponent.move(with: CGPoint(x: movement.x / moveLength * 50, y: movement.y / moveLength * 50))
                let aimLength = max(1, hypot(aim.x, aim.y))
                shootComponent.shoot(with: CGPoint(x: aim.x / aimLength * 50, y: aim.y / aimLength * 50), currentTime: room.time)
                #endif
                room.started = true
                if Date().timeIntervalSince(lastReport) > 5 {
                    let bosses = room.entites.compactMap { ($0 as? BossEntity).map { "\($0.type ?? "?") \(Int($0.currentHealth))/\(Int($0.health))" } }
                    print("PLAYTHROUGH bosses=\(bosses)")
                    print("PLAYTHROUGH floor=\(floor) hp=\(Int(Player.currentHealth)) shield=\(Int(Player.currentShield)) enemies=\(enemies.count) position=\(player) xp=\(controller.levelExp) frameSeconds=\(room.frameDuration)")
                    lastReport = Date()
                }
            }
            print("PLAYTHROUGH END floor=\(floor) alive=\(Player.alive) completed=\(controller.rewardsGranted) hp=\(Player.currentHealth)")
            guard controller.rewardsGranted else { continue }
            cleared = true
            if reloadCombat { XCTAssertTrue(reloadedCombat); XCTAssertTrue(reloadedBoss) }
            XCTAssertEqual(Player.totalExp, xpBeforeAttempt + controller.levelExp, "Rewards must be credited exactly once")
            XCTAssertEqual(defaults.integer(forKey: "LevelCompleted"), floor)
            XCTAssertGreaterThan(controller.levelExp, 0)
            XCTAssertFalse(Player.inventory.isEmpty)
            print("PLAYTHROUGH COMPLETED floor=\(floor) totalXP=\(Player.totalExp) inventory=\(Player.inventory.count)")
            RunLoop.main.run(until: Date().addingTimeInterval(20))
            break
            }
            XCTAssertTrue(cleared, "Floor \(floor) did not complete through its exit after ten normal attempts")
            guard cleared else { return }
        }
    }
    // This fixture isolates simulation persistence while the default economy is
    // still legacy. It deliberately freezes the exact existing combat stats.
    private func legacyCombatCatalog(level: Int) -> DelveFloorCombatStats {
        func enemy(_ type: String, elite: Bool = false) -> DelveEnemyStats {
            let key = type.prefix(1).lowercased() + String(type.dropFirst())
            let values = EnemyEntity.enemyDict![key] as! [String: Any]
            let scale = Constants.enemyMultiplier(level + (elite ? 4 : 0))
            return DelveEnemyStats(health: Double(Int(Player.healthBase * (values["healthMult"] as! Double) * scale)),
                rangeAttackPower: Double(Int(Player.attackPowerBase * (values["rangeAttackMult"] as! Double) * scale)),
                meleeAttackPower: Double(Int(Player.attackPowerBase * (values["meleeAttackMult"] as! Double) * scale)), effectAttackPower: 0)
        }
        let enemies = Dictionary(uniqueKeysWithValues: DelveEnemyKind.allCases.map { ($0, enemy($0.gameType, elite: $0.isElite)) })
        let bosses = Dictionary(uniqueKeysWithValues: DelveBossKind.allCases.map { kind -> (DelveBossKind, DelveEnemyStats) in
            let values = BossEntity.bossDict![kind.rawValue] as! [String: Any]
            return (kind, DelveEnemyStats(health: Double(values["healthBase"] as! Int) * Constants.bossHealthMultiplier(level),
                rangeAttackPower: Double(Int(Double(values["rangeBase"] as! Int) * Constants.bossDamageMultiplier(level))),
                meleeAttackPower: Double(Int(Double(values["meleeBase"] as! Int) * Constants.bossDamageMultiplier(level))),
                effectAttackPower: Double(Int(Double(values["effectBase"] as! Int) * Constants.enemyMultiplier(level)))))
        })
        return DelveFloorCombatStats(enemies: enemies, bosses: bosses, fireball: enemy("DragonFireball"))
    }

}

private class BombCallbackTestComponent: EnemyBombDroppingComponent {
    var explosions = [CGPoint]()
    override func explode(_ position: CGPoint) { explosions.append(position) }
}

private class RestorableMotionTestScene: GameScene {
    override var usesRestorableCombat: Bool { true }
}

private class WallShotTestScene: GameScene {
    var wallHits = [CGPoint]()
    override func update(_ currentTime: TimeInterval) {}
    override func didBegin(_ contact: SKPhysicsContact) {
        for body in [contact.bodyA, contact.bodyB] {
            if body.node?.name?.hasPrefix("test-shot-") == true {
                wallHits.append(body.node!.position)
            }
        }
        super.didBegin(contact)
    }
}
