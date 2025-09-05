//
//  CustomTextFieldWithHeading.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/26/25.
//

import SwiftUI

struct CustomTextFieldWithHeading: View {
    var heading : String
    var textToShow : String
    @Binding var variabletoBind : String
    var body: some View {
        VStack(alignment: .leading){
            Text(heading)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.leading, 5)
            
            CustomTextField(textToShow: textToShow, variableToBind: $variabletoBind)
        }
    }
}

#Preview {
    CustomTextFieldWithHeading(heading: "Test Heading", textToShow: "Test Text", variabletoBind: .constant("Hello"))
}
