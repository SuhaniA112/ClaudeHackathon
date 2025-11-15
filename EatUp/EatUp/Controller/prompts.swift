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
        }
    }

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
}
