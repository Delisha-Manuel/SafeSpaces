import SwiftUI
import Foundation
import MapKit

class Person: Codable {
    var name: String = ""
    var guardians: [Guardian] = []
    var phone: String = ""
    var deviceName: String = ""
}

class Guardian: Person {
    var monitored_people: [Person] = []
}

struct Place: Codable {
    var name: String
    var location: Location
    var radius: Double
    var lastState: Int = 0
}

struct Location: Codable {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
}

struct SafeSpace: Codable {
    var place: Place
    var duration: DateInterval
    var notify: Guardian
}

struct AppData : Codable {
    public static var data = AppData.load()
    var me: Person = Person()
    public var places: [Place] = []
    var safeSpaces: [SafeSpace] = []
    
    static public func AddPlace(name: String, latitude: Double, longitude: Double, radius: Double) {
        var place: Place
        
        // Add the very first place
        if data.places.count == 0 {
            place = Place(name:name, location: Location(latitude: latitude, longitude: longitude), radius:radius)
            data.places.append(place)
            print("DEBUG: Added first place \(place)")
            data.save()
            return
        }
        
        // Update an existing place
        for i in 0...data.places.count-1 {
            if data.places[i].name == name {
                data.places[i].location = Location(latitude: latitude, longitude: longitude)
                data.places[i].radius = radius
                print("DEBUG: Updated existing place \(data.places[i])")
                data.save()
            }
        }
        
        // Add a new place
        place = Place(name:name, location: Location(latitude: latitude, longitude: longitude), radius:radius)
        data.places.append(place)
        print("DEBUG: Added new place \(place)")
        data.save()
    }
    
    
    public static func GetPlaces() -> [Place] {
        return data.places
    }
    
    public static func GetPlace(name : String) -> Place?	 {
        for place in AppData.GetPlaces() {
            if place.name == name {
                return place
            }
        }
        return nil
    }
    
    public static func GetSafeSpace(name : String) -> SafeSpace?     {
        for space in data.safeSpaces {
            if space.place.name == name {
                return space
            }
        }
        return nil
    }
    
    static public func AddSafeSpace(space: SafeSpace) {
        // Add the very first place
        if data.safeSpaces.count == 0 {
            data.safeSpaces.append(space)
            AddPlace(name: space.place.name,
                     latitude: space.place.location.latitude,
                     longitude: space.place.location.longitude,
                     radius: space.place.radius)
            print("DEBUG: Added first Safe Space \(space)")
            data.save()
            return
        }
        
        // Update an existing place
        for i in 0...data.safeSpaces.count-1 {
            if data.safeSpaces[i].place.name == space.place.name {
                data.safeSpaces[i] = space
                AddPlace(name: space.place.name,
                         latitude: space.place.location.latitude,
                         longitude: space.place.location.longitude,
                         radius: space.place.radius)
                print("DEBUG: Updated existing Safe Space \(data.safeSpaces[i])")
                data.save()
                return
            }
        }
        
        // Add a new place
        data.safeSpaces.append(space)
        AddPlace(name: space.place.name,
                 latitude: space.place.location.latitude,
                 longitude: space.place.location.longitude,
                 radius: space.place.radius)
        print("DEBUG: Added new Safe Space \(space)")
        data.save()
    }
    
    static public func DeleteSpace(name: String) {
        
        // Remove from both the data.places and data.spaces arrays
        if !data.places.isEmpty {
            data.places = data.places.filter { $0.name != name }
        }
        
        if !data.safeSpaces.isEmpty {
            data.safeSpaces = data.safeSpaces.filter { $0.place.name != name }
        }
        data.save()
        
        DeviceLocationService.shared.RemoveMonitor(name: name)
    }
    
    static func getGuardianForSpace(name: String) -> Guardian? {
        if data.safeSpaces.isEmpty {
            return nil
        }
        
        for i in 0...data.safeSpaces.count-1 {
            if data.safeSpaces[i].place.name == name {
                return data.safeSpaces[i].notify
            }
        }
        return nil
    }

    
    // Save application data to device storage
    func save() {
        print("DEBUG: Saving AppData \(self)")
        if let savedData = try? JSONEncoder().encode(self) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "SafeSpaces")
            defaults.synchronize()
        } else {
            print("Failed to save data.")
        }
    }
    
    // Load application data from device storage
    static func load() -> AppData {
        var data: AppData

        if let savedData = UserDefaults.standard.object(forKey: "SafeSpaces") as? Data {
             do {
                 data = try JSONDecoder().decode(AppData.self, from: savedData)
             } catch {
                 print("Failed to load data. Using blank slate.")
                 data = AppData()
             }
         } else {
             print("No existing data found. Creating afresh.")
             data = AppData()
         }
        
        print("DEBUG: Loaded data \(data)")
        return data
    }
}
