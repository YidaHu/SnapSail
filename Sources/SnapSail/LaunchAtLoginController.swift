import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

protocol LaunchAtLoginManaging: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func setEnabled(_ enabled: Bool) throws
}

protocol LaunchAtLoginServicing: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

enum LaunchAtLoginError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Launch at login requires macOS 13 or later."
    }
}

final class LaunchAtLoginController: LaunchAtLoginManaging {
    private let service: LaunchAtLoginServicing

    init(service: LaunchAtLoginServicing = SystemLaunchAtLoginService()) {
        self.service = service
    }

    var status: LaunchAtLoginStatus { service.status }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            switch service.status {
            case .enabled:
                return
            case .requiresApproval:
                service.openSystemSettings()
            case .disabled:
                try service.register()
                if service.status == .requiresApproval {
                    service.openSystemSettings()
                }
            case .unavailable:
                throw LaunchAtLoginError.unavailable
            }
        } else {
            switch service.status {
            case .disabled:
                return
            case .enabled, .requiresApproval:
                try service.unregister()
            case .unavailable:
                throw LaunchAtLoginError.unavailable
            }
        }
    }
}

#if compiler(>=5.8)
private final class SystemLaunchAtLoginService: LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus {
        guard #available(macOS 13.0, *) else { return .unavailable }
        switch SMAppService.mainApp.status {
        case .notRegistered, .notFound: return .disabled
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        @unknown default: return .unavailable
        }
    }

    func register() throws {
        guard #available(macOS 13.0, *) else { throw LaunchAtLoginError.unavailable }
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        guard #available(macOS 13.0, *) else { throw LaunchAtLoginError.unavailable }
        try SMAppService.mainApp.unregister()
    }

    func openSystemSettings() {
        guard #available(macOS 13.0, *) else { return }
        SMAppService.openSystemSettingsLoginItems()
    }
}
#else
private final class SystemLaunchAtLoginService: LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus { .unavailable }
    func register() throws { throw LaunchAtLoginError.unavailable }
    func unregister() throws { throw LaunchAtLoginError.unavailable }
    func openSystemSettings() {}
}
#endif
