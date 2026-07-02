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
