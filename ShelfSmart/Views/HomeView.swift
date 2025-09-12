//
//  HomeView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//
import SwiftData
import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @State var showingAddProduct : Bool = false
    @State var showingDetailProductView : Bool = false
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    
    // Get all groups and filter in the view - this will be reactive to changes
    @Query(sort: \GroupedProducts.expirationDate) private var allGroups: [GroupedProducts]
    
    // Computed property that filters groups by current user
    var groups: [GroupedProducts] {
        return allGroups.filter { group in
            group.userId == currentUserId
        }
    }
    
    var body: some View {
        NavigationStack{
            VStack(alignment:.leading){
                Text("Your Products")
                    .font(.title.bold())
                    .padding(.leading)
                    .padding(.top)
                
                ZStack{
                    
                    if groups.isEmpty{
                        Text("Start by adding your first product.")
                            .foregroundStyle(.gray)
                    }
                    
                    else {
                        ScrollViewReader{ proxy in
                            ScrollView{
                                LazyVStack{
                                    ForEach(groups){group in
                                        GroupView(group: group)
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                    
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Button {
                                // Show the sheet for the addProductView
                                showingAddProduct = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .glassEffect()
                            }
                        }
                    }
                }
                .padding(.top)
                .padding(.horizontal, 5)
                .sheet(isPresented: $showingAddProduct) {
                    AddProductView()
                }
            }
        }
        .onAppear {
            // Update userId when view appears
            currentUserId = Auth.auth().currentUser?.uid ?? ""
        }
        .onChange(of: currentUserId) { oldValue, newValue in
            // This will trigger a view update when userId changes
            print("User ID changed from \(oldValue) to \(newValue)")
        }
    }
}


#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: GroupedProducts.self, Product.self, configurations: config)
        let context = container.mainContext
        
        // Add sample products
        let threeDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? Date.now)
        let fiveDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? Date.now)
        let twoDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? Date.now)
        
        // Use empty string to match what HomeView uses when no user is authenticated
        let sampleUserId = ""
        let sampleGroups = [
            GroupedProducts(expirationDate: threeDaysFromNow, products: [
                Product(id: 123456789, barcode: "123456789", title: "Milk", brand: "Organic Milk", expirationDate: threeDaysFromNow),
                Product(id: 12345679, barcode: "12345679", title: "Bread", brand: "Whole Wheat Bread", expirationDate: threeDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: fiveDaysFromNow, products: [
                Product(id: 12345689, barcode: "12345689", title: "Eggs", brand: "Free-range eggs", expirationDate: fiveDaysFromNow),
                Product(id: 1234589, barcode: "1234589", title: "Yogurt", brand: "Greek Yogurt", expirationDate: fiveDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: twoDaysAgo, products: [
                Product(id: 345689, barcode: "345689", title: "Honey", brand: "Organic Honey", expirationDate: twoDaysAgo),
                Product(id: 45689, barcode: "45689", title: "Tortilla", brand: "Corn Tortilla", expirationDate: twoDaysAgo)
            ], userId: sampleUserId)
        ]
        
        for group in sampleGroups {
            context.insert(group)
        }
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
