import SwiftUI
import MapKit


struct LocationDetailsView : View {
    @Binding var mapSelection:MKMapItem?
    @Binding var show:Bool
    @State private var lookAroundScene: MKLookAroundScene?
    @State var forSheet = false
    @Binding var getDirections:Bool
    @State var isSafe:Bool
    @State private var space: SafeSpace?
    
    var body: some View {
        VStack {
            HStack {
                
                VStack(alignment: .leading) {
                    Text(mapSelection?.placemark.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                        .padding(.trailing)
                }
                
                Spacer()
                
                Button {
                    show.toggle()
                    mapSelection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width:24, height:24)
                        .foregroundStyle(.gray, Color(.systemGray6))
                }
            }
            
            
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
            } else {
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            
            
            HStack(spacing: 24) {
                Button {
                    show = false
                } label: {
                    Text("Safe Space")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(Color.red)
                        .background(isSafe ? Color.red : Color.green)
                        .cornerRadius(12)
                        .onTapGesture {
                            isSafe = true
                        }
                }
                
                Button {
                    getDirections = true
                    show = false
                } label: {
                    Text("Get Directions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 150, height: 48)
                        .background(.blue)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            fetchLookAroundPreview()
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            fetchLookAroundPreview()
        }
        .onChange(of: isSafe) { oldValue, newValue in
            forSheet = newValue
        }
        .sheet(isPresented: $forSheet, content:{
            SafeSpaceView(mapSelection: $mapSelection, selectedSpaceBinding: $space)
            .presentationDetents([.height(500)])
            .presentationBackgroundInteraction(.enabled(upThrough: .height(500)))
            .presentationCornerRadius(12)
        })
        .padding()
    }
    
}

extension LocationDetailsView {
    func fetchLookAroundPreview() {
        if let mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

#Preview {
    @Previewable @State var mapSelection:MKMapItem?
    @Previewable @State var show = true
    @Previewable @State var getDirections = false
    @Previewable @State var isSafe = true
    
    return LocationDetailsView(mapSelection: $mapSelection, show: $show, getDirections: $getDirections, isSafe: isSafe)
}
