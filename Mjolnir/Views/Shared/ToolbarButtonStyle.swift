import SwiftUI

struct ToolbarButtonStyle: ButtonStyle {
    var flexible: Bool = false
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: flexible ? nil : 28, height: 28)
            .padding(.horizontal, flexible ? 8 : 0)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .onHover { isHovered = $0 }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed {
            return Color.primary.opacity(0.12)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Sidebar Row Hover Style

struct SidebarRowModifier: ViewModifier {
    var isSelected: Bool = false
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .textBackgroundColor))
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}

extension View {
    func sidebarRow(isSelected: Bool = false) -> some View {
        modifier(SidebarRowModifier(isSelected: isSelected))
    }
}
