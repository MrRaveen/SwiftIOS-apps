import SwiftUI

struct HomeView: View {
    @State private var showSettings = false

    // Best scores shown on the mode cards
    @AppStorage(GameMode.tapFrenzy.bestScoreKey) private var tapFrenzyBest = 0
    @AppStorage(GameMode.lightItUp.bestScoreKey) private var lightItUpBest = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GameBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    logo
                    modeCard(.tapFrenzy, best: tapFrenzyBest)
                    modeCard(.lightItUp, best: lightItUpBest)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 30)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }

            settingsButton
        }
        // Home has no navigation bar. The game screens show one with a Back button.
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: Pieces

    private var logo: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Constants.accentsBlue, Constants.neonViolet],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .neonGlow(Constants.accentsBlue, radius: 18)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.white)
            }

            Text("TAP FRENZY")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(LinearGradient(colors: [Color.white, Constants.neonCyan],
                                                startPoint: .top, endPoint: .bottom))

            Text("Choose your game")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))
        }
        .padding(.bottom, 8)
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Constants.panel))
                .overlay(Circle().strokeBorder(Constants.panelStroke, lineWidth: 1.5))
        }
        .padding(.trailing, 20)
        .padding(.top, 8)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settingsButton")
    }

    // A big NavigationLink card. It pushes the game screen of that mode.
    private func modeCard(_ mode: GameMode, best: Int) -> some View {
        NavigationLink {
            destination(for: mode)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(mode.accent.opacity(0.25))
                    Image(systemName: mode.icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(mode.accent)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(mode.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    Text("BEST")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(Color.white.opacity(0.55))
                    Text("\(best)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(mode.accent)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [mode.accent.opacity(0.30), mode.accent.opacity(0.06)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(mode.accent.opacity(0.75), lineWidth: 2)
            )
            .neonGlow(mode.accent.opacity(0.6), radius: 12)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityIdentifier(mode == .tapFrenzy ? "tapFrenzyModeButton" : "lightItUpModeButton")
    }

    @ViewBuilder
    private func destination(for mode: GameMode) -> some View {
        switch mode {
        case .tapFrenzy: GameView()
        case .lightItUp: LightItUpView()
        }
    }
}

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
}