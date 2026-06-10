//
//  Models.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI
import Foundation

enum ProfileIcon: String, CaseIterable, Identifiable, Codable {
    case flame
    case moon
    case ramen
    case fork
    case heart
    case star

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .flame: return "flame.fill"
        case .moon: return "moon.stars.fill"
        case .ramen: return "takeoutbag.and.cup.and.straw.fill"
        case .fork: return "fork.knife.circle.fill"
        case .heart: return "heart.circle.fill"
        case .star: return "star.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .flame: return .orange
        case .moon: return .purple
        case .ramen: return .pink
        case .fork: return .blue
        case .heart: return .red
        case .star: return .yellow
        }
    }
}

struct UserAccount: Identifiable {
    let id: UUID
    var userName: String
    var profileIcon: ProfileIcon = .flame
    var profileImage: UIImage?
    var email: String = ""
    var badgeTitle: String = "夜食ビギナー"

    init(
        id: UUID = UUID(),
        userName: String,
        profileIcon: ProfileIcon = .flame,
        profileImage: UIImage? = nil,
        email: String = "",
        badgeTitle: String = "夜食ビギナー"
    ) {
        self.id = id
        self.userName = userName
        self.profileIcon = profileIcon
        self.profileImage = profileImage
        self.email = email
        self.badgeTitle = badgeTitle
    }
}

enum FoodCategory: String, CaseIterable, Identifiable, Codable {
    case ramen = "ラーメン"
    case cupNoodle = "アレンジめし"
    case riceBowl = "丼もの"
    case meat = "肉"
    case fried = "揚げ物"
    case midnightMeal = "深夜めし"
    case other = "その他"
    
    var id: String { rawValue }
}

enum ModerationStatus: String, Codable {
    case normal
    case reported
    case flagged
}

struct Comment: Identifiable, Hashable {
    let id: UUID
    var userName: String
    var text: String
    var createdAt: Date = Date()

    init(id: UUID = UUID(), userName: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.userName = userName
        self.text = text
        self.createdAt = createdAt
    }
}

struct StampAchievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rewardStamp: String
    let progressValue: Int
    let goalValue: Int
    let isUnlocked: Bool

    var progressFraction: Double {
        guard goalValue > 0 else { return isUnlocked ? 1 : 0 }
        return min(Double(progressValue) / Double(goalValue), 1.0)
    }
}

struct AchievementNotice: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let rewardStamp: String
}

struct FoodPost: Identifiable {
    let id: UUID
    var authorID: UUID

    var userName: String
    var authorIcon: ProfileIcon
    var authorProfileImage: UIImage?
    var foodName: String
    var comment: String
    var emotionTag: String
    var category: FoodCategory

    var dangerLevel: Int
    var soundLevel: Int
    var midnightLevel: Int

    var image: UIImage?
    var videoURL: URL?

    var createdAt: Date = Date()

    var wantCount: Int = 0
    var lostCount: Int = 0
    var itadakimasuCount: Int = 0

    var isNightOnly: Bool = false
    var isRestaurant: Bool = false
    var restaurantName: String = ""
    var address: String = ""
    
    var latitude: Double?
    var longitude: Double?
    var stampText: String = "鬼ヤバ"
    var recipe: String = ""
    var customCategoryName: String = ""
    var comments: [Comment] = []
    var reportCount: Int = 0
    var moderationStatus: ModerationStatus = .normal

