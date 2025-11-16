//
//  prompts.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

import Foundation
import UIKit

class ClaudePromptService {
    
    static let shared = ClaudePromptService()
    
    // Get API key
    private var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            return key
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String {
            return key
        }
        fatalError("ANTHROPIC_API_KEY not found")
    }
    
    /// Main function to analyze a meal
    func analyzeMeal(
        image: UIImage,
        userId: UUID,
        userDescription: String?,
        mealType: String
    ) async throws -> (analysis: ClaudeAnalysisResult, displayText: String) {
        
        let prompt = generatePrompt(
            image: image,
            userId: userId,
            userDescription: userDescription,
            mealType: mealType
        )
        
        let jsonResponse = try await callClaudeAPI(prompt: prompt, image: image)
        let analysis = try parseClaudeResponse(jsonResponse)
        
        // Log meal to database
        _ = MealManager.shared.logMeal(
            userId: userId,
            mealType: mealType,
            image: image,
            analysis: analysis
        )
        
        let displayText = generateDisplayText(analysis: analysis, mealType: mealType)
        return (analysis, displayText)
    }
    
    private func generatePrompt(
        image: UIImage,
        userId: UUID,
        userDescription: String?,
        mealType: String
    ) -> String {
        
        let age = getAge(userId: userId)
        let weight = getWeight(userId: userId)
        let height = getHeight(userId: userId)
        let exercise = getExercise(userId: userId)
        let gender = getGender(userId: userId)
        let restrictions = getRestrictions(userId: userId)
        let goal = getGoal(userId: userId)
        let past = getPastMealsSummary(userId: userId)
        
        let descText = userDescription.map { " The food contains: \($0)." } ?? ""
        
        return """
        You are a nutrition analysis assistant. Analyze the provided meal image and user information, and return the results strictly as a JSON object with the following structure:
        
        {
          "protein": 0.0,
          "carbs": 0.0,
          "fat": 0.0,
          "fiber": 0.0,
          "sugar": 0.0,
          "sodium": 0.0,
          "foodItems": "item1, item2, item3",
          "healthScore": 0.0,
          "portionQualityScore": 0.0,
          "varietyScore": 0.0,
          "nutritionBalanceScore": 0.0,
          "recommendations": "Your recommendations here"
        }
        
        ### Additional User Description:
        \(descText)
        
        ### User Information:
        - Age: \(age)
        - Weight: \(weight) lbs
        - Height: \(height) inches
        - Gender: \(gender)
        - Meal Type: \(mealType)
        - Exercise frequency: \(exercise)
        - Health goal: \(goal)
        - Dietary restrictions: \(restrictions)
        
        ### Past Meal Averages:
        \(past)
        
        ### Instructions:
        1. Estimate macronutrient values (in grams) and food items from the image and context.
        2. Fill out the JSON in the format specified. For score fields, provide a number between 1 and 10.
        3. Provide a short, helpful string with food recommendations.
        4. Respond with **ONLY** the JSON object — no explanations, no extra text.
        5. If the user's gender is "prefer not to say" or "Not specified", do not consider gender.
        
        Return only valid JSON.
        """
    }
    
    private func callClaudeAPI(prompt: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1)
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw NSError(domain: "APIError", code: 2)
        }
        
        return text
    }
    
    private func parseClaudeResponse(_ jsonString: String) throws -> ClaudeAnalysisResult {
        let cleanedString = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedString.data(using: .utf8) else {
            throw NSError(domain: "JSONError", code: 3)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ClaudeAnalysisResult.self, from: data)
    }
    
    private func generateDisplayText(analysis: ClaudeAnalysisResult, mealType: String) -> String {
        let scoreEmoji = analysis.healthScore >= 8 ? "🌟" : analysis.healthScore >= 6 ? "👍" : "💡"
        
        return """
        \(scoreEmoji) \(mealType) Analysis
        
        📊 Nutrition Breakdown:
        • Protein: \(String(format: "%.1f", analysis.protein))g
        • Carbs: \(String(format: "%.1f", analysis.carbs))g
        • Fat: \(String(format: "%.1f", analysis.fat))g
        
        🎯 Scores:
        • Overall Health: \(String(format: "%.1f", analysis.healthScore))/10
        • Portion Quality: \(String(format: "%.1f", analysis.portionQualityScore))/10
        • Variety: \(String(format: "%.1f", analysis.varietyScore))/10
        • Balance: \(String(format: "%.1f", analysis.nutritionBalanceScore))/10
        
        💡 Recommendations:
        \(analysis.recommendations)
        """
    }
}

// MARK: - Make ClaudeAnalysisResult Codable
extension ClaudeAnalysisResult: Codable {
    enum CodingKeys: String, CodingKey {
        case protein, carbs, fat, fiber, sugar, sodium
        case foodItems, healthScore, portionQualityScore
        case varietyScore, nutritionBalanceScore, recommendations
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        protein = try container.decode(Float.self, forKey: .protein)
        carbs = try container.decode(Float.self, forKey: .carbs)
        fat = try container.decode(Float.self, forKey: .fat)
        fiber = try container.decode(Float.self, forKey: .fiber)
        sugar = try container.decode(Float.self, forKey: .sugar)
        sodium = try container.decode(Float.self, forKey: .sodium)
        foodItems = try container.decode(String.self, forKey: .foodItems)
        healthScore = try container.decode(Float.self, forKey: .healthScore)
        portionQualityScore = try container.decode(Float.self, forKey: .portionQualityScore)
        varietyScore = try container.decode(Float.self, forKey: .varietyScore)
        nutritionBalanceScore = try container.decode(Float.self, forKey: .nutritionBalanceScore)
        recommendations = try container.decode(String.self, forKey: .recommendations)
    }
}