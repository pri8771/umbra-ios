//
//  UmbraUITests.swift
//  UmbraUITests
//
//  End-to-end smoke test for the flow a real user sees: launch, onboarding,
//  reaching the lens screen, the time-scrub control responding, and placing a
//  proxy object. On the Simulator (which this suite always runs in) ARKit has
//  no real camera/world-tracking, so `ARLensView` always falls back to
//  `MockSceneView` (see `#if canImport(ARKit) && !targetEnvironment(simulator)`
//  in ARLensView.swift). That is expected and intentional here: this test
//  exercises the UI plumbing (state, navigation, controls), not real AR
//  tracking. It says nothing about on-device AR behavior, which can only be
//  validated on a physical iPhone in a physical space.
//

import XCTest

final class UmbraUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// App launch -> onboarding (skip path) -> project library -> lens screen
    /// -> time scrub responds -> place a proxy object.
    func testOnboardingToLensPlaceObjectFlow() throws {
        let app = XCUIApplication()
        // Forces a fresh in-memory SwiftData store (see UmbraApp.swift) so the
        // test always starts at onboarding, independent of whatever state a
        // prior run or a developer's own simulator session left behind.
        app.launchArguments += ["-UITestReset"]
        app.launch()

        // --- Onboarding ---
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10), "Onboarding Skip button never appeared")
        skipButton.tap()

        // --- Project library (empty state) -> create a plan ---
        let createFirstPlan = app.buttons["Create First Plan"]
        XCTAssertTrue(createFirstPlan.waitForExistence(timeout: 10), "Empty-state library did not appear")
        createFirstPlan.tap()

        // --- Lens screen ---
        // Dismiss the first-run "See it line up first" coach if it appears.
        let gotIt = app.buttons["Got it"]
        if gotIt.waitForExistence(timeout: 10) {
            gotIt.tap()
        }

        // The mock (non-AR) scene is the only path the Simulator can exercise;
        // its accessibility label confirms we're on the lens screen at all.
        let scene = app.otherElements["Top-down plan preview"]
        XCTAssertTrue(scene.waitForExistence(timeout: 10), "Mock scene (Simulator AR fallback) never appeared")

        // --- Time-scrub control responds ---
        let nowButton = app.buttons["Jump to now"]
        XCTAssertTrue(nowButton.waitForExistence(timeout: 5), "Time scrubber 'Now' button not found")
        nowButton.tap()

        let timeSlider = app.sliders["Time of day"]
        XCTAssertTrue(timeSlider.waitForExistence(timeout: 5), "Time-of-day slider not found")
        let beforeValue = timeSlider.value as? String
        timeSlider.adjust(toNormalizedSliderPosition: 0.25)
        let afterValue = timeSlider.value as? String
        XCTAssertNotEqual(beforeValue, afterValue, "Scrubbing the time slider did not change its reported value")

        // --- Place a proxy object ---
        // Pick a non-default kind from the palette (default selection is Pole).
        let umbrella = app.buttons["Umbrella"]
        XCTAssertTrue(umbrella.waitForExistence(timeout: 5), "Object palette 'Umbrella' entry not found")
        umbrella.tap()

        scene.tap()

        // Placing an object selects it, which reveals the per-object controls.
        let rotateButton = app.buttons["Rotate object"]
        XCTAssertTrue(rotateButton.waitForExistence(timeout: 5), "Placing an object did not surface the selected-object controls")
    }
}
