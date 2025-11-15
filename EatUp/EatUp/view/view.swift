import SwiftUI

// MARK: - View Models for UI Display

struct MealTypeAnalytics {
    let mealType: String // "Breakfast", "Lunch", "Dinner"
    let mealCount: Int
    let averageHealthScore: Float
    let averagePortionScore: Float
    let averageVarietyScore: Float
    let averageBalanceScore: Float
    //hihello
    // Macro totals for pie chart
    let totalProtein: Float
    let totalCarbs: Float
    let totalFat: Float
    
    // Calculated percentages for pie chart
    var proteinPercent: Float {
        let total = totalProtein + totalCarbs + totalFat
        return total > 0 ? (totalProtein / total) * 100 : 0
    }
    
    var carbPercent: Float {
        let total = totalProtein + totalCarbs + totalFat
        return total > 0 ? (totalCarbs / total) * 100 : 0
    }
    
    var fatPercent: Float {
        let total = totalProtein + totalCarbs + totalFat
        return total > 0 ? (totalFat / total) * 100 : 0
    }
    
    // All Claude recommendations combined
    let combinedRecommendations: String
}

struct DailyAnalytics {
    let date: Date
    let breakfastAnalytics: MealTypeAnalytics?
    let lunchAnalytics: MealTypeAnalytics?
    let dinnerAnalytics: MealTypeAnalytics?
    
    // Overall day score (average of all meals)
    var overallDayScore: Float {
        var scores: [Float] = []
        if let b = breakfastAnalytics { scores.append(b.averageHealthScore) }
        if let l = lunchAnalytics { scores.append(l.averageHealthScore) }
        if let d = dinnerAnalytics { scores.append(d.averageHealthScore) }
        
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Float(scores.count)
    }
    
    // Combined daily recommendations
    var dailySummary: String {
        var summaries: [String] = []
        if let b = breakfastAnalytics { summaries.append("Breakfast: \(b.combinedRecommendations)") }
        if let l = lunchAnalytics { summaries.append("Lunch: \(l.combinedRecommendations)") }
        if let d = dinnerAnalytics { summaries.append("Dinner: \(d.combinedRecommendations)") }
        return summaries.joined(separator: "\n\n")
    }
}

// MARK: - Analytics Calculator
class NutritionAnalyticsCalculator {
    
    /// Calculate analytics for a specific meal type on a specific day
    static func calculateMealTypeAnalytics(
        userId: UUID,
        mealType: String,
        date: Date
    ) -> MealTypeAnalytics? {
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Get all meals of this type for the day
        let allMeals = MealManager.shared.getMeals(
            userId: userId,
            from: startOfDay,
            to: endOfDay
        )
        
        let mealsOfType = allMeals.filter { $0.mealType?.lowercased() == mealType.lowercased() }
        
        guard !mealsOfType.isEmpty else { return nil }
        
        // Aggregate scores
        var totalHealthScore: Float = 0
        var totalPortionScore: Float = 0
        var totalVarietyScore: Float = 0
        var totalBalanceScore: Float = 0
        
        var totalProtein: Float = 0
        var totalCarbs: Float = 0
        var totalFat: Float = 0
        
        var recommendations: [String] = []
        
        for meal in mealsOfType {
            totalHealthScore += meal.healthScore
            totalPortionScore += meal.portionQualityScore
            totalVarietyScore += meal.varietyScore
            totalBalanceScore += meal.nutritionBalanceScore
            
            totalProtein += meal.protein
            totalCarbs += meal.carbs
            totalFat += meal.fat
            
            if let rec = meal.claudeRecommendations, !rec.isEmpty {
                recommendations.append(rec)
            }
        }
        
        let count = Float(mealsOfType.count)
        
        return MealTypeAnalytics(
            mealType: mealType.capitalized,
            mealCount: mealsOfType.count,
            averageHealthScore: totalHealthScore / count,
            averagePortionScore: totalPortionScore / count,
            averageVarietyScore: totalVarietyScore / count,
            averageBalanceScore: totalBalanceScore / count,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            combinedRecommendations: recommendations.joined(separator: " ")
        )
    }
    
    /// Calculate full day analytics
    static func calculateDailyAnalytics(userId: UUID, date: Date) -> DailyAnalytics {
        return DailyAnalytics(
            date: date,
            breakfastAnalytics: calculateMealTypeAnalytics(userId: userId, mealType: "breakfast", date: date),
            lunchAnalytics: calculateMealTypeAnalytics(userId: userId, mealType: "lunch", date: date),
            dinnerAnalytics: calculateMealTypeAnalytics(userId: userId, mealType: "dinner", date: date)
        )
    }
}

// MARK: - SwiftUI Views

struct DailyNutritionView: View {
    let userId: UUID
    let date: Date
    @State private var analytics: DailyAnalytics?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Day Score
                if let stats = userStats {
                    UserStatsCard(stats: stats)
                }
                
