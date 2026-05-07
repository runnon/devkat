import SwiftUI

struct AcidOverlay: View {
    let session: Session
    var export: Bool = false

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: session.startedAt).uppercased()
    }

    private var stats: [(String)] {
        let duration = SessionFormatting.duration(session.activeDuration)
        let volume = "\(session.linesAdded + session.linesRemoved) LINES"
        let pace = "\(session.linesPerHour) LINES/HR"
        let scope = "\(session.filesTouched) FILES"
        let burn = session.tokens > 0 ? "\(SessionFormatting.tokens(session.tokens)) TOKENS" : ""

        var lines = [dateString, duration, volume, pace, scope]
        if !burn.isEmpty { lines.append(burn) }
        return lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(stats, id: \.self) { line in
                Text(line)
                    .font(.custom("AcidTM-Regular", size: 22))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(export ? Color.clear : Theme.surface)
    }
}

#Preview {
    let session = Session(
        id: "preview",
        startedAt: Date().addingTimeInterval(-8040),
        endedAt: Date(),
        activeDuration: 8040,
        linesAdded: 842, linesRemoved: 137,
        filesTouched: 12, tokens: 18_400,
        sources: ["claude"],
        models: ["claude-opus-4-5"],
        repoAlias: "devkat", gitBranch: "main"
    )
    AcidOverlay(session: session)
        .aspectRatio(1.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding()
        .background(Color.black)
}
