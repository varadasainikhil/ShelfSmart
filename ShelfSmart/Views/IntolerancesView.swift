//
//  IntolerancesView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct IntolerancesView: View {
    @State var viewModel = RandomRecipeViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack{
            VStack(alignment: .leading){
                Text("Any Allergies?")
                    .font(.title)
                    .padding(.leading)
                ScrollView{
                    LazyVGrid(columns: columns) {
                        ForEach(Intolerances.allCases,id: \.self){ intolerance in
                            ZStack{
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(lineWidth: 2)
                                    .foregroundStyle(viewModel.includeTags.contains(where: {$0 == intolerance.apiValue}) ? .green : .black)
                                
                                VStack(alignment: .center){
                                    Text(intolerance.emoji)
                                        .font(.title)
                                    
                                    Text(intolerance.displayName)
                                        .font(.title3)
                                        .foregroundStyle(viewModel.includeTags.contains(where: {$0 == intolerance.apiValue}) ? .green : .black)
                                }
                            }
                            .frame(width: 120, height: 120)
                            .padding(.bottom, 8)
                            .onTapGesture {
                                if viewModel.includeTags.contains(where: {$0 == intolerance.apiValue}){
                                    viewModel.removeIntolerance(intolerance: intolerance)
                                }
                                else {
                                    viewModel.addIntolerance(intolerance: intolerance)
                                    
                                }
                            }
                        }
                    }
                }
                
                NavigationLink(destination: RandomRecipeView()) {
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
}

#Preview {
    IntolerancesView()
}
