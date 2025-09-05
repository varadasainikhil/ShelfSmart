//
//  CustomTextField.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import SwiftUI

struct CustomTextField: View {
    var textToShow : String
    @Binding var variableToBind : String
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(lineWidth: 2)
            TextField(textToShow, text: $variableToBind)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}

#Preview {
    CustomTextField(textToShow: "Test", variableToBind: .constant("Test Text"))
}
