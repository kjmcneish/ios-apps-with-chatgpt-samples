import SwiftUI
import SwiftData

struct CuisineSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock cuisines for preview
        let mockCuisines = [
            CuisineEntity(uuid: UUID(), name: "Italian"),
            CuisineEntity(uuid: UUID(), name: "Mexican"),
            CuisineEntity(uuid: UUID(), name: "Japanese"),
            CuisineEntity(uuid: UUID(), name: "French")
        ]
        
        return CuisineSelectionView(
            cuisines: mockCuisines,  // Set mock cuisines here
            currentCuisine: mockCuisines.first,
            onCuisineSelected: { selectedCuisine in
                print("Selected cuisine: \(selectedCuisine.name)")
            }
        )
    }
}

struct CuisineSelectionView: View {
    @State var cuisines: [CuisineEntity]  // Accept cuisines as input
    @State private var selectedCuisine: CuisineEntity?
    
    // Pass the currently selected cuisine (if any) to the view
    var currentCuisine: CuisineEntity?
    
    // To notify the parent view controller of the selected cuisine
    var onCuisineSelected: (CuisineEntity) -> Void
    
    // Dismiss the view after a cuisine is selected
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            // Wrap the List in a ScrollViewReader
            ScrollViewReader { proxy in
                List(cuisines, id: \.id) { cuisine in
                    HStack {
                        Text(cuisine.name)
                        
                        // Show a checkmark for the currently selected cuisine
                        if cuisine.id == selectedCuisine?.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle()) // Make the entire row tappable
                    .onTapGesture {
                        // Set the selected cuisine and notify the parent view
                        selectedCuisine = cuisine
                        onCuisineSelected(cuisine)
                        
                        // Dismiss the view after selecting the cuisine
                        dismiss()
                    }
                    .id(cuisine.id) // Tag each row with its ID for scrolling
                }
                .navigationTitle("Select Cuisine")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    // Set the currently selected cuisine if any
                    self.selectedCuisine = currentCuisine
                    
                    // Scroll to the currently selected cuisine
                    if let currentCuisine = currentCuisine {
                        proxy.scrollTo(currentCuisine.id, anchor: .center)
                    }
                }
            }
        }
    }
}
