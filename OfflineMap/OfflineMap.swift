import GLMap
import GLMapSwift
import CoreLocation

class OfflineMap {
    public var map: GLMapView!
    private var accuracyCircle: GLMapVectorLayer?
    private let locationManager = CLLocationManager()
    private let accuracyStyle = GLMapVectorCascadeStyle.createStyle("area{width:3px; fill-color:#3D99FA26; color:#3D99FA26;}")
    private let CIRCLE_RADIUS: Double = 2048
    
    init(frame: CGRect) {
        GLMapManager.activate(apiKey: "a4264c4d-afd8-4115-91d3-9ca4f504aea0")
        map = GLMapView(frame: frame)
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupMap()
        setupUserLocation()
    }
    
    func setupMap() {
        map.localeSettings = GLMapLocaleSettings(localesOrder: ["native"], unitSystem: .international)
        updateMaps()
        
        map.mapGeoCenter = GLMapGeoPoint(lat: 50.073658, lon: 14.41854)
        map.mapZoomLevel = 14
    }
    
    func updateMaps() {
        GLMapManager.shared.updateMapList { (fetchedMaps: [GLMapInfo]?, _, error: Error?) in
            if error != nil {
                NSLog("Map downloading error \(error!.localizedDescription)")
            } else {
                if let maps = fetchedMaps {
                    self.downloadDefaultMap(maps)
                }
            }
        }
        printMapList()
    }
    
    func downloadDefaultMap(_ maps: [GLMapInfo]) {
        
        var mapToDownload = maps.first { map in
            map.name(inLanguage: "en") == "United States"
        }
        
        let subMapToDownload = mapToDownload?.subMaps.first { map in
            map.name(inLanguage: "en") == "California"
        }
        
        mapToDownload = subMapToDownload
        startDownloadingMap(mapToDownload!, retryCount: 3)
        
    }
    
    func startDownloadingMap(_ map: GLMapInfo, retryCount: Int) {
        if retryCount > 0 {
            GLMapManager.shared.downloadDataSets(.all, forMap: map, withCompletionBlock: { (task: GLMapDownloadTask) in
                if let error = task.error as NSError? {
                    NSLog("Map downloading error: \(error)")
                    if error.domain == "CURL", error.code == 28 {
                        self.startDownloadingMap(map, retryCount: 2)
                    }
                }
            })
        }
    }
    
    
    func printMapList() {
        for map in GLMapManager.shared.cachedMapList()! {
            print(map.name(inLanguage: "en")!)
            if map.subMaps.count > 0 {
                for subMap in map.subMaps {
                    print("     ", subMap.name(inLanguage: "en") ?? "Can't fetch this map")
                }
                print()
            }
        }
    }
    
    func setupUserLocation() {
        guard let locationImagePath = Bundle.main.path(forResource: "circle_new", ofType: "svg"),
              let locationImage = GLMapVectorImageFactory.shared.image(fromSvg: locationImagePath),
              let movementImagePath = Bundle.main.path(forResource: "arrow_new", ofType: "svg"),
              let movementImage = GLMapVectorImageFactory.shared.image(fromSvg: movementImagePath) else {
            assertionFailure("Fix location images path")
            return
        }
        
        map.setUserLocationImage(locationImage, movementImage: movementImage)
        map.showUserLocation = true
        showAccuracyCircle()
    }
    
    func showAccuracyCircle() {
        let CIRCLE_POINTS_COUNT: UInt = 100
        guard let accuracyStyle = accuracyStyle else { return }
        
        let vectorLayer = GLMapVectorLayer()
        let outerRings = [GLMapPointArray(count: CIRCLE_POINTS_COUNT, callback: { index in
            let f = 2 * Double.pi * Double(index) / Double(CIRCLE_POINTS_COUNT)
            return GLMapPoint(x: self.CIRCLE_RADIUS * sin(f), y: self.CIRCLE_RADIUS * cos(f))
        })]
        let circle = GLMapVectorPolygon(outerRings, innerRings: nil)
        vectorLayer.transformMode = .custom
        vectorLayer.position = map.mapCenter
        vectorLayer.setVectorObject(circle, with: accuracyStyle)
        map.add(vectorLayer)
        
        accuracyCircle = vectorLayer
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var locationAnimation: GLMapAnimation?
        locationAnimation?.cancel(false)
        locationAnimation = map.animate { anim in
            anim.duration = 1
            anim.transition = .linear
            map.locationManager(manager, didUpdateLocations: locations)
            
            if let accuracyCircle = accuracyCircle, let location = locations.last {
                accuracyCircle.position = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                accuracyCircle.scale = map.makeInternal(fromMeters: location.horizontalAccuracy) / 2048.0
            }
        }
    }
}
