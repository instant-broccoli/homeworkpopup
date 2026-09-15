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
    @Published var isOpen = false
    @Published var isHandleVisible = false
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
        NSApplication.shared.setActivationPolicy(.accessory)

        panelController = EdgePanelController()
        panelController?.show()
    }
}

final class EdgePanelController {
    private let buttonWidth: CGFloat = 48
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

        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .canJoinAllApplications,
            .stationary
        ]

        panel.contentView = NSHostingView(
            rootView: EdgePanelView(
                state: state,
                toggle: { [weak self] in
                    self?.togglePanel()
                },
                hoverChanged: { [weak self] hovering in
                    self?.handleHover(hovering)
                }
            )
        )

        panel.setFrame(
            frame(width: buttonWidth),
            display: true
        )
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private func handleHover(_ hovering: Bool) {
        guard !state.isOpen else {
            return
        }

        state.isHandleVisible = hovering
    }

    private func togglePanel() {
        state.isOpen.toggle()

        if state.isOpen {
            state.isHandleVisible = true
            animatePanel(to: openWidth)

            NSApplication.shared.activate(
                ignoringOtherApps: true
            )
            panel.makeKey()
        } else {
            animatePanel(to: buttonWidth)
        }
    }

    private func animatePanel(to width: CGFloat) {
        let newFrame = frame(width: width)

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
    let hoverChanged: (Bool) -> Void

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
                .opacity(
                    state.isOpen || state.isHandleVisible
                        ? 1
                        : 0
                )
                .offset(
                    x: state.isOpen || state.isHandleVisible
                        ? 0
                        : 48
                )
                .animation(
                    .easeInOut(duration: 0.2),
                    value: state.isHandleVisible
                )

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
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16
            )
        )
        .onHover { hovering in
            hoverChanged(hovering)
        }
    }
}
