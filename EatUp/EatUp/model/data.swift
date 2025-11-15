import CoreData
import UIKit
import Foundation

// User Manager
class UserManager {
    static let shared = UserManager()
    let context = CoreDataManager.shared.context
    
    // CREATE: Register new user with email lookup
    func createUser(email: String, profile: UserProfileData) -> User? {
        // Check if email already exists
        if let existingUser = getUserByEmail(email) {
            print("User with email \(email) already exists")
            return existingUser
        }
        
        let user = User(context: context)
        user.userId = UUID()
        user.email = email.lowercased()
        user.createdAt = Date()
        user.currentStreak = 0
        user.longestStreak = 0
        user.lastUploadDate = nil
        
        // Create associated profile
        let userProfile = UserProfile(context: context)
        userProfile.userId = user.userId
        userProfile.age = Int16(profile.age)
        userProfile.weight = profile.weight
        userProfile.height = profile.height
        userProfile.gender = profile.gender
        userProfile.activityLevel = profile.activityLevel
        userProfile.dietType = profile.dietType
        userProfile.proteinTarget = profile.proteinTarget
        userProfile.carbTarget = profile.carbTarget
        userProfile.fatTarget = profile.fatTarget
        userProfile.healthGoal = profile.healthGoal
        
        user.profile = userProfile
        
        CoreDataManager.shared.saveContext()
        print("Created user: \(email) with ID: \(user.userId?.uuidString ?? "")")
        return user
    }
    
    // READ: Get user by email (login flow)
    func getUserByEmail(_ email: String) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email.lowercased())
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch user by email: \(error)")
            return nil
        }
    }
    
    // READ: Get user by ID (most common operation)
    func getUserById(_ userId: UUID) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch user by ID: \(error)")
            return nil
        }
    }
    
    // UPDATE: Modify user profile
    func updateUserProfile(_ userId: UUID, updates: UserProfileData) {
        guard let user = getUserById(userId),
              let profile = user.profile else { return }
        
        profile.age = Int16(updates.age)
        profile.weight = updates.weight
        profile.height = updates.height
        profile.activityLevel = updates.activityLevel
        profile.proteinTarget = updates.proteinTarget
        profile.carbTarget = updates.carbTarget
        profile.fatTarget = updates.fatTarget
        
        CoreDataManager.shared.saveContext()
        print("Updated profile for user: \(userId)")
    }

    // Get user stats for display
    func getUserStats(_ userId: UUID) -> UserStats? {
        guard let user = getUserById(userId) else { return nil }
        
        let calendar = Calendar.current
        let daysSinceJoined = calendar.dateComponents([.day], from: user.createdAt ?? Date(), to: Date()).day ?? 0
        
        return UserStats(
            joinedDate: user.createdAt ?? Date(),
            daysOnApp: daysSinceJoined,
            currentStreak: Int(user.currentStreak),
            longestStreak: Int(user.longestStreak)
        )
    }
}

// MARK: - Meal Management (Per-User Data)
class MealManager {
    static let shared = MealManager()
    let context = CoreDataManager.shared.context
    
    // CREATE: Log meal for specific user
    func logMeal(userId: UUID, mealType: String, image: UIImage, analysis: ClaudeAnalysisResult) -> Meal? {
        // Save image to file system
        guard let imageURL = FileSystemManager.shared.saveImage(image, userId: userId),
              let thumbnailURL = FileSystemManager.shared.saveThumbnail(image, userId: userId) else {
            print("Failed to save images")
            return nil
        }
        
        let meal = Meal(context: context)
        meal.mealId = UUID()
        meal.userId = userId
        meal.timestamp = Date()
        meal.imageURL = imageURL.path
        meal.thumbnailURL = thumbnailURL.path
        
        // Nutrition data
        meal.mealType = mealType
        meal.protein = analysis.protein
        meal.carbs = analysis.carbs
        meal.fat = analysis.fat
        meal.fiber = analysis.fiber
        meal.sugar = analysis.sugar
        meal.sodium = analysis.sodium
        meal.foodItems = analysis.foodItems
        
        // Scores
        meal.healthScore = analysis.healthScore
        meal.portionQualityScore = analysis.portionQualityScore
        meal.varietyScore = analysis.varietyScore
        meal.nutritionBalanceScore = analysis.nutritionBalanceScore
        
        // Claude recommendations
        meal.claudeRecommendations = analysis.recommendations
        
        // Week number for aggregation
        meal.weekNumber = Int16(Calendar.current.component(.weekOfYear, from: Date()))
        
        CoreDataManager.shared.saveContext()
        print("Logged meal for user \(userId)")

        // Update streak tracking
        StreakManager.shared.updateStreak(for: userId)
        
        // Trigger weekly stats update if needed
        WeeklyStatsManager.shared.updateWeeklyStats(for: userId)
        
        return meal
    }
    
