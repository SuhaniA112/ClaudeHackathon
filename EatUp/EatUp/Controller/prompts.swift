//
//  prompts.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//
 
import SwiftAnthropic
import UIKit

package model

class Prompt{
    
    public Prompt(){
        let client = Anthropic(apiKey: Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as! String)
        MealManager mm = new MealManager();
        
        struct Secrets {
            static let claudeAPIKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]
        }
    }
    
    func getFeedback(img: UIImage, usr : Int, desc: String, mealType:String) -> String {
        
        prompt = getPrompt(img, usr, desc, mealType)
        
        let response = try await client.messages.create(
            model: "claude-3-5-sonnet-latest",
            maxTokens: 250,
            messages: [
                .init(role: .user, content: .text(prompt))
            ]
        )
        
        let jsonString = response.content.first?.text ?? ""
        
        let analysis = try JSONDecoder().decode(
            ClaudeAnalysisResult.self,
            from: Data(jsonString.utf8)
        )
        
        mm.logMeal(usr, img, analysis);
        
        // create text output for what the user should see
        
        return text;
    }
    
    
    func getPrompt(img: UIImage, usr: Int, usrdesc : String, mealType: String) -> String {
        
        // fetch: user age, user weight, user past data, user health goal
        let base64Image = img.base64EncodedString()
        
        age = model.getAge(usr);
        weight = model.getWeight(usr);
        height = model.getHeight(usr);
        exercise = model.getExercise(usr);
        gender = model.getGender(usr);
        restrictions = model.getRefstrictions(usr);
        past = getPast(usr);
        healthGoal = model.getGoal(usr);
        desc = " "
        if (usrdesc != null){
            desc = " The food contains: " + usrdesc + "."
        }
        
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
        
    }
    
}
