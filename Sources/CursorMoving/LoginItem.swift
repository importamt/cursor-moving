import ServiceManagement

/// 로그인 시 자동 실행 (SMAppService, macOS 13+)
enum LoginItem {
    /// 사용자가 시스템 설정에서 승인해야 하는 상태도 켜짐으로 본다
    static var isEnabled: Bool {
        [.enabled, .requiresApproval].contains(SMAppService.mainApp.status)
    }

    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
