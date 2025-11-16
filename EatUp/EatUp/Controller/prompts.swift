<<<<<<< HEAD
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
=======
import SwiftAnthropic
import UIKit;

// MARK: - Client

let client = Anthropic(
    apiKey: Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
)

// MARK: - Dependencies

let mealManager = MealManager()

// MARK: - Main Function

func getFeedback(
    img: UIImage,
    usr: Int,
    desc: String?,
    mealType: String
) async throws -> String {

    let prompt = getPrompt(
        img: img,
        usr: usr,
        usrdesc: desc,
        mealType: mealType
    )
    
    let userMessage = MessageParameter.Message(
        role: .user,
        content: .text(prompt)
    )

    let response = try await client.messages.create(
        model: "claude-3-5-sonnet-latest",
        maxTokens: 250,
        messages: [userMessage]
    )

    let jsonString = response.content.first?.text ?? ""
    
    struct StringOrFloat: Decodable {
        let value: Float
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let f = try? container.decode(Float.self) {
                value = f
            } else if let s = try? container.decode(String.self), let f = Float(s) {
                value = f
            } else {
                value = 0
            }
>>>>>>> f2313d40c0c3eeedcddfa5f3b444c3bbf86d9e04
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String {
            return key
        }
        fatalError("ANTHROPIC_API_KEY not found")
    }
<<<<<<< HEAD
    
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
=======

    struct ClaudeAnalysisResult: Decodable {
        let protein: StringOrFloat
        let carbs: StringOrFloat
        let fat: StringOrFloat
        let fiber: StringOrFloat
        let sugar: StringOrFloat
        let sodium: StringOrFloat
        let foodItems: [String]
        let healthScore: StringOrFloat
        let portionQualityScore: StringOrFloat
        let varietyScore: StringOrFloat
        let nutritionBalanceScore: StringOrFloat
        let recommendations: String
    }
    
    let analysis = try JSONDecoder().decode(
        ClaudeAnalysisResult.self,
        from: Data(jsonString.utf8)
    )
    
    // Log the meal
    mealManager.logMeal(userId: usr, image: img, analysis: analysis)
    
    // Generate user-facing text (define how you want this string)
    let text = """
    Protein: \(analysis.protein)
    Carbs: \(analysis.carbs)
    Fat: \(analysis.fat)
    Score: \(analysis.healthScore)
    """
    
    return text
}
    
func getPrompt(
    img: UIImage,
    usr: Int,
    usrdesc: String?,
    mealType: String
) -> String {
    
    // Convert image to base64
    let base64Image = img.jpegData(compressionQuality: 0.8)?
        .base64EncodedString() ?? ""
    
    // Fetch user info
    let age = getAge(uid: usr)
    let weight = getWeight(uid: usr)
    let height = getHeight(uid: usr)
    let exercise = getExercise(uid: usr)
    let gender = getGender(uid: usr)
    let restrictions = getRestriction(uid: usr)
    let past = getPast(uid: usr)
    let goal = getGoal(uid: usr)
    
    let descText = usrdesc != nil && usrdesc!.isEmpty == false
        ? "The food contains: \(usrdesc!)."
        : ""
    
    // Prompt template
    let prompt = """
    You are a nutrition analysis assistant. Analyze the provided meal image and user information, and return the results strictly as a JSON object with the following structure:

    {
      "protein": Number,
      "carbs": Number,
      "fat": Number,
      "fiber": Number,
      "sugar": Number,
      "sodium": Number,
      "foodItems": [String],
      "healthScore": Number,
      "portionQualityScore": Number,
      "varietyScore": Number,
      "nutritionBalanceScore": Number,
      "recommendations": String
    }

    ### Image (base64 encoded):
    \(base64Image)

    ### Additional User Description:
    \(descText)

    ### User Information:
    - Age: \(age)
    - Weight: \(weight) lbs
    - Height: \(height) inches
    - Gender: \(gender)
    - Meal Type: \(mealType)
    - Exercise frequency: \(exercise) times per week
    - Health goal: \(goal)
    - Dietary restrictions: \(restrictions)

    ### Past Meal Averages:
    \(past)

    ### Instructions:
    1. Estimate macronutrient values and food items from the image and context.
    2. Fill out the JSON in the format specified. For each category accepting a number provide an integer between 1 and 10 inclusive considering their goals and information.
    3. Provide a short, helpful string with food recommendations for the user accounting for their health goal and dietary restrictions.
    4. Respond with **ONLY** the JSON object — no explanations, no extra text.
    5. If the user's gender is described as prefer not to say do not consider gender when providing results

    Return only valid JSON.
    """
    
    return prompt
>>>>>>> f2313d40c0c3eeedcddfa5f3b444c3bbf86d9e04
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