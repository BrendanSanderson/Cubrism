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

class CubrismTests: XCTestCase {

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
        for name in ["StyleGun", "StyleEnemies", "StyleItems", "StyleBosses"] {
            let cg = try XCTUnwrap(UIImage(named: name)?.cgImage)
            XCTAssertNotEqual(cg.alphaInfo, .none, name)
            XCTAssertNotEqual(cg.alphaInfo, .noneSkipLast, name)
        }
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

    func testGreenShotsReachEveryWallAndCleanUp() {
        let scene = WallShotTestScene(size: GameScene.arenaSize)
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(origin: .zero, size: GameScene.arenaSize))
        window.rootViewController = controller
        let skView = SKView(frame: window.bounds)
        controller.view.addSubview(skView)
        window.isHidden = false
        skView.presentScene(scene)
        let previousPosition = Player.entity.sprite.position
        defer {
            Player.entity.sprite.position = previousPosition
            skView.presentScene(nil)
            window.isHidden = true
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

    func testCompletionLayoutKeepsContinueVisibleAndLootReachable() throws {
        for size in [CGSize(width: 667, height: 375), CGSize(width: 844, height: 390),
                     CGSize(width: 640, height: 480), CGSize(width: 1440, height: 900)] {
            for count in [2, 8] {
            let completed = CompletedViewController()
            completed.drops = (0..<count).map { Equipment(t: "Power Core", lev: $0 + 1, tie: 1, st: "") }
            completed.loadViewIfNeeded()
            completed.view.frame = CGRect(origin: .zero, size: size)
            completed.view.layoutIfNeeded()
            let content = try XCTUnwrap(completed.view.subviews.first)
            let scroll = try XCTUnwrap(content.subviews.compactMap { $0 as? UIScrollView }.first)
            let button = try XCTUnwrap(content.subviews.compactMap { $0 as? UIButton }.first)
            let buttonFrame = button.convert(button.bounds, to: completed.view)
            XCTAssertTrue(completed.view.safeAreaLayoutGuide.layoutFrame.contains(buttonFrame))
            XCTAssertGreaterThanOrEqual(buttonFrame.height, 48)
            XCTAssertLessThanOrEqual(content.bounds.width, 720)
            XCTAssertLessThanOrEqual(scroll.frame.maxY, button.frame.minY - 12)
            if count == 8 && size.height < 500 {
                XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
            }
            scroll.setContentOffset(CGPoint(x: 0, y: max(0, scroll.contentSize.height - scroll.bounds.height)), animated: false)
            let stack = try XCTUnwrap(scroll.subviews.first as? UIStackView)
            let lastLoot = try XCTUnwrap(stack.arrangedSubviews.last)
            XCTAssertTrue(scroll.bounds.contains(lastLoot.convert(lastLoot.bounds, to: scroll)))
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
    /// Presentation fixtures only; this does not count as a combat completion.
    func testRewardPageScrollingAndContinueNavigation() throws {
        guard ProcessInfo.processInfo.environment["CUBRISM_ACCEPTANCE"] == "1" else {
            throw XCTSkip("Run the CubrismAcceptance scheme for presentation validation")
        }
        let window = try XCTUnwrap((UIApplication.shared.delegate as? AppDelegate)?.window)
        let home = try XCTUnwrap(window.rootViewController as? HomeViewController)
        let floor = home.floorView!
        floor.needsNewRun = true
        home.present(floor, animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        floor.skView.presentScene(nil)
        let completed = CompletedViewController()
        completed.expGained = 147
        completed.drops = (0..<8).map { Equipment(t: "Power Core", lev: $0 + 1, tie: 1, st: "") }
        completed.modalPresentationStyle = .fullScreen
        floor.present(completed, animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        let scroll = try XCTUnwrap(completed.view.subviews.first?.subviews.compactMap { $0 as? UIScrollView }.first)
        XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
        XCTAssertTrue(completed.view.safeAreaLayoutGuide.layoutFrame.contains(scroll.convert(scroll.bounds, to: completed.view)))
        print("PRESENTATION READY: reward page scroll and Continue")
        RunLoop.main.run(until: Date().addingTimeInterval(30))
        if completed.presentingViewController != nil { completed.goToHome(UIButton()) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertNil(home.presentedViewController)
        XCTAssertTrue(home.skView.scene is HomeScene)
        XCTAssertNil(Player.currentViewController)
    }

    func testFirstTwoFloorsThroughCombatAndDoors() throws {
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
        for floor in 1...2 {
            var cleared = false
            for attempt in 1...10 {
            guard Date() < acceptanceDeadline else { break }
            print("PLAYTHROUGH ATTEMPT floor=\(floor) attempt=\(attempt) playerLevel=\(Player.level)")
            let xpBeforeAttempt = Player.totalExp
            let controller = FloorViewController(min: UInt32(floor + 3), max: UInt32(floor + 4), level: floor, world: 1)
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.loadViewIfNeeded()
            controller.view.layoutIfNeeded()
            if controller.needsNewRun { controller.startNewRun() }
            let end = min(Date().addingTimeInterval(180), acceptanceDeadline)
            var visited = Set<ObjectIdentifier>()
            var lastRoom: RoomScene?
            var lastReport = Date.distantPast
            while Date() < end && !controller.rewardsGranted && Player.alive {
                RunLoop.main.run(until: Date().addingTimeInterval(1.0 / 60.0))
                guard let room = controller.scene, room.view != nil else { continue }
                if room !== lastRoom {
                    visited.insert(ObjectIdentifier(room))
                    lastRoom = room
                    print("PLAYTHROUGH floor=\(floor) room=\(room.name ?? "?") visited=\(visited.count)")
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
                } else {
                    let destination: CGPoint
                    if room.name == "bossRoom" && room.completed {
                        destination = CGPoint(x: room.size.width/2, y: room.size.height/2)
                    } else if let door = room.doors.first(where: {
                        !visited.contains(ObjectIdentifier(controller.maze[Int($0.pointer.x)][Int($0.pointer.y)]))
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
                    print("PLAYTHROUGH floor=\(floor) hp=\(Int(Player.currentHealth)) shield=\(Int(Player.currentShield)) enemies=\(enemies.count) position=\(player) xp=\(controller.levelExp)")
                    lastReport = Date()
                }
            }
            print("PLAYTHROUGH END floor=\(floor) alive=\(Player.alive) completed=\(controller.rewardsGranted) hp=\(Player.currentHealth)")
            guard controller.rewardsGranted else { continue }
            cleared = true
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
