//
//  AuthView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState

    @State private var nickname = ""
    @State private var selectedIcon: ProfileIcon = .flame
    @State private var selectedProfileImage: UIImage?
    @State private var showIconSourceDialog = false
    @State private var showBuiltInIconPicker = true
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var pickerVideoURL: URL?
    @State private var pickerLatitude: Double?
    @State private var pickerLongitude: Double?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .purple.opacity(0.55), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("MESHI TERO")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                    
                    Text("深夜の飯を、ゆるく共有する。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("アイコン")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))

                    HStack(spacing: 16) {
                        ProfileIconBadge(icon: selectedIcon, image: selectedProfileImage, size: 64)

                        Button {
                            showIconSourceDialog = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("アイコンを設定")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)

                                    Text("既存アイコン / 写真を選ぶ / 今撮影する")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.75))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .white.opacity(0.09)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    if showBuiltInIconPicker {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(ProfileIcon.allCases) { icon in
                                Button {
                                    selectedIcon = icon
                                    selectedProfileImage = nil
                                } label: {
                                    ProfileIconBadge(icon: icon, size: 52)
                                        .overlay {
                                            Circle()
                                                .stroke(selectedIcon == icon && selectedProfileImage == nil ? Color.white : .clear, lineWidth: 3)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("ニックネーム")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                    
                    TextField("例：夜食ユーザー", text: $nickname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("メールアドレスやパスワードなしで、すぐに始められます。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding()
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                Button {
                    let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    appState.signIn(
                        userName: name,
                        profileIcon: selectedIcon,
                        profileImage: selectedProfileImage
                    )
                } label: {
                    Text("はじめる")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.5) : .pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
                
                Text("アイコンとニックネームはあとから見返せます。")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom)
            }
            .padding()
        }
        .confirmationDialog("アイコンの設定方法", isPresented: $showIconSourceDialog, titleVisibility: .visible) {
            Button("既存のアイコンから選ぶ") {
                showBuiltInIconPicker = true
                selectedProfileImage = nil
            }
            Button("写真を選ぶ") {
                showBuiltInIconPicker = false
                showPhotoLibrary = true
            }
            Button("今撮影する") {
                showBuiltInIconPicker = false
                showCamera = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(
                image: $selectedProfileImage,
                videoURL: $pickerVideoURL,
                photoLatitude: $pickerLatitude,
                photoLongitude: $pickerLongitude,
                sourceType: .camera
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            CameraPicker(
                image: $selectedProfileImage,
                videoURL: $pickerVideoURL,
                photoLatitude: $pickerLatitude,
                photoLongitude: $pickerLongitude,
                sourceType: .photoLibrary
            )
            .ignoresSafeArea()
        }
    }
}