    init(
        id: UUID = UUID(),
        authorID: UUID,
        userName: String,
        authorIcon: ProfileIcon,
        authorProfileImage: UIImage? = nil,
        foodName: String,
        comment: String,
        emotionTag: String,
        category: FoodCategory,
        dangerLevel: Int,
        soundLevel: Int,
        midnightLevel: Int,
        image: UIImage? = nil,
        videoURL: URL? = nil,
        createdAt: Date = Date(),
        wantCount: Int = 0,
        lostCount: Int = 0,
        itadakimasuCount: Int = 0,
        isNightOnly: Bool = false,
        isRestaurant: Bool = false,
        restaurantName: String = "",
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        stampText: String = "鬼ヤバ",
        recipe: String = "",
        customCategoryName: String = "",
        comments: [Comment] = [],
        reportCount: Int = 0,
        moderationStatus: ModerationStatus = .normal
    ) {
        self.id = id
        self.authorID = authorID
        self.userName = userName
        self.authorIcon = authorIcon
        self.authorProfileImage = authorProfileImage
        self.foodName = foodName
        self.comment = comment
        self.emotionTag = emotionTag
        self.category = category
        self.dangerLevel = dangerLevel
        self.soundLevel = soundLevel
        self.midnightLevel = midnightLevel
        self.image = image
        self.videoURL = videoURL
        self.createdAt = createdAt
        self.wantCount = wantCount
        self.lostCount = lostCount
        self.itadakimasuCount = itadakimasuCount
        self.isNightOnly = isNightOnly
        self.isRestaurant = isRestaurant
        self.restaurantName = restaurantName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.stampText = stampText
        self.recipe = recipe
        self.customCategoryName = customCategoryName
        self.comments = comments
        self.reportCount = reportCount
        self.moderationStatus = moderationStatus
    }
}

struct PersistedUserAccount: Codable {
    var id: UUID
    var userName: String
    var profileIcon: ProfileIcon
    var profileImageData: Data?
    var email: String
    var badgeTitle: String

    init(_ user: UserAccount) {
        id = user.id
        userName = user.userName
        profileIcon = user.profileIcon
        profileImageData = user.profileImage?.pngData()
        email = user.email
        badgeTitle = user.badgeTitle
    }

    var userAccount: UserAccount {
        UserAccount(
            id: id,
            userName: userName,
            profileIcon: profileIcon,
            profileImage: profileImageData.flatMap(UIImage.init(data:)),
            email: email,
            badgeTitle: badgeTitle
        )
    }
}

struct PersistedComment: Codable {
    var id: UUID
    var userName: String
    var text: String
    var createdAt: Date

    init(_ comment: Comment) {
        id = comment.id
        userName = comment.userName
        text = comment.text
        createdAt = comment.createdAt
    }

    var comment: Comment {
        Comment(id: id, userName: userName, text: text, createdAt: createdAt)
    }
}

struct PersistedFoodPost: Codable {
    var id: UUID
    var authorID: UUID
    var userName: String
    var authorIcon: ProfileIcon
    var authorProfileImageData: Data?
    var foodName: String
    var comment: String
    var emotionTag: String
    var category: FoodCategory
    var dangerLevel: Int
    var soundLevel: Int
    var midnightLevel: Int
    var imageData: Data?
    var bundleVideoName: String?
    var bundleVideoExtension: String?
    var localVideoFileName: String?
    var createdAt: Date
    var wantCount: Int
    var lostCount: Int
    var itadakimasuCount: Int
    var isNightOnly: Bool
    var isRestaurant: Bool
    var restaurantName: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var stampText: String
    var recipe: String
    var customCategoryName: String?
    var comments: [PersistedComment]
    var reportCount: Int?
    var moderationStatus: ModerationStatus?
}

struct PersistedAppSnapshot: Codable {
    var currentUser: PersistedUserAccount?
    var posts: [PersistedFoodPost]
    var nowEatingCount: Int
    var onlineCount: Int
    var tappedWantPostIDs: [UUID]
    var tappedLostPostIDs: [UUID]
    var tappedItadakimasuPostIDs: [UUID]
    var reportedPostIDs: [UUID]?
    var claimedAchievementRewardIDs: [String]
}

struct ProfileIconBadge: View {
    var icon: ProfileIcon
    var image: UIImage? = nil
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.28), lineWidth: 1.5)
                    }
            } else {
                Circle()
                    .fill(icon.accentColor.opacity(0.18))

                Circle()
                    .stroke(icon.accentColor.opacity(0.55), lineWidth: 1.5)

                Image(systemName: icon.symbolName)
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(icon.accentColor)
            }
        }
        .frame(width: size, height: size)
    }
}
