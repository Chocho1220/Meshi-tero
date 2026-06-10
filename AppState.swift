//
//  AppState.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI
import Observation
import UserNotifications
import Foundation

@Observable
final class AppState {
    private enum ModerationPolicy {
        static let flagThreshold = 3
    }

    private struct RestoredState {
        var currentUser: UserAccount?
        var posts: [FoodPost]
        var nowEatingCount: Int
        var onlineCount: Int
        var tappedWantPostIDs: Set<UUID>
        var tappedLostPostIDs: Set<UUID>
        var tappedItadakimasuPostIDs: Set<UUID>
        var reportedPostIDs: Set<UUID>
        var claimedAchievementRewardIDs: Set<String>
    }

    private enum NotificationKey {
        static let rankingStartEnabled = "ranking_start_notification_enabled"
        static let rankingStartIdentifier = "ranking_start_notification"
        static let rankingStartPromptShown = "ranking_start_prompt_shown"
    }

    private enum PersistencePath {
        static let directoryName = "MeshiTeroPersistence"
        static let stateFileName = "app_state.json"
    }

    private enum RestorePolicy {
        static let timeoutNanoseconds: UInt64 = 2_000_000_000
    }

    let defaultStamps = ["鬼ヤバ", "高カロリー", "背徳", "深夜注意", "危険飯"]
    var currentUser: UserAccount?
    var nowEatingCount: Int = 327
    var onlineCount: Int = 1842
    var tappedWantPostIDs: Set<UUID> = []
    var tappedLostPostIDs: Set<UUID> = []
    var tappedItadakimasuPostIDs: Set<UUID> = []
    var reportedPostIDs: Set<UUID> = []
    var activeAchievementNotice: AchievementNotice?
    private var pendingAchievementNotices: [AchievementNotice] = []
    private var knownUnlockedAchievementIDs: Set<String> = []
    private var claimedAchievementRewardIDs: Set<String> = []
    var isRankingStartNotificationEnabled = UserDefaults.standard.bool(forKey: NotificationKey.rankingStartEnabled)
    var hasShownRankingStartPrompt = UserDefaults.standard.bool(forKey: NotificationKey.rankingStartPromptShown)
    var shouldShowRankingStartPrompt = false
    var isWaitingForRankingPromptAfterPostAlert = false
    var isRestoringPersistedState = true
    private var pendingPersistTask: Task<Void, Never>?
    private var hasRestoredPersistedState = false
    private var hasLocalStateChangesSinceLaunch = false

    var posts: [FoodPost]

    init() {
        self.posts = Self.defaultPosts
        resetSessionScopedState()
    }

    private static var defaultPosts: [FoodPost] {
        [
            FoodPost(
                authorID: UUID(),
                userName: "ラーメン民",
                authorIcon: .ramen,
                authorProfileImage: nil,
                foodName: "深夜の味噌ラーメン",
                comment: "背徳感感じるラーメン",
                emotionTag: "ご褒美",
                category: .midnightMeal,
                dangerLevel: 4,
                soundLevel: 2,
                midnightLevel: 3,
                image: nil,
                videoURL: nil,
                wantCount: 89,
                lostCount: 18,
                itadakimasuCount: 0,
                isNightOnly: false,
                isRestaurant: false,
                restaurantName: "",
                address: "",
                stampText: "鬼ヤバ"
            )
        ]
    }
    
    var visiblePosts: [FoodPost] {
        posts
    }
    
