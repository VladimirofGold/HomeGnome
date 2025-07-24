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
    
    var numericPrice: Int {
        Int(price.filter { $0.isNumber }) ?? 0
    }
}

// Роли пользователя
enum Role: String, Codable {
    case customer = "Заказчик"
    case performer = "Исполнитель"
}

// Модель фильтров
struct TaskFilters {
    var showCustomers: Bool = true
    var showPerformers: Bool = true
    var minPrice: String = ""
    var maxPrice: String = ""
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
    @State private var showingFilters = false
    @State private var filters = TaskFilters()
    
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
    
    // Фильтрованные задачи
    var filteredTasks: [Task] {
        tasks.filter { task in
            // Фильтр по типу
            let roleFilter = (task.role == .customer && filters.showCustomers) ||
                            (task.role == .performer && filters.showPerformers)
            
            // Фильтр по цене
            var priceFilter = true
            if !filters.minPrice.isEmpty {
                let minPrice = Int(filters.minPrice) ?? 0
                priceFilter = task.numericPrice >= minPrice
            }
            if !filters.maxPrice.isEmpty {
                let maxPrice = Int(filters.maxPrice) ?? Int.max
                priceFilter = priceFilter && (task.numericPrice <= maxPrice)
            }
            
            return roleFilter && priceFilter
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
                    VStack {
                        // Кнопка фильтров
                        HStack {
                            Spacer()
                            Button(action: { showingFilters = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(primaryColor)
                            }
                            .padding(.trailing)
                        }
                        
                        // Список задач
                        ScrollView {
                            VStack(spacing: 16) {
                                if filteredTasks.isEmpty {
                                    Text("Нет подходящих объявлений")
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    ForEach(filteredTasks) { task in
                                        TaskRow(task: task, primaryColor: primaryColor)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(selectedRole == nil ? "HomeGnome" : selectedRole!.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedRole != nil {
                        Button("Сменить роль") {
                            showRoleSelection = true
                        }
                        .foregroundColor(.white)
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
            .sheet(isPresented: $showingFilters) {
                FiltersView(filters: $filters, primaryColor: primaryColor)
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

// Строка задачи
struct TaskRow: View {
    let task: Task
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Spacer()
                
                Text("\(task.numericPrice) ₽")
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
                    TextField("Бюджет (только цифры)", text: $price)
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
            price: "\(price) ₽",
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

// Экран фильтров
struct FiltersView: View {
    @Binding var filters: TaskFilters
    let primaryColor: Color
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Тип объявления")) {
                    Toggle("Показывать заказы", isOn: $filters.showCustomers)
                    Toggle("Показывать услуги", isOn: $filters.showPerformers)
                }
                
                Section(header: Text("Цена (₽)")) {
                    TextField("Минимальная цена", text: $filters.minPrice)
                        .keyboardType(.numberPad)
                    TextField("Максимальная цена", text: $filters.maxPrice)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        // Закрываем окно
                    }
                }
            }
        }
        .accentColor(primaryColor)
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
