import Combine
import CoreLocation

//Returns coordinates of new user location
class DeviceLocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    var coordinatesPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    var deniedLocationAccessPublisher = PassthroughSubject<Void, Never>()
    var someCenter: CLLocation = CLLocation()
    private override init() {
        super.init()
    }
    
    static let shared = DeviceLocationService()
    
    public lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
       return manager
    }()
    
    func startMonitoring() {
        // Re-create existing geo-fences
        for place in AppData.GetPlaces() {
            makeFence(name: place.name, center: CLLocationCoordinate2D(
                latitude: place.location.latitude,
                longitude: place.location.longitude),
                      radius: (place.radius))
        }
    }
    
    func requestLocationUpdates() {
        switch locationManager.authorizationStatus {
        
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            startMonitoring()
            
        default:
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
        switch manager.authorizationStatus {
        
        case .authorizedAlways:
            manager.startUpdatingLocation()
            startMonitoring()
        
        default:
            manager.stopUpdatingLocation()
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinatesPublisher.send(location.coordinate) //Coordinates of user location
        
        CheckRegionStatusAndNotify()
    }
    
    
    // Geofences
    func makeFence(name: String, center: CLLocationCoordinate2D, radius: Double) {
        
        let geofenceRegion:CLCircularRegion = CLCircularRegion(center: center, radius: radius, identifier: name)
        
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true

        locationManager.startMonitoring(for: geofenceRegion)
        
        print("DEBUG: Monitoring started for region: \(name), center: \(center), radius: \(radius)")
        
        someCenter = CLLocation(latitude: center.latitude,
                                longitude: center.longitude)
        
        // Set a timer for the start and end time for this place
        guard let space = AppData.GetSafeSpace(name: name) as SafeSpace? else { return }
        Timer.scheduledTimer(timeInterval: space.duration.start.timeIntervalSinceNow,
                                              target: self, selector: #selector(OnTimer),
                                              userInfo: ["start": space], repeats: false)
        Timer.scheduledTimer(timeInterval: space.duration.end.timeIntervalSinceNow,
                                            target: self, selector: #selector(OnTimer),
                                            userInfo: ["end": space], repeats: false)
        
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("DEBUG: Started monitoring safe zone: \(region)")
    }
 
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("DEBUG: Did Enter Region \(region.identifier)")
        
        for i in 0...AppData.data.places.count-1 {
            let place = AppData.data.places[i]
            if region.identifier == place.name {
                NotifyOnEntry(place: place, distance: 0)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("DEBUG: Did Exit Region \(region.identifier)")
    
        for i in 0...AppData.data.places.count-1 {
            let place = AppData.data.places[i]
            if region.identifier == place.name {
                NotifyOnExit(place: place, distance: 0)
            }
        }
    }
    
    // For testing only
    func CheckRegionStatusAndNotify() {
        if AppData.data.places.count == 0 {
            return
        }
        for region in locationManager.monitoredRegions {
            let name = region.identifier
            for i in 0...AppData.data.places.count-1 {
                let place = AppData.data.places[i]
                if name == AppData.data.places[i].name {
                    let location = CLLocation(latitude: AppData.data.places[i].location.latitude, longitude: place.location.longitude)
                    if let distance = locationManager.location?.distance(from: location) {
                        if distance < place.radius {
                            if place.lastState == 2 {
                                // didEnter Region
                                NotifyOnEntry(place: place, distance: distance)
                            }
                            AppData.data.places[i].lastState = 1
                        }
                        if distance > place.radius {
                            if place.lastState == 1 {
                                // didExit Region
                                NotifyOnExit(place: place, distance: distance)
                            }
                            AppData.data.places[i].lastState = 2
                        }
                    }
                }
            }
        }
    }
    
    func IsInsideSpace(space: SafeSpace) -> Bool {
        let location = CLLocation(latitude: space.place.location.latitude, longitude: space.place.location.longitude)
        if let distance = locationManager.location?.distance(from: location) {
            return distance < space.place.radius
        }
        return false
    }
    
    func IsWithinSafeTime(space: SafeSpace) -> Bool {
        return space.duration.start.timeIntervalSinceNow <= 0 && space.duration.end.timeIntervalSinceNow >= 0
    }
    
    func NotifyOnEntry(place: Place, distance: Double) {
        print("DEBUG: NotifyOnEntry Region \(place.name). Radius: \(place.radius) Distance: \(distance) LastState: \(place.lastState)")
        if let guardian = AppData.getGuardianForSpace(name: place.name) {
            guard let space = AppData.GetSafeSpace(name: place.name) as SafeSpace? else { return }
            if IsWithinSafeTime(space: space) {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "You entered \(place.name). Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "\(AppData.data.me.name) entered \(place.name)" )
            } else {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "CAUTION: You just entered \(place.name). Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "CAUTION: \(AppData.data.me.name) just entered \(place.name)" )
            }
        }
    }
    
    func NotifyOnExit(place: Place, distance: Double) {
        print("DEBUG: NotifyOnExit Region \(place.name). Radius: \(place.radius) Distance: \(distance) LastState: \(place.lastState)")
        if let guardian = AppData.getGuardianForSpace(name: place.name) {
            guard let space = AppData.GetSafeSpace(name: place.name) as SafeSpace? else { return }
            if !IsWithinSafeTime(space: space) {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "You left \(place.name). Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "\(AppData.data.me.name) left \(place.name)")
            } else {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "CAUTION! You are leaving \(place.name) before the expected time. Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "CAUTION! \(AppData.data.me.name) is leaving \(place.name) before the expected time." )
            }
        }
    }
    
    func RemoveMonitor(name: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == name {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    @objc func OnTimer(timer: Timer) {
        guard let context = timer.userInfo as? [String: SafeSpace] else {
            timer.invalidate()
            return
        }
        var start = false
        var space = context["start"]
        if space == nil {
            space = context["end"]
            if space == nil {
                timer.invalidate()
                return
            }
        } else {
            start = true
        }

        print("DEBUG: OnTimer(\(space!.place.name) fired.")
        
        // Check if the user is already inside the safe space
        if IsInsideSpace(space: space!) {
            timer.invalidate()
            return
        }
        
        if let guardian = AppData.getGuardianForSpace(name: space!.place.name) {
            if start {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "CAUTION! You have not arrived at \(space!.place.name) yet. Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "CAUTION! \(AppData.data.me.name) has not arrived at \(space!.place.name) yet.")
            } else {
                NotificationHandler.sendNotification(title: "Safe Spaces", body: "CAUTION! You have already left \(space!.place.name). Notifying \(guardian.name)")
                NotificationHandler.sendRemoteNotification(guardian: guardian, title: "Safe Spaces", body: "CAUTION! \(AppData.data.me.name) has already left  \(space!.place.name).")
            }
        }
        
        timer.invalidate()
    }
}
