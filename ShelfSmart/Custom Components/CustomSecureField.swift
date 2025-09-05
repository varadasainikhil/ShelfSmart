//
//  CustomSecureField.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import SwiftUI

struct CustomSecureField: View {
    var textToShow : String
    @Binding var variableToBind : String
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(lineWidth: 2)
            SecureField(textToShow, text: $variableToBind)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}

#Preview {
    CustomSecureField(textToShow: "Test", variableToBind: .constant("Test Text"))
}

