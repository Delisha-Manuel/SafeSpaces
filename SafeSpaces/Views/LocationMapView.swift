import Combine
import SwiftUI
import MapKit

struct LocationMapView: View {
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State var mapSelection: MKMapItem?
    @State private var showDetails = false
    
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    @State private var newTask: String?
    @State var getPlaces = AppData.GetPlaces()
    @State var tokens: Set<AnyCancellable> = []
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State private var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()

    var body: some View {
        ZStack{
            Map(position: $cameraPosition, selection: $mapSelection){
                Annotation(AppData.data.me.name, coordinate: userLocation) {
                    ZStack {
                        Circle()
                            .frame(width:32, height:32)
                            .foregroundColor(.blue.opacity(0.25))
                        Circle()
                            .frame(width: 20, height:20)
                            .foregroundColor(.white)
                        Circle()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.blue)
                    }
                }

                ForEach(results, id: \.self) { item in
                    if routeDisplaying {
                        if item == routeDestination {
                            let placemark = item.placemark
                            Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                        }
                    } else {
                        let placemark = item.placemark
                        Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                    }
                }
                
                ForEach(AppData.GetPlaces(), id: \.name) { place in
                    let coordinate = CLLocationCoordinate2D(latitude: place.location.latitude, longitude: place.location.longitude)
                    Marker(place.name, coordinate: coordinate)
                        .tint(.green)
                    MapCircle(center: coordinate, radius: CLLocationDistance(place.radius))
                        .foregroundStyle(.teal.opacity(0.30))
                        .mapOverlayLevel(level: .aboveRoads)
                }
                
                if let route{
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
            }
  
            .overlay(alignment: .top){
                TextField("Search for a location: ", text: $searchText)
                    .font(.subheadline)
                    .padding(12)
                    .background(.white)
                    .padding()
                    .cornerRadius(12)
                    .shadow(radius:10)
            }
            .onSubmit(of: .text) {
                Task { await searchPlaces() }
            }
            
            .onChange(of: getDirections, { oldValue, newValue in
                if newValue {
                    fetchRoute()
                }
            })
            .onChange(of: mapSelection, { oldValue, newValue in
                showDetails = newValue != nil
            })
            //Muy Importante
            .sheet(isPresented: $showDetails, content: {
                LocationDetailsView(mapSelection: $mapSelection,
                                    show: $showDetails,
                                    getDirections: $getDirections,
                                    isSafe: false)
                .presentationDetents([.height(340)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(12)
            })
                .mapControlVisibility(.visible)
                .mapControlVisibility(.visible)
            
            .controlSize(.large)
            
            .onAppear {
                print("DEBUG: On Appear Ask Location")
                NotificationHandler.askPermission()
                observeCoordinateUpdates()
                observeLocationAccessDenied()
                deviceLocationService.requestLocationUpdates()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension LocationMapView {
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
        
        
    func fetchRoute() {
        if let mapSelection {
            let request = MKDirections.Request ()
            request.source = MKMapItem(placemark: .init(coordinate: userLocation))
            request.destination = mapSelection
            
            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                routeDestination = mapSelection
                
                withAnimation(.snappy) {
                    routeDisplaying = true
                    showDetails = false
                        
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                        cameraPosition = .rect(rect)
                        }
                    }
                }
            }
        }
    
    func observeCoordinateUpdates() {
        deviceLocationService.coordinatesPublisher
            .receive(on:DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.userLocation = coordinates
            }
            .store(in: &tokens)
    }
    
    func observeLocationAccessDenied () {
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Show some kind of all")
            }
            .store(in: &tokens)
    }
}


#Preview {
    LocationMapView()
}
