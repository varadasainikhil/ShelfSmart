//
//  QuickScanProductSheet.swift
//  ShelfSmart
//
//  Created by Claude Code on 12/15/25.
//

import SwiftUI

struct QuickScanProductSheet: View {
    @Bindable var viewModel: QuickScanViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // Product Image and Basic Info
                    HStack(alignment: .top, spacing: 16) {
                        // Product Image
                        RobustAsyncImage(url: viewModel.productImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Product Details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.productName ?? "Unknown Product")
                                .font(.headline)
                                .lineLimit(2)

                            if let brand = viewModel.productBrand {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let quantity = viewModel.productQuantity {
                                Text(quantity)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Allergen Tags
                    if let allergens = viewModel.allergensTags, !allergens.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(allergens, id: \.self) { allergen in
                                Text(formatAllergenName(allergen))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Scores Section
                    HStack(spacing: 12) {
                        // Nutri-Score - only show if valid grade A-E
                        if let grade = viewModel.nutriscoreGrade?.uppercased(),
                           !grade.isEmpty,
                           ["A", "B", "C", "D", "E"].contains(grade) {
                            ScoreBadge(
                                grade: grade,
                                title: "Nutri-Score",
                                color: nutriscoreColor(for: grade)
                            )
                        }

                        // Processing Level (NOVA Group) - only show if valid 1-4
                        if let nova = viewModel.novaGroup,
                           nova >= 1 && nova <= 4 {
                            ScoreBadge(
                                grade: "\(nova)",
                                title: "Processing Level",
                                color: novaColor(for: nova)
                            )
                        }

                        // Eco-Score - only show if valid grade A-E
                        if let eco = viewModel.ecoScoreGrade?.uppercased(),
                           !eco.isEmpty,
                           ["A", "B", "C", "D", "E"].contains(eco) {
                            ScoreBadge(
                                grade: eco,
                                title: "Eco-Score",
                                color: ecoscoreColor(for: eco)
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Calories Section
                    if let energy = viewModel.energyKcal {
                        VStack(spacing: 4) {
                            Text("Calories")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(energy))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                Text("kcal per 100g")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear,
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }

                    // Pros Section (Positive Components)
                    if let positives = viewModel.positiveComponents, !positives.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundStyle(.green)
                                Text("Pros")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.secondary)

                            ForEach(positives, id: \.nutrientId) { component in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text(formatNutrientName(component.nutrientId))
                                        .font(.subheadline)
                                    Spacer()
                                    if let value = component.value {
                                        Text(String(format: "%.1f%@", value, component.unit ?? ""))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear,
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }

                    // Cons Section (Negative Components)
                    if let negatives = viewModel.negativeComponents, !negatives.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .foregroundStyle(.red)
                                Text("Cons")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.secondary)

                            ForEach(negatives, id: \.nutrientId) { component in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text(formatNutrientName(component.nutrientId))
                                        .font(.subheadline)
                                    Spacer()
                                    if let value = component.value {
                                        Text(String(format: "%.1f%@", value, component.unit ?? ""))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear,
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }

                    // Nutrition Quick Info
                    if hasNutritionData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition per 100g")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                if let fat = viewModel.fat {
                                    NutritionItem(
                                        label: "Fat",
                                        value: String(format: "%.1fg", fat),
                                        labelColor: nutrientColor(for: "fat")
                                    )
                                }
                                if let carbs = viewModel.carbohydrates {
                                    NutritionItem(
                                        label: "Carbs",
                                        value: String(format: "%.1fg", carbs),
                                        labelColor: nutrientColor(for: "carbohydrates")
                                    )
                                }
                                if let protein = viewModel.proteins {
                                    NutritionItem(
                                        label: "Protein",
                                        value: String(format: "%.1fg", protein),
                                        labelColor: nutrientColor(for: "proteins")
                                    )
                                }
                                if let sugars = viewModel.sugars {
                                    NutritionItem(
                                        label: "Sugars",
                                        value: String(format: "%.1fg", sugars),
                                        labelColor: nutrientColor(for: "sugars")
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear,
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Computed Properties
    private var hasNutritionData: Bool {
        viewModel.energyKcal != nil ||
        viewModel.fat != nil ||
        viewModel.carbohydrates != nil ||
        viewModel.proteins != nil ||
        viewModel.sugars != nil
    }

    // MARK: - Color Helpers
    private func nutriscoreColor(for grade: String) -> Color {
        switch grade {
        case "A": return Color(red: 0.01, green: 0.51, blue: 0.25)
        case "B": return Color(red: 0.52, green: 0.73, blue: 0.18)
        case "C": return Color(red: 0.99, green: 0.80, blue: 0.01)
        case "D": return Color(red: 0.93, green: 0.51, blue: 0.00)
        case "E": return Color(red: 0.90, green: 0.24, blue: 0.07)
        default: return .gray
        }
    }

    private func novaColor(for group: Int) -> Color {
        switch group {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }

    private func ecoscoreColor(for grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return Color(red: 0.52, green: 0.73, blue: 0.18)
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default: return .gray
        }
    }

    // MARK: - Nutrient Name Formatter
    private func formatNutrientName(_ nutrientId: String) -> String {
        // Special case for energy -> Calories
        if nutrientId.lowercased() == "energy" {
            return "Calories"
        }

        // Convert snake_case to Title Case
        let components = nutrientId.split(separator: "_")
        return components.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    // MARK: - Nutrient Color Helper
    /// Returns green if nutrient is in positives, red if in negatives, secondary otherwise
    private func nutrientColor(for nutrientId: String) -> Color {
        // Check if in positive components (pros)
        if let positives = viewModel.positiveComponents,
           positives.contains(where: { $0.nutrientId.lowercased() == nutrientId.lowercased() }) {
            return .green
        }
        
        // Check if in negative components (cons)
        if let negatives = viewModel.negativeComponents,
           negatives.contains(where: { $0.nutrientId.lowercased() == nutrientId.lowercased() }) {
            return .red
        }
        
        // Default to secondary
        return .secondary
    }

    // MARK: - Allergen Name Formatter
    private func formatAllergenName(_ allergen: String) -> String {
        // Remove language prefix (e.g., "en:", "fr:", etc.)
        var cleaned = allergen
        if let colonIndex = allergen.firstIndex(of: ":") {
            cleaned = String(allergen[allergen.index(after: colonIndex)...])
        }

        // Replace hyphens and underscores with spaces
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")
                        .replacingOccurrences(of: "_", with: " ")

        // Capitalize each word (Title Case)
        let words = cleaned.split(separator: " ")
        let titleCased = words.map { word -> String in
            let lowercased = word.lowercased()
            return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
        }.joined(separator: " ")

        return titleCased
    }
}

// MARK: - Nutrition Item Component
struct NutritionItem: View {
    let label: String
    let value: String
    var labelColor: Color = .secondary
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(labelColor)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
        .cornerRadius(8)
    }
}

#Preview {
    let vm = QuickScanViewModel()
    vm.productName = "Nutella Hazelnut Spread"
    vm.productBrand = "Ferrero"
    vm.productQuantity = "400g"
    vm.nutriscoreGrade = "e"
    vm.novaGroup = 4
    vm.ecoScoreGrade = "d"
    vm.energyKcal = 539
    vm.fat = 30.9
    vm.carbohydrates = 57.5
    vm.proteins = 6.3
    vm.sugars = 56.3
    vm.source = "api"

    return QuickScanProductSheet(viewModel: vm)
}
