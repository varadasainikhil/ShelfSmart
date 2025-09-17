//
//  Cuisines.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct CuisinesView: View {
    @State var viewModel = RandomRecipeViewModel()
    var columns = [ GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack{
            
            ScrollView{
                LazyVGrid(columns: columns) {
                    ForEach(Cuisine.allCases, id: \.self) { cuisine in
                        ZStack{
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(lineWidth: 2)
                                .foregroundStyle(viewModel.includeTags.contains(where: {$0 == cuisine.apiValue}) ? .green : .black)
                            
                            VStack(alignment: .center){
                                Text(cuisine.flagEmoji)
                                    .font(.title)
                                
                                Text(cuisine.displayName)
                                    .font(.title3)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 8)
                        .onTapGesture {
                            if viewModel.includeTags.contains(where: {$0 == cuisine.apiValue}){
                                viewModel.removeCuisine(cuisine: cuisine)
                            }
                            else {
                                viewModel.addCuisine(cuisine: cuisine)
                                
                            }
                        }
                    }
                }
            }
            NavigationLink(destination: IntolerancesView()) {
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
                .padding(.horizontal)
                
            }
        }
        
    }
}

#Preview {
    CuisinesView()
}
