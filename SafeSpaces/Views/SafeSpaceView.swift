import Foundation
import SwiftUI
import MapKit

struct SafeSpaceView: View {
    @Binding var mapSelection:MKMapItem?
    @Binding var selectedSpaceBinding: SafeSpace?
    @State private var selectedSpace: SafeSpace = SafeSpace(place: Place(name: "", location: Location(latitude: 0, longitude: 0), radius: 0), duration: DateInterval(), notify: Guardian())
    @State var saved = false
    @Environment(\.dismiss) var dismiss: DismissAction
    
    @State var mapScene = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude:0,longitude:0)))
    @State private var lookAroundScene: MKLookAroundScene?
        
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
            LazyVStack {
                
                LookAroundPreview(scene: $lookAroundScene)
                    .frame(height: 200)
                    .cornerRadius(12)
              
                TextField(selectedSpace.place.name, text: $selectedSpace.place.name)
                    .font(.subheadline)
             
                    .background(.white)
                    .border(.secondary)

                DatePicker("From", selection: $selectedSpace.duration.start)
                DatePicker("To", selection: $selectedSpace.duration.end)
                
                HStack{
                    Text("Circle Radius:")
                
                    TextField("Enter SafeRadius Here", value: $selectedSpace.place.radius, formatter: formatter)
                        .font(.subheadline)
                        .background(.white)
                        .border(.secondary)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Guardian Name:")
                    
                    TextField("Enter name here", text: $selectedSpace.notify.name)
                        .font(.subheadline)
                        .background(.white)
                        .border(.secondary)
                }
                HStack{
                    Text("Phone Number:")
                    
                    TextField("Enter Phone # Here", text: $selectedSpace.notify.phone)
                        .font(.subheadline)
                        .background(.white)
                        .border(.secondary)
                        .keyboardType(.decimalPad)
                    
                }
                HStack {
                    Button(action:{
                        self.saved.toggle()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 170, height: 48)
                            .background(saved ? Color.green : Color.blue)
                            .cornerRadius(12)
                            .onTapGesture {
                                print("DEBUG: REACHED SAFE TAP GESTURE")
                                AppData.AddSafeSpace(space: selectedSpace)
                                DeviceLocationService.shared.makeFence(name: selectedSpace.place.name, center: CLLocationCoordinate2D(latitude: selectedSpace.place.location.latitude,longitude: selectedSpace.place.location.longitude),radius: selectedSpace.place.radius
                                )
                                
                                dismiss()
                            }
                    }
                    Button(action:{}) {
                        Text("Delete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 170, height: 48)
                            .background(Color.red)
                            .cornerRadius(12)
                            .onTapGesture {
                                print("DEBUG: Delete Safe Space \(selectedSpace)")
                                AppData.DeleteSpace(name: selectedSpace.place.name)
                                dismiss()
                            }
                    }
                }
            }
            .padding()
            .onAppear() {
                if let selectedSpaceBinding {
                    selectedSpace = selectedSpaceBinding
                } else {
                    selectedSpace = SafeSpace(place: Place(name: mapSelection?.placemark.name ?? "",
                                                           location: Location(latitude: mapSelection?.placemark.location?.coordinate.latitude ?? 0,
                                                                              longitude: mapSelection?.placemark.location?.coordinate.longitude ?? 0
                                                                             ),
                                                           radius: 50
                                                          ),
                                              duration: DateInterval(start: Date.now, end: Date.now),
                                              notify: Guardian()
                    )
                }
                fetchLookAroundPreview()
            }
            .frame(alignment: .topLeading)
            .clipped()
    }
    
    func fetchLookAroundPreview() {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: selectedSpace.place.location.latitude, longitude: selectedSpace.place.location.longitude))
                lookAroundScene = try? await request.scene
            }
    }
    
}

#Preview {
    @Previewable @State var mapSelection:MKMapItem?
    @Previewable @State var selectedSpaceBinding: SafeSpace?
    
    return SafeSpaceView(mapSelection: $mapSelection, selectedSpaceBinding: $selectedSpaceBinding)
}