    // READ: Get user's meals with pagination
    func getMeals(userId: UUID, limit: Int = 20, offset: Int = 0) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals: \(error)")
            return []
        }
    }
    
    // READ: Get meals for date range
    func getMeals(userId: UUID, from startDate: Date, to endDate: Date) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND timestamp >= %@ AND timestamp <= %@",
            userId as CVarArg, startDate as CVarArg, endDate as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals for date range: \(error)")
            return []
        }
    }

    // READ: Get meals by type for a user
    func getMealsByType(userId: UUID, mealType: String, limit: Int = 20) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND mealType == %@", userId as CVarArg, mealType)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals by type: \(error)")
            return []
        }
    }
    
    // READ: Get today's meals
    func getTodaysMeals(userId: UUID) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return getMeals(userId: userId, from: startOfDay, to: endOfDay)
    }

    // READ: Get today's meals filtered by type
    func getTodaysMealsByType(userId: UUID, mealType: String) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND mealType == %@ AND timestamp >= %@ AND timestamp <= %@",
            userId as CVarArg, mealType, startOfDay as CVarArg, endOfDay as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch today's meals by type: \(error)")
            return []
        }
    }
    
    // ANALYTICS: Calculate daily totals
    func getDailyTotals(userId: UUID, for date: Date = Date()) -> DailyNutritionTotals {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let meals = getMeals(userId: userId, from: startOfDay, to: endOfDay)
        
        var totals = DailyNutritionTotals()
        for meal in meals {
            totals.totalProtein += meal.protein
            totals.totalCarbs += meal.carbs
            totals.totalFat += meal.fat
            totals.mealCount += 1
            totals.averageHealthScore += meal.healthScore
        }
        
        if totals.mealCount > 0 {
            totals.averageHealthScore /= Float(totals.mealCount)
        }
        
        return totals
    }
    
    // DELETE: Remove meal and associated files
    func deleteMeal(_ meal: Meal) {
        if let imagePath = meal.imageURL {
            FileSystemManager.shared.deleteImage(path: imagePath)
        }
        if let thumbnailPath = meal.thumbnailURL {
            FileSystemManager.shared.deleteImage(path: thumbnailPath)
        }
        
        context.delete(meal)
        CoreDataManager.shared.saveContext()
    }
}

import CoreData
import UIKit
import Foundation

// User Manager
class UserManager {
    static let shared = UserManager()
    let context = CoreDataManager.shared.context
    
    // CREATE: Register new user with email lookup
    func createUser(email: String, profile: UserProfileData) -> User? {
        // Check if email already exists
        if let existingUser = getUserByEmail(email) {
            print("User with email \(email) already exists")
            return existingUser
        }
        
        let user = User(context: context)
        user.userId = UUID()
        user.email = email.lowercased()
        user.createdAt = Date()
        user.currentStreak = 0
        user.longestStreak = 0
        user.lastUploadDate = nil
        
        // Create associated profile
        let userProfile = UserProfile(context: context)
        userProfile.userId = user.userId
        userProfile.age = Int16(profile.age)
        userProfile.weight = profile.weight
        userProfile.height = profile.height
        userProfile.gender = profile.gender
        userProfile.activityLevel = profile.activityLevel
        userProfile.dietType = profile.dietType
        userProfile.proteinTarget = profile.proteinTarget
        userProfile.carbTarget = profile.carbTarget
        userProfile.fatTarget = profile.fatTarget
        userProfile.healthGoal = profile.healthGoal
        
        user.profile = userProfile
        
        CoreDataManager.shared.saveContext()
        print("Created user: \(email) with ID: \(user.userId?.uuidString ?? "")")
        return user
    }
    
