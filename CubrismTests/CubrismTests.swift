//
//  CubrismTests.swift
//  CubrismTests
//
//  Created by Brendan Sanderson on 3/3/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import XCTest
@testable import Cubrism

class CubrismTests: XCTestCase {

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

}