    func isNightTime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 22 || hour < 5
    }
    
    func addPost(_ post: FoodPost) {
        posts.insert(post, at: 0)
        checkForAchievementUnlocks()

        if !hasShownRankingStartPrompt && currentUserPosts.count == 1 {
            isWaitingForRankingPromptAfterPostAlert = true
        }
        persistState()
    }

    func signIn(userName: String, profileIcon: ProfileIcon, profileImage: UIImage?) {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser = UserAccount(
            userName: trimmedName.isEmpty ? "夜食ユーザー" : trimmedName,
            profileIcon: profileIcon,
            profileImage: profileImage,
            email: ""
        )
        resetSessionScopedState()
    }

    func signOut() {
        currentUser = nil
        resetSessionScopedState()
    }

    func restorePersistedStateIfNeeded() {
        guard !hasRestoredPersistedState else { return }
        hasRestoredPersistedState = true

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            guard let restoredState = self.loadRestoredState() else {
                await MainActor.run {
                    self.finishRestoration()
                }
                return
            }
            await MainActor.run {
                guard self.isRestoringPersistedState else { return }
                self.applyRestoredState(restoredState)
                self.finishRestoration()
            }
        }

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: RestorePolicy.timeoutNanoseconds)
            self?.finishRestoration()
        }
    }

    var currentUserPosts: [FoodPost] {
        guard let currentUser else { return [] }
        return posts.filter { $0.authorID == currentUser.id }
    }

    var currentUserTotalLost: Int {
        currentUserPosts.map(\.lostCount).reduce(0, +)
    }

    var currentUserRamenCount: Int {
        currentUserPosts.filter { $0.category == .ramen }.count
    }

    var currentUserMaxPostStreak: Int {
        let dates = currentUserPosts.map { Calendar.current.startOfDay(for: $0.createdAt) }
        let uniqueDates = Array(Set(dates)).sorted()
        guard !uniqueDates.isEmpty else { return 0 }

        var currentStreak = 1
        var maxStreak = 1

        for index in 1..<uniqueDates.count {
            let previousDate = uniqueDates[index - 1]
            let currentDate = uniqueDates[index]
            let diff = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if diff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if diff > 1 {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    var currentUserActivePostStreak: Int {
        let dates = currentUserPosts.map { Calendar.current.startOfDay(for: $0.createdAt) }
        let uniqueDates = Array(Set(dates)).sorted()
        guard let latestDate = uniqueDates.last else { return 0 }

        let today = Calendar.current.startOfDay(for: Date())
        let daysFromLatestToToday = Calendar.current.dateComponents([.day], from: latestDate, to: today).day ?? 0
        guard daysFromLatestToToday <= 1 else { return 0 }

        var streak = 1
        var cursor = latestDate

        for index in stride(from: uniqueDates.count - 2, through: 0, by: -1) {
            let candidate = uniqueDates[index]
            let diff = Calendar.current.dateComponents([.day], from: candidate, to: cursor).day ?? 0
            if diff == 1 {
                streak += 1
                cursor = candidate
            } else {
                break
            }
        }

        return streak
    }

    var allAchievements: [StampAchievement] {
        let posts = currentUserPosts
        let activeStreak = currentUserActivePostStreak
        let totalLost = currentUserTotalLost
        let ramenCount = currentUserRamenCount
        let arrangedMealCount = currentUserPosts.filter { $0.category == .cupNoodle }.count

        return [
            StampAchievement(
                id: "first_post",
                title: "最初の一皿",
                description: "はじめて飯テロを投稿した",
                icon: "sparkles",
                rewardStamp: "飯テロ見習い",
                progressValue: posts.count,
                goalValue: 1,
                isUnlocked: posts.count >= 1
            ),
            StampAchievement(
                id: "three_day_streak",
                title: "三夜連続",
                description: "3日連続で飯テロを投稿した",
                icon: "calendar.badge.clock",
                rewardStamp: "食欲ブースター",
                progressValue: activeStreak,
                goalValue: 3,
                isUnlocked: activeStreak >= 3
            ),
            StampAchievement(
                id: "five_posts",
                title: "常習犯",
                description: "飯テロを5件投稿した",
                icon: "photo.stack.fill",
                rewardStamp: "常習犯",
                progressValue: posts.count,
                goalValue: 5,
                isUnlocked: posts.count >= 5
            ),
            StampAchievement(
                id: "ramen_master",
                title: "ラーメン賢者",
                description: "ラーメンを3件以上投稿した",
                icon: "fork.knife",
                rewardStamp: "麺神",
                progressValue: ramenCount,
                goalValue: 3,
                isUnlocked: ramenCount >= 3
            ),
            StampAchievement(
                id: "arrange_master",
                title: "深夜アレンジャー",
                description: "アレンジめしを3件投稿した",
                icon: "takeoutbag.and.cup.and.straw.fill",
                rewardStamp: "魔改造",
                progressValue: arrangedMealCount,
                goalValue: 3,
                isUnlocked: arrangedMealCount >= 3
            ),
            StampAchievement(
                id: "victims_30",
                title: "三十人斬り",
                description: "累計30人を敗北させた",
                icon: "flame.circle.fill",
                rewardStamp: "猛攻",
                progressValue: totalLost,
                goalValue: 30,
                isUnlocked: totalLost >= 30
            ),
            StampAchievement(
                id: "victims_100",
                title: "百人隊長",
                description: "累計100人を敗北させた",
                icon: "flame.fill",
                rewardStamp: "百鬼夜行",
                progressValue: totalLost,
                goalValue: 100,
                isUnlocked: totalLost >= 100
            ),
            StampAchievement(
                id: "seven_day_streak",
                title: "背徳の習慣",
                description: "7日連続で飯テロを投稿した",
                icon: "moon.stars.fill",
                rewardStamp: "夜王降臨",
                progressValue: activeStreak,
                goalValue: 7,
                isUnlocked: activeStreak >= 7
            )
        ]
    }

    var visibleAchievements: [StampAchievement] {
        Array(allAchievements.prefix(8))
    }

    var claimableAchievements: [StampAchievement] {
        visibleAchievements.filter { $0.isUnlocked && !claimedAchievementRewardIDs.contains($0.id) }
    }

    var claimedRewardStamps: [String] {
        visibleAchievements
            .filter { claimedAchievementRewardIDs.contains($0.id) }
            .map(\.rewardStamp)
    }

    func availableStamps(including currentStamp: String? = nil) -> [String] {
        let candidates = defaultStamps + claimedRewardStamps + [currentStamp].compactMap { $0 }
        var uniqueStamps: [String] = []

        for stamp in candidates {
            let trimmedStamp = stamp.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedStamp.isEmpty, !uniqueStamps.contains(trimmedStamp) else { continue }
            uniqueStamps.append(trimmedStamp)
        }

        return uniqueStamps
    }

    func claimReward(for achievementID: String) {
        guard let achievement = visibleAchievements.first(where: { $0.id == achievementID }),
              achievement.isUnlocked,
              !claimedAchievementRewardIDs.contains(achievementID) else { return }

        claimedAchievementRewardIDs.insert(achievementID)
        persistState()
    }
    
    func canManagePost(_ post: FoodPost) -> Bool {
        guard let currentUser else { return false }
        return post.authorID == currentUser.id
    }
    
    func updatePost(_ post: FoodPost) {
        guard canManagePost(post) else { return }
        var updatedPost = post
        updatedPost.emotionTag = updatedPost.stampText
        if updatedPost.category != .cupNoodle {
            updatedPost.recipe = ""
        }
        if updatedPost.category != .other {
            updatedPost.customCategoryName = ""
        } else {
            updatedPost.customCategoryName = updatedPost.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
            persistState()
        }
    }
    
    func deletePost(_ post: FoodPost) {
        guard canManagePost(post) else { return }
        posts.removeAll { $0.id == post.id }
        reportedPostIDs.remove(post.id)
        persistState()
    }

    func canReportPost(_ post: FoodPost) -> Bool {
        guard let currentUser else { return false }
        return post.authorID != currentUser.id && !reportedPostIDs.contains(post.id)
    }

    func reportPost(_ post: FoodPost) {
        guard canReportPost(post) else { return }
        reportedPostIDs.insert(post.id)

        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].reportCount += 1
            posts[index].moderationStatus = posts[index].reportCount >= ModerationPolicy.flagThreshold ? .flagged : .reported
            persistState()
        }
    }

    func canAppearInRanking(_ post: FoodPost) -> Bool {
        post.isNightOnly && post.moderationStatus != .flagged
    }
    
    func tapWant(_ post: FoodPost) {
        guard !tappedWantPostIDs.contains(post.id) else { return }
        tappedWantPostIDs.insert(post.id)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].wantCount += 1
            persistState()
        }
    }

    func tapLost(_ post: FoodPost) {
        guard !tappedLostPostIDs.contains(post.id) else { return }
        tappedLostPostIDs.insert(post.id)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].lostCount += 1
            checkForAchievementUnlocks()
            persistState()
        }
    }

    func tapItadakimasu(_ post: FoodPost) {
        guard !tappedItadakimasuPostIDs.contains(post.id) else { return }
        tappedItadakimasuPostIDs.insert(post.id)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].itadakimasuCount += 1
            nowEatingCount += 1
            persistState()
        }
    }

    func addComment(to postID: UUID, text: String) {
        guard let user = currentUser else { return }
        let newComment = Comment(userName: user.userName, text: text)
        if let index = posts.firstIndex(where: { $0.id == postID }) {
            posts[index].comments.append(newComment)
            persistState()
        }
    }

    func renameCurrentUser(to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, var user = currentUser else { return }
        user.userName = trimmedName
        currentUser = user

        for index in posts.indices where posts[index].authorID == user.id {
            posts[index].userName = trimmedName
        }
        persistState()
    }

    func setRankingStartNotificationEnabled(_ isEnabled: Bool) async -> Bool {
        if isEnabled {
            let granted = await requestRankingStartNotificationPermission()
            guard granted else {
                isRankingStartNotificationEnabled = false
                UserDefaults.standard.set(false, forKey: NotificationKey.rankingStartEnabled)
                await cancelRankingStartNotification()
                return false
            }

            isRankingStartNotificationEnabled = true
            UserDefaults.standard.set(true, forKey: NotificationKey.rankingStartEnabled)
            await scheduleRankingStartNotification()
            return true
        } else {
            isRankingStartNotificationEnabled = false
            UserDefaults.standard.set(false, forKey: NotificationKey.rankingStartEnabled)
            await cancelRankingStartNotification()
            return true
        }
    }

    func markRankingStartPromptShown() {
        hasShownRankingStartPrompt = true
        shouldShowRankingStartPrompt = false
        isWaitingForRankingPromptAfterPostAlert = false
        UserDefaults.standard.set(true, forKey: NotificationKey.rankingStartPromptShown)
        persistState()
    }

    func triggerRankingStartPromptIfNeeded() {
        guard isWaitingForRankingPromptAfterPostAlert, !hasShownRankingStartPrompt else { return }
        shouldShowRankingStartPrompt = true
    }

    private func requestRankingStartNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private func scheduleRankingStartNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "週間飯テロランキング"
        content.body = "飯テロランキングが開始されました。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationKey.rankingStartIdentifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationKey.rankingStartIdentifier])
        try? await center.add(request)
    }

    private func cancelRankingStartNotification() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationKey.rankingStartIdentifier])
    }

    private func resetSessionScopedState() {
        activeAchievementNotice = nil
        pendingAchievementNotices = []
        knownUnlockedAchievementIDs = Set(allAchievements.filter(\.isUnlocked).map(\.id))
        claimedAchievementRewardIDs = []
    }

    func dismissAchievementNotice() {
        if pendingAchievementNotices.isEmpty {
            activeAchievementNotice = nil
        } else {
            activeAchievementNotice = pendingAchievementNotices.removeFirst()
        }
    }

    private func checkForAchievementUnlocks() {
        let newlyUnlockedAchievements = visibleAchievements.filter { achievement in
            achievement.isUnlocked && !knownUnlockedAchievementIDs.contains(achievement.id)
        }

        guard !newlyUnlockedAchievements.isEmpty else { return }

        for achievement in newlyUnlockedAchievements {
            knownUnlockedAchievementIDs.insert(achievement.id)

            let notice = AchievementNotice(
                title: achievement.title,
                rewardStamp: achievement.rewardStamp
            )

            if activeAchievementNotice == nil {
                activeAchievementNotice = notice
            } else {
                pendingAchievementNotices.append(notice)
            }
        }
    }

    private func applyRestoredState(_ restoredState: RestoredState) {
        guard !hasLocalStateChangesSinceLaunch else { return }

        currentUser = restoredState.currentUser
        posts = restoredState.posts
        nowEatingCount = restoredState.nowEatingCount
        onlineCount = restoredState.onlineCount
        tappedWantPostIDs = restoredState.tappedWantPostIDs
        tappedLostPostIDs = restoredState.tappedLostPostIDs
        tappedItadakimasuPostIDs = restoredState.tappedItadakimasuPostIDs
        reportedPostIDs = restoredState.reportedPostIDs
        claimedAchievementRewardIDs = restoredState.claimedAchievementRewardIDs
        resetSessionScopedState()
        claimedAchievementRewardIDs = restoredState.claimedAchievementRewardIDs
    }

    @MainActor
    private func finishRestoration() {
        isRestoringPersistedState = false
    }

    private func loadRestoredState() -> RestoredState? {
        guard let data = try? Data(contentsOf: persistenceFileURL()),
              let snapshot = try? JSONDecoder().decode(PersistedAppSnapshot.self, from: data) else {
            return nil
        }

        return RestoredState(
            currentUser: snapshot.currentUser?.userAccount,
            posts: snapshot.posts.map(makeFoodPost),
            nowEatingCount: snapshot.nowEatingCount,
            onlineCount: snapshot.onlineCount,
            tappedWantPostIDs: Set(snapshot.tappedWantPostIDs),
            tappedLostPostIDs: Set(snapshot.tappedLostPostIDs),
            tappedItadakimasuPostIDs: Set(snapshot.tappedItadakimasuPostIDs),
            reportedPostIDs: Set(snapshot.reportedPostIDs ?? []),
            claimedAchievementRewardIDs: Set(snapshot.claimedAchievementRewardIDs)
        )
    }

    private func persistState() {
        hasLocalStateChangesSinceLaunch = true
        pendingPersistTask?.cancel()
        pendingPersistTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self?.persistStateNow()
        }
    }

    private func persistStateNow() {
        let currentUser = currentUser
        let posts = posts
        let nowEatingCount = nowEatingCount
        let onlineCount = onlineCount
        let tappedWantPostIDs = tappedWantPostIDs
        let tappedLostPostIDs = tappedLostPostIDs
        let tappedItadakimasuPostIDs = tappedItadakimasuPostIDs
        let reportedPostIDs = reportedPostIDs
        let claimedAchievementRewardIDs = claimedAchievementRewardIDs
        let persistenceDirectoryURL = persistenceDirectoryURL()
        let persistenceFileURL = persistenceFileURL()

        DispatchQueue.global(qos: .utility).async {
            let snapshot = PersistedAppSnapshot(
                currentUser: currentUser.map(PersistedUserAccount.init),
                posts: posts.map { Self.makePersistedFoodPost(from: $0, persistenceDirectoryURL: persistenceDirectoryURL) },
                nowEatingCount: nowEatingCount,
                onlineCount: onlineCount,
                tappedWantPostIDs: Array(tappedWantPostIDs),
                tappedLostPostIDs: Array(tappedLostPostIDs),
                tappedItadakimasuPostIDs: Array(tappedItadakimasuPostIDs),
                reportedPostIDs: Array(reportedPostIDs),
                claimedAchievementRewardIDs: Array(claimedAchievementRewardIDs)
            )

            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            let fileManager = FileManager.default

            do {
                try fileManager.createDirectory(at: persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                try data.write(to: persistenceFileURL, options: .atomic)
            } catch {
                return
            }
        }
    }

    func flushPersistence() {
        hasLocalStateChangesSinceLaunch = true
        pendingPersistTask?.cancel()
        pendingPersistTask = nil
        persistStateNow()
    }

    private static func makePersistedFoodPost(from post: FoodPost, persistenceDirectoryURL: URL) -> PersistedFoodPost {
        let bundleReference = bundleVideoReference(for: post.videoURL)
        let localVideoFileName = bundleReference == nil ? persistLocalVideoIfNeeded(for: post, persistenceDirectoryURL: persistenceDirectoryURL) : nil

        return PersistedFoodPost(
            id: post.id,
            authorID: post.authorID,
            userName: post.userName,
            authorIcon: post.authorIcon,
            authorProfileImageData: post.authorProfileImage?.pngData(),
            foodName: post.foodName,
            comment: post.comment,
            emotionTag: post.emotionTag,
            category: post.category,
            dangerLevel: post.dangerLevel,
            soundLevel: post.soundLevel,
            midnightLevel: post.midnightLevel,
            imageData: post.image?.pngData(),
            bundleVideoName: bundleReference?.name,
            bundleVideoExtension: bundleReference?.ext,
            localVideoFileName: localVideoFileName,
            createdAt: post.createdAt,
            wantCount: post.wantCount,
            lostCount: post.lostCount,
            itadakimasuCount: post.itadakimasuCount,
            isNightOnly: post.isNightOnly,
            isRestaurant: post.isRestaurant,
            restaurantName: post.restaurantName,
            address: post.address,
            latitude: post.latitude,
            longitude: post.longitude,
            stampText: post.stampText,
            recipe: post.recipe,
            customCategoryName: post.customCategoryName,
            comments: post.comments.map(PersistedComment.init),
            reportCount: post.reportCount,
            moderationStatus: post.moderationStatus
        )
    }

    private static func persistLocalVideoIfNeeded(for post: FoodPost, persistenceDirectoryURL: URL) -> String? {
        guard let videoURL = post.videoURL else { return nil }
        guard bundleVideoReference(for: videoURL) == nil else { return nil }

        let destinationURL = mediaDirectoryURL(from: persistenceDirectoryURL).appendingPathComponent("\(post.id.uuidString).mov")
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: mediaDirectoryURL(from: persistenceDirectoryURL), withIntermediateDirectories: true, attributes: nil)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.copyItem(at: videoURL, to: destinationURL)
            return destinationURL.lastPathComponent
        } catch {
            return nil
        }
    }

    private static func mediaDirectoryURL(from persistenceDirectoryURL: URL) -> URL {
        persistenceDirectoryURL.appendingPathComponent("Media", isDirectory: true)
    }

    private static func bundleVideoReference(for url: URL?) -> (name: String, ext: String)? {
        guard let url else { return nil }
        let bundlePath = Bundle.main.bundlePath
        guard url.path.hasPrefix(bundlePath) else { return nil }
        let ext = url.pathExtension
        let name = url.deletingPathExtension().lastPathComponent
        guard !name.isEmpty, !ext.isEmpty else { return nil }
        return (name, ext)
    }

    private func restoredVideoURL(from persisted: PersistedFoodPost) -> URL? {
        if let name = persisted.bundleVideoName, let ext = persisted.bundleVideoExtension {
            return Bundle.main.url(forResource: name, withExtension: ext)
        }

        guard let localVideoFileName = persisted.localVideoFileName else {
            return nil
        }

        return mediaDirectoryURL().appendingPathComponent(localVideoFileName)
    }

    private func mediaDirectoryURL() -> URL {
        persistenceDirectoryURL().appendingPathComponent("Media", isDirectory: true)
    }

    private func persistenceDirectoryURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL.appendingPathComponent(PersistencePath.directoryName, isDirectory: true)
    }

    private func persistenceFileURL() -> URL {
        persistenceDirectoryURL().appendingPathComponent(PersistencePath.stateFileName)
    }

    private func bundleVideoReference(for url: URL?) -> (name: String, ext: String)? {
        Self.bundleVideoReference(for: url)
    }

    private func makePersistedFoodPost(from post: FoodPost) -> PersistedFoodPost {
        Self.makePersistedFoodPost(from: post, persistenceDirectoryURL: persistenceDirectoryURL())
    }

    private func persistLocalVideoIfNeeded(for post: FoodPost) -> String? {
        Self.persistLocalVideoIfNeeded(for: post, persistenceDirectoryURL: persistenceDirectoryURL())
    }

    private func makeFoodPost(from persisted: PersistedFoodPost) -> FoodPost {
        FoodPost(
            id: persisted.id,
            authorID: persisted.authorID,
            userName: persisted.userName,
            authorIcon: persisted.authorIcon,
            authorProfileImage: persisted.authorProfileImageData.flatMap(UIImage.init(data:)),
            foodName: persisted.foodName,
            comment: persisted.comment,
            emotionTag: persisted.emotionTag,
            category: persisted.category,
            dangerLevel: persisted.dangerLevel,
            soundLevel: persisted.soundLevel,
            midnightLevel: persisted.midnightLevel,
            image: persisted.imageData.flatMap(UIImage.init(data:)),
            videoURL: restoredVideoURL(from: persisted),
            createdAt: persisted.createdAt,
            wantCount: persisted.wantCount,
            lostCount: persisted.lostCount,
            itadakimasuCount: persisted.itadakimasuCount,
            isNightOnly: persisted.isNightOnly,
            isRestaurant: persisted.isRestaurant,
            restaurantName: persisted.restaurantName,
            address: persisted.address,
            latitude: persisted.latitude,
            longitude: persisted.longitude,
            stampText: persisted.stampText,
            recipe: persisted.recipe,
            customCategoryName: persisted.customCategoryName ?? "",
            comments: persisted.comments.map(\.comment),
            reportCount: persisted.reportCount ?? 0,
            moderationStatus: persisted.moderationStatus ?? .normal
        )
    }

}
