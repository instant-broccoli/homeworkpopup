import SwiftUI
import AppKit
import Combine
import QuartzCore

@main
struct HomeworkAddon: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class HomeworkPanelState: ObservableObject {
    @Published var isOpen: Bool

    init(isOpen: Bool = false) {
        self.isOpen = isOpen
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: EdgePanelController?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        panelController = EdgePanelController()
        panelController?.show()
    }
}

final class EdgePanelController {
    private let collapsedWidth: CGFloat = 48
    private let openWidth: CGFloat = 380
    private let panelHeight: CGFloat = 520

    private let state = HomeworkPanelState()
    private let panel: FloatingPanel

    init() {
        panel = FloatingPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        panel.contentView = NSHostingView(
            rootView: EdgePanelView(
                state: state,
                toggle: { [weak self] in
                    self?.togglePanel()
                }
            )
        )

        setPanelFrame(width: collapsedWidth)
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private func togglePanel() {
        state.isOpen.toggle()

        let newWidth = state.isOpen
            ? openWidth
            : collapsedWidth

        let newFrame = frame(width: newWidth)

        NSAnimationContext.runAnimationGroup { animation in
            animation.duration = 0.25
            animation.timingFunction = CAMediaTimingFunction(
                name: .easeInEaseOut
            )

            panel.animator().setFrame(
                newFrame,
                display: true
            )
        }

        if state.isOpen {
            NSApplication.shared.activate(
                ignoringOtherApps: true
            )
            panel.makeKey()
        }
    }

    private func setPanelFrame(width: CGFloat) {
        panel.setFrame(
            frame(width: width),
            display: true
        )
    }

    private func frame(width: CGFloat) -> NSRect {
        guard let screen =
            NSScreen.main ?? NSScreen.screens.first
        else {
            return .zero
        }

        let screenFrame = screen.visibleFrame

        return NSRect(
            x: screenFrame.maxX - width,
            y: screenFrame.midY - panelHeight / 2,
            width: width,
            height: panelHeight
        )
    }
}

struct EdgePanelView: View {
    @ObservedObject var state: HomeworkPanelState
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Spacer()

                Button(action: toggle) {
                    Image(
                        systemName: state.isOpen
                            ? "chevron.right"
                            : "checklist"
                    )
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 90)
                    .background(Color.indigo)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(width: 48)

            if state.isOpen {
                HomeworkView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16
            )
        )
    }
}
