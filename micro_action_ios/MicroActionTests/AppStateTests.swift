import XCTest
@testable import MicroActionApp

@MainActor
final class AppStateTests: XCTestCase {
    private func makeTestState() -> AppState {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("micro_action_test_\(UUID().uuidString).json")
        return AppState(store: LocalStoreService(customURL: tempURL), preloadNetwork: false)
    }

    func testMultiLevelSubPlansAutoPromoteAndCascadeComplete() async {
        let state = makeTestState()
        let root = state.addPlan(name: "准备全面体检")!
        let sub1 = state.addSubPlan(parentId: root.id, name: "对比三家体检套餐")!
        let sub2 = state.addSubPlan(parentId: root.id, name: "预约周六上午体检")!

        // 子任务应自动前置到首页最上方，且保持录入正序
        let ordered = state.ongoingPlans
        XCTAssertEqual(ordered.first?.id, sub1.id)
        XCTAssertEqual(ordered[1].id, sub2.id)
        XCTAssertEqual(ordered.last?.id, root.id)
        XCTAssertEqual(sub1.groupColorIndex, sub2.groupColorIndex)

        // 完成父任务应级联完成全部未完成子任务并触发庆祝
        await state.togglePlanStatus(id: root.id)
        XCTAssertTrue(state.ongoingPlans.isEmpty)
        XCTAssertEqual(state.completedPlans.count, 3)
        XCTAssertEqual(state.shineRecords.count, 1)
        XCTAssertNotNil(state.activeCelebration)
    }

    func testRainbowAndColdJokeRatioControl() async {
        let state = makeTestState()

        // 100% 彩虹屁
        state.setRainbowRatio(100)
        for _ in 0..<15 {
            let quote = await state.pickNextCelebrationQuote()
            XCTAssertFalse(CelebrationLibrary.coldJokes.contains(quote))
        }

        // 0% 彩虹屁（100% 冷笑话）
        state.setRainbowRatio(0)
        for _ in 0..<15 {
            let quote = await state.pickNextCelebrationQuote()
            XCTAssertTrue(CelebrationLibrary.coldJokes.contains(quote))
        }
    }

    func testBackupExportAndImportPreservesProPreferences() throws {
        let state = makeTestState()
        state.addPlan(name: "阅读一页书")
        state.addHabit(name: "早睡")
        state.setRainbowRatio(65)
        state.setAiPersona(.domineeringCeo)
        state.setThemeSkin(.auroraNight)
        state.setSoundPack(.royalChord)

        let json = try state.exportBackupJSON()
        let restored = makeTestState()
        try restored.importBackupJSON(json)

        XCTAssertEqual(restored.plans.count, 1)
        XCTAssertEqual(restored.habits.count, 1)
        XCTAssertEqual(restored.rainbowRatio, 65)
        XCTAssertEqual(restored.aiPersona, .domineeringCeo)
        XCTAssertEqual(restored.themeSkin, .auroraNight)
        XCTAssertEqual(restored.soundPack, .royalChord)
    }

    func testHabitPinAndStopStatusTransitions() {
        let state = makeTestState()
        let first = state.addHabit(name: "喝一杯温水")!
        let second = state.addHabit(name: "读一页书")!

        // 置顶第一条习惯后应排在 activeHabits 首位
        state.togglePinHabit(id: first.id)
        XCTAssertEqual(state.activeHabits.first?.id, first.id)
        XCTAssertEqual(state.activeHabits.count, 2)
        XCTAssertTrue(state.stoppedHabits.isEmpty)

        // 停用第二条习惯后应迁移至 stoppedHabits
        state.toggleHabitStatus(id: second.id)
        XCTAssertEqual(state.activeHabits.count, 1)
        XCTAssertEqual(state.stoppedHabits.count, 1)
        XCTAssertEqual(state.stoppedHabits.first?.id, second.id)

        // 再次切换应恢复为进行中
        state.toggleHabitStatus(id: second.id)
        XCTAssertEqual(state.activeHabits.count, 2)
        XCTAssertTrue(state.stoppedHabits.isEmpty)
    }

    func testHabitLegacyJSONDecodeCompatibility() throws {
        let legacyJSON = """
        {"id":"h1","name":"早睡","status":"进行中","createTime":1700000000000,"totalDays":3,"completionHistory":[1700000000000]}
        """
        let decoded = try JSONDecoder().decode(HabitItem.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.id, "h1")
        XCTAssertEqual(decoded.name, "早睡")
        XCTAssertEqual(decoded.totalDays, 3)
        XCTAssertFalse(decoded.isPinned)
    }
}
