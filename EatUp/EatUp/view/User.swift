//
//  User.swift
//  
//
//  Created by Suhani Aggarwal on 11/15/25.
//


import SwiftUI

// MARK: - Color Scheme
extension Color {
    static let primaryOrange = Color(red: 1.0, green: 0.73, blue: 0.15) // FF7726
    static let secondaryOrange = Color(red: 1.0, green: 0.65, blue: 0.19) // FFA630
    static let lightGray = Color(red: 0.93, green: 0.93, blue: 0.93) // EEEEEE
    static let primaryBlue = Color(red: 0.00, green: 0.82, blue: 0.95) // 00D2F1
    static let secondaryBlue = Color(red: 0.04, green: 0.71, blue: 0.91) // 0473BA
}

// MARK: - Models
struct User {
    var name: String = ""
    var age: String = ""
    var gender: String = ""
    var email: String = ""
    var password: String = ""
}

struct HealthGoal: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct HealthCondition: Identifiable {
    let id = UUID()
    let title: String
}

struct DietaryPreference: Identifiable {
    let id = UUID()
    let title: String
}

// MARK: - Main App
struct ContentView: View {
    @State private var currentScreen = 0
    @State private var user = User()
    @State private var loggedInUserId: UUID? = UUID()
    @State private var selectedGoals: Set<UUID> = []
    @State private var selectedConditions: Set<UUID> = []
    @State private var selectedDietary: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            Group {
                switch currentScreen {
                case 0:
                    OnboardingView(currentScreen: $currentScreen)
                case 1:
                    SignUpView(user: $user, currentScreen: $currentScreen)
                case 2:
                    BasicsView(user: $user, currentScreen: $currentScreen)
                case 3:
                    ActivityGoalsView(selectedGoals: $selectedGoals, currentScreen: $currentScreen)
                case 4:
                    HealthMetricsView(currentScreen: $currentScreen)
                case 5:
                    HealthConditionsView(selectedConditions: $selectedConditions, currentScreen: $currentScreen)
                case 6:
                    DietaryPreferencesView(selectedDietary: $selectedDietary, currentScreen: $currentScreen)
                case 7:
                    CameraView(currentScreen: $currentScreen, userId: loggedInUserId ?? UUID())
                default:
                    MainTabView()
                }
            }
        }
    }
}