    // READ: Get user by email (login flow)
    func getUserByEmail(_ email: String) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email.lowercased())
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch user by email: \(error)")
            return nil
        }
    }
    
    // READ: Get user by ID (most common operation)
    func getUserById(_ userId: UUID) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch user by ID: \(error)")
            return nil
        }
    }
    
    // UPDATE: Modify user profile
    func updateUserProfile(_ userId: UUID, updates: UserProfileData) {
        guard let user = getUserById(userId),
              let profile = user.profile else { return }
        
        profile.age = Int16(updates.age)
        profile.weight = updates.weight
        profile.height = updates.height
        profile.activityLevel = updates.activityLevel
        profile.proteinTarget = updates.proteinTarget
        profile.carbTarget = updates.carbTarget
        profile.fatTarget = updates.fatTarget
        
        CoreDataManager.shared.saveContext()
        print("Updated profile for user: \(userId)")
    }

    // *** ADDED: Get user stats for display ***
    func getUserStats(_ userId: UUID) -> UserStats? {
        guard let user = getUserById(userId) else { return nil }
        
        let calendar = Calendar.current
        let daysSinceJoined = calendar.dateComponents([.day], from: user.createdAt ?? Date(), to: Date()).day ?? 0
        
        return UserStats(
            joinedDate: user.createdAt ?? Date(),
            daysOnApp: daysSinceJoined,
            currentStreak: Int(user.currentStreak),
            longestStreak: Int(user.longestStreak)
        )
    }
}

// MARK: - Meal Management (Per-User Data)
class MealManager {
    static let shared = MealManager()
    let context = CoreDataManager.shared.context
    
    // CREATE: Log meal for specific user
    func logMeal(userId: UUID, mealType: String, image: UIImage, analysis: ClaudeAnalysisResult) -> Meal? {
        // Save image to file system
        guard let imageURL = FileSystemManager.shared.saveImage(image, userId: userId),
              let thumbnailURL = FileSystemManager.shared.saveThumbnail(image, userId: userId) else {
            print("Failed to save images")
            return nil
        }
        
        let meal = Meal(context: context)
        meal.mealId = UUID()
        meal.userId = userId
        meal.timestamp = Date()
        meal.imageURL = imageURL.path
        meal.thumbnailURL = thumbnailURL.path
        
        // Nutrition data
        meal.mealType = mealType
        meal.protein = analysis.protein
        meal.carbs = analysis.carbs
        meal.fat = analysis.fat
        meal.fiber = analysis.fiber
        meal.sugar = analysis.sugar
        meal.sodium = analysis.sodium
        meal.foodItems = analysis.foodItems
        
        // Scores
        meal.healthScore = analysis.healthScore
        meal.portionQualityScore = analysis.portionQualityScore
        meal.varietyScore = analysis.varietyScore
        meal.nutritionBalanceScore = analysis.nutritionBalanceScore
        
        // Claude recommendations
        meal.claudeRecommendations = analysis.recommendations
        
        // Week number for aggregation
        meal.weekNumber = Int16(Calendar.current.component(.weekOfYear, from: Date()))
        
        CoreDataManager.shared.saveContext()
        print("Logged meal for user \(userId)")

        // *** ADDED: Update streak tracking ***
        StreakManager.shared.updateStreak(for: userId)
        
        // Trigger weekly stats update if needed
        WeeklyStatsManager.shared.updateWeeklyStats(for: userId)
        
        return meal
    }
    
    // READ: Get user's meals with pagination
    func getMeals(userId: UUID, limit: Int = 20, offset: Int = 0) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals: \(error)")
            return []
        }
    }
    
    // READ: Get meals for date range
    func getMeals(userId: UUID, from startDate: Date, to endDate: Date) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND timestamp >= %@ AND timestamp <= %@",
            userId as CVarArg, startDate as CVarArg, endDate as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals for date range: \(error)")
            return []
        }
    }

    // READ: Get meals by type for a user
    func getMealsByType(userId: UUID, mealType: String, limit: Int = 20) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND mealType == %@", userId as CVarArg, mealType)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals by type: \(error)")
            return []
        }
    }
    
    // READ: Get today's meals
    func getTodaysMeals(userId: UUID) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return getMeals(userId: userId, from: startOfDay, to: endOfDay)
    }

    // READ: Get today's meals filtered by type
    func getTodaysMealsByType(userId: UUID, mealType: String) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND mealType == %@ AND timestamp >= %@ AND timestamp <= %@",
            userId as CVarArg, mealType, startOfDay as CVarArg, endOfDay as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch today's meals by type: \(error)")
            return []
        }
    }
    
    // ANALYTICS: Calculate daily totals
    func getDailyTotals(userId: UUID, for date: Date = Date()) -> DailyNutritionTotals {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let meals = getMeals(userId: userId, from: startOfDay, to: endOfDay)
        
        var totals = DailyNutritionTotals()
        for meal in meals {
            totals.totalProtein += meal.protein
            totals.totalCarbs += meal.carbs
            totals.totalFat += meal.fat
            totals.mealCount += 1
            totals.averageHealthScore += meal.healthScore
        }
        
        if totals.mealCount > 0 {
            totals.averageHealthScore /= Float(totals.mealCount)
        }
        
        return totals
    }
    
    // DELETE: Remove meal and associated files
    func deleteMeal(_ meal: Meal) {
        if let imagePath = meal.imageURL {
            FileSystemManager.shared.deleteImage(path: imagePath)
        }
        if let thumbnailPath = meal.thumbnailURL {
            FileSystemManager.shared.deleteImage(path: thumbnailPath)
        }
        
        context.delete(meal)
        CoreDataManager.shared.saveContext()
    }
}

