import AppKit
import XCTest
@testable import SnapSail

final class LaunchAtLoginSettingsTests: XCTestCase {
    func testGeneralSettingsExposeLaunchAtLoginCheckbox() throws {
        let suiteName = "LaunchAtLoginSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let launchAtLogin = StubLaunchAtLoginManager(status: .disabled)
        let controller = SettingsWindowController(
            preferences: AppPreferences(defaults: defaults),
            launchAtLogin: launchAtLogin
        )
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let button = try XCTUnwrap(allSubviews(of: contentView).compactMap { $0 as? NSButton }.first {
            $0.identifier?.rawValue == "settings.launchAtLogin"
        })

        XCTAssertFalse(button.title.isEmpty)
        XCTAssertTrue(button.isEnabled)
        XCTAssertEqual(button.state, .off)
    }

    func testClickingLaunchAtLoginCheckboxUpdatesSystemControllerAndReloadsState() throws {
        let suiteName = "LaunchAtLoginSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let launchAtLogin = StubLaunchAtLoginManager(status: .disabled)
        let controller = SettingsWindowController(
            preferences: AppPreferences(defaults: defaults),
            launchAtLogin: launchAtLogin
        )
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let button = try XCTUnwrap(allSubviews(of: contentView).compactMap { $0 as? NSButton }.first {
            $0.identifier?.rawValue == "settings.launchAtLogin"
        })

        button.performClick(nil)

        XCTAssertEqual(launchAtLogin.status, .enabled)
        XCTAssertEqual(button.state, .on)
    }

    private func allSubviews(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap(allSubviews)
    }
}

private final class StubLaunchAtLoginManager: LaunchAtLoginManaging {
    var status: LaunchAtLoginStatus

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func setEnabled(_ enabled: Bool) throws {
        status = enabled ? .enabled : .disabled
    }
}