                if let analytics = analytics {
                    DayScoreCard(score: analytics.overallDayScore)
                    
                    // Meal Type Sections
                    if let breakfast = analytics.breakfastAnalytics {
                        MealTypeSectionView(analytics: breakfast)
                    }
                    
                    if let lunch = analytics.lunchAnalytics {
                        MealTypeSectionView(analytics: lunch)
                    }
                    
                    if let dinner = analytics.dinnerAnalytics {
                        MealTypeSectionView(analytics: dinner)
                    }
                    
                    // Daily Summary
                    DailySummaryCard(summary: analytics.dailySummary)
                }
            }
            .padding()
        }
        .onAppear {
            analytics = NutritionAnalyticsCalculator.calculateDailyAnalytics(
                userId: userId,
                date: date
            )
            userStats = UserManager.shared.getUserStats(userId)
        }
    }
}

// User Stats Card View 
struct UserStatsCard: View {
    let stats: UserStats
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Journey")
                        .font(.headline)
                    Text("Member since \(stats.joinedDateString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(stats.daysOnApp) days")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            // Streak Stats
            HStack(spacing: 30) {
                // Current Streak
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.title)
                        Text("\(stats.currentStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                // Longest Streak
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("🏆")
                            .font(.title)
                        Text("\(stats.longestStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.purple)
                    }
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Motivational message
            if stats.currentStreak > 0 {
                Text(streakMessage(for: stats.currentStreak))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    func streakMessage(for streak: Int) -> String {
        switch streak {
        case 1: return "Great start! Keep it going tomorrow! 💪"
        case 2...6: return "You're building momentum! 🚀"
        case 7...13: return "One week down! You're on fire! 🔥"
        case 14...29: return "Two weeks strong! Consistency is key! ⭐"
        case 30...: return "Amazing dedication! You're unstoppable! 🎉"
        default: return ""
        }
    }
}

struct DayScoreCard: View {
    let score: Float
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Today's Overall Score")
                .font(.headline)
            
            Text(String(format: "%.1f", score))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(scoreColor)
            
            Text("/ 10")
                .font(.title2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<10) { index in
                    Circle()
                        .fill(index < Int(score) ? scoreColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var scoreColor: Color {
        switch score {
        case 8...: return .green
        case 6..<8: return .orange
        default: return .red
        }
    }
}

struct MealTypeSectionView: View {
    let analytics: MealTypeAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(analytics.mealType)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(String(format: "%.1f/10", analytics.averageHealthScore))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor(analytics.averageHealthScore))
            }
            
            // Pie Chart for Macros
            MacroPieChartView(
                proteinPercent: analytics.proteinPercent,
                carbPercent: analytics.carbPercent,
                fatPercent: analytics.fatPercent
            )
            
            // Score Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Breakdown")
                    .font(.headline)
                
                ScoreRow(
                    label: "Portions",
                    score: analytics.averagePortionScore,
                    icon: "📏"
                )
                
                ScoreRow(
                    label: "Variety",
                    score: analytics.averageVarietyScore,
                    icon: "🥗"
                )
                
                ScoreRow(
                    label: "Balance",
                    score: analytics.averageBalanceScore,
                    icon: "⚖️"
                )
            }
            
            // Recommendations
            if !analytics.combinedRecommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Suggestions")
                        .font(.headline)
                    
                    Text(analytics.combinedRecommendations)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    func scoreColor(_ score: Float) -> Color {
        switch score {
        case 8...: return .green
        case 6..<8: return .orange
        default: return .red
        }
    }
}

struct MacroPieChartView: View {
    let proteinPercent: Float
    let carbPercent: Float
    let fatPercent: Float
    
    var body: some View {
        VStack(spacing: 12) {
            // Pie chart visualization
            ZStack {
                // Protein slice
                PieSlice(
                    startAngle: .degrees(0),
                    endAngle: .degrees(Double(proteinPercent) * 3.6)
                )
                .fill(Color.red)
                
                // Carbs slice
                PieSlice(
                    startAngle: .degrees(Double(proteinPercent) * 3.6),
                    endAngle: .degrees(Double(proteinPercent + carbPercent) * 3.6)
                )
                .fill(Color.blue)
                
                // Fat slice
                PieSlice(
                    startAngle: .degrees(Double(proteinPercent + carbPercent) * 3.6),
                    endAngle: .degrees(360)
                )
                .fill(Color.orange)
            }
            .frame(width: 150, height: 150)
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(
                    color: .red,
                    label: "Protein",
                    value: String(format: "%.0f%%", proteinPercent)
                )
                
                LegendItem(
                    color: .blue,
                    label: "Carbs",
                    value: String(format: "%.0f%%", carbPercent)
                )
                
                LegendItem(
                    color: .orange,
                    label: "Fat",
                    value: String(format: "%.0f%%", fatPercent)
                )
            }
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(
            center: center,
            radius: rect.width / 2,
            startAngle: startAngle - .degrees(90),
            endAngle: endAngle - .degrees(90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct ScoreRow: View {
    let label: String
    let score: Float
    let icon: String
    
    var body: some View {
        HStack {
            Text(icon)
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score / 10), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text(String(format: "%.1f", score))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    var scoreColor: Color {
        switch score {
        case 8...: return .green
        case 6..<8: return .orange
        default: return .red
        }
    }
}

struct DailySummaryCard: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 Daily Summary")
                .font(.headline)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview
struct DailyNutritionView_Previews: PreviewProvider {
    static var previews: some View {
        DailyNutritionView(
            userId: UUID(),
            date: Date()
        )
    }
}
