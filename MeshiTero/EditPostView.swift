//
//  EditPostView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI
import AVKit

struct EditPostView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) var dismiss
    
    @State private var editingPost: FoodPost
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showPlacePickerFromSavedLocation = false
    @State private var showPlacePickerFromCurrentLocation = false
    @State private var selectedPlaceName: String
    @State private var selectedAddress: String
    
    init(post: FoodPost) {
        _editingPost = State(initialValue: post)
        _selectedPlaceName = State(initialValue: post.restaurantName)
        _selectedAddress = State(initialValue: post.address)
    }
    
    var hasSavedMediaLocation: Bool {
        (editingPost.image != nil || editingPost.videoURL != nil) && editingPost.latitude != nil && editingPost.longitude != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("写真・動画を編集") {
                    Button {
                        showCamera = true
                    } label: {
                        Label("今撮影し直す", systemImage: "camera.fill")
                    }

                    Button {
                        showPhotoLibrary = true
                    } label: {
                        Label("ライブラリから選び直す", systemImage: "photo.fill")
                    }

                    if let image = editingPost.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else if let videoURL = editingPost.videoURL {
                        VStack(alignment: .leading, spacing: 8) {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                            Text("動画プレビュー")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("この投稿には写真・動画がありません")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if editingPost.image != nil || editingPost.videoURL != nil {
                        Button("写真・動画を外す", role: .destructive) {
                            editingPost.image = nil
                            editingPost.videoURL = nil
                            editingPost.latitude = nil
                            editingPost.longitude = nil
                            selectedPlaceName = ""
                            selectedAddress = ""
                            if !editingPost.isRestaurant {
                                editingPost.restaurantName = ""
                                editingPost.address = ""
                            }
                        }
                    }
                }

                Section("編集内容") {
                    TextField("料理名", text: $editingPost.foodName)
                    TextField("コメント", text: $editingPost.comment, axis: .vertical)

                    Picker("カテゴリー", selection: $editingPost.category) {
                        ForEach(FoodCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    if editingPost.category == .cupNoodle {
                        TextField("レシピ（任意）", text: $editingPost.recipe, axis: .vertical)
                    }

                    if editingPost.category == .other {
                        TextField("カテゴリー名を入力", text: $editingPost.customCategoryName)
                    }
                    
                    Picker("ハンコ", selection: $editingPost.stampText) {
                        ForEach(appState.availableStamps(including: editingPost.stampText), id: \.self) { stamp in
                            Text(stamp).tag(stamp)
                        }
                    }
                }
                
                Section("飯テロ指数") {
                    SliderGaugeView(title: "背徳感", value: $editingPost.dangerLevel)
                    SliderGaugeView(title: "深夜危険度", value: $editingPost.midnightLevel)
                }
                
                Section("公開設定") {
                    Toggle("ランキングに参加する", isOn: $editingPost.isNightOnly)
                }
                
                Section("お店情報") {
                    Toggle("お店の投稿", isOn: $editingPost.isRestaurant)
                    
                    if editingPost.isRestaurant {
                        if hasSavedMediaLocation {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("この投稿には写真・動画由来の位置情報が保存されています")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Button {
                                    showPlacePickerFromSavedLocation = true
                                } label: {
                                    HStack {
                                        Image(systemName: editingPost.videoURL != nil ? "video.fill" : "photo.fill")
                                        Text("保存された撮影場所からお店を探す")
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
                                    Image(systemName: "location.slash.fill")
                                        .foregroundColor(.orange)
                                    Text("写真・動画の位置情報がないため、現在地からお店を探せます")
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
                        
                        TextField("店名", text: $editingPost.restaurantName)
                        TextField("住所", text: $editingPost.address)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .preferredColorScheme(.dark)
            .navigationTitle("投稿を編集")
            .sheet(isPresented: $showCamera) {
                CameraPicker(
                    image: $editingPost.image,
                    videoURL: $editingPost.videoURL,
                    photoLatitude: $editingPost.latitude,
                    photoLongitude: $editingPost.longitude,
                    sourceType: .camera
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                CameraPicker(
                    image: $editingPost.image,
                    videoURL: $editingPost.videoURL,
                    photoLatitude: $editingPost.latitude,
                    photoLongitude: $editingPost.longitude,
                    sourceType: .photoLibrary
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPlacePickerFromSavedLocation) {
                PlacePickerView(
                    selectedPlaceName: $selectedPlaceName,
                    selectedAddress: $selectedAddress,
                    selectedLatitude: $editingPost.latitude,
                    selectedLongitude: $editingPost.longitude,
                    restaurantName: $editingPost.restaurantName,
                    address: $editingPost.address,
                    searchLatitude: editingPost.latitude,
                    searchLongitude: editingPost.longitude
                )
            }
            .sheet(isPresented: $showPlacePickerFromCurrentLocation) {
                PlacePickerView(
                    selectedPlaceName: $selectedPlaceName,
                    selectedAddress: $selectedAddress,
                    selectedLatitude: $editingPost.latitude,
                    selectedLongitude: $editingPost.longitude,
                    restaurantName: $editingPost.restaurantName,
                    address: $editingPost.address,
                    searchLatitude: nil,
                    searchLongitude: nil
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        editingPost.customCategoryName = editingPost.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        appState.updatePost(editingPost)
                        dismiss()
                    }
                }
            }
        }
    }
}
