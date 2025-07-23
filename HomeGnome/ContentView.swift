//
//  ContentView.swift
//  HomeGnome
//
//  Created by Vladimir on 23.07.2025.
//

import SwiftUI

// Модель данных для услуги
struct HomeService: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priceRange: String
    let imageName: String
}

// Основной экран со списком услуг
struct ServicesListView: View {
    let services = [
        HomeService(title: "Стрижка газона",
                    description: "Профессиональная стрижка газона с уборкой",
                    priceRange: "500-1500 ₽",
                    imageName: "leaf"),
        HomeService(title: "Уборка",
                    description: "Генеральная уборка квартиры или дома",
                    priceRange: "1500-5000 ₽",
                    imageName: "house"),
        HomeService(title: "Ремонт",
                    description: "Мелкий бытовой ремонт",
                    priceRange: "1000-10000 ₽",
                    imageName: "wrench"),
        HomeService(title: "Химчистка",
                    description: "Химчистка мебели и ковров",
                    priceRange: "2000-8000 ₽",
                    imageName: "washer")
    ]
    
    var body: some View {
        NavigationView {
            List(services) { service in
                NavigationLink(destination: ServiceDetailView(service: service)) {
                    ServiceRow(service: service)
                }
            }
            .navigationTitle("HomeGnome")
        }
    }
}

// Строка услуги в списке
struct ServiceRow: View {
    let service: HomeService
    
    var body: some View {
        HStack {
            Image(systemName: service.imageName)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text(service.title)
                    .font(.headline)
                Text(service.priceRange)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }
}

// Экран деталей услуги
struct ServiceDetailView: View {
    let service: HomeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: service.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
            
            Text(service.title)
                .font(.title)
                .bold()
            
            Text(service.description)
                .font(.body)
            
            Text("Ценовой диапазон: \(service.priceRange)")
                .font(.headline)
                .padding(.top, 8)
            
            Spacer()
            
            Button(action: {
                // Действие при нажатии
                print("Выбрана услуга: \(service.title)")
            }) {
                Text("Выбрать")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle(service.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Предварительный просмотр
struct ServicesListView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesListView()
    }
}

// Точка входа приложения
@main
struct HomeGnomeApp: App {
    var body: some Scene {
        WindowGroup {
            ServicesListView()
        }

    }}
