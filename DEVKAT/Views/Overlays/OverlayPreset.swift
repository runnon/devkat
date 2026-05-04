import SwiftUI

enum OverlayPreset: String, CaseIterable, Identifiable {
    case single

    var id: String { rawValue }

    @ViewBuilder
    func view(for slot: StatSlot,
              showChevron: Bool = false,
              onChevronTap: (() -> Void)? = nil) -> some View {
        AuraOverlay(
            slot: slot,
            showChevron: showChevron,
            onChevronTap: onChevronTap
        )
    }
}
