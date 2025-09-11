//
//  SwiftUIView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/29/25.
//

import SwiftData
import SwiftUI

struct CardView: View {
    @Environment(\.modelContext) var modelContext
    @State private var viewModel = CardViewViewModel()
    var product : Item
    var body: some View {
        
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .fill(product.borderColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.borderColor, lineWidth: 2)
                )
            
            
            
            VStack{
                HStack{
                    
                    ZStack{
                        if product.productImage != nil  {
                            AsyncImage(url: URL(string: product.productImage ?? "no image")){phase in
                                if let image = phase.image{
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 75, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                else if phase.error != nil{
                                    Text("There was an error in loading the image")
                                }
                                else {
                                    ProgressView()
                                }
                            }
                        }
                        else {
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 75, height: 75)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                if product.nutritionGrade != nil {
                                    Image(systemName: "\(product.nutritionGrade!.lowercased()).square.fill")
                                        .foregroundStyle(product.nutritionColor)
                                        .font(.title2)
                                }
                            }
                        }
                        
                        
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    
                    Spacer()
                    
                    VStack(alignment: .leading){
                        Text(product.name)
                            .foregroundStyle(.black)
                            .font(.title3.bold())
                            .lineLimit(2)
                        
                        Text(!product.productDescription.isEmpty ? product.productDescription : "")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    Spacer()
                    
                    if product.isExpired{
                        Button {
                            // delete the product
                            withAnimation {
                                viewModel.deleteProduct(modelContext: modelContext, product: product)
                            }
                        } label: {
                            Image(systemName: "trash.circle")
                                .font(.title)
                                .foregroundStyle(product.isUsed ? .green : .black)
                        }
                    }
                    else {
                        Button {
                            // mark the product as used and completed
                            product.markUsed()
                        } label: {
                            Image(systemName: product.isUsed ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title)
                                .foregroundStyle(product.isUsed ? .green : .black)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 8)
        
    }
}

#Preview {
    let newOFFAProduct = OFFAProduct(productName: "Milk", brands: "Pascual", imageURL: "https://images.openfoodfacts.org/images/products/841/012/875/0145/front_es.25.400.jpg", ingredientsText: "", nutriments: OFFANutriments(nutritionScore: 90), nutritionGrade: "a")
    
    let newItem = Item(barcode: "8410128750145", name: newOFFAProduct.productName, productDescription: "", expirationDate: Date.now.addingTimeInterval(86400), productImage: newOFFAProduct.imageURL)
    
    CardView(product: newItem)
}
