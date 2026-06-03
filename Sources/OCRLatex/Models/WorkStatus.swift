import Foundation

enum WorkStatus: Equatable {
    case idle
    case checkingPermission
    case waitingForSelection
    case recognizing
    case callingLargeModel
    case awaitingAcceptance
    case copied
    case ready
    case cancelled
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            "待命"
        case .checkingPermission:
            "检查权限"
        case .waitingForSelection:
            "等待选择区域"
        case .recognizing:
            "正在识别"
        case .callingLargeModel:
            "调用大模型"
        case .awaitingAcceptance:
            "等待确认"
        case .copied:
            "已复制"
        case .ready:
            "已完成"
        case .cancelled:
            "已取消"
        case .failed:
            "失败"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "后台运行中"
        case .checkingPermission:
            "屏幕截取权限"
        case .waitingForSelection:
            "区域选择中"
        case .recognizing:
            "本机识别中"
        case .callingLargeModel:
            "远程识别中"
        case .awaitingAcceptance:
            "候选结果已生成"
        case .copied:
            "剪贴板已更新"
        case .ready:
            "结果已生成"
        case .cancelled:
            "操作取消"
        case .failed(let message):
            message
        }
    }

    var systemImageName: String {
        switch self {
        case .idle:
            "circle.dotted"
        case .checkingPermission:
            "lock.shield"
        case .waitingForSelection:
            "viewfinder"
        case .recognizing:
            "text.viewfinder"
        case .callingLargeModel:
            "sparkles"
        case .awaitingAcceptance:
            "checkmark.rectangle.stack"
        case .copied:
            "checkmark.circle.fill"
        case .ready:
            "doc.on.clipboard"
        case .cancelled:
            "xmark.circle"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }
}
