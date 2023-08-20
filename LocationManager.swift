import GLMap
import GLMapSwift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    func startUpdatingLocation(updateHandler: @escaping ([CLLocation]) -> Void) {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        // Handle location updates using updateHandler
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Other location-related methods
}
