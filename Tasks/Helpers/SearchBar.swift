//
//  SearchBar.swift
//  Tasks
//
//  Created by Nick Garfitt on 3/5/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct SearchBar: View {
    
    @Binding var showCancelButton: Bool
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.leading, 5)
                TextField("Search", text: $searchText, onEditingChanged: { isEditing in
                    self.showCancelButton = true
                }, onCommit: {
                    print("onCommit")
                }).foregroundColor(.primary)

                Button(action: {
                    self.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
            .foregroundColor(.secondary)
            .background(Color(.systemGray4))
            .cornerRadius(10.0)
            if showCancelButton  {
                Button("Cancel") {
                        UIApplication.shared.endEditing(true)
                        self.searchText = ""
                        self.showCancelButton = false
                }
                .foregroundColor(Color(.systemBlue))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
    
}
