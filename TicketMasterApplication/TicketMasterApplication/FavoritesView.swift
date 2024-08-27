//
//  FavoritesView.swift
//  TicketMasterApplication
//
//  Created by Neranjhana  on 02/05/23.
//

import SwiftUI



struct FavoritesView: View {
    
    @AppStorage("eventDetails") var storedEventDetails: Data?
    
    @State private var showAlert = false
    @State private var decodedData: [FavoritesDetails] = []
    
    var body: some View {
        NavigationView {
            if let storedData = storedEventDetails {
                if var decodedData = try? JSONDecoder().decode([FavoritesDetails].self, from: storedData) {
                    if decodedData.count > 0 {
                        
                        List(decodedData, id: \.id) { favorite in
                            HStack(spacing: 12) {
                                Text(favorite.date)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                Text(favorite.name)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                Text(favorite.genre)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                Text(favorite.venue)
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(action: {
                                    // Implement delete action here
                                    deleteFavorite(favorite, from: &decodedData, showAlert: $showAlert)
                                    
                                }, label: {
                                    Text("Delete")
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                })
                                Text("")
                                .background(Color.red)
                            }
                        }
                        .navigationTitle("Favorites")
                        .navigationTitle("Favorites")
                    } else {
                        Text("No favorites found")
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Error decoding favorites data")
                        .foregroundColor(.red)
                }
            } else {
                Text("No favorites found")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func deleteFavorite(_ favorite: FavoritesDetails, from decodedData: inout [FavoritesDetails], showAlert: Binding<Bool>) {
        // Remove the favorite from the decodedData array
        print("Fav name is", favorite.name)
        decodedData.removeAll { item in
            if item.name == favorite.name {
                print(item.name)
                print("Item name is", item.name)
                return true
            } else {
                print("Item name is", item.name)
                return false
            }
        }
        storedEventDetails = try? JSONEncoder().encode(decodedData)
        print("Data deleted")
        
        // Save the updated data to UserDefaults
        if let encodedData = try? JSONEncoder().encode(decodedData) {
            UserDefaults.standard.set(encodedData, forKey: "storedEventDetails")
        }
        
        // Update the state variable to trigger a view refresh
        showAlert.wrappedValue = true
    }
}
