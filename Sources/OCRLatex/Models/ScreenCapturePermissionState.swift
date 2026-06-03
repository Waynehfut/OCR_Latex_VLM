import Foundation

enum ScreenCapturePermissionState: Equatable {
    case unknown
    case authorized
    case missing

    var title: String {
        switch self {
        case .unknown:
            "权限未检查"
        case .authorized:
            "截图权限正常"
        case .missing:
            "需要截图权限"
        }
    }

    var systemImageName: String {
        switch self {
        case .unknown:
            "questionmark.circle"
        case .authorized:
            "checkmark.shield"
        case .missing:
            "lock.trianglebadge.exclamationmark"
        }
    }
}
