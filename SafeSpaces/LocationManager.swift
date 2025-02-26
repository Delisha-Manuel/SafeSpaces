//
//  LocationManager.swift
//  RouteDemo
//
//  Created by Delisha Manuel on 8/24/24.
//
/*
import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    //@IBOutlet weak var map: MKMapView!
    let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    
    override init() {
        super.init()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        //locationManager.startUpdatingLocation()
        //setupGeofencing()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            // Insert code here of what should happen when Location services are authorized
            authorizationStatus = .authorizedWhenInUse
            locationManager.requestLocation()
            break
            
        case .restricted:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .restricted
            break
            
        case .denied:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .denied
            break
            
        case .notDetermined:        // Authorization not determined yet.
            authorizationStatus = .notDetermined
            manager.requestAlwaysAuthorization()
            break
            
        default:
            break
        }
    }
    
    /*if (CLLocationManager.authorizedWhenInUse()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()*/

    
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userlocation = locations.last! as CLLocation
                
                let center = CLLocationCoordinate2D(latitude: userlocation.coordinate.latitude, longitude: userlocation.coordinate.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.map.setRegion(region, animated: true)
        }
    }*/
    
    /*func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle changes if location permissions
    }*/

    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            // Handle location update
        }
    }*/
    
    // Save the user's location when it changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            //Handle location update
            locationManager.startUpdatingLocation()
        }
        //self.userLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        //let location = locations.last! as CLLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let region = region as? CLCircularRegion else { return }
        //showAlert(message: "User enter \(region.identifier)")
        NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: "Entered safe zone " + region.description)
        //NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let region = region as? CLCircularRegion else { return }
        //showAlert(message: "User leave \(region.identifier)")
        NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: "Exited safe zone " + region.description)
        //NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
    func stopLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    
    private func setupGeofencing() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            //showAlert(message: "Geofencing is not supported on this device")
            NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: "Geofencing is not supported on this device")
            return
        }
        
        guard locationManager.authorizationStatus == .authorizedAlways else {
            //showAlert(message: "App does not have correct location authorization")
            NotificationCenter.default.post(name: Notification.Name.taskAddedNotification, object: "App does not have correct location authorization")
            return
        }
       
        startMonitoring()
    }

    private func startMonitoring() {
        let regionCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.3346438, longitude: -122.008972)
        let geofenceRegion: CLCircularRegion = CLCircularRegion(
            center: regionCoordinate,
            radius: 100, // Radius in Meter
            identifier: "apple_park" // unique identifier
        )
        
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        
        // Start monitoring
        locationManager.startMonitoring(for: geofenceRegion)
        
    }
    
    /*private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Information", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alertController, animated: true, completion: nil)*/
        
}
*/
