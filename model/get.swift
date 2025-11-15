//
//  get.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

func getAge(uid: Int) -> Int {
    return getUserById(uid).age
}

func getWeight(uid: Int) -> Int {
    return getUserById(uid).weight
}

func getHeight(uid: Int) -> Int {
    return getUserById(uid).height
}

func getExericse(uid: Int) -> Double{
    return getUserById(uid).activityLevel
}

func getGender(uid: Int) -> String {
    return getUserById(uid).gender
}

func getRestriction(uid: Int) -> String {
    return getUserById(uid).dietType
}

func getGoal(uid: Int) -> String {
    return getUserById(uid).healthGoal
}