// MARK: - Streak Manager
class StreakManager {
    static let shared = StreakManager()
    let context = CoreDataManager.shared.context
    
    /// Update user's streak after logging a meal
    func updateStreak(for userId: UUID) {
        guard let user = UserManager.shared.getUserById(userId) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // If lastUploadDate is nil, this is first upload
        guard let lastUpload = user.lastUploadDate else {
            user.currentStreak = 1
            user.longestStreak = 1
            user.lastUploadDate = today
            CoreDataManager.shared.saveContext()
            print("Started new streak for user \(userId)")
            return
        }
        
        let lastUploadDay = calendar.startOfDay(for: lastUpload)
        
        // Check if already uploaded today
        if lastUploadDay == today {
            print("User already uploaded today - streak unchanged")
            return
        }
        
        // Check if yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           lastUploadDay == yesterday {
            // Consecutive day - increment streak
            user.currentStreak += 1
            user.lastUploadDate = today
            
            // Update longest streak if current is higher
            if user.currentStreak > user.longestStreak {
                user.longestStreak = user.currentStreak
            }
            
            CoreDataManager.shared.saveContext()
            print("Extended streak to \(user.currentStreak) days for user \(userId)")
        } else {
            // Streak broken - reset to 1
            user.currentStreak = 1
            user.lastUploadDate = today
            CoreDataManager.shared.saveContext()
            print("Streak broken - reset to 1 day for user \(userId)")
        }
    }
    
    /// Get days with uploads (for calendar visualization)
    func getDaysWithUploads(userId: UUID, from startDate: Date, to endDate: Date) -> [Date] {
        let meals = MealManager.shared.getMeals(userId: userId, from: startDate, to: endDate)
        
        let calendar = Calendar.current
        let uniqueDays = Set(meals.compactMap { meal -> Date? in
            guard let timestamp = meal.timestamp else { return nil }
            return calendar.startOfDay(for: timestamp)
        })
        
        return Array(uniqueDays).sorted()
    }
}

// MARK: - Weekly Statistics Manager
class WeeklyStatsManager {
    static let shared = WeeklyStatsManager()
    let context = CoreDataManager.shared.context
    
