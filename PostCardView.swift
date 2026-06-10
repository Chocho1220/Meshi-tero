//
//  PostCardView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//
import SwiftUI

struct PostCardView: View {
    @Environment(AppState.self) private var appState

    let post: FoodPost

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    @State private var commented = false
    @State private var newCommentText = ""
    @State private var isLostPressed = false
    @State private var showLostPopup = false
    @State private var popupOffset: CGFloat = 0
    @State private var popupOpacity: Double = 0
    @State private var isRecipeExpanded = false
    @State private var showReportDialog = false
    @State private var showReportedAlert = false

    var canManagePost: Bool {
        appState.canManagePost(post)
    }

    var displayedCategoryName: String {
        if post.category == .other {
            let trimmedName = post.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedName.isEmpty ? post.category.rawValue : trimmedName
        }
        return post.category.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            imageArea

            VStack(alignment: .leading, spacing: 10) {
                headerArea

                HStack(alignment: .top) {

                    VStack(alignment: .leading, spacing: 12) {

                        Text(post.comment)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))

                        if post.category == .cupNoodle,
                           !post.recipe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isRecipeExpanded.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Text("レシピを見る")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.pink)

                                        Spacer()

                                        Image(systemName: isRecipeExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                .buttonStyle(.plain)

                                if isRecipeExpanded {
                                    Text(post.recipe)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.75))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        dangerGauge
                    }

                    Spacer()

