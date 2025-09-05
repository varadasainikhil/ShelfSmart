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
                    ScrollViewReader{ proxy in
                        ScrollView{
                            LazyVStack{
                                ForEach(groups){group in
                                    HStack{
                                        Text(group.daysTillExpiry().message)
                                        Spacer()
                                    }
                                    
                                    ForEach(group.products ?? []){ product in
                                        NavigationLink(destination: DetailProductView(item: product)) {
                                            if group.products?.last == product {
                                                CardView(product: product)
                                                    .padding(.bottom)
                                                
                                            }
                                            else {
                                                CardView(product: product)
                                            }
                                            
                                        }
                                        
                                        
                                    }
                                }
                            }
                            
                        }
                        .scrollContentBackground(.hidden)
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
                .padding()
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
        let container = try ModelContainer(for: GroupedProducts.self, configurations: config)
        let context = container.mainContext
        
        // Add sample products
        let today = Calendar.current.startOfDay(for: Date())
        let threeDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 3, to: today) ?? today)
        let fiveDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 5, to: today) ?? today)
        let twoDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today)
        
        let sampleUserId = "preview-user-id"
        let sampleGroups = [
            GroupedProducts(expirationDate: threeDaysFromNow, products: [
                Item(barcode: "123456789", name: "Milk", productDescription: "Organic whole milk", expirationDate: threeDaysFromNow),
                Item(barcode: "987654321", name: "Bread", productDescription: "Whole wheat bread", expirationDate: threeDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: fiveDaysFromNow, products: [
                Item(barcode: "456789123", name: "Eggs", productDescription: "Free-range eggs", expirationDate: fiveDaysFromNow),
                Item(barcode: "789123456", name: "Yogurt", productDescription: "Greek yogurt", expirationDate: fiveDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: twoDaysAgo, products: [
                Item(barcode: "987654322", name: "Bread", productDescription: "Whole wheat bread", expirationDate: twoDaysAgo),
                Item(barcode: "456789124", name: "Eggs", productDescription: "Free-range eggs", expirationDate: twoDaysAgo),
                Item(barcode: "789123457", name: "Yogurt", productDescription: "Greek yogurt", expirationDate: twoDaysAgo)
            ], userId: sampleUserId)
        ]
        
        
        for group in sampleGroups {
            context.insert(group)
        }
        
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}
