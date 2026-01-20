//
//  ProductCompareView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//

import SwiftUI

/// Main comparison view for Compare feature
/// Displays 1-2 products in side-by-side comparison layout
struct ProductCompareView: View {
    let userId: String
    
    @State private var viewModel = ProductCompareViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section (matching HomeView style)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compare")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text("Products")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Clear button in header
                        if !viewModel.comparisonProducts.isEmpty {
                            Button {
                                viewModel.clearComparison()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Subtitle
                    Text("Scan and compare nutritional values side by side")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                
                // Content Section
                ZStack {
                    // Background
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if viewModel.comparisonProducts.isEmpty {
                        emptyStateView
                    } else if viewModel.productCount == 1 {
                        singleProductView
                    } else {
                        comparisonView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showScannerSheet) {
                BarcodeScannerSheetView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                // Auto-show scanner when navigating to this tab
                if viewModel.shouldAutoShowScanner && !viewModel.showScannerSheet {
                    viewModel.showScannerSheet = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.green.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("Compare Products")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Scan up to 2 products to compare\ntheir nutritional values side by side")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.openScanner()
            } label: {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Scan Product")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.green)
                )
            }
        }
        .padding()
    }
    
    // MARK: - Single Product View
    
    private var singleProductView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let product = viewModel.firstProduct {
                    // Product Card
                    singleProductCard(product: product)
                    
                    // Scan Another Prompt
                    scanAnotherPrompt
                }
            }
            .padding()
        }
    }
    
    // MARK: - Single Product Card
    
    private func singleProductCard(product: CompareProduct) -> some View {
        VStack(spacing: 16) {
            // Header with image and info
            HStack(alignment: .top, spacing: 16) {
                // Product Image
                ZStack {
                    if let imageURL = product.images.front, !imageURL.isEmpty {
                        RobustAsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Product Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Labels
                    if !product.formattedLabels.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(product.formattedLabels, id: \.text) { label in
                                HStack(spacing: 4) {
                                    Image(systemName: label.icon)
                                        .font(.caption2)
                                    Text(label.text)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(label.color.opacity(0.15))
                                )
                                .foregroundStyle(label.color)
                            }
                        }
                    }
                    
                    // Scores Row
                    HStack(spacing: 8) {
                        ScorePill(grade: product.nutriscoreGradeDisplay, color: product.nutriscoreColor)
                        ScorePill(grade: product.processingLevelGrade, color: product.processingLevelColor)
                    }
                }
                
                Spacer()
                
                // Remove button
                Button {
                    viewModel.removeFromComparison(product)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Nutrition Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NutritionStatCell(label: "Calories", value: product.nutrition.calories, unit: product.nutrition.caloriesUnit ?? "kcal")
                NutritionStatCell(label: "Sugar", value: product.nutrition.sugar, unit: product.nutrition.sugarUnit ?? "g")
                NutritionStatCell(label: "Protein", value: product.nutrition.protein, unit: product.nutrition.proteinUnit ?? "g")
                NutritionStatCell(label: "Fat", value: product.nutrition.fat, unit: product.nutrition.fatUnit ?? "g")
                NutritionStatCell(label: "Fiber", value: product.nutrition.fiber, unit: "g")
                NutritionStatCell(label: "Salt", value: product.nutrition.salt, unit: product.nutrition.saltUnit ?? "g")
            }
            

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Scan Another Prompt
    
    private var scanAnotherPrompt: some View {
        VStack(spacing: 12) {
            Text("Scan another product to compare")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                viewModel.openScanner()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Scan Product")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.green.opacity(0.5))
        )
    }
    
    // MARK: - Comparison View (2 Products)
    
    private var comparisonView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Product Headers
                productHeadersSection
                
                // Labels Comparison
                labelsComparisonSection
                
                // Allergens Comparison
                allergensComparisonSection
                
                // Scores Comparison
                scoresComparisonSection
                
                // Nutrition Comparison
                nutritionComparisonSection
            }
            .padding()
        }
    }
    
    // MARK: - Product Headers Section
    
    private var productHeadersSection: some View {
        HStack(spacing: 12) {
            if let product1 = viewModel.firstProduct {
                compactProductCard(product: product1, position: 1)
            }
            
            // VS Badge
            VStack {
                Text("VS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray)
                    )
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 50)
            
            if let product2 = viewModel.secondProduct {
                compactProductCard(product: product2, position: 2)
            }
        }
        .fixedSize(horizontal: false, vertical: true) // Forces children to match the height of the tallest child
    }
    
    // MARK: - Compact Product Card
    
    private func compactProductCard(product: CompareProduct, position: Int) -> some View {
        VStack(spacing: 8) {
            // Product Image
            ZStack {
                if let imageURL = product.images.front, !imageURL.isEmpty {
                    RobustAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(product.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if let brand = product.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0) // Ensure content pushes/fills nicely if we want vertical flow, though primarily we just want background to stretch
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow expanding to match neighbor
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.removeFromComparison(product)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }
    
    // MARK: - Nutrition Comparison Section
    
    private var nutritionComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition (per 100g)")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                ComparisonRow(label: "Calories", value1: viewModel.firstProduct?.nutrition.calories, value2: viewModel.secondProduct?.nutrition.calories, unit: viewModel.firstProduct?.nutrition.caloriesUnit ?? "kcal", viewModel: viewModel, lowerIsBetter: true)
                ComparisonRow(label: "Sugar", value1: viewModel.firstProduct?.nutrition.sugar, value2: viewModel.secondProduct?.nutrition.sugar, unit: viewModel.firstProduct?.nutrition.sugarUnit ?? "g", viewModel: viewModel, lowerIsBetter: true)
                ComparisonRow(label: "Protein", value1: viewModel.firstProduct?.nutrition.protein, value2: viewModel.secondProduct?.nutrition.protein, unit: viewModel.firstProduct?.nutrition.proteinUnit ?? "g", viewModel: viewModel, lowerIsBetter: false)
                ComparisonRow(label: "Fat", value1: viewModel.firstProduct?.nutrition.fat, value2: viewModel.secondProduct?.nutrition.fat, unit: viewModel.firstProduct?.nutrition.fatUnit ?? "g", viewModel: viewModel, lowerIsBetter: true)
                ComparisonRow(label: "Saturated Fat", value1: viewModel.firstProduct?.nutrition.saturatedFat, value2: viewModel.secondProduct?.nutrition.saturatedFat, unit: viewModel.firstProduct?.nutrition.saturatedFatUnit ?? "g", viewModel: viewModel, lowerIsBetter: true)
                ComparisonRow(label: "Fiber", value1: viewModel.firstProduct?.nutrition.fiber, value2: viewModel.secondProduct?.nutrition.fiber, unit: "g", viewModel: viewModel, lowerIsBetter: false)
                ComparisonRow(label: "Salt", value1: viewModel.firstProduct?.nutrition.salt, value2: viewModel.secondProduct?.nutrition.salt, unit: viewModel.firstProduct?.nutrition.saltUnit ?? "g", viewModel: viewModel, lowerIsBetter: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Scores Comparison Section
    
    private var scoresComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scores")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                // Nutri-Score
                ScoreComparisonRow(
                    title: "Nutri-Score",
                    grade1: viewModel.firstProduct?.nutriscoreGradeDisplay ?? "N/A",
                    grade2: viewModel.secondProduct?.nutriscoreGradeDisplay ?? "N/A",
                    color1: viewModel.firstProduct?.nutriscoreColor ?? .gray,
                    color2: viewModel.secondProduct?.nutriscoreColor ?? .gray,
                    winner: viewModel.compareGrades(grade1: viewModel.firstProduct?.scores.nutriscoreGrade, grade2: viewModel.secondProduct?.scores.nutriscoreGrade)
                )
                
                Divider()
                
                // Processing Level
                ScoreComparisonRow(
                    title: "Processing",
                    grade1: viewModel.firstProduct?.processingLevelGrade ?? "N/A",
                    grade2: viewModel.secondProduct?.processingLevelGrade ?? "N/A",
                    color1: viewModel.firstProduct?.processingLevelColor ?? .gray,
                    color2: viewModel.secondProduct?.processingLevelColor ?? .gray,
                    winner: viewModel.compareNovaGroups(nova1: viewModel.firstProduct?.scores.novaGroup, nova2: viewModel.secondProduct?.scores.novaGroup)
                )
                
                Divider()
                
                // Eco-Score
                ScoreComparisonRow(
                    title: "Eco-Score",
                    grade1: viewModel.firstProduct?.ecoscoreGradeDisplay ?? "N/A",
                    grade2: viewModel.secondProduct?.ecoscoreGradeDisplay ?? "N/A",
                    color1: viewModel.firstProduct?.ecoscoreColor ?? .gray,
                    color2: viewModel.secondProduct?.ecoscoreColor ?? .gray,
                    winner: viewModel.compareGrades(grade1: viewModel.firstProduct?.scores.ecoscoreGrade, grade2: viewModel.secondProduct?.scores.ecoscoreGrade)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Allergens Comparison Section
    
    private var allergensComparisonSection: some View {
        let allergens1 = viewModel.firstProduct?.formattedAllergens ?? []
        let allergens2 = viewModel.secondProduct?.formattedAllergens ?? []
        
        guard !allergens1.isEmpty || !allergens2.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Allergens")
                        .font(.headline)
                }
                
                HStack(alignment: .top, spacing: 16) {
                    // Product 1 Allergens
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allergens1, id: \.self) { allergen in
                            Text(allergen)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .foregroundStyle(.orange)
                        }
                        if allergens1.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Product 2 Allergens
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allergens2, id: \.self) { allergen in
                            Text(allergen)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .foregroundStyle(.orange)
                        }
                        if allergens2.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        )
    }
    
    // MARK: - Labels Comparison Section
    
    private var labelsComparisonSection: some View {
        let labels1 = viewModel.firstProduct?.formattedLabels ?? []
        let labels2 = viewModel.secondProduct?.formattedLabels ?? []
        
        guard !labels1.isEmpty || !labels2.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Labels")
                    .font(.headline)
                
                HStack(alignment: .top, spacing: 16) {
                    // Product 1 Labels
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(labels1, id: \.text) { label in
                            HStack(spacing: 4) {
                                Image(systemName: label.icon)
                                    .font(.caption2)
                                Text(label.text)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(label.color.opacity(0.15))
                            )
                            .foregroundStyle(label.color)
                        }
                        if labels1.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Product 2 Labels
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(labels2, id: \.text) { label in
                            HStack(spacing: 4) {
                                Image(systemName: label.icon)
                                    .font(.caption2)
                                Text(label.text)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(label.color.opacity(0.15))
                            )
                            .foregroundStyle(label.color)
                        }
                        if labels2.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        )
    }
}

// MARK: - Supporting Views

struct ScorePill: View {
    let grade: String
    let color: Color
    
    var body: some View {
        StyledGradeText(grade, fontSize: .caption)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

struct NutritionStatCell: View {
    let label: String
    let value: Double?
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            if let value = value {
                Text("\(String(format: "%.1f", value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

struct ComparisonRow: View {
    let label: String
    let value1: Double?
    let value2: Double?
    let unit: String
    let viewModel: ProductCompareViewModel
    let lowerIsBetter: Bool
    
    var body: some View {
        let comparisonResult = viewModel.compareBetter(value1: value1, value2: value2, lowerIsBetter: lowerIsBetter)
        
        HStack {
            // Value 1
            HStack {
                if let v = value1 {
                    Text("\(String(format: "%.1f", v))\(unit)")
                        .font(.subheadline)
                        .fontWeight(.bold) // Make it bolder
                        .foregroundStyle(colorForValue(isFirst: true, result: comparisonResult))
                } else {
                    Text("N/A")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100)
            
            // Value 2
            HStack {
                if let v = value2 {
                    Text("\(String(format: "%.1f", v))\(unit)")
                        .font(.subheadline)
                        .fontWeight(.bold) // Make it bolder
                        .foregroundStyle(colorForValue(isFirst: false, result: comparisonResult))
                } else {
                    Text("N/A")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
    
    private func colorForValue(isFirst: Bool, result: Int) -> Color {
        if result == 0 { return .primary }
        
        if isFirst {
            return result == 1 ? .green : .red
        } else {
            return result == 2 ? .green : .red
        }
    }
}

struct ScoreComparisonRow: View {
    let title: String
    let grade1: String
    let grade2: String
    let color1: Color
    let color2: Color
    let winner: Int // 0 = tie, 1 = first, 2 = second
    
    var body: some View {
        HStack {
            // Grade 1
            HStack {
                ZStack {
                    Circle()
                        .fill(color1.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    StyledGradeText(grade1, fontSize: .subheadline)
                        .foregroundStyle(color1)
                }
                .overlay(
                    winner == 1 ?
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .offset(x: 12, y: -12)
                        : nil
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            
            // Grade 2
            HStack {
                ZStack {
                    Circle()
                        .fill(color2.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    StyledGradeText(grade2, fontSize: .subheadline)
                        .foregroundStyle(color2)
                }
                .overlay(
                    winner == 2 ?
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .offset(x: 12, y: -12)
                        : nil
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct StyledGradeText: View {
    let grade: String
    let fontSize: Font
    
    init(_ grade: String, fontSize: Font = .title2) {
        self.grade = grade
        self.fontSize = fontSize
    }
    
    var body: some View {
        if grade.hasSuffix("+") {
            Text(grade.dropLast())
                .font(fontSize)
                .fontWeight(.bold) +
            Text("+")
                .font(fontSize == .title2 ? .body : .caption2) // Smaller font for the plus
                .fontWeight(.bold)
                .baselineOffset(fontSize == .title2 ? 4.0 : 2.0) // Superscript effect (looks like A⁺)
        } else {
            Text(grade)
                .font(fontSize)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    ProductCompareView(userId: "preview_user")
}