                    if !post.stampText.isEmpty {
                        stampView
                            .scaleEffect(0.75)
                            .offset(y: -5)
                    }
                }

                actionArea

                if commented {
                    Divider()
                        .background(.white.opacity(0.15))
                        .padding(.vertical, 4)
                    commentSection
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.24),
                    .black.opacity(0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .sheet(isPresented: $showEdit) {
            EditPostView(post: post)
                .environment(appState)
        }
        .alert("投稿を削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                appState.deletePost(post)
            }

            Button("キャンセル", role: .cancel) {}
        }
        .confirmationDialog("この投稿を通報", isPresented: $showReportDialog, titleVisibility: .visible) {
            Button("料理と関係ない") {
                submitReport()
            }
            Button("不快・危険な内容") {
                submitReport()
            }
            Button("スパム・宣伝") {
                submitReport()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("通報が一定数集まると、この投稿はランキング集計から外れます。")
        }
        .alert("通報しました", isPresented: $showReportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("確認のため、この投稿はランキング集計から外れる場合があります。")
        }
    }

    var imageArea: some View {
        ZStack(alignment: .topTrailing) {
            if let videoURL = post.videoURL {
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.black.opacity(0.9), .purple.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 10) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)

                        Text(videoURL.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                            .padding(.horizontal, 16)

                        Text("動画は投稿詳細で確認できます")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .clipped()
                .allowsHitTesting(false)
            } else if let image = post.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .allowsHitTesting(false)
            } else {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .allowsHitTesting(false)
            }

            // 左上に被害バッジ
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(post.lostCount)人が敗北")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .red.opacity(0.4), radius: 3)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Menu {
                if canManagePost {
                    Button {
                        showEdit = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } else if appState.canReportPost(post) {
                    Button(role: .destructive) {
                        showReportDialog = true
                    } label: {
                        Label("この投稿を通報", systemImage: "exclamationmark.bubble")
                    }
                } else {
                    Label("通報済み", systemImage: "checkmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
                    .padding(12)
            }
        }
    }

    var headerArea: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ProfileIconBadge(icon: post.authorIcon, image: post.authorProfileImage, size: 28)

                    Text(post.userName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Text(post.foodName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Text(displayedCategoryName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.pink.opacity(0.25))
                        .clipShape(Capsule())

                    if post.isRestaurant {
                        Text(post.restaurantName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    if post.moderationStatus == .flagged {
                        Text("ランキング保留")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.yellow.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // 破壊数デカ表示
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(post.lostCount)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                }
                Text("食欲破壊数")
                    .font(.system(size: 8))
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    var displayedStampText: String {
        let trimmedStampText = post.stampText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedStampText.isEmpty {
            return trimmedStampText
        }
        
        let count = post.lostCount
        if count == 0 {
            return "被害ゼロ"
        } else if count < 5 {
            return "背徳めし"
        } else if count < 10 {
            return "深夜注意"
        } else if count < 20 {
            return "危険飯"
        } else {
            return "極悪テロ"
        }
    }

    var stampFontSize: CGFloat {
        let count = displayedStampText.count
        switch count {
        case 0...4:
            return 34
        case 5...6:
            return 28
        case 7...8:
            return 24
        default:
            return 20
        }
    }
    
    var stampColor: Color {
        let count = post.lostCount
        if count < 5 {
            return .gray
        } else if count < 10 {
            return .blue
        } else if count < 20 {
            return .orange
        } else {
            return .red
        }
    }

    var stampView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(stampColor.opacity(0.9), lineWidth: 4)
                .frame(width: 140, height: 80)

            RoundedRectangle(cornerRadius: 12)
                .stroke(stampColor.opacity(0.4), lineWidth: 1.5)
                .frame(width: 126, height: 66)

            VStack(spacing: 0) {
                Text("飯テロ認定")
                    .font(.system(size: 12))
                    .fontWeight(.bold)

                Text(displayedStampText)
                    .font(.system(size: stampFontSize))
                    .fontWeight(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 8)
            }
            .foregroundStyle(stampColor)
            .opacity(0.78)
            .blur(radius: 0.15)
        }
        .rotationEffect(.degrees(-12))
        .shadow(color: stampColor.opacity(0.15), radius: 2)
    }
    
    var dangerGauge: some View {
        VStack(spacing: 6) {
            gaugeRow(title: "背徳感", value: post.dangerLevel)
            gaugeRow(title: "深夜危険度", value: post.midnightLevel)
        }
    }

    func gaugeRow(title: String, value: Int) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 90, alignment: .leading)

            HStack(spacing: 7) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= value ? .pink : .white.opacity(0.18))
                        .frame(width: 10, height: 10)
                }
            }

            Spacer()
        }
    }

    var actionArea: some View {
        let isLiked = appState.tappedWantPostIDs.contains(post.id)
        let isLost = appState.tappedLostPostIDs.contains(post.id)
        
        return VStack(spacing: 12) {
            // メイン: 「負けた」ボタン（巨大表示・炎のグラデーション）
            ZStack {
                Button {
                    triggerLostAction()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.body)
                        Text("降参！食欲に負けた (\(post.lostCount))")
                            .font(.caption)
                            .fontWeight(.black)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: isLost ? [.red, .orange] : [.red.opacity(0.35), .orange.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isLost ? Color.orange : Color.red.opacity(0.6), lineWidth: 1.5)
                    }
                    .shadow(color: isLost ? Color.red.opacity(0.5) : Color.clear, radius: 6)
                    .scaleEffect(isLostPressed ? 0.94 : 1.0)
                }
                
                if showLostPopup {
                    Text("敗北 +1 💀🔥")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.orange)
                        .shadow(color: .black, radius: 2)
                        .offset(y: popupOffset)
                        .opacity(popupOpacity)
                }
            }
            
            // サブ: 食べたい / コメント
            HStack(spacing: 10) {
                Button {
                    appState.tapWant(post)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("食べたい \(post.wantCount)")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isLiked ? Color.pink.opacity(0.65) : Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }

                Button {
                    commented.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                        Text(post.comments.isEmpty ? "コメント" : "コメント \(post.comments.count)")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(commented ? Color.blue.opacity(0.65) : Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
    }
    
    func triggerLostAction() {
        guard !appState.tappedLostPostIDs.contains(post.id) else { return }
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            isLostPressed = true
        }
        
        appState.tapLost(post)
        
        popupOffset = 0
        popupOpacity = 1.0
        showLostPopup = true
        
        withAnimation(.easeOut(duration: 0.8)) {
            popupOffset = -35
            popupOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation {
                isLostPressed = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showLostPopup = false
        }
    }

    func actionButton(title: String, icon: String) -> some View {
        Button {
            // 必要ならここに処理を書く
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    func submitReport() {
        appState.reportPost(post)
        showReportedAlert = true
    }

    var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // コメント一覧
            if post.comments.isEmpty {
                Text("まだコメントがありません。最初のコメントを残そう！")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 4)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(post.comments) { comment in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(comment.userName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.pink)
                                    Spacer()
                                    Text(comment.createdAt, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                Text(comment.text)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(8)
                            .background(.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 180)
            }

            // 新規コメント入力欄
            HStack(spacing: 8) {
                TextField("コメントを入力...", text: $newCommentText)
                    .font(.caption)
                    .padding(10)
                    .background(.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }

                Button {
                    let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    appState.addComment(to: post.id, text: text)
                    newCommentText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.caption)
                        .padding(10)
                        .background(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 4)
        }
    }
}
