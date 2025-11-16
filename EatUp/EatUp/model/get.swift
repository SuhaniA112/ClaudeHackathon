//
//  get.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

import Foundation

// Helper functions to fetch user data
func getAge(userId: UUID) -> Int {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return 0 }
    return Int(profile.age)
}

func getWeight(userId: UUID) -> Float {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return 0 }
    return profile.weight
}

func getHeight(userId: UUID) -> Float {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return 0 }
    return profile.height
}

func getExercise(userId: UUID) -> String {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return "Not specified" }
    return profile.activityLevel ?? "Not specified"
}

func getGender(userId: UUID) -> String {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return "Not specified" }
    return profile.gender ?? "Not specified"
}

func getRestrictions(userId: UUID) -> String {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return "None" }
    return profile.dietType ?? "None"
}

func getGoal(userId: UUID) -> String {
    guard let user = UserManager.shared.getUserById(userId),
          let profile = user.profile else { return "General wellness" }
    return profile.healthGoal ?? "General wellness"
}

func getPastMealsSummary(userId: UUID) -> String {
    let calendar = Calendar.current
    let now = Date()
    
    guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
          let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
        return "No past data available"
    }
    
    let meals = MealManager.shared.getMeals(userId: userId, from: weekStart, to: weekEnd)
    
    guard !meals.isEmpty else {
        return "No meals logged this week"
    }
    
    var totalProtein: Float = 0
    var totalCarbs: Float = 0
    var totalFat: Float = 0
    var totalHealthScore: Float = 0
    
    for meal in meals {
        totalProtein += meal.protein
        totalCarbs += meal.carbs
        totalFat += meal.fat
        totalHealthScore += meal.healthScore
    }
    
    let count = Float(meals.count)
    let avgProtein = totalProtein / count
    let avgCarbs = totalCarbs / count
    let avgFat = totalFat / count
    let avgHealthScore = totalHealthScore / count
    
    return """
    Weekly averages (\(meals.count) meals):
    - Protein: \(String(format: "%.1f", avgProtein))g
    - Carbs: \(String(format: "%.1f", avgCarbs))g
    - Fat: \(String(format: "%.1f", avgFat))g
    - Health Score: \(String(format: "%.1f", avgHealthScore))/10
    """
}