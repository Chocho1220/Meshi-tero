//
//  CollectionBookView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/06/08.
//

import SwiftUI

struct MonthlySummary: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let posts: [FoodPost]
    
    var totalLost: Int {
        posts.map { $0.lostCount }.reduce(0, +)
    }
    
    var mvpPost: FoodPost? {
        posts.max(by: { $0.lostCount < $1.lostCount })
    }
}

struct CollectionBookView: View {
    @Environment(AppState.self) private var appState
    
    @State private var selectedPost: FoodPost? = nil
    
    var myPosts: [FoodPost] {
        appState.currentUserPosts
    }
    
    var totalLost: Int {
        myPosts.map { $0.lostCount }.reduce(0, +)
    }
    
    var mvpPost: FoodPost? {
        myPosts.max(by: { $0.lostCount < $1.lostCount })
    }
    
    var postsThisMonth: Int {
        let now = Date()
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)
        return myPosts.filter { post in
            let m = Calendar.current.component(.month, from: post.createdAt)
            let y = Calendar.current.component(.year, from: post.createdAt)
            return m == currentMonth && y == currentYear
        }.count
    }
    
    var monthlySummaries: [MonthlySummary] {
        let grouped = Dictionary(grouping: myPosts) { post -> String in
            let year = Calendar.current.component(.year, from: post.createdAt)
            let month = Calendar.current.component(.month, from: post.createdAt)
            return "\(year)-\(month)"
        }
        
        return grouped.map { (key, posts) -> MonthlySummary in
            let components = key.split(separator: "-")
            let year = Int(components[0]) ?? 0
            let month = Int(components[1]) ?? 0
            return MonthlySummary(year: year, month: month, posts: posts.sorted(by: { $0.createdAt > $1.createdAt }))
        }.sorted {
            if $0.year != $1.year {
                return $0.year > $1.year
            }
            return $0.month > $1.month
        }
    }
    
    var achievements: [StampAchievement] {
        appState.visibleAchievements
    }
    
    var unlockedRewardStamps: [String] {
        appState.claimedRewardStamps
    }
    
    var claimableAchievements: [StampAchievement] {
        appState.claimableAchievements
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景の重厚なグラデーション
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.05, blue: 0.18), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        bookCoverHeader
                        
                        statsGrid
                        
                        achievementSection
                        
                        rewardClaimSection
                        
                        premiumStampSection
                        
                        monthlyHistorySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("飯テロ図鑑")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    ScrollView {
                        PostCardView(post: post)
                            .padding()
                    }
                    .background(Color.black.ignoresSafeArea())
                    .navigationTitle("飯テロ詳細")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("閉じる") {
                                selectedPost = nil
                            }
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Views
    
    var bookCoverHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                // 本の立体感と装飾
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.15, blue: 0.45), Color(red: 0.15, green: 0.05, blue: 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 160)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                            .padding(8)
                    }
                    .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                
                // 本の背表紙風の帯
                HStack {
                    Rectangle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: 12)
                        .padding(.vertical, 8)
                    
                    Spacer()
                }
                .padding(.leading, 8)
                
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                    
                    Text("あなたの飯テロ記録書")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text("〜 誘惑と敗北の食欲歴史 〜")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.top, 10)
        }
    }
    
    var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📖 破壊戦績")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statsCard(title: "総飯テロ数", value: "\(myPosts.count) 投稿", icon: "photo.stack", color: .purple)
                statsCard(title: "累計被害者数", value: "\(totalLost) 人敗北", icon: "flame.fill", color: .red)
                statsCard(title: "今月の悪行", value: "\(postsThisMonth) 投稿", icon: "calendar", color: .blue)
                if let mvpPost {
                    statsCard(
                        title: "最大被害の元凶",
                        value: mvpPost.foodName,
                        subValue: "🔥 \(mvpPost.lostCount)人敗北",
                        icon: "crown.fill",
                        color: .orange
                    )
                } else {
                    statsCard(
                        title: "最大被害の元凶",
                        value: "なし",
                        icon: "crown.fill",
                        color: .orange
                    )
                }
            }
        }
    }
    
    func statsCard(title: String, value: String, subValue: String = "", icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if !subValue.isEmpty {
                Text(subValue)
                    .font(.system(size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }
    
    var achievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 実績とごほうびハンコ")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { ach in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(ach.isUnlocked ? Color.purple.opacity(0.25) : Color.white.opacity(0.06))
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Circle()
                                            .stroke(ach.isUnlocked ? Color.orange : Color.white.opacity(0.12), lineWidth: 2)
                                    }

                                Circle()
                                    .trim(from: 0, to: ach.progressFraction)
                                    .stroke(
                                        ach.isUnlocked ? Color.orange : Color.pink.opacity(0.85),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                    )
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))
                                
                                Image(systemName: ach.icon)
                                    .font(.title2)
                                    .foregroundColor(ach.isUnlocked ? .orange : .white.opacity(0.2))
                            }
                            
                            VStack(spacing: 2) {
                                Text(ach.title)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(ach.isUnlocked ? .white : .white.opacity(0.4))
                                
                                Text(ach.description)
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)

                                Text("\(min(ach.progressValue, ach.goalValue))/\(ach.goalValue)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(ach.isUnlocked ? .orange : .pink.opacity(0.85))
                                    .frame(width: 80)

                                Text(ach.isUnlocked ? "解放: \(ach.rewardStamp)" : "報酬: \(ach.rewardStamp)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(ach.isUnlocked ? .orange : .white.opacity(0.35))
                                    .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            if unlockedRewardStamps.isEmpty {
                Text("まだ受け取り済みのごほうびハンコはありません。達成した実績の報酬は下の欄から受け取れます。")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(unlockedRewardStamps, id: \.self) { stamp in
                            Text(stamp)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.9), .pink.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    var rewardClaimSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎁 報酬受け取り")
                .font(.headline)
                .foregroundColor(.white)
            
            if claimableAchievements.isEmpty {
                Text("受け取れる報酬はまだありません。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
            } else {
                VStack(spacing: 10) {
                    ForEach(claimableAchievements) { achievement in
                        HStack(spacing: 12) {
                            rewardStampPreview(text: achievement.rewardStamp)
                                .frame(width: 98, height: 66)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(achievement.title)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("報酬ハンコ: \(achievement.rewardStamp)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            
                            Spacer()
                            
                            Button {
                                appState.claimReward(for: achievement.id)
                            } label: {
                                Text("受け取る")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    func rewardStampPreview(text: String) -> some View {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.45), lineWidth: 3)

            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                .padding(5)

            VStack(spacing: 1) {
                Text("飯テロ認定")
                    .font(.system(size: 6, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(trimmedText)
                    .font(.system(size: rewardStampFontSize(for: trimmedText), weight: .black))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.45)
                    .allowsTightening(true)
                    .frame(maxWidth: 64)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 6)
        }
        .padding(4)
        .rotationEffect(.degrees(-7))
    }

    func rewardStampFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...4:
            return 18
        case 5...6:
            return 14
        case 7...8:
            return 12
        default:
            return 10
        }
    }

    var premiumStampSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💎 プレミアムハンコ工房")
                .font(.headline)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("自分だけのハンコを作る課金枠")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("好きな文字でオリジナルスタンプを作れる予定です。")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("プレビュー")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.75))

                    HStack {
                        Text("わたしの限定ハンコ")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.35))

                        Spacer()

                        Text("準備中")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("課金で解放予定")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(true)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.yellow.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
            }
        }
    }
    
    var monthlyHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🗂 月別アーカイブ")
                .font(.headline)
                .foregroundColor(.white)
            
            if monthlySummaries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.2))
                    
                    Text("まだ記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("最初の飯テロを投稿して図鑑を埋めましょう！")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            } else {
                ForEach(monthlySummaries) { summary in
                    VStack(alignment: .leading, spacing: 12) {
                        // 月の要約バナー
                        HStack {
                            Text("\(summary.year)年 \(summary.month)月")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("投稿: \(summary.posts.count)件  |  被害: \(summary.totalLost)人")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 4)
                        
                        // 今月の最大被害紹介
                        if let mvp = summary.mvpPost {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                Text("危険度最大: \(mvp.foodName) (🔥 \(mvp.lostCount)人敗北)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                        }
                        
                        // 投稿アイテムの横スクロール/グリッド表示
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(summary.posts) { post in
                                Button {
                                    selectedPost = post
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        // サムネイル
                                        ZStack(alignment: .bottomTrailing) {
                                            if let image = post.image {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                            } else {
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(width: 100, height: 100)
                                                    .overlay {
                                                        Image(systemName: "photo")
                                                            .foregroundColor(.white.opacity(0.3))
                                                    }
                                            }
                                            
                                            // 敗北バッジ
                                            Text("🔥 \(post.lostCount)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red)
                                                .cornerRadius(4)
                                                .padding(4)
                                        }
                                        .cornerRadius(12)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(post.foodName)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(post.isRestaurant ? post.restaurantName : "おうち")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white.opacity(0.5))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(18)
                }
            }
        }
    }
    
}
