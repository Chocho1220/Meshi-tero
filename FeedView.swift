//
//  FeedView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedCategory: FoodCategory? = nil
    
    var filteredPosts: [FoodPost] {
        if let selectedCategory {
            return appState.visiblePosts.filter { $0.category == selectedCategory }
        } else {
            return appState.visiblePosts
        }
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 300)) { context in
            NavigationStack {
                ZStack {
                    TimeAwareSkyBackground()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            NightAirPanelView()
                                .frame(maxWidth: .infinity)

                            categoryScroll

                            ForEach(filteredPosts) { post in
                                PostCardView(post: post)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarColorScheme(
                    TimeAwareSkyStyle.navigationBarColorScheme(for: context.date),
                    for: .navigationBar
                )
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("飯テロナイト")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(TimeAwareSkyStyle.titleColor(for: context.date))
                    }
                }
            }
        }
    }
    
    var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("すべて") {
                    selectedCategory = nil
                }
                .buttonStyle(CategoryButtonStyle(isSelected: selectedCategory == nil))
                
                ForEach(FoodCategory.allCases) { category in
                    Button(category.rawValue) {
                        selectedCategory = category
                    }
                    .buttonStyle(CategoryButtonStyle(isSelected: selectedCategory == category))
                }
            }
        }
    }
}

#Preview {
    FeedView()
        .environment(AppState())
}

struct CategoryButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? .pink : .white.opacity(0.12))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
