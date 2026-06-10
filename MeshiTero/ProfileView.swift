//
//  ProfileView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLogoutAlert = false
    @State private var showRenameSheet = false
    @State private var showNotificationPermissionAlert = false
    @State private var draftUserName = ""
    
    var myPosts: [FoodPost] {
        guard let currentUser = appState.currentUser else { return [] }
        return appState.posts.filter { $0.authorID == currentUser.id }
    }

    var trimmedDraftUserName: String {
        draftUserName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProfileIconBadge(
                        icon: appState.currentUser?.profileIcon ?? .flame,
                        image: appState.currentUser?.profileImage,
                        size: 88
                    )
                    
                    Text(appState.currentUser?.userName ?? "ユーザー")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("投稿数：\(myPosts.count)")
                        .foregroundStyle(.white.opacity(0.7))

                    Toggle(isOn: Binding(
                        get: { appState.isRankingStartNotificationEnabled },
                        set: { newValue in
                            Task {
                                let succeeded = await appState.setRankingStartNotificationEnabled(newValue)
                                if newValue && !succeeded {
                                    showNotificationPermissionAlert = true
                                }
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("22時のランキング開始通知")
                                .foregroundStyle(.white)

                            Text("オンにすると、毎日22:00に『飯テロランキングが開始されました。』と通知します。")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .tint(.pink)
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        draftUserName = appState.currentUser?.userName ?? ""
                        showRenameSheet = true
                    } label: {
                        Text("アカウント名を変更")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Text("ログアウト")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            .navigationTitle("プロフィール")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("ログアウトしますか？", isPresented: $showLogoutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("ログアウトすると、いまのアカウント表示は終了します。これまでの投稿や実績は消えません。")
            }
            .alert("通知を許可できませんでした", isPresented: $showNotificationPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("22時のランキング開始通知を使うには、iPhoneの設定アプリで通知を許可してください。")
            }
            .sheet(isPresented: $showRenameSheet) {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()

                        VStack(alignment: .leading, spacing: 20) {
                            Text("新しいアカウント名")
                                .font(.headline)
                                .foregroundStyle(.white)

                            TextField("例：夜食マスター", text: $draftUserName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text("変更すると、これまでの自分の投稿に表示される名前も新しい名前にそろいます。")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))

                            Button {
                                appState.renameCurrentUser(to: draftUserName)
                                showRenameSheet = false
                            } label: {
                                Text("変更を保存")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(trimmedDraftUserName.isEmpty ? .gray.opacity(0.45) : .pink)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(trimmedDraftUserName.isEmpty)

                            Spacer()
                        }
                        .padding(24)
                    }
                    .navigationTitle("名前を変更")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("閉じる") {
                                showRenameSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
