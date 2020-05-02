//
//  TextEdit.swift
//  Tasks
//
//  Created by Nick Garfitt on 2/5/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import SwiftUI

class UIKitTextField: UITextField, UITextFieldDelegate {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        delegate = self
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        self.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }

}

struct UBSTextField : UIViewRepresentable {

    @Binding var myText: String
    let placeHolderText: String

    func makeCoordinator() -> UBSTextField.Coordinator {
        return Coordinator(text: $myText)
    }

    class Coordinator: NSObject {
        var textBinding: Binding<String>
        init(text: Binding<String>) {
            self.textBinding = text
        }

        @objc func textFieldEditingChanged(_ sender: UIKitTextField) {
            self.textBinding.wrappedValue = sender.text ?? ""
        }
    }

    func makeUIView(context: Context) -> UIKitTextField {

        let textField = UIKitTextField(frame: .zero)

        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingChanged(_:)), for: .editingChanged)

        textField.text = self.myText
        textField.placeholder = self.placeHolderText
        textField.borderStyle = .none
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.autocapitalizationType = .sentences
        textField.clearButtonMode = .whileEditing

        return textField
    }

    func updateUIView(_ uiView: UIKitTextField,
                      context: Context) {
        uiView.text = self.myText
    }
}

struct CTextField: View {
    
    @Binding var text: String
    @State var placeholder: String
      
    var body: some View {
        VStack {
            UBSTextField(myText: $text, placeHolderText: placeholder)
        }
    }
    
}
