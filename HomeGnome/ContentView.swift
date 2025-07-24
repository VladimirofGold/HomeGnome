//
//  ContentView.swift
//  HomeGnome
//
//  Created by Vladimir on 23.07.2025.
//
import SwiftUI

// Модель данных для объявления
struct Task: Identifiable, Codable {
    var id = UUID()
    let role: Role
    let title: String
    let description: String
    let price: String
    let phone: String
    let date: Date
}

// Роли пользователя
enum Role: String, Codable {
    case customer = "Заказчик"
    case performer = "Исполнитель"
}

// Главный экран приложения
struct ContentView: View {
    // Цвета
    private let primaryColor = Color(red: 74/255, green: 120/255, blue: 101/255)
    private let backgroundColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    // Состояние приложения
    @State private var tasks: [Task] = []
    @State private var showRoleSelection = true
    @State private var showTaskCreation = false
    @State private var selectedRole: Role?
    
    // Настройка NavigationBar
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(primaryColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
        
        // Загрузка сохраненных задач
        if let savedTasks = UserDefaults.standard.data(forKey: "savedTasks") {
            if let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasks) {
                _tasks = State(initialValue: decodedTasks)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if showRoleSelection {
                    RoleSelectionView(primaryColor: primaryColor, selectedRole: $selectedRole) {
                        withAnimation {
                            showRoleSelection = false
                        }
                    }
                } else {
                    MainContentView(
                        tasks: $tasks,
                        selectedRole: $selectedRole,
                        showTaskCreation: $showTaskCreation,
                        primaryColor: primaryColor,
                        backgroundColor: backgroundColor,
                        onAddTask: saveTasks
                    )
                }
            }
            .navigationTitle(selectedRole == nil ? "HomeGnome" : selectedRole!.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Кнопка добавления (справа)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedRole != nil {
                        Button(action: {
                            showTaskCreation = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Кнопка смены роли (слева)
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedRole != nil {
                        Button("Сменить роль") {
                            showRoleSelection = true
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showTaskCreation) {
            if let role = selectedRole {
                NewTaskView(
                    role: role,
                    isPresented: $showTaskCreation,
                    tasks: $tasks,
                    primaryColor: primaryColor,
                    onAddTask: saveTasks
                )
            }
        }
        .accentColor(.white)
    }
    
    // Сохранение задач
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
        }
    }
}

// Экран выбора роли
struct RoleSelectionView: View {
    let primaryColor: Color
    @Binding var selectedRole: Role?
    let onRoleSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Выберите роль")
                .font(.title2)
                .padding(.bottom, 30)
            
            RoleButton(
                role: .customer,
                title: "Я заказчик",
                description: "Нужно выполнить работу",
                primaryColor: primaryColor,
                selectedRole: $selectedRole,
                onRoleSelected: onRoleSelected
            )
            
            RoleButton(
                role: .performer,
                title: "Я исполнитель",
                description: "Могу выполнить работу",
                primaryColor: primaryColor,
                selectedRole: $selectedRole,
                onRoleSelected: onRoleSelected
            )
        }
        .padding()
    }
}

// Кнопка выбора роли
struct RoleButton: View {
    let role: Role
    let title: String
    let description: String
    let primaryColor: Color
    @Binding var selectedRole: Role?
    let onRoleSelected: () -> Void
    
    var body: some View {
        Button(action: {
            selectedRole = role
            onRoleSelected()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// Главный контент после выбора роли
struct MainContentView: View {
    @Binding var tasks: [Task]
    @Binding var selectedRole: Role?
    @Binding var showTaskCreation: Bool
    let primaryColor: Color
    let backgroundColor: Color
    let onAddTask: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if tasks.isEmpty {
                    Text("Нет объявлений")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(tasks) { task in
                        TaskRow(task: task, primaryColor: primaryColor, currentRole: selectedRole)
                    }
                }
            }
            .padding()
        }
    }
}

// Строка задачи
struct TaskRow: View {
    let task: Task
    let primaryColor: Color
    let currentRole: Role?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Spacer()
                
                Text(task.price)
                    .font(.subheadline)
                    .foregroundColor(primaryColor)
            }
            
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            
            HStack {
                Text("Тип: \(task.role.rawValue)")
                    .font(.caption)
                    .foregroundColor(task.role == .customer ? .blue : .green)
                
                Spacer()
                
                Text("Телефон: \(task.phone)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text("Добавлено: \(task.date.formatted(date: .numeric, time: .shortened))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Экран создания новой задачи
struct NewTaskView: View {
    let role: Role
    @Binding var isPresented: Bool
    @Binding var tasks: [Task]
    let primaryColor: Color
    let onAddTask: () -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(role == .customer ? "Какая работа нужна?" : "Какую работу предлагаете?", text: $title)
                    TextField("Подробное описание", text: $description)
                    TextField("Бюджет", text: $price)
                        .keyboardType(.numberPad)
                    TextField("Контактный телефон", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button(action: addTask) {
                        HStack {
                            Spacer()
                            Text("Добавить")
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || price.isEmpty || phone.isEmpty)
                }
            }
            .navigationTitle("Новое объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                }
            }
        }
        .accentColor(primaryColor)
    }
    
    private func addTask() {
        let newTask = Task(
            role: role,
            title: title,
            description: description,
            price: price + " ₽",
            phone: phone,
            date: Date()
        )
        tasks.append(newTask)
        onAddTask()
        isPresented = false
        
        // Сброс полей после добавления
        title = ""
        description = ""
        price = ""
        phone = ""
    }
}

// Предварительный просмотр
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Точка входа приложения
@main
struct HomeGnomeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
