//
//  TimeAwareSkyBackground.swift
//  MeshiTero
//
//  Created by Codex on 2026/06/10.
//

import SwiftUI
import UIKit

private struct SkyTheme {
    let hour: Double
    let top: UIColor
    let middle: UIColor
    let bottom: UIColor
    let glow: UIColor
}

enum TimeAwareSkyStyle {
    static func titleColor(for date: Date) -> Color {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<18:
            return Color.black.opacity(0.82)
        case 18..<20:
            return Color.white.opacity(0.92)
        default:
            return .white
        }
    }

    static func navigationBarColorScheme(for date: Date) -> ColorScheme {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<18:
            return .light
        default:
            return .dark
        }
    }
}

struct TimeAwareSkyBackground: View {
    private let themes: [SkyTheme] = [
        SkyTheme(
            hour: 0,
            top: UIColor(red: 0.04, green: 0.08, blue: 0.18, alpha: 1),
            middle: UIColor(red: 0.08, green: 0.11, blue: 0.23, alpha: 1),
            bottom: UIColor(red: 0.14, green: 0.12, blue: 0.20, alpha: 1),
            glow: UIColor(red: 0.34, green: 0.43, blue: 0.75, alpha: 1)
        ),
        SkyTheme(
            hour: 5,
            top: UIColor(red: 0.12, green: 0.18, blue: 0.34, alpha: 1),
            middle: UIColor(red: 0.31, green: 0.39, blue: 0.60, alpha: 1),
            bottom: UIColor(red: 0.79, green: 0.55, blue: 0.42, alpha: 1),
            glow: UIColor(red: 1.00, green: 0.76, blue: 0.55, alpha: 1)
        ),
        SkyTheme(
            hour: 8,
            top: UIColor(red: 0.23, green: 0.56, blue: 0.93, alpha: 1),
            middle: UIColor(red: 0.48, green: 0.73, blue: 0.98, alpha: 1),
            bottom: UIColor(red: 0.80, green: 0.90, blue: 1.00, alpha: 1),
            glow: UIColor(red: 1.00, green: 0.93, blue: 0.70, alpha: 1)
        ),
        SkyTheme(
            hour: 13,
            top: UIColor(red: 0.18, green: 0.50, blue: 0.88, alpha: 1),
            middle: UIColor(red: 0.44, green: 0.75, blue: 0.98, alpha: 1),
            bottom: UIColor(red: 0.83, green: 0.94, blue: 1.00, alpha: 1),
            glow: UIColor(red: 1.00, green: 0.95, blue: 0.78, alpha: 1)
        ),
        SkyTheme(
            hour: 17,
            top: UIColor(red: 0.20, green: 0.34, blue: 0.70, alpha: 1),
            middle: UIColor(red: 0.79, green: 0.49, blue: 0.52, alpha: 1),
            bottom: UIColor(red: 0.98, green: 0.71, blue: 0.47, alpha: 1),
            glow: UIColor(red: 1.00, green: 0.78, blue: 0.58, alpha: 1)
        ),
        SkyTheme(
            hour: 19,
            top: UIColor(red: 0.09, green: 0.15, blue: 0.34, alpha: 1),
            middle: UIColor(red: 0.34, green: 0.21, blue: 0.42, alpha: 1),
            bottom: UIColor(red: 0.63, green: 0.34, blue: 0.32, alpha: 1),
            glow: UIColor(red: 0.98, green: 0.69, blue: 0.44, alpha: 1)
        ),
        SkyTheme(
            hour: 22,
            top: UIColor(red: 0.03, green: 0.06, blue: 0.14, alpha: 1),
            middle: UIColor(red: 0.06, green: 0.09, blue: 0.19, alpha: 1),
            bottom: UIColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 1),
            glow: UIColor(red: 0.38, green: 0.42, blue: 0.72, alpha: 1)
        ),
        SkyTheme(
            hour: 24,
            top: UIColor(red: 0.04, green: 0.08, blue: 0.18, alpha: 1),
            middle: UIColor(red: 0.08, green: 0.11, blue: 0.23, alpha: 1),
            bottom: UIColor(red: 0.14, green: 0.12, blue: 0.20, alpha: 1),
            glow: UIColor(red: 0.34, green: 0.43, blue: 0.75, alpha: 1)
        )
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 300)) { context in
            let theme = interpolatedTheme(for: context.date)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(theme.top),
                        Color(theme.middle),
                        Color(theme.bottom)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(Color(theme.glow).opacity(0.55))
                    .frame(width: 240, height: 240)
                    .blur(radius: 28)
                    .offset(x: 130, y: -240)

                LinearGradient(
                    colors: [
                        .white.opacity(0.14),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        }
    }

    private func interpolatedTheme(for date: Date) -> SkyTheme {
        let hour = Double(Calendar.current.component(.hour, from: date))
        let minute = Double(Calendar.current.component(.minute, from: date))
        let currentHour = hour + minute / 60

        guard let upperIndex = themes.firstIndex(where: { currentHour <= $0.hour }),
              upperIndex > 0 else {
            return themes[0]
        }

        let lower = themes[upperIndex - 1]
        let upper = themes[upperIndex]
        let progress = (currentHour - lower.hour) / (upper.hour - lower.hour)

        return SkyTheme(
            hour: currentHour,
            top: mix(lower.top, upper.top, progress),
            middle: mix(lower.middle, upper.middle, progress),
            bottom: mix(lower.bottom, upper.bottom, progress),
            glow: mix(lower.glow, upper.glow, progress)
        )
    }

    private func mix(_ first: UIColor, _ second: UIColor, _ progress: Double) -> UIColor {
        var firstRed: CGFloat = 0
        var firstGreen: CGFloat = 0
        var firstBlue: CGFloat = 0
        var firstAlpha: CGFloat = 0
        var secondRed: CGFloat = 0
        var secondGreen: CGFloat = 0
        var secondBlue: CGFloat = 0
        var secondAlpha: CGFloat = 0

        first.getRed(&firstRed, green: &firstGreen, blue: &firstBlue, alpha: &firstAlpha)
        second.getRed(&secondRed, green: &secondGreen, blue: &secondBlue, alpha: &secondAlpha)

        let rate = CGFloat(progress)

        return UIColor(
            red: firstRed + (secondRed - firstRed) * rate,
            green: firstGreen + (secondGreen - firstGreen) * rate,
            blue: firstBlue + (secondBlue - firstBlue) * rate,
            alpha: firstAlpha + (secondAlpha - firstAlpha) * rate
        )
    }
}
