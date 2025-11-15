//
//  prompts.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

import SwiftAnthropic
import UIKit

package model

let client = Anthropic(apiKey: Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as! String)

func getFeedback(img: UIImage, usr : Int, desc: String) -> String {
    
    prompt = getPrompt(img, usr, desc)
    
    let response = try await client.messages.create(
        model: "claude-3-5-sonnet-latest",
        maxTokens: 512,
        messages: [
            .init(role: .user, content: .text(prompt))
        ]
    )
    let text = response.content.first?.text ?? "(no response)"
    
    mm.logMeal(usr, img, text);
    
    return msg;
}


func getPrompt(img: UIImage, usr: Int, usrdesc : String) -> String {
    
    // fetch: user age, user weight, user past data, user health goal
    let base64Image = img.base64EncodedString()
    
    age = model.getAge(usr);
    weight = model.getWeight(usr);
    exercise = model.getExercise(usr);
    gender = model.getGender(usr);
    restrictions = model.getRefstrictions(usr);
    past = []; // TODO
    healthGoal = model.getGoal(usr);
    desc = " "
    if (usrdesc != null){
        desc = " The food contains: " + usrdesc + "."
    }
    
    if (gender is "prefer not to say") {
        String prompt = "Please respond with an array of integers with comma deliminators. For this image rate the food proportions in terms of protein, carbohydrates, and fat consumption. Provide me with 3 numbers, each on a scale of 1-10 corresponding to each category listed. The food image is: " + base64Image + "." + desc + "For an individual with age " + age + " and weight " + weight + " pounds and exercises " + exercise + " times per week and a health goal of " + health goal + " how healthy is their meal on a scale of 1 - 10? " + "Also, what are some suggestions for improving this meal? They're dietary restrictions are " + restrictions + "Additionally, this the average of their past weeks in the same format of 4 numbers, how does today compare to that: " + past
    } else {
        String prompt = "Please respond with an array of integers with comma deliminators. For this image rate the food proportions in terms of protein, carbohydrates, and fat consumption. Provide me with 3 numbers, each on a scale of 1-10 corresponding to each category listed. The food image is: " + base64Image + "." + desc + "For an individual of gender " + gender + " with age " + age + " and weight " + weight + " pounds and exercises " + exercise + " times per week and a health goal of " + health goal + " how healthy is their meal on a scale of 1 - 10? " + "Also, what are some suggestions for improving this meal? They're dietary restrictions are " + restrictions + "Additionally, this the average of their past weeks in the same format of 4 numbers, how does today compare to that: " + past
    }
    
    
    
}


