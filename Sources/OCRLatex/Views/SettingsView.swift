import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PreferencesPanelView(model: model)
        }
        .padding(24)
    }
}
