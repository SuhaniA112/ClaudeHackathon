//
//  prompts.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

import SwiftAnthropic
import UIKit




func getFeedback(img: UIImage, usr : Int) -> String {
    
    prompt = getPrompt(img, usr)
    
   // change return msg to return ai thing
    return msg;
}


func getPrompt(img: UIImage, usr: Int) -> String {
    
    // fetch: user age, user weight, user past data, user health goal
    let base64Image = img.base64EncodedString()
    
    age = 0;
    weight = 0;
    past = [];
    healthGoal = "";
    
    String prompt = "For this image what is their.. " + "For an individual with age " + age + " and weight " + weight + " pounds and a health goal of " + health goal + " how healthy is their meal on a scale of 1 - 10? " + "Also, what are some suggestions for improving this meal?"
    
}
