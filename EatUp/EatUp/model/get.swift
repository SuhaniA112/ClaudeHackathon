//
//  get.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//

func getAge(uid: Int) -> Int {
    let userManager = UserManager()
    return userManager.getUserById(uid).age
}

func getWeight(uid: Int) -> Int {
    let userManager = UserManager()
    return userManager.getUserById(uid).weight
}

func getHeight(uid: Int) -> Int {
    let userManager = UserManager()
    return userManager.getUserById(uid).height
}

func getExercise(uid: Int) -> Double{
    let userManager = UserManager()
    return userManager.getUserById(uid).activityLevel
}

func getGender(uid: Int) -> String {
    let userManager = UserManager()
    return userManager.getUserById(uid)?.gender
}

func getRestriction(uid: Int) -> String {
    let userManager = UserManager()
    return userManager.getUserById(uid).dietType
}

func getGoal(uid: Int) -> String {
    let userManager = UserManager()
    return userManager.getUserById(uid).healthGoal
}

func getPast(uid: Int) -> String {
    return "0" // TODO
}
