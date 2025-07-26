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
    let date: Date
    let authorName: String
    let authorPhone: String
    var isCompleted: Bool = false
    var completedBy: UUID?
    
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
    var phone: String
    var password: String
    var completedTasks: Int = 0
    var completedTasksIDs: [UUID] = []
}

struct TaskFilters {
    var showCustomers: Bool = true
    var showPerformers: Bool = true
    var minPrice: String = ""
    var maxPrice: String = ""
}

// Главный View
struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var showTaskCreation = false
    @State private var showingFilters = false
    @State private var filters = TaskFilters()
    @State private var currentUser: User?
    @State private var showingAuth = false
    
    private let primaryColor = Color(red: 74/255, green: 120/255, blue: 101/255)
    private let backgroundColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    init() {
        loadData()
        setupNavigationBar()
    }
    
    var body: some View {
        Group {
            if currentUser == nil {
                AuthView(currentUser: $currentUser)
            } else {
                NavigationView {
                    ZStack {
                        backgroundColor.edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 16) {
                            // Кнопка профиля
                            profileButton
                            
                            // Кнопка фильтров
                            filtersButton
                            
                            // Список задач
                            tasksList
                        }
                    }
                    .navigationTitle("HomeGnome")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { plusButtonToolbarItem }
                    .sheet(isPresented: $showTaskCreation) { newTaskSheet }
                    .sheet(isPresented: $showingFilters) { filtersSheet }
                    .sheet(isPresented: $showingAuth) { profileSheet }
                }
                .accentColor(.white)
            }
        }
    }
    
    // MARK: - Subviews
    private var profileButton: some View {
        HStack {
            Spacer()
            Button(action: { showingAuth = true }) {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(primaryColor)
                    .padding(.top, 8)
            }
            .padding(.trailing, 20)
        }
    }
    
    private var filtersButton: some View {
        HStack {
            Spacer()
            Button(action: { showingFilters = true }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Фильтры")
                }
                .foregroundColor(primaryColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            }
            .padding(.trailing, 20)
        }
    }
    
    private var tasksList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if tasks.isEmpty {
                    Text("Нет объявлений")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach($tasks) { $task in
                        TaskRow(task: task,
                               primaryColor: primaryColor,
                               currentUser: $currentUser,
                               onComplete: {
                            completeTask(task: &task)
                        })
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var plusButtonToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showTaskCreation = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var newTaskSheet: some View {
        Group {
            if let user = currentUser {
                NewTaskView(
                    isPresented: $showTaskCreation,
                    tasks: $tasks,
                    primaryColor: primaryColor,
                    authorName: user.name,
                    authorPhone: user.phone,
                    onAddTask: saveTasks
                )
            }
        }
    }
    
    private var filtersSheet: some View {
        FiltersView(filters: $filters,
                   primaryColor: primaryColor,
                   isPresented: $showingFilters)
    }
    
    private var profileSheet: some View {
        Group {
            if let user = currentUser {
                ProfileView(currentUser: $currentUser, user: user)
            }
        }
    }
    
    // MARK: - Methods
    private func loadData() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            currentUser = try? JSONDecoder().decode(User.self, from: userData)
        }
        
        if let tasksData = UserDefaults.standard.data(forKey: "tasks") {
            tasks = (try? JSONDecoder().decode([Task].self, from: tasksData)) ?? []
        }
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(primaryColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    
    private func completeTask(task: inout Task) {
        guard var user = currentUser,
              !user.completedTasksIDs.contains(task.id) else { return }
        
        task.isCompleted = true
        task.completedBy = user.id
        user.completedTasks += 1
        user.completedTasksIDs.append(task.id)
        currentUser = user
        
        // Сохраняем изменения
        saveUser(user)
        saveTasks()
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
}

// Компоненты аутентификации
struct AuthView: View {
    @Binding var currentUser: User?
    @State private var isLoginMode = true
    @State private var name = ""
    @State private var phone = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                if !isLoginMode {
                    Section(header: Text("Ваши данные")) {
                        TextField("Имя", text: $name)
                            .textContentType(.name)
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                        SecureField("Пароль", text: $password)
                    }
                } else {
                    Section {
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                        SecureField("Пароль", text: $password)
                    }
                }
                
                Section {
                    Button(isLoginMode ? "Войти" : "Зарегистрироваться") {
                        handleAuth()
                    }
                    .disabled(!isFormValid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    Button(isLoginMode ? "Нет аккаунта? Зарегистрируйтесь" : "Уже есть аккаунт? Войти") {
                        isLoginMode.toggle()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(isLoginMode ? "Вход" : "Регистрация")
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !phone.isEmpty && !password.isEmpty
        } else {
            return !name.isEmpty && !phone.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuth() {
        let user = User(
            name: name,
            phone: phone,
            password: password
        )
        saveUser(user)
        currentUser = user
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
}

// Личный кабинет
struct ProfileView: View {
    @Binding var currentUser: User?
    let user: User
    @State private var showingEdit = false
    
    private var primaryColor: Color {
        Color(red: 74/255, green: 120/255, blue: 101/255)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(primaryColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.title2)
                            Text(user.phone)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Статистика") {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .frame(width: 30)
                        Text("Выполнено задач: \(user.completedTasks)")
                    }
                    
                    if user.completedTasks > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .frame(width: 30)
                            Text("Уровень: \(calculateLevel())")
                        }
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
    
    private func calculateLevel() -> String {
        switch user.completedTasks {
        case 0: return "Новичок"
        case 1..<5: return "Начинающий"
        case 5..<10: return "Опытный"
        case 10..<20: return "Профессионал"
        default: return "Эксперт"
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
                    .frame(maxWidth: .infinity)
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

// Компонент задачи
struct TaskRow: View {
    let task: Task
    let primaryColor: Color
    @Binding var currentUser: User?
    var onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Автор:")
                        .font(.caption)
                    Text(task.authorName)
                        .font(.caption)
                        .bold()
                }
                
                HStack {
                    Text("Тип:")
                        .font(.caption)
                    Text(task.role.rawValue)
                        .font(.caption)
                        .foregroundColor(task.role == .customer ? .blue : .green)
                }
                
                HStack {
                    Text("Телефон:")
                        .font(.caption)
                    Text(task.authorPhone)
                        .font(.caption)
                }
                
                Text("Добавлено: \(task.date.formatted(date: .numeric, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Кнопка выполнения
            if shouldShowCompleteButton {
                completeTaskButton
            }
            
            // Статус выполнения
            if task.isCompleted {
                Text("✅ Задача выполнена")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var shouldShowCompleteButton: Bool {
        // Показываем кнопку если:
        // 1. Это задача исполнителя И текущий пользователь - автор задачи
        // 2. Задача еще не выполнена
        // 3. Пользователь авторизован
        guard currentUser != nil else { return false }
        
        return task.role == .performer &&
               !task.isCompleted &&
               currentUser?.phone == task.authorPhone
    }
    
    private var completeTaskButton: some View {
        Button(action: onComplete) {
            Text("Отметить выполненным")
                .font(.caption)
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(primaryColor)
                .cornerRadius(8)
        }
    }
}

// Создание новой задачи
struct NewTaskView: View {
    @Binding var isPresented: Bool
    @Binding var tasks: [Task]
    let primaryColor: Color
    let authorName: String
    let authorPhone: String
    let onAddTask: () -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedRole: Role = .customer
    
    var body: some View {
        NavigationView {
            Form {
                Section("Тип объявления") {
                    Picker("Роль", selection: $selectedRole) {
                        ForEach(Role.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                }
                
                Section("Детали") {
                    TextField(selectedRole == .customer ? "Какая работа нужна?" : "Какую работу предлагаете?", text: $title)
                    TextField("Подробное описание", text: $description)
                    TextField("Бюджет", text: $price)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: addTask) {
                        Text("Опубликовать")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(title.isEmpty || price.isEmpty)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Новое объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
        }
        .accentColor(primaryColor)
    }
    
    private func addTask() {
        let newTask = Task(
            role: selectedRole,
            title: title,
            description: description,
            price: price + " ₽",
            date: Date(),
            authorName: authorName,
            authorPhone: authorPhone
        )
        tasks.append(newTask)
        onAddTask()
        isPresented = false
    }
}

// Фильтры
struct FiltersView: View {
    @Binding var filters: TaskFilters
    let primaryColor: Color
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Тип объявления")) {
                    Toggle("Показывать заказы", isOn: $filters.showCustomers)
                    Toggle("Показывать услуги", isOn: $filters.showPerformers)
                }
                
                Section(header: Text("Цена (₽)")) {
                    TextField("От", text: $filters.minPrice)
                        .keyboardType(.numberPad)
                    TextField("До", text: $filters.maxPrice)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Сбросить фильтры") {
                        filters = TaskFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        filters = TaskFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                }
            }
        }
        .accentColor(primaryColor)
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
