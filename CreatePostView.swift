//
//  CreatePostView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI
import AVKit

struct CreatePostView: View {
    @Environment(AppState.self) private var appState
    
    @State private var foodName = ""
    @State private var comment = ""
    @State private var category: FoodCategory = .ramen
    @State private var dangerLevel = 3
    @State private var midnightLevel = 3
    @State private var isNightOnly = false
    
    @State private var isRestaurant = false
    @State private var restaurantName = ""
    @State private var address = ""
    
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    @State private var photoLatitude: Double?
    @State private var photoLongitude: Double?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showPostedAlert = false
    
    @State private var showPlacePickerFromPhoto = false
    @State private var showPlacePickerFromCurrentLocation = false
    @State private var selectedPlaceName = ""
    @State private var selectedAddress = ""
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    
    @State private var stampText = "鬼ヤバ"
    @State private var recipe = ""
    @State private var customCategoryName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("写真を追加") {
                    Button {
                        showCamera = true
                    } label: {
                        Label("今撮影する", systemImage: "camera.fill")
                    }
                    
                    Button {
                        showPhotoLibrary = true
                    } label: {
                        Label("ライブラリから選ぶ", systemImage: "photo.fill")
                    }
                    
                    if let capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else if let capturedVideoURL {
                        VStack(alignment: .leading, spacing: 8) {
                            VideoPlayer(player: AVPlayer(url: capturedVideoURL))
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                            Text("動画プレビュー（15秒以内）")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("写真・動画を撮影、またはライブラリから選択してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("投稿内容") {
                    Toggle("お店の投稿", isOn: $isRestaurant)
                    
                    if isRestaurant {
                        if capturedImage != nil || capturedVideoURL != nil {
                            if let lat = photoLatitude, let lon = photoLongitude {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("写真・動画の撮影場所情報が取得できました")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Button {
                                        showPlacePickerFromPhoto = true
                                    } label: {
                                        HStack {
                                            Image(systemName: capturedVideoURL != nil ? "video.fill" : "photo.fill")
                                            Text("撮影場所からお店を探す")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.pink.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("この写真・動画には撮影場所の情報がありません")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Button {
                                        showPlacePickerFromCurrentLocation = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "location.fill")
                                            Text("現在地からお店を探す")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("※写真や動画を選択すると、撮影場所からお店を自動検索できます。")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Button {
                                    showPlacePickerFromCurrentLocation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "location.fill")
                                        Text("現在地からお店を探す")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        if !selectedPlaceName.isEmpty {

                            HStack(alignment: .top) {

                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)

                                VStack(alignment: .leading) {

                                    Text(selectedPlaceName)
                                        .font(.headline)

                                    Text(selectedAddress)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                        TextField("店名", text: $restaurantName)
                        TextField("住所", text: $address)
                    }
                    
                    TextField("料理名", text: $foodName)
                    TextField("コメント", text: $comment, axis: .vertical)
                    
                    Picker("カテゴリー", selection: $category) {
                        ForEach(FoodCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    if category == .cupNoodle {
                        TextField("レシピ（任意）", text: $recipe, axis: .vertical)
                    }

                    if category == .other {
                        TextField("カテゴリー名を入力", text: $customCategoryName)
                    }
                    
                    Picker("ハンコ", selection: $stampText) {
                        ForEach(appState.availableStamps(including: stampText), id: \.self) { stamp in
                            Text(stamp)
                        }
                    }
                }
                
                Section("飯テロ指数") {
                    SliderGaugeView(title: "背徳感", value: $dangerLevel)
                    SliderGaugeView(title: "深夜危険度", value: $midnightLevel)
                }
                
                Section("公開設定") {
                    Toggle("ランキングに参加する", isOn: $isNightOnly)
                }
            
                Button("投稿する") {
                    guard let user = appState.currentUser else { return }
                    
                    let newPost = FoodPost(
                        authorID: user.id,
                        userName: user.userName,
                        authorIcon: user.profileIcon,
                        authorProfileImage: user.profileImage,
                        foodName: foodName,
                        comment: comment,
                        emotionTag: stampText,
                        category: category,
                        dangerLevel: dangerLevel,
                        soundLevel: 0,
                        midnightLevel: midnightLevel,
                        image: capturedImage,
                        videoURL: capturedVideoURL,

                        isNightOnly: isNightOnly,
                        isRestaurant: isRestaurant,
                        restaurantName: restaurantName,
                        address: address,
                        latitude: selectedLatitude,
                        longitude: selectedLongitude,

                        stampText: stampText,
                        recipe: recipe,
                        customCategoryName: customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    appState.addPost(newPost)
                    showPostedAlert = true
                    resetForm()
                }
                .disabled(
                    foodName.isEmpty ||
                    comment.isEmpty ||
                    (capturedImage == nil && capturedVideoURL == nil) ||
                    (category == .other && customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .preferredColorScheme(.dark)
            .navigationTitle("飯テロ投稿")
            .alert("投稿しました！", isPresented: $showPostedAlert) {
                Button("OK", role: .cancel) {
                    appState.triggerRankingStartPromptIfNeeded()
                }
            } message: {
                Text("飯テロ投稿がタイムラインに追加されました。")
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $capturedImage, videoURL: $capturedVideoURL, photoLatitude: $photoLatitude, photoLongitude: $photoLongitude, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                CameraPicker(image: $capturedImage, videoURL: $capturedVideoURL, photoLatitude: $photoLatitude, photoLongitude: $photoLongitude, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPlacePickerFromPhoto) {
                PlacePickerView(
                    selectedPlaceName: $selectedPlaceName,
                    selectedAddress: $selectedAddress,
                    selectedLatitude: $selectedLatitude,
                    selectedLongitude: $selectedLongitude,
                    restaurantName: $restaurantName,
                    address: $address,
                    searchLatitude: photoLatitude,
                    searchLongitude: photoLongitude
                )
            }
            .sheet(isPresented: $showPlacePickerFromCurrentLocation) {
                PlacePickerView(
                    selectedPlaceName: $selectedPlaceName,
                    selectedAddress: $selectedAddress,
                    selectedLatitude: $selectedLatitude,
                    selectedLongitude: $selectedLongitude,
                    restaurantName: $restaurantName,
                    address: $address,
                    searchLatitude: nil,
                    searchLongitude: nil
                )
            }
        }
    }
    
    func resetForm() {
        foodName = ""
        comment = ""
        category = .ramen
        dangerLevel = 3
        midnightLevel = 3
        isNightOnly = false
        isRestaurant = false
        restaurantName = ""
        address = ""
        capturedImage = nil
        capturedVideoURL = nil
        photoLatitude = nil
        photoLongitude = nil
        stampText = "鬼ヤバ"
        recipe = ""
        customCategoryName = ""
    }
}

struct SliderGaugeView: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title)：\(value)")
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(String(repeating: "🔥", count: value))
                    .font(.caption)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: 1...5,
                step: 1
            )
            .tint(.pink)
        }
        .padding(.vertical, 6)
    }
    
}
