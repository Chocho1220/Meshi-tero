//
//  RankingView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/27.
//

import SwiftUI

struct RankingView: View {
    @Environment(AppState.self) private var appState
    
    var canViewRanking: Bool {
        appState.isNightTime()
    }

    var weekStartDate: Date {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysSinceMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: startOfToday) ?? startOfToday
    }

    var weeklyPosts: [FoodPost] {
        return appState.posts.filter { post in
            post.createdAt >= weekStartDate && appState.canAppearInRanking(post)
        }
    }
    
    var rankedPosts: [FoodPost] {
        weeklyPosts.sorted {
            let score1 = $0.wantCount + $0.lostCount * 2
            let score2 = $1.wantCount + $1.lostCount * 2
            return score1 > score2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("週間飯テロランキング")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("📅 集計対象: 毎週月曜 0:00 からのランキング参加投稿")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                Text("🌙 結果の閲覧時間: 毎日 22:00〜翌 5:00")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.72))
                                
                                Text("🔥 ランキング参加をオンにした投稿のうち、通報で保留になっていないものだけが集計されます。※『負けた』はポイント2倍！")
                                    .font(.caption2)
                                    .foregroundStyle(.pink.opacity(0.85))
                                    .lineLimit(nil)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .padding(.top, 20)

                        if !canViewRanking {
                            rankingClosedSection
                        } else if rankedPosts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.purple)
                                
                                Text("まだ今週のランキング投稿はありません")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text("月曜からの投稿で、今週いちばん食欲を揺さぶる一皿を目指しましょう。")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        } else {
                            ForEach(Array(rankedPosts.enumerated()), id: \.element.id) { index, post in
                                rankingRow(rank: index + 1, post: post)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    var rankingClosedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("ランキング結果は夜だけ開きます")
                .font(.headline)
                .foregroundStyle(.white)

            Text("投稿は1週間いつでもできます。ランキング結果は毎日22:00〜翌5:00にひらくので、夜の時間にのぞくと今週の順位が見られます。")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.65))
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    func rankingRow(rank: Int, post: FoodPost) -> some View {
        let score = post.wantCount + post.lostCount * 2
        
        return HStack(spacing: 14) {
            Text(rankIcon(rank))
                .font(.largeTitle)
                .frame(width: 46)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.foodName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Text(post.stampText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.pink.opacity(0.2))
                        .foregroundStyle(.pink)
                        .cornerRadius(4)
                    
                    HStack(spacing: 2) {
                        Text("食欲破壊指数:")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.45))
                        Text(String(repeating: "★", count: post.dangerLevel))
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("今週 \(post.lostCount) 人が誘惑に敗北")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.red.opacity(0.9))
                
                HStack(spacing: 10) {
                    Label("\(post.wantCount)", systemImage: "heart.fill")
                    Label("\(post.lostCount)", systemImage: "flame.fill")
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.orange)
                
                Text("破壊pt")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: rank <= 3
                    ? [.orange.opacity(0.25), .pink.opacity(0.18)]
                    : [.white.opacity(0.1), .white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    func rankIcon(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}
