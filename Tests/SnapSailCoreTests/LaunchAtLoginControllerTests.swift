import XCTest
@testable import SnapSail

final class LaunchAtLoginControllerTests: XCTestCase {
    func testEnablingRegistersDisabledService() throws {
        let service = FakeLaunchAtLoginService(status: .disabled)
        let controller = LaunchAtLoginController(service: service)

        try controller.setEnabled(true)

        XCTAssertEqual(service.registerCount, 1)
        XCTAssertEqual(service.unregisterCount, 0)
    }

    func testDisablingUnregistersEnabledService() throws {
        let service = FakeLaunchAtLoginService(status: .enabled)
        let controller = LaunchAtLoginController(service: service)

        try controller.setEnabled(false)

        XCTAssertEqual(service.unregisterCount, 1)
        XCTAssertEqual(service.registerCount, 0)
    }

    func testApprovalStateOpensSystemSettingsWithoutRegisteringAgain() throws {
        let service = FakeLaunchAtLoginService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)

        try controller.setEnabled(true)

        XCTAssertEqual(service.openSettingsCount, 1)
        XCTAssertEqual(service.registerCount, 0)
    }

    func testUnavailableServiceRejectsChanges() {
        let service = FakeLaunchAtLoginService(status: .unavailable)
        let controller = LaunchAtLoginController(service: service)

        XCTAssertThrowsError(try controller.setEnabled(true))
        XCTAssertEqual(service.registerCount, 0)
    }
}

private final class FakeLaunchAtLoginService: LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus
    var registerCount = 0
    var unregisterCount = 0
    var openSettingsCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        status = .disabled
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}