    // Calculate and store weekly aggregated stats
    func updateWeeklyStats(for userId: UUID) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get week boundaries
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
            return
        }
        
        // Get all meals for this week
        let meals = MealManager.shared.getMeals(userId: userId, from: weekStart, to: weekEnd)
        
        guard !meals.isEmpty else { return }
        
        // Check if weekly stat already exists
        let existingStat = getWeeklyStat(userId: userId, weekStart: weekStart)
        let weeklyStat = existingStat ?? WeeklyStat(context: context)
        
        if existingStat == nil {
            weeklyStat.weekId = UUID()
            weeklyStat.userId = userId
            weeklyStat.weekStartDate = weekStart
            weeklyStat.weekEndDate = weekEnd
        }
        
        // Aggregate data
        var totalProtein: Float = 0
        var totalCarbs: Float = 0
        var totalFat: Float = 0
        var totalHealthScore: Float = 0
        var bestMeal: Meal?
        var worstMeal: Meal?
        
        for meal in meals {
            totalProtein += meal.protein
            totalCarbs += meal.carbs
            totalFat += meal.fat
            totalHealthScore += meal.healthScore
            
            if bestMeal == nil || meal.healthScore > (bestMeal?.healthScore ?? 0) {
                bestMeal = meal
            }
            if worstMeal == nil || meal.healthScore < (worstMeal?.healthScore ?? 10) {
                worstMeal = meal
            }
        }
        
        let mealCount = Float(meals.count)
        weeklyStat.totalMeals = Int16(meals.count)
        weeklyStat.averageProtein = totalProtein / mealCount
        weeklyStat.averageCarbs = totalCarbs / mealCount
        weeklyStat.averageFat = totalFat / mealCount
        weeklyStat.averageHealthScore = totalHealthScore / mealCount
        weeklyStat.bestMealId = bestMeal?.mealId
        weeklyStat.worstMealId = worstMeal?.mealId
        
        // Determine trend
        if let previousWeek = getWeeklyStat(userId: userId, weekStart: calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!) {
            let scoreDiff = weeklyStat.averageHealthScore - previousWeek.averageHealthScore
            if scoreDiff > 0.5 {
                weeklyStat.weeklyTrend = "improving"
            } else if scoreDiff < -0.5 {
                weeklyStat.weeklyTrend = "declining"
            } else {
                weeklyStat.weeklyTrend = "maintaining"
            }
        } else {
            weeklyStat.weeklyTrend = "baseline"
        }
        
        CoreDataManager.shared.saveContext()
        print("Updated weekly stats for user \(userId)")
    }
    
    // Get weekly stat for specific week
    func getWeeklyStat(userId: UUID, weekStart: Date) -> WeeklyStat? {
        let fetchRequest: NSFetchRequest<WeeklyStat> = WeeklyStat.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND weekStartDate == %@",
            userId as CVarArg, weekStart as CVarArg
        )
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            return nil
        }
    }
    
    // Get all weekly stats for user
    func getAllWeeklyStats(userId: UUID) -> [WeeklyStat] {
        let fetchRequest: NSFetchRequest<WeeklyStat> = WeeklyStat.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "weekStartDate", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch weekly stats: \(error)")
            return []
        }
    }
}

// MARK: - File System Manager (User-Scoped)
class FileSystemManager {
    static let shared = FileSystemManager()
    
    private func getUserDirectory(userId: UUID) -> URL {
        let baseDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userDir = baseDir.appendingPathComponent("Users").appendingPathComponent(userId.uuidString)
        
        if !FileManager.default.fileExists(atPath: userDir.path) {
            try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        }
        
        return userDir
    }
    
    func saveImage(_ image: UIImage, userId: UUID) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return nil }
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = getUserDirectory(userId: userId).appendingPathComponent(filename)
        
        try? imageData.write(to: fileURL)
        return fileURL
    }
    
    func saveThumbnail(_ image: UIImage, userId: UUID) -> URL? {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let thumb = thumbnail,
              let thumbData = thumb.jpegData(compressionQuality: 0.5) else { return nil }
        
        let filename = "\(UUID().uuidString)_thumb.jpg"
        let fileURL = getUserDirectory(userId: userId).appendingPathComponent(filename)
        
        try? thumbData.write(to: fileURL)
        return fileURL
    }
    
    func loadImage(path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteImage(path: String) {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path))
    }
    
    func calculateUserStorageSize(userId: UUID) -> Int64 {
        let userDir = getUserDirectory(userId: userId)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: userDir,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}

// MARK: - Supporting Data Structures
struct UserProfileData {
    let age: Int
    let weight: Float
    let height: Float
    let gender: String
    let activityLevel: String
    let dietType: String
    let proteinTarget: Float
    let carbTarget: Float
    let fatTarget: Float
    let healthGoal: String
}

struct ClaudeAnalysisResult {
    let protein: Float
    let carbs: Float
    let fat: Float
    let fiber: Float
    let sugar: Float
    let sodium: Float
    let foodItems: String
    let healthScore: Float
    let portionQualityScore: Float
    let varietyScore: Float
    let macroBalanceScore: Float
    let recommendations: String
}

struct DailyNutritionTotals {
    var totalProtein: Float = 0
    var totalCarbs: Float = 0
    var totalFat: Float = 0
    var mealCount: Int = 0
    var averageHealthScore: Float = 0
}

// MARK: - User Stats Struct
struct UserStats {
    let joinedDate: Date
    let daysOnApp: Int
    let currentStreak: Int
    let longestStreak: Int
    
    var joinedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinedDate)
    }
}

// MARK: - Core Data Stack
class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NutritionAppModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data load failed: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
