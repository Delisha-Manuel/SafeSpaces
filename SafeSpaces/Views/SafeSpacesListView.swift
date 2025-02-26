import SwiftUI
import MapKit

struct SafeSpacesListView: View {
    @State private var spaces = AppData.data.safeSpaces
    @State private var selectedSpaceBinding: SafeSpace?
    @State private var mapSelection: MKMapItem?
    
    var body: some View {

        VStack {
            NavigationView {
                List(spaces, id: \.place.name) {space in
                    NavigationLink(destination: SafeSpaceView(mapSelection: $mapSelection, selectedSpaceBinding: Binding(get: { space }, set: { value in selectedSpaceBinding = value
                    }))) {
                            HStack {
                                Image(systemName: Tab.spaces.rawValue)
                                    .foregroundColor(.red)
                                    .font(.system(size: 22))
                                    .frame(width: 50, height: 50)
                                Text(space.place.name)
                            }
                        }
                }
                .refreshable() { Task { spaces = AppData.data.safeSpaces } }
                .onAppear() { spaces = AppData.data.safeSpaces }
                .navigationTitle("Safe Spaces")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    SafeSpacesListView()
}
