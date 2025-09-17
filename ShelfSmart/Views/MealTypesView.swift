//
//  MealTypesView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct MealTypesView: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel = RandomRecipeViewModel()
    @State private var navigateToRandomRecipe = false
    var columns = [GridItem(.flexible()),GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 16) {
                Text("Meal Type")
                    .font(.largeTitle.bold())
                    .padding(.leading, 10)
                
                ScrollView{
                    LazyVGrid(columns: columns) {
                        ForEach(MealType.allCases, id: \.self){ mealType in
                            VStack{
                                ZStack{
                                    Image(mealType.apiValue)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(lineWidth: viewModel.includeTags.contains(where: {$0 == mealType.apiValue}) ? 4 : 2 )
                                        .foregroundStyle(viewModel.includeTags.contains(where: {$0 == mealType.apiValue}) ? .green : .black)
                                    
                                }
                                
                                Text(mealType.displayName)
                                    .foregroundStyle(viewModel.includeTags.contains(where: {$0 == mealType.apiValue}) ? .green : .black)
                                
                            }
                            .frame(width: 120, height: 130)
                            .padding(.bottom)
                            .onTapGesture {
                                if viewModel.includeTags.contains(where: {$0 == mealType.apiValue}){
                                    viewModel.removeMealType(mealType: mealType)
                                }
                                else {
                                    viewModel.addMealType(mealType: mealType)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
                
                HStack{
                    Button(action: {
                        Task {
                            // Call the API first, then navigate
                            await viewModel.completelyRandomRecipe()
                            // Navigate only after API call completes (success or failure)
                            navigateToRandomRecipe = true
                        }
                    }) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.green)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                            
                            VStack{
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Loading...")
                                            .foregroundStyle(.white)
                                    }
                                } else {
                                    Text("Surprise Me!")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .shadow(radius: 5)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.trailing,3)
                    .navigationDestination(isPresented: $navigateToRandomRecipe) {
                        RandomRecipeView(viewModel: viewModel)
                    }
                    
                    
                    NavigationLink(destination: CuisinesView()) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.green)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                            
                            VStack{
                                Text("Next")
                            }
                            .foregroundStyle(.white)
                        }
                        
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .shadow(radius: 5)
                        
                    }
                    .padding(.leading, 3)
                    
                }
                .padding()
            }
            .padding(.top)
        }
        
    }
}

#Preview {
    MealTypesView()
}
