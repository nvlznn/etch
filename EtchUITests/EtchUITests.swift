import XCTest

/// End-to-end flows through the real app, with screenshots attached to the test results.
/// Every test starts from an empty in-memory store.
@MainActor
final class EtchUITests: XCTestCase {
    private var app: XCUIApplication!

    /// Launches a fresh app on an empty in-memory store, plus any extra launch arguments.
    private func launch(_ arguments: String...) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-EtchInMemory"] + arguments
        app.launch()
    }

    func testHabitLifecycle() throws {
        launch()
        snapshot("01 empty")

        // Add a habit from the empty state.
        app.buttons["Add Habit"].firstMatch.tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertFalse(app.navigationBars.buttons["Done"].isEnabled, "Done is disabled while the name is empty")
        name.typeText("Read")
        snapshot("02 new habit sheet")
        app.navigationBars.buttons["Done"].tap()

        // Check in, undo, check in again.
        let notDone = app.buttons["Read, not done today"]
        XCTAssertTrue(notDone.waitForExistence(timeout: 3))
        tapDimple(of: notDone)
        let done = app.buttons["Read, done today"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        snapshot("03 checked in")
        tapDimple(of: done)
        XCTAssertTrue(notDone.waitForExistence(timeout: 3))
        tapDimple(of: notDone)
        XCTAssertTrue(done.waitForExistence(timeout: 3))

        // Rename from the context menu.
        done.press(forDuration: 1.2)
        let rename = app.buttons["Rename"]
        XCTAssertTrue(rename.waitForExistence(timeout: 3))
        snapshot("04 context menu")
        rename.tap()
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        XCTAssertEqual(name.value as? String, "Read")
        name.typeText(" 20 pages")
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Read 20 pages, done today"].waitForExistence(timeout: 3))

        // A second habit.
        app.navigationBars.buttons["Add Habit"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.typeText("Run")
        app.navigationBars.buttons["Done"].tap()
        let runTile = app.buttons["Run, not done today"]
        XCTAssertTrue(runTile.waitForExistence(timeout: 3))
        snapshot("05 two habits")

        // Log: cards in the order the habits were added, and no Edit button.
        app.tabBars.buttons["Log"].tap()
        let readCard = app.buttons["Read 20 pages"]
        let runCard = app.buttons["Run"]
        XCTAssertTrue(readCard.waitForExistence(timeout: 3))
        XCTAssertLessThan(readCard.frame.minY, runCard.frame.minY)
        XCTAssertFalse(app.navigationBars.buttons["Edit"].exists)
        snapshot("06 log")

        // Long-press a card and drag it above the other to reorder.
        runCard.press(forDuration: 1.0, thenDragTo: readCard)
        XCTAssertTrue(waitUntil(runCard.frame.minY < readCard.frame.minY), "Run was dragged above Read 20 pages")
        snapshot("07 log reordered")

        // The new order is shared with Check-In.
        app.tabBars.buttons["Check-In"].tap()
        let readTile = app.buttons["Read 20 pages, done today"]
        XCTAssertTrue(runTile.waitForExistence(timeout: 3))
        XCTAssertLessThan(runTile.frame.minX, readTile.frame.minX)
        app.tabBars.buttons["Log"].tap()

        // Detail: stats, then backfill yesterday — before the habit was created, which is allowed.
        readCard.tap()
        let current = app.otherElements["Current Streak"]
        XCTAssertTrue(current.waitForExistence(timeout: 3))
        XCTAssertEqual(current.value as? String, "1")
        XCTAssertEqual(app.otherElements["Total"].value as? String, "1")
        XCTAssertEqual(app.buttons[dayLabel(0)].value as? String, "Completed")
        XCTAssertFalse(app.buttons[dayLabel(1)].exists, "Future days can't be tapped")

        showMonth(containing: -1)
        let yesterday = app.buttons[dayLabel(-1)]
        XCTAssertEqual(yesterday.value as? String, "Not completed")
        yesterday.tap()
        XCTAssertEqual(yesterday.value as? String, "Completed")
        XCTAssertEqual(current.value as? String, "2")
        XCTAssertEqual(app.otherElements["Longest Streak"].value as? String, "2")
        XCTAssertEqual(app.otherElements["Total"].value as? String, "2")
        snapshot("08 detail after backfill")

        // Delete from the detail page.
        app.navigationBars.buttons["More"].tap()
        app.buttons["Delete"].tap()
        let confirm = app.buttons["Delete Habit"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        snapshot("09 delete confirmation")
        confirm.tap()
        XCTAssertTrue(runCard.waitForExistence(timeout: 3))
        XCTAssertFalse(readCard.exists)

        app.tabBars.buttons["Check-In"].tap()
        XCTAssertTrue(runTile.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Read 20 pages, done today"].exists)
    }

    func testDeleteFromCheckInAsksFirst() {
        launch()
        app.buttons["Add Habit"].firstMatch.tap()
        app.textFields["Name"].typeText("Stretch\n")
        let tile = app.buttons["Stretch, not done today"]
        XCTAssertTrue(tile.waitForExistence(timeout: 3))

        tile.press(forDuration: 1.2)
        app.buttons["Delete"].tap()
        let confirm = app.buttons["Delete Habit"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        XCTAssertTrue(tile.exists, "Nothing is deleted until confirmed")
        confirm.tap()
        XCTAssertTrue(app.staticTexts["No habits yet"].waitForExistence(timeout: 3))
    }

    func testCheckInOnAnotherDay() {
        launch()
        app.buttons["Add Habit"].firstMatch.tap()
        app.textFields["Name"].typeText("Read\n")
        let today = app.buttons["Read, not done today"]
        XCTAssertTrue(today.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Next Day"].isEnabled, "Can't go past today")

        // Back a day, check in there; today is untouched.
        app.buttons["Previous Day"].tap()
        XCTAssertTrue(app.buttons["Next Day"].isEnabled)
        let yesterday = app.buttons["Read, not done on \(tileDate(-1))"]
        XCTAssertTrue(yesterday.waitForExistence(timeout: 3))
        tapDimple(of: yesterday)
        XCTAssertTrue(app.buttons["Read, done on \(tileDate(-1))"].waitForExistence(timeout: 3))
        snapshot("check-in yesterday")

        app.buttons["Next Day"].tap()
        XCTAssertTrue(today.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Next Day"].isEnabled)
        snapshot("check-in today")
    }

    func testBackfillUpdatesStats() {
        launch("-EtchSeed", "1", "-EtchTab", "log", "-EtchOpenFirst")
        let total = app.otherElements["Total"]
        XCTAssertTrue(total.waitForExistence(timeout: 20))
        let before = Int(total.value as! String)!

        // Ten days ago, so the change can't touch today's tile on Check-In.
        // The page is pushed on launch; let it finish sliding in before tapping.
        XCTAssertTrue(waitUntil(app.navigationBars.buttons["More"].isHittable))
        showMonth(containing: -10)
        let dot = app.buttons[dayLabel(-10)]
        XCTAssertTrue(waitUntil(dot.isHittable))
        let wasDone = dot.value as? String == "Completed"
        dot.tap()
        XCTAssertTrue(waitUntil(dot.value as? String == (wasDone ? "Not completed" : "Completed")))
        XCTAssertEqual(Int(total.value as! String)!, before + (wasDone ? -1 : 1))
        snapshot("detail after backfill")

        dot.tap()
        XCTAssertTrue(waitUntil(Int(total.value as! String)! == before))
    }

    func testSeededScreens() {
        launch("-EtchSeed", "20")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ENDSWITH 'today'")).firstMatch.waitForExistence(timeout: 20))
        snapshot("seeded check-in")
        app.tabBars.buttons["Log"].tap()
        snapshot("seeded log")
        // Scroll the whole list: 20 habits with a year of history each.
        let list = app.collectionViews.firstMatch
        for _ in 0..<4 { list.swipeUp(velocity: .fast) }
        snapshot("seeded log bottom")
    }

    /// Step 8 of the plan: 20 habits with a year of data each must scroll smoothly on the Log page.
    /// Reports hitch time ratio; run on a device for numbers that mean something.
    func testLogScrollPerformance() {
        launch("-EtchSeed", "20", "-EtchTab", "log")
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 20))

        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            list.swipeUp(velocity: .fast)
            list.swipeDown(velocity: .fast)
        }
    }

    // MARK: Helpers

    /// The dimple sits in the lower part of the tile; the tile's center is just above it.
    private func tapDimple(of tile: XCUIElement) {
        tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.68)).tap()
    }

    /// Polls `condition` until it holds or `timeout` passes.
    private func waitUntil(timeout: TimeInterval = 5, _ condition: @autoclosure () -> Bool) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return true }
            RunLoop.current.run(until: .now.addingTimeInterval(0.1))
        }
        return condition()
    }

    /// Pages the detail calendar back to the month holding the day `offset` days from today.
    /// The calendar opens on this month.
    private func showMonth(containing offset: Int) {
        let calendar = Calendar.current
        let target = calendar.date(byAdding: .day, value: offset, to: .now)!
        let months = calendar.dateComponents([.month], from: calendar.dateInterval(of: .month, for: target)!.start,
                                             to: calendar.dateInterval(of: .month, for: .now)!.start).month!
        for _ in 0..<months {
            app.buttons["Previous Month"].tap()
        }
    }

    /// The VoiceOver label of a day in the detail calendar, `offset` days from today.
    private func dayLabel(_ offset: Int) -> String {
        Calendar.current.date(byAdding: .day, value: offset, to: .now)!
            .formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    /// How a Check-In tile names a day other than today, `offset` days from today.
    private func tileDate(_ offset: Int) -> String {
        Calendar.current.date(byAdding: .day, value: offset, to: .now)!
            .formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
