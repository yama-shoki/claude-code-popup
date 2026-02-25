import AppKit
import SwiftUI

// MARK: - Risk Level

enum RiskLevel: String {
    case safe, low, medium, high, critical

    var color: Color {
        switch self {
        case .safe: return .green
        case .low: return .blue
        case .medium: return .orange
        case .high: return Color(red: 1.0, green: 0.23, blue: 0.19)
        case .critical: return Color(red: 1.0, green: 0.18, blue: 0.33)
        }
    }

    var japaneseName: String {
        switch self {
        case .safe: return "安全"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "危険"
        }
    }

    var dotCount: Int {
        switch self {
        case .safe: return 1
        case .low: return 2
        case .medium: return 3
        case .high: return 4
        case .critical: return 5
        }
    }

    var headerIcon: String {
        switch self {
        case .safe, .low, .medium: return "shield.checkered"
        case .high, .critical: return "exclamationmark.triangle.fill"
        }
    }

    var showSessionAllow: Bool {
        switch self {
        case .safe, .low, .medium: return true
        case .high, .critical: return false
        }
    }
}

// MARK: - Tool Info

struct ToolInfo {
    let name: String
    let command: String
    let risk: RiskLevel
    let explanation: String
    let impact: String
    let timeout: Int

    var icon: String {
        switch name {
        case "Bash": return "terminal.fill"
        case "Edit", "MultiEdit": return "pencil.line"
        case "Write": return "doc.badge.plus"
        case "Read": return "doc.text"
        case "WebFetch": return "globe"
        case "WebSearch": return "magnifyingglass"
        case "Task": return "person.2.fill"
        default:
            if name.hasPrefix("mcp__") { return "puzzlepiece.fill" }
            return "gear"
        }
    }

    /// Truncate command to a reasonable display length
    var displayCommand: String {
        if command.count > 500 {
            return String(command.prefix(500)) + "..."
        }
        return command
    }
}

// MARK: - Permission View

struct PermissionView: View {
    let tool: ToolInfo
    let onAllow: () -> Void
    let onAlwaysAllow: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top accent line
            Rectangle()
                .fill(tool.risk.color.gradient)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 0) {
                // Header (fixed)
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 24)

                // Scrollable content area
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        toolRiskSection
                        commandBlock
                        explanationSection

                        if !tool.impact.isEmpty {
                            impactSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 400)

                // Footer (fixed)
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 24)

                    buttonSection
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
            }
        }
        .frame(width: 480)
        .background(VisualEffectView())
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.risk.headerIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(tool.risk.color)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 2) {
                Text("権限リクエスト")
                    .font(.system(size: 16, weight: .semibold))
                Text("Claude Code")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Tool & Risk

    private var toolRiskSection: some View {
        HStack(spacing: 20) {
            Label {
                Text(tool.name)
                    .font(.system(size: 14, weight: .medium))
            } icon: {
                Image(systemName: tool.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < tool.risk.dotCount ? tool.risk.color : Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                Text(tool.risk.japaneseName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tool.risk.color)
            }
        }
    }

    // MARK: - Command Block

    private var commandBlock: some View {
        Text(tool.displayCommand)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.primary)
            .lineLimit(12)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor).opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .textSelection(.enabled)
    }

    // MARK: - Explanation

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("説明")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Text(tool.explanation)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
    }

    // MARK: - Impact

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("影響範囲")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "scope")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Text(tool.impact)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        HStack(spacing: 8) {
            Button(action: onDeny) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                    Text("拒否")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)

            Button(action: onAllow) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text("許可")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            if tool.risk.showSessionAllow {
                Button(action: onAlwaysAllow) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 13))
                        Text("このセッション中は許可")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
    }
}

// MARK: - Visual Effect (Vibrancy)

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel?
    var result: String = "deny"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let tool = parseArgs()

        let contentView = PermissionView(
            tool: tool,
            onAllow: { [weak self] in
                self?.result = "allow"
                NSApplication.shared.stopModal(withCode: .OK)
            },
            onAlwaysAllow: { [weak self] in
                self?.result = "always_allow"
                NSApplication.shared.stopModal(withCode: .OK)
            },
            onDeny: { [weak self] in
                self?.result = "deny"
                NSApplication.shared.stopModal(withCode: .cancel)
            }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panelSize = hostingView.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.titled, .closable, .hudWindow, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.title = "Claude Code"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()

        // Position slightly above center
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY + 50
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = panel

        // Play notification sound
        let soundName = (tool.risk == .high || tool.risk == .critical) ? "Basso" : "Glass"
        NSSound(named: NSSound.Name(soundName))?.play()

        panel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Timeout: auto-deny
        let timeoutSec = Double(tool.timeout)
        let timer = Timer.scheduledTimer(withTimeInterval: timeoutSec, repeats: false) { _ in
            NSApplication.shared.stopModal(withCode: .cancel)
        }

        NSApplication.shared.runModal(for: panel)
        timer.invalidate()
        panel.close()

        print(result)
        NSApplication.shared.terminate(nil)
    }

    func parseArgs() -> ToolInfo {
        let args = CommandLine.arguments
        var toolName = "Bash"
        var command = ""
        var risk = "medium"
        var explanation = "コマンドを実行します"
        var impact = ""
        var timeout = 120

        var i = 1
        while i < args.count {
            switch args[i] {
            case "--tool":
                i += 1; if i < args.count { toolName = args[i] }
            case "--command":
                i += 1; if i < args.count { command = args[i] }
            case "--risk":
                i += 1; if i < args.count { risk = args[i] }
            case "--explanation":
                i += 1; if i < args.count { explanation = args[i] }
            case "--impact":
                i += 1; if i < args.count { impact = args[i] }
            case "--timeout":
                i += 1; if i < args.count { timeout = Int(args[i]) ?? 120 }
            default: break
            }
            i += 1
        }

        return ToolInfo(
            name: toolName,
            command: command,
            risk: RiskLevel(rawValue: risk) ?? .medium,
            explanation: explanation,
            impact: impact,
            timeout: timeout
        )
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
