//
//  DetailProductView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import SwiftUI
import SwiftData

struct DetailProductView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recipeViewModel = RandomRecipeViewModel()
    @State private var showingRecipeDetail = false
    var product : Product
    var body: some View {
        ZStack{
            // Background Color of the screen
            Rectangle()
                .fill(product.borderColor.opacity(0.4))
                .ignoresSafeArea()
            
            ScrollView {
                VStack{
                    ZStack{
                        if let imageLink = product.imageLink, !imageLink.isEmpty {
                            let _ = print("🖼️ DetailProductView - Attempting to load image: \(imageLink)")
                            // Convert HTTP to HTTPS if needed for App Transport Security
                            let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                            AsyncImage(url: URL(string: secureImageLink)){phase in
                                
                                if let image = phase.image{
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                        .clipped()
                                }
                                else if phase.error != nil{
                                    let _ = print("🚨 DetailProductView - Image loading error: \(String(describing: phase.error))")
                                    Text("There was an issue loading the image")
                                }
                                else {
                                    ProgressView()
                                        .frame(width: 300, height: 300)
                                        .clipped()
                                }
                            }
                        }
                        else{
                            Image("placeholder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .clipped()
                        }
                        
                        VStack{
                            
                            Spacer()
                            
                            HStack{
                                
                                Spacer()
                                
                                Button {
                                    // Like the item and store it
                                    withAnimation {
                                        product.LikeProduct()
                                        try? modelContext.save()
                                    }
                                    
                                } label: {
                                    if product.isLiked{
                                        Image(systemName: "heart.circle.fill")
                                            .symbolRenderingMode(.palette) // Enable the palette mode
                                            .foregroundStyle(.white, .red) // Assign colors to the layers
                                            .font(.system(size: 50))
                                    }
                                    else {
                                        ZStack{
                                            Image(systemName: "circle.fill")
                                                .foregroundStyle(.white)
                                                .font(.system(size: 50, weight: .light))
                                            
                                            Image(systemName: "circle")
                                                .foregroundStyle(.red)
                                                .font(.system(size: 50, weight: .light))
                                            
                                            Image(systemName: "heart")
                                                .foregroundStyle(.red)
                                                .font(.system(size: 25))
                                        }
                                    }
                                    
                                }
                                .padding(.trailing)
                                .padding(.bottom)
                            }
                            
                        }
                    }
                    .frame(width: 300, height: 300)
                    
                    VStack(spacing: 8) {
                        Text(product.title)
                            .font(.title.bold())
                        
                        // Product type tag
                        HStack {
                            Image(systemName: product.id != nil ? "cloud.fill" : "person.fill")
                                .font(.caption)
                            Text(product.type)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(product.id != nil ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        )
                        .foregroundColor(product.id != nil ? .blue : .green)
                    }
                    
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(product.borderColor.opacity(0.4))
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                        
                        HStack{
                            
                            Spacer()
                            
                            VStack(alignment: .center){
                                Text("Expires on")
                                Text("\(product.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                            }
                            Spacer()
                            
                            Spacer()
                            
                            VStack(alignment: .center){
                                if product.spoonacularScore != nil {
                                    Text(String(format: "%.2f", product.spoonacularScore!))
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .padding(.horizontal)
                    
                    VStack{
                        if product.productDescription != nil {
                            Text(product.productDescription!)
                        }
                        else if product.generatedText != nil {
                            Text(product.generatedText!)
                        }
                    }
                    .padding()
                    
                    // Recipes Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack{
                            Text("Recipes Using this Product")
                                .font(.title2.bold())
                            
                            Spacer()
                            
                            // Recipe count badge
                            if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
                                Text("\(recipeIds.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // Recipe IDs display
                        if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(Array(recipeIds.enumerated()), id: \.offset) { index, recipeId in
                                    HStack {
                                        // Recipe number
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        // Recipe ID
                                        Text("Recipe ID: \(recipeId)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        // View recipe button
                                        Button("View") {
                                            Task {
                                                await recipeViewModel.fetchFullRecipeDetails(recipeId: recipeId)
                                                showingRecipeDetail = true
                                            }
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                        .disabled(recipeViewModel.isLoading)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        } else {
                            // No recipes found
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                                Text("No recipes found for this product")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("Try adding more specific ingredients or check back later")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = recipeViewModel.fetchedRecipe {
                // You can create a custom recipe detail view here
                // For now, showing a simple view with recipe details
                NavigationView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(recipe.title)
                            .font(.title.bold())
                            .padding()
                        
                        if let summary = recipe.summary {
                            Text("Summary")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text(summary)
                                .font(.body)
                                .padding(.horizontal)
                        }
                        
                        if let instructions = recipe.analyzedInstructions, !instructions.isEmpty {
                            Text("Instructions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Step \(index + 1)")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal)
                                    
                                    ForEach(Array(instruction.steps.enumerated()), id: \.offset) { stepIndex, step in
                                        Text("\(stepIndex + 1). \(step.step)")
                                            .font(.body)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingRecipeDetail = false
                            }
                        }
                    }
                }
            } else if recipeViewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading recipe details...")
                        .font(.headline)
                        .padding()
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Failed to load recipe")
                        .font(.headline)
                        .padding()
                    
                    Button("Try Again") {
                        showingRecipeDetail = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}


#Preview {
    let spoonacularCredit = SpoonacularCredit(text: "openfoodfacts.org under (ODbL) v1.0", link: "https://opendatacommons.org/licenses/odbl/1-0/", image: "openfoodfacts.org under CC BY-SA 3.0 DEED", imageLink:  "https://creativecommons.org/licenses/by-sa/3.0/deed.en")
    let groceryProduct = GroceryProduct(id: 9348958, title: "LECHE SIN LACTOSA", breadcrumbs: ["Dairy", "Milk"], upc: "8410128750145", credits: spoonacularCredit)
    
    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink)
    
    let newProduct = Product(id: groceryProduct.id ?? 9348958, barcode: groceryProduct.upc ?? "", title: groceryProduct.title ?? "", brand: groceryProduct.brand ?? "", breadcrumbs: groceryProduct.breadcrumbs, badges: groceryProduct.badges, importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.image, moreImageLinks: groceryProduct.images, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, recipeIds: [12345, 67890, 11111], credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    DetailProductView(product: newProduct)
}
