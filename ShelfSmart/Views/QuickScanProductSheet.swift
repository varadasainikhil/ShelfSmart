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

                            // Source Badge
                            if let source = viewModel.source {
                                HStack(spacing: 4) {
                                    Image(systemName: source == "cache" ?
                                          "bolt.fill" : "cloud.fill")
                                        .font(.caption2)
                                    Text(source == "cache" ? "Cached" : "Fresh")
                                        .font(.caption2)
                                }
                                .foregroundStyle(source == "cache" ? .orange : .green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(source == "cache" ?
                                              Color.orange.opacity(0.1) :
                                              Color.green.opacity(0.1))
                                )
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Scores Section
                    HStack(spacing: 12) {
                        // Nutri-Score
                        if let grade = viewModel.nutriscoreGrade?.uppercased(),
                           !grade.isEmpty {
                            let displayGrade = ["A", "B", "C", "D", "E"].contains(grade) ? grade : "N/A"
                            ScoreBadge(
                                grade: displayGrade,
                                title: "Nutri-Score",
                                color: nutriscoreColor(for: grade)
                            )
                        }

                        // NOVA Group
                        if let nova = viewModel.novaGroup {
                            ScoreBadge(
                                grade: "\(nova)",
                                title: "NOVA",
                                color: novaColor(for: nova)
                            )
                        }

                        // Eco-Score
                        if let eco = viewModel.ecoScoreGrade?.uppercased(),
                           !eco.isEmpty, eco != "UNKNOWN" {
                            ScoreBadge(
                                grade: eco,
                                title: "Eco-Score",
                                color: ecoscoreColor(for: eco)
                            )
                        }
                    }
                    .padding(.horizontal)

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
                                if let energy = viewModel.energyKcal {
                                    NutritionItem(
                                        label: "Energy",
                                        value: "\(Int(energy)) kcal"
                                    )
                                }
                                if let fat = viewModel.fat {
                                    NutritionItem(
                                        label: "Fat",
                                        value: String(format: "%.1fg", fat)
                                    )
                                }
                                if let carbs = viewModel.carbohydrates {
                                    NutritionItem(
                                        label: "Carbs",
                                        value: String(format: "%.1fg", carbs)
                                    )
                                }
                                if let protein = viewModel.proteins {
                                    NutritionItem(
                                        label: "Protein",
                                        value: String(format: "%.1fg", protein)
                                    )
                                }
                                if let sugars = viewModel.sugars {
                                    NutritionItem(
                                        label: "Sugars",
                                        value: String(format: "%.1fg", sugars)
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

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            viewModel.reset()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Scan Another")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            .shadow(color: .green.opacity(0.2), radius: 2, x: 0, y: 1)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
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
}

// MARK: - Nutrition Item Component
struct NutritionItem: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
