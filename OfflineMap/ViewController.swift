import GLMap
import GLMapSwift
import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    private var offlineMap: OfflineMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = view.bounds
        
        offlineMap = OfflineMap(frame: frame)
        view.addSubview(offlineMap.map)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        offlineMap.startLocationUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        offlineMap.stopLocationUpdates()
    }
    
}
