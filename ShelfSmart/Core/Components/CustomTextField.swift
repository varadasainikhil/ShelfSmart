//
//  CustomTextField.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import SwiftUI

struct CustomTextField: View {
    var textToShow: String
    @Binding var variableToBind: String

    var body: some View {
        TextField(textToShow, text: $variableToBind)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(height: 44)
    }
}

#Preview {
    CustomTextField(textToShow: "Test", variableToBind: .constant("Test Text"))
        .padding()
}
