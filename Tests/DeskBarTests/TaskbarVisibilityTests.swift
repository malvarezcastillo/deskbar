import AppKit
import Testing
@testable import DeskBar

@MainActor
struct TaskbarVisibilityTests {
    @Test
    func onlyIntentionalDownwardVerticalScrollsHideTheBar() {
        #expect(TaskbarVisibilityController.isHideScroll(deltaX: 0, deltaY: -10, isMomentum: false))
        #expect(!TaskbarVisibilityController.isHideScroll(deltaX: 0, deltaY: 10, isMomentum: false))
        #expect(!TaskbarVisibilityController.isHideScroll(deltaX: 10, deltaY: -1, isMomentum: false))
        #expect(!TaskbarVisibilityController.isHideScroll(deltaX: 0, deltaY: -10, isMomentum: true))
        #expect(!TaskbarVisibilityController.isHideScroll(deltaX: 0, deltaY: 0, isMomentum: false))
    }

    @Test
    func refreshesDoNotUndoManualDismissalAndShowRestoresIt() throws {
        let panel = try makePanel()
        defer { panel.orderOut(nil) }
        let visibility = TaskbarVisibilityController(panel: panel)
        visibility.setAvailable(true)
        #expect(panel.isVisible)
        visibility.hide()
        visibility.setAvailable(true)
        #expect(visibility.isManuallyHidden)
        #expect(!panel.isVisible)
        visibility.show()
        #expect(!visibility.isManuallyHidden)
        #expect(panel.isVisible)
    }

    @Test
    func fullScreenSuppressionTakesPriorityOverManualShow() throws {
        let panel = try makePanel()
        defer { panel.orderOut(nil) }
        let visibility = TaskbarVisibilityController(panel: panel)
        visibility.setAvailable(true)
        visibility.hide()
        visibility.setAvailable(false)
        visibility.show()
        #expect(!visibility.isManuallyHidden)
        #expect(!panel.isVisible)
        visibility.setAvailable(true)
        #expect(panel.isVisible)
    }

    @Test
    func hidingOnePanelDoesNotDismissAnother() throws {
        let first = try makePanel()
        let second = try makePanel()
        defer { first.orderOut(nil); second.orderOut(nil) }
        let firstVisibility = TaskbarVisibilityController(panel: first)
        let secondVisibility = TaskbarVisibilityController(panel: second)
        firstVisibility.setAvailable(true)
        secondVisibility.setAvailable(true)
        firstVisibility.hide()
        #expect(!first.isVisible)
        #expect(second.isVisible)
        #expect(!secondVisibility.isManuallyHidden)
    }

    @Test
    func pointerAlreadyOnTheEdgeMustLeaveBeforeRevealing() throws {
        let view = TaskbarRevealView()
        var reveals = 0
        view.reveal = { reveals += 1 }
        let event = try #require(NSEvent.enterExitEvent(
            with: .mouseEntered, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, eventNumber: 0, trackingNumber: 0, userData: nil
        ))
        view.arm(pointerIsInside: true)
        view.mouseEntered(with: event)
        #expect(reveals == 0)
        view.mouseExited(with: event)
        view.mouseEntered(with: event)
        #expect(reveals == 1)
        view.arm(pointerIsInside: false)
        view.mouseEntered(with: event)
        #expect(reveals == 2)
        #expect(view.accessibilityPerformPress())
        #expect(reveals == 3)
    }

    private func makePanel() throws -> TaskbarPanel {
        let screen = try #require(NSScreen.screens.first)
        let suite = "com.deskbar.tests.visibility.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        return TaskbarPanel(permissionsManager: PermissionsManager(),
                            settings: TaskbarSettings(defaults: defaults), screen: screen)
    }
}
