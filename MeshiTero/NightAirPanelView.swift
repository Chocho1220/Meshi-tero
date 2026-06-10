//
//  NightAirPanelView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/27.
//

import SwiftUI

struct NightAirPanelView: View {
    private var recommendedCategory: String {
        let weekday = Calendar.current.component(.weekday, from: Date())

        switch weekday {
        case 1: return "丼もの"
        case 2: return "ラーメン"
        case 3: return "肉"
        case 4: return "アレンジめし"
        case 5: return "揚げ物"
        case 6: return "深夜めし"
        case 7: return "ラーメン"
        default: return "深夜めし"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌙 今夜の空気")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("こんばんは！今日の飯テロを投稿しよう！")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 8) {
                Text("今日のおすすめカテゴリー")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Text(recommendedCategory)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.45), .pink.opacity(0.25), .black.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