// MARK: - Onboarding Screen
struct OnboardingView: View {
    @Binding var currentScreen: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.secondaryBlue)
            
            Text("EatUp")
                .font(.custom("SF Pro", size: 48))
                .fontWeight(.bold)
                .kerning(-0.96)
            
            Spacer()
            
            Button(action: {
                currentScreen = 1
            }) {
                Text("Get Started")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Sign Up Screen
struct SignUpView: View {
    @Binding var user: User
    @Binding var currentScreen: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("Welcome!")
                .font(.custom("SF Pro", size: 28))
                .fontWeight(.semibold)
                .kerning(-0.56)
                .padding(.bottom, 10)
            
            Text("Sign up and get started with our multi-platform health app!")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Email", text: $user.email)
                    .textFieldStyle(CustomTextFieldStyle())
                
                SecureField("Password", text: $user.password)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            Spacer()
            
            Button(action: {
                currentScreen = 2
            }) {
                Text("Next")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Basics Screen
struct BasicsView: View {
    @Binding var user: User
    @Binding var currentScreen: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("Let's start with the basics.")
                .font(.custom("SF Pro", size: 24))
                .fontWeight(.semibold)
                .kerning(-0.48)
                .padding(.bottom, 10)
            
            Text("Fill out the form to get started with our multi-platform health app!")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Name", text: $user.name)
                    .textFieldStyle(CustomTextFieldStyle())
                
                TextField("Age", text: $user.age)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Menu {
                    Button("Male") { user.gender = "Male" }
                    Button("Female") { user.gender = "Female" }
                    Button("Other") { user.gender = "Other" }
                } label: {
                    HStack {
                        Text(user.gender.isEmpty ? "Gender" : user.gender)
                            .foregroundColor(user.gender.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                TextField("Height", text: .constant(""))
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            Spacer()
            
            Button(action: {
                currentScreen = 3
            }) {
                Text("Next!")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Activity Goals Screen
struct ActivityGoalsView: View {
    @Binding var selectedGoals: Set<UUID>
    @Binding var currentScreen: Int
    
    let goals = [
        HealthGoal(title: "Sedentary", icon: "bed.double.fill"),
        HealthGoal(title: "Light Exercise", icon: "figure.walk"),
        HealthGoal(title: "Moderate Exercise", icon: "figure.run"),
        HealthGoal(title: "Very Active (5-6 Days)", icon: "bolt.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("How active are you most daily?")
                .font(.custom("SF Pro", size: 24))
                .fontWeight(.semibold)
                .kerning(-0.48)
                .padding(.bottom, 10)
            
            Text("Let us know your activity level")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                ForEach(goals) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoals.contains(goal.id),
                        action: {
                            if selectedGoals.contains(goal.id) {
                                selectedGoals.remove(goal.id)
                            } else {
                                selectedGoals.insert(goal.id)
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            Button(action: {
                currentScreen = 4
            }) {
                Text("Next!")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Health Metrics Screen
struct HealthMetricsView: View {
    @Binding var currentScreen: Int
    @State private var weightLoss = ""
    @State private var muscleGain = ""
    @State private var maintenance = ""
    @State private var generalWellness = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("What brings you here?")
                .font(.custom("SF Pro", size: 24))
                .fontWeight(.semibold)
                .kerning(-0.48)
                .padding(.bottom, 10)
            
            Text("Let us know your goals so we can better help you!")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                TextField("Weight Loss", text: $weightLoss)
                    .textFieldStyle(CustomTextFieldStyle())
                
                TextField("Muscle Gain", text: $muscleGain)
                    .textFieldStyle(CustomTextFieldStyle())
                
                TextField("Maintenance", text: $maintenance)
                    .textFieldStyle(CustomTextFieldStyle())
                
                TextField("General Wellness", text: $generalWellness)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    currentScreen -= 1
                }) {
                    Text("Skip")
                        .font(.custom("SF Pro", size: 18))
                        .kerning(-0.36)
                        .foregroundColor(.secondaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondaryBlue, lineWidth: 2)
                        )
                }
                
                Button(action: {
                    currentScreen = 5
                }) {
                    Text("Next")
                        .font(.custom("SF Pro", size: 18))
                        .kerning(-0.36)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondaryBlue)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Health Conditions Screen
struct HealthConditionsView: View {
    @Binding var selectedConditions: Set<UUID>
    @Binding var currentScreen: Int
    
    let conditions = [
        HealthCondition(title: "High Cholesterol"),
        HealthCondition(title: "Diabetes Risk"),
        HealthCondition(title: "High Blood Pressure")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("Any areas you'd like us to watch out for?")
                .font(.custom("SF Pro", size: 24))
                .fontWeight(.semibold)
                .kerning(-0.48)
                .padding(.bottom, 10)
            
            Text("Specific conditions or dietary restrictions we should consider")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                ForEach(conditions) { condition in
                    ConditionRow(
                        condition: condition,
                        isSelected: selectedConditions.contains(condition.id),
                        action: {
                            if selectedConditions.contains(condition.id) {
                                selectedConditions.remove(condition.id)
                            } else {
                                selectedConditions.insert(condition.id)
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    currentScreen -= 1
                }) {
                    Text("Skip")
                        .font(.custom("SF Pro", size: 18))
                        .kerning(-0.36)
                        .foregroundColor(.secondaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondaryBlue, lineWidth: 2)
                        )
                }
                
                Button(action: {
                    currentScreen = 6
                }) {
                    Text("Next")
                        .font(.custom("SF Pro", size: 18))
                        .kerning(-0.36)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondaryBlue)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Dietary Preferences Screen
struct DietaryPreferencesView: View {
    @Binding var selectedDietary: Set<UUID>
    @Binding var currentScreen: Int
    
    let preferences = [
        DietaryPreference(title: "Vegan"),
        DietaryPreference(title: "Vegetarian"),
        DietaryPreference(title: "Gluten-free"),
        DietaryPreference(title: "Dairy-free"),
        DietaryPreference(title: "Allergies")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Text("Do you follow any dietary preferences or restrictions?")
                .font(.custom("SF Pro", size: 24))
                .fontWeight(.semibold)
                .kerning(-0.48)
                .padding(.bottom, 10)
            
            Text("Help us tailor meal suggestions")
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                ForEach(preferences) { pref in
                    ConditionRow(
                        condition: HealthCondition(title: pref.title),
                        isSelected: selectedDietary.contains(pref.id),
                        action: {
                            if selectedDietary.contains(pref.id) {
                                selectedDietary.remove(pref.id)
                            } else {
                                selectedDietary.insert(pref.id)
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            Button(action: {
                currentScreen = 7
            }) {
                Text("Finish Setup!")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Camera Screen
struct CameraView: View {
    @Binding var currentScreen: Int
    @State private var mealType = "Breakfast"
    
    var userId: UUID
    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isAnalyzing = false
    @State private var analysisResult: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var userDescription = ""

    var body: some View {
        VStack {
            Text("EatUp")
                .font(.custom("SF Pro", size: 32))
                .fontWeight(.bold)
                .kerning(-0.64)
                .padding(.top, 60)
            
            Spacer()
            
            if let image = capturedImage {
                Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal, 30)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lightGray)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Button("Take/Choose Photo") {
                                showImagePicker = true
                            }
                            .padding()
                            .background(Color.secondaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    )
                    .padding(.horizontal, 30)
            }

            TextField("Additional details (optional)", text: $userDescription)
                .textFieldStyle(CustomTextFieldStyle())
                .padding(.horizontal, 30)
                .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What is this meal?")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .padding(.horizontal, 30)
                
                HStack(spacing: 12) {
                    ForEach(["Breakfast", "Lunch", "Dinner"], id: \.self) { meal in
                        Button(action: {
                            mealType = meal
                        }) {
                            HStack {
                                Image(systemName: mealType == meal ? "checkmark.circle.fill" : "circle")
                                Text(meal)
                            }
                            .font(.custom("SF Pro", size: 16))
                            .kerning(-0.32)
                            .foregroundColor(mealType == meal ? .secondaryBlue : .primary)
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding(.top, 30)
            
            if let result = analysisResult {
                ScrollView {
                    Text(result)
                        .font(.custom("SF Pro", size: 14))
                        .kerning(-0.28)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.lightGray)
                        .cornerRadius(12)
                        .padding(.horizontal, 30)
                }
                .frame(maxHeight: 200)
                .padding(.top, 16)
            }

            Spacer()
            
            Button(action: {
                currentScreen = 8
            }) {
                Text("Analyze my meal!")
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        TabView {
            DayView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            CalendarTabView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.secondaryBlue)
    }
}

// MARK: - Day View
struct DayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("EatUp")
                    .font(.custom("SF Pro", size: 32))
                    .fontWeight(.bold)
                    .kerning(-0.64)
                
                Text("Today")
                    .font(.custom("SF Pro", size: 28))
                    .fontWeight(.semibold)
                    .kerning(-0.56)
                
                MealSection(title: "Breakfast", time: "8:00 AM")
                MealSection(title: "Lunch", time: "12:30 PM")
                MealSection(title: "Dinner", time: "6:00 PM")
                
                Text("Day Summary")
                    .font(.custom("SF Pro", size: 24))
                    .fontWeight(.semibold)
                    .kerning(-0.48)
                    .padding(.top, 20)
                
                Text("Average Daily Calorie: #TBD")
                    .font(.custom("SF Pro", size: 16))
                    .kerning(-0.32)
                    .foregroundColor(.gray)
            }
            .padding(30)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("EatUp")
                    .font(.custom("SF Pro", size: 32))
                    .fontWeight(.bold)
                    .kerning(-0.64)
                
                // Placeholder for charts
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lightGray)
                    .frame(height: 200)
                    .overlay(
                        Text("Macronutrient Breakdown")
                            .font(.custom("SF Pro", size: 18))
                            .kerning(-0.36)
                    )
            }
            .padding(30)
        }
    }
}

// MARK: - Calendar View
struct CalendarTabView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("EatUp")
                    .font(.custom("SF Pro", size: 32))
                    .fontWeight(.bold)
                    .kerning(-0.64)
                
                // Calendar placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lightGray)
                    .frame(height: 350)
                    .overlay(
                        Text("Calendar View")
                            .font(.custom("SF Pro", size: 18))
                            .kerning(-0.36)
                    )
            }
            .padding(30)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("EatUp")
                    .font(.custom("SF Pro", size: 32))
                    .fontWeight(.bold)
                    .kerning(-0.64)
                
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.secondaryBlue)
                
                Text("You're doing an excellent job!")
                    .font(.custom("SF Pro", size: 20))
                    .kerning(-0.40)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 16) {
                    ProfileRow(title: "Your Goal", value: "")
                    ProfileRow(title: "Name", value: "")
                    ProfileRow(title: "Height", value: "")
                    ProfileRow(title: "Calorie Tracking Rules", value: "")
                    ProfileRow(title: "Health Concerns", value: "#TBD")
                }
                .padding(.top, 20)
                
                Button(action: {}) {
                    Text("Logout (Google OAuth)")
                        .font(.custom("SF Pro", size: 16))
                        .kerning(-0.32)
                        .foregroundColor(.red)
                }
            }
            .padding(30)
        }
    }
}

// MARK: - Supporting Views
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct GoalCard: View {
    let goal: HealthGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .secondaryBlue : .gray)
                    .frame(width: 50)
                
                Text(goal.title)
                    .font(.custom("SF Pro", size: 18))
                    .kerning(-0.36)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.secondaryBlue.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.secondaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

struct ConditionRow: View {
    let condition: HealthCondition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(condition.title)
                    .font(.custom("SF Pro", size: 16))
                    .kerning(-0.32)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .secondaryBlue : .gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct MealSection: View {
    let title: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.custom("SF Pro", size: 20))
                    .fontWeight(.semibold)
                    .kerning(-0.40)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.secondaryBlue)
                        .font(.system(size: 24))
                }
            }
            
            Text(time)
                .font(.custom("SF Pro", size: 14))
                .kerning(-0.28)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.lightGray)
        .cornerRadius(12)
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
            
            Spacer()
            
            Text(value)
                .font(.custom("SF Pro", size: 16))
                .kerning(-0.32)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
