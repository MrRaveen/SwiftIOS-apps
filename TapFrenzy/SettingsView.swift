import SwiftUI

// Sheet opened from the Home screen. Picks the round length for Light It Up.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(RoundLength.storageKey) private var roundLengthRaw = RoundLength.normal.rawValue

    var body: some View {
        ZStack {
            GameBackground(glow: Constants.neonViolet)

            VStack(spacing: 20) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.neonCyan)
                        .accessibilityIdentifier("settingsDoneButton")
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("ROUND LENGTH")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundColor(Color.white.opacity(0.55))

                    HStack(spacing: 12) {
                        ForEach(RoundLength.allCases) { option in
                            chip(option)
                        }
                    }

                    Text("Applies to Light It Up. Each of the 4 levels takes a quarter of the round, so a longer round means longer levels. Tap Frenzy always lasts 10 seconds.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .padding(18)
                .glassPanel()

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .presentationDetents([.medium])
    }

    private func chip(_ option: RoundLength) -> some View {
        let selected = option == RoundLength.from(stored: roundLengthRaw)

        return Button {
            roundLengthRaw = option.rawValue
            Haptics.tap()
        } label: {
            VStack(spacing: 2) {
                Text("\(option.rawValue)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text("seconds")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selected ? Color.white : Color.white.opacity(0.6))
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Constants.neonViolet.opacity(0.45) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? Constants.neonViolet : Constants.panelStroke,
                                  lineWidth: selected ? 2.5 : 1.5)
            )
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityIdentifier("roundLength\(option.rawValue)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    SettingsView()
}