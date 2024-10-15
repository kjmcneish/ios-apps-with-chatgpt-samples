//
//  CountrySelectionView.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/10/24.
//

import SwiftUI

import SwiftUI

struct CountrySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelectionView(
            currentCountry: Locale.Region("US"),  // Example selected country
            onCountrySelected: { selectedCountry in
                print("Selected country: \(selectedCountry)")
            }
        )
    }
}

struct CountrySelectionView: View {
    @State private var selectedCountry: Locale.Region?
    
    // Get a sorted list of regions (countries) alphabetized by their localized names
    let countries = Locale.Region.isoRegions.sorted {
        (Locale.current.localizedString(forRegionCode: $0.identifier) ?? $0.identifier) <
        (Locale.current.localizedString(forRegionCode: $1.identifier) ?? $1.identifier)
    }
    
    // Pass the currently selected country (if any)
    var currentCountry: Locale.Region?
    
    // To notify the parent view controller of the selected country name
    @Environment(\.dismiss) private var dismiss
    var onCountrySelected: (String) -> Void  // Return country name
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                List(countries, id: \.identifier) { country in
                    HStack {
                        let countryName = Locale.current.localizedString(forRegionCode: country.identifier) ?? country.identifier
                        Text(countryName)
                        
                        // Show a checkmark for the currently selected country
                        if country == selectedCountry {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle()) // Make the entire row tappable
                    .onTapGesture {
                        // Get the country name and pass it back to the parent view
                        let countryName = Locale.current.localizedString(forRegionCode: country.identifier) ?? country.identifier
                        selectedCountry = country
                        onCountrySelected(countryName)
                        
                        // Dismiss the SwiftUI view
                        dismiss()
                    }
                }
                .navigationTitle("Select Country")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    // Set the currently selected country if any
                    if let currentCountry = currentCountry {
                        self.selectedCountry = currentCountry
                        
                        // Scroll to the currently selected country
                        if let selectedCountry = selectedCountry {
                            scrollProxy.scrollTo(selectedCountry.identifier, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
