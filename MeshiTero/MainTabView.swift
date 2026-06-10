//
//  MainTabView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI

private enum AppTab: String, CaseIterable, Identifiable {
    case feed
    case ranking
    case create
    case collection
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "飯テロ"
        case .ranking: return "ランキング"
        case .create: return "投稿"
        case .collection: return "図鑑"
        case .profile: return "自分"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: return "flame.fill"
        case .ranking: return "crown.fill"
        case .create: return "plus.circle.fill"
        case .collection: return "book.closed.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .profile
    @State private var showRankingStartPrompt = false
    @State private var showNotificationPermissionAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            currentTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .overlay(alignment: .top) {
            if let notice = appState.activeAchievementNotice {
                AchievementNoticeBanner(notice: notice)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: appState.activeAchievementNotice)
        .task(id: appState.activeAchievementNotice?.id) {
            guard appState.activeAchievementNotice != nil else { return }
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            appState.dismissAchievementNotice()
        }
        .onChange(of: appState.shouldShowRankingStartPrompt) { _, shouldShow in
            guard shouldShow, !appState.hasShownRankingStartPrompt else { return }
            appState.markRankingStartPromptShown()
            showRankingStartPrompt = true
        }
        .alert("22時のランキング開始通知をオンにしますか？", isPresented: $showRankingStartPrompt) {
            Button("あとで") {}
            Button("オンにする") {
                Task {
                    let succeeded = await appState.setRankingStartNotificationEnabled(true)
                    if !succeeded {
                        showNotificationPermissionAlert = true
                    }
                }
            }
        } message: {
            Text("毎日22:00に『飯テロランキングが開始されました。』と通知を受け取れます。あとからプロフィールでも変更できます。")
        }
        .alert("通知を許可できませんでした", isPresented: $showNotificationPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("22時のランキング開始通知を使うには、iPhoneの設定アプリで通知を許可してください。")
        }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .feed:
            FeedView()
        case .ranking:
            RankingView()
        case .create:
            CreatePostView()
        case .collection:
            CollectionBookView()
        case .profile:
            ProfileView()
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .bold))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                        ? LinearGradient(
                            colors: [.pink.opacity(0.95), .purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.black.opacity(0.45), .black.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

struct AchievementNoticeBanner: View {
    let notice: AchievementNotice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.title3)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 3) {
                Text("実績解除達成！")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(notice.title) クリア")
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)

                Text("報酬ハンコ「\(notice.rewardStamp)」を獲得！")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.95), .pink.opacity(0.92)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
    }
}
