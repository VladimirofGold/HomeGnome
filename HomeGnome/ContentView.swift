//
//  ContentView.swift
//  HomeGnome
//
//  Created by Vladimir on 23.07.2025.
//
import SwiftUI

// Модели данных
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

enum Role: String, Codable, CaseIterable {
    case customer = "Заказчик"
    case performer = "Исполнитель"
}

struct User: Codable {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var role: Role
    var completedTasks: Int = 0
}

struct TaskFilters {
    var showCustomers: Bool = true
    var showPerformers: Bool = true
    var minPrice: String = ""
    var maxPrice: String = ""
}

// Главный View
struct ContentView: View {
    // Состояние приложения
    @State private var tasks: [Task] = []
    @State private var showTaskCreation = false
    @State private var showingFilters = false
    @State private var filters = TaskFilters()
    @State private var currentUser: User?
    @State private var showingAuth = false
    @State private var showRoleSelection = true
    @State private var selectedRole: Role?
    
    // Цвета
    private let primaryColor = Color(red: 74/255, green: 120/255, blue: 101/255)
    private let backgroundColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    init() {
        // Загрузка пользователя
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            currentUser = try? JSONDecoder().decode(User.self, from: userData)
        }
        
        // Загрузка задач
        if let tasksData = UserDefaults.standard.data(forKey: "tasks") {
            tasks = (try? JSONDecoder().decode([Task].self, from: tasksData)) ?? []
        }
        
        // Настройка NavigationBar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(primaryColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    var body: some View {
        Group {
            if currentUser == nil {
                AuthView(currentUser: $currentUser)
            } else {
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
                                // Кнопка профиля
                                HStack {
                                    Spacer()
                                    Button(action: { showingAuth = true }) {
                                        Image(systemName: "person.circle")
                                            .font(.title)
                                            .foregroundColor(primaryColor)
                                    }
                                    .padding(.trailing)
                                }
                                
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
                                        if tasks.isEmpty {
                                            Text("Нет объявлений")
                                                .foregroundColor(.gray)
                                                .padding()
                                        } else {
                                            ForEach(tasks) { task in
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
                    .sheet(isPresented: $showingAuth) {
                        if let user = currentUser {
                            ProfileView(currentUser: $currentUser, user: user)
                        }
                    }
                }
                .accentColor(.white)
            }
        }
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
}

// Компоненты аутентификации
struct AuthView: View {
    @Binding var currentUser: User?
    @State private var isLoginMode = true
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var selectedRole: Role = .customer
    
    var body: some View {
        NavigationView {
            Form {
                if !isLoginMode {
                    Section {
                        TextField("Имя", text: $name)
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                        Picker("Роль", selection: $selectedRole) {
                            ForEach(Role.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }
                    }
                }
                
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Пароль", text: $password)
                }
                
                Section {
                    Button(isLoginMode ? "Войти" : "Зарегистрироваться") {
                        let user = User(
                            name: name,
                            email: email,
                            phone: phone,
                            role: selectedRole
                        )
                        saveUser(user)
                        currentUser = user
                    }
                    .disabled(!isFormValid)
                    
                    Button(isLoginMode ? "Создать аккаунт" : "Уже есть аккаунт? Войти") {
                        isLoginMode.toggle()
                    }
                }
            }
            .navigationTitle(isLoginMode ? "Вход" : "Регистрация")
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && !phone.isEmpty
        }
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
}

struct ProfileView: View {
    @Binding var currentUser: User?
    let user: User
    @State private var showingEdit = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.title2)
                            Text(user.role.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Контакты") {
                    HStack {
                        Image(systemName: "envelope")
                            .frame(width: 30)
                        Text(user.email)
                    }
                    HStack {
                        Image(systemName: "phone")
                            .frame(width: 30)
                        Text(user.phone)
                    }
                }
                
                Section("Статистика") {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .frame(width: 30)
                        Text("Выполнено задач: \(user.completedTasks)")
                    }
                }
                
                Section {
                    Button("Редактировать профиль") {
                        showingEdit = true
                    }
                    Button("Выйти", role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "currentUser")
                        currentUser = nil
                    }
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showingEdit) {
                EditProfileView(user: $currentUser)
            }
        }
    }
}

struct EditProfileView: View {
    @Binding var user: User?
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var phone: String
    
    init(user: Binding<User?>) {
        self._user = user
        self._name = State(initialValue: user.wrappedValue?.name ?? "")
        self._phone = State(initialValue: user.wrappedValue?.phone ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button("Сохранить") {
                        if var current = user {
                            current.name = name
                            current.phone = phone
                            user = current
                            saveUser(current)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
}

// Остальные компоненты (без изменений)
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

@main
struct HomeGnomeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
