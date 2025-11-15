//
//  prompts.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

import SwiftAnthropic
import UIKit

package model

func getFeedback(img: UIImage, usr : Int) -> String {
    
    prompt = getPrompt(img, usr)
    // get msg
    
    // parse msg, add data to model etc.
   // return relevant content
    return msg;
}


func getPrompt(img: UIImage, usr: Int) -> String {
    
    // fetch: user age, user weight, user past data, user health goal
    let base64Image = img.base64EncodedString()
    
    age = model.getAge(usr);
    weight = model.getWeight(usr);
    exercise = model.getExercise(usr);
    gender = model.getGender(usr);
    restrictions = model.getRestrictions(usr);
    past = []; // TODO
    healthGoal = model.getGoal(usr);
    
    if (gender is "prefer not to say") {
        String prompt = "For this image what rate their food proprtions in terms of protein, carbohydrates, and fat consumption. Also consider any other nutritional factors that may be important. Provide me with 4 numbers, each on a scale of 1-10 corresponding to each category listed. The food image is: " + base64Image + ". For an individual with age " + age + " and weight " + weight + " pounds and exercises " + exercise + " times per week and a health goal of " + health goal + " how healthy is their meal on a scale of 1 - 10? " + "Also, what are some suggestions for improving this meal? They're dietary restrictions are " + restrictions + "Additionally, this the average of their past weeks in the same format of 4 numbers, how does today compare to that: " + past
    } else {
        String prompt = "For this image what rate their food proprtions in terms of protein, carbohydrates, and fat consumption. Also consider any other nutritional factors that may be important. Provide me with 4 numbers, each on a scale of 1-10 corresponding to each category listed. The food image is: " + base64Image + ". For an individual of gender " + gender + " with age " + age + " and weight " + weight + " pounds and exercises " + exercise + " times per week and a health goal of " + health goal + " how healthy is their meal on a scale of 1 - 10? " + "Also, what are some suggestions for improving this meal? They're dietary restrictions are " + restrictions + "Additionally, this the average of their past weeks in the same format of 4 numbers, how does today compare to that: " + past
    }
    
    
    
}


