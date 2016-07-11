//
//  ViewController.swift
//  Weather
//
//  Created by Alex Berezovsky on 7/11/16.
//
//  kindly thanks for opensource code created by Joey deVilla, MIT professor <2016>

import UIKit
import CoreLocation

var favouriteCitiesList = [String]()
var celsiusFarengeit = Bool()

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, WeatherGetterDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var getLocationWeatherButton: UIButton!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var getCityWeatherButton: UIButton!
    @IBOutlet weak var favouriteCities: UIButton!
    @IBOutlet weak var cF: UIButton!
    
    let locationManager = CLLocationManager()
    var weather: WeatherGetter!
    
    @IBAction func farengeitCelsiusSwitch(sender: AnyObject) {
        if celsiusFarengeit == true {
            celsiusFarengeit = false
        } else {
            celsiusFarengeit = true
        }
    }
    
    @IBAction func favouriteCities(sender: AnyObject) {
        favoriteCitiesList.hidden = false
        favoriteCitiesList.userInteractionEnabled = true
        fevCityOKBtn.userInteractionEnabled = true
        fevCityOKBtn.hidden = false
    }
    @IBOutlet weak var favoriteCitiesList: UITableView!

    @IBOutlet weak var fevCityOKBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


        celsiusFarengeit = true
        cityLbl.text = ""
        weatherLabel.text = ""
        temperatureLabel.text = ""
        cloudCoverLabel.text = ""
        windLabel.text = ""
        rainLabel.text = ""
        humidityLabel.text = ""
        cityTextField.text = ""
        cityTextField.placeholder = "Навзва вашого міста"
        cityTextField.delegate = self
        cityTextField.enablesReturnKeyAutomatically = true
        getCityWeatherButton.enabled = false
        
        getLocation()
        
        if NSUserDefaults.standardUserDefaults().objectForKey("favouriteCitiesList") != nil {
            favouriteCitiesList = NSUserDefaults.standardUserDefaults().objectForKey("favouriteCitiesList") as! [String]
        }
        
        favouriteCitiesList = ["Горішні Плавні", "Жмеренка", "Бобринець", "Сихів"]
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favouriteCitiesList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell0")
        cell.textLabel?.text = favouriteCitiesList[indexPath.row]
        cityLbl.text = cell.textLabel?.text
        return cell
    }
    

    
    @IBAction func fevouriteCityChosen(sender: AnyObject) {
        
        favoriteCitiesList.hidden = true
        favoriteCitiesList.userInteractionEnabled = false
        fevCityOKBtn.hidden = true
        fevCityOKBtn.userInteractionEnabled = false
    }
    
    
    @IBAction func getWeatherForLocationButtonTapped(sender: UIButton) {
        setWeatherButtonStates(false)
        getLocation()
    }
    
    @IBAction func getWeatherForCityButtonTapped(sender: UIButton) {
        guard let text = cityLbl.text where !text.trimmed.isEmpty else {
            return
        }
        setWeatherButtonStates(false)
        weather.getWeatherByCity(cityLbl.text!.urlEncoded)
    }
    
    func setWeatherButtonStates(state: Bool) {
        getLocationWeatherButton.enabled = state
        getCityWeatherButton.enabled = state
    }
    
    
    func didGetWeather(weather: Weather) {
        // This method is called asynchronously, which means it won't execute in the main queue.
        // All UI code needs to execute in the main queue, which is why we're wrapping the code
        // that updates all the labels in a dispatch_async() call.
        dispatch_async(dispatch_get_main_queue()) {
            self.cityLbl.text = weather.city
            self.weatherLabel.text = weather.weatherDescription
            if celsiusFarengeit == true {
                self.temperatureLabel.text = "\(Int(round(weather.tempCelsius)))°"
            } else if celsiusFarengeit == false {
                self.temperatureLabel.text = "\(Int(round(weather.tempFahrenheit)))°"
            }
            self.cloudCoverLabel.text = "\(weather.cloudCover)%"
            self.windLabel.text = "\(weather.windSpeed) m/s"
            
            if let rain = weather.rainfallInLast3Hours {
                self.rainLabel.text = "\(rain) mm"
            }
            else {
                self.rainLabel.text = "None"
            }
            
            self.humidityLabel.text = "\(weather.humidity)%"
            self.getLocationWeatherButton.enabled = true
            self.getCityWeatherButton.enabled = self.cityTextField.text?.characters.count > 0
        }
    }
    
    func didNotGetWeather(error: NSError) {
        // This method is called asynchronously, which means it won't execute in the main queue.
        // All UI code needs to execute in the main queue, which is why we're wrapping the call
        // to showSimpleAlert(title:message:) in a dispatch_async() call.
        dispatch_async(dispatch_get_main_queue()) {
            self.showSimpleAlert(title: "Can't get the weather",
                                 message: "The weather service isn't responding.")
            self.getLocationWeatherButton.enabled = true
            self.getCityWeatherButton.enabled = self.cityTextField.text?.characters.count > 0
        }
        print("didNotGetWeather error: \(error)")
    }
    
    
    // MARK: - CLLocationManagerDelegate and related methods
    
    func getLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            showSimpleAlert(
                title: "Вімкніть геолокацію, будласочка",
                message: "Цей налаштунок хоче дізнатися ваше місцезнаходження, для надання прогнозу погоди. Будь ласка, надайте нам таку можливість.\n" +
                "Щоб налаштувати геолокацію, зверніться до Settings → Privacy → Location Services and turn location services on."
            )
            getLocationWeatherButton.enabled = true
            return
        }
        
        let authStatus = CLLocationManager.authorizationStatus()
        guard authStatus == .AuthorizedWhenInUse else {
            switch authStatus {
            case .Denied, .Restricted:
                let alert = UIAlertController(
                    title: "Надання геолокації вимкненно",
                    message: "Щоб дозволити налаштунку дізнатися ваше місцезнаходження, зверніться до налаштунків, та оберіть \"Location\" і змініть опцію \"Allow location access\" на ось таку \"While Using the App\".",
                    preferredStyle: .Alert
                )
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) {
                    action in
                    if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
                alert.addAction(cancelAction)
                alert.addAction(openSettingsAction)
                presentViewController(alert, animated: true, completion: nil)
                getLocationWeatherButton.enabled = true
                return
                
            case .NotDetermined:
                locationManager.requestWhenInUseAuthorization()
                
            default:
                print("ой лишенько...")
            }
            
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        weather.getWeatherByCoordinates(latitude: newLocation.coordinate.latitude,
                                        longitude: newLocation.coordinate.longitude)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // This method is called asynchronously, which means it won't execute in the main queue.
        // All UI code needs to execute in the main queue, which is why we're wrapping the call
        // to showSimpleAlert(title:message:) in a dispatch_async() call.
        dispatch_async(dispatch_get_main_queue()) {
            self.showSimpleAlert(title: "неможливо встановити ваше місцезнаходження",
                                 message: "GPS вашого пристрою не відповідають")
        }
        print("locationManager didFailWithError: \(error)")
    }
    
    
    // MARK: - UITextFieldDelegate and related methods
    // -----------------------------------------------
    
    // Enable the "Get weather for the city above" button
    // if the city text field contains any text,
    // disable it otherwise.
    func textField(textField: UITextField,
                   shouldChangeCharactersInRange range: NSRange,
                                                 replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).stringByReplacingCharactersInRange(
            range,
            withString: string).trimmed
        getCityWeatherButton.enabled = prospectiveText.characters.count > 0
        return true
    }
    
    // Pressing the clear button on the text field (the x-in-a-circle button
    // on the right side of the field)
    func textFieldShouldClear(textField: UITextField) -> Bool {
        // Even though pressing the clear button clears the text field,
        // this line is necessary. I'll explain in a later blog post.
        textField.text = ""
        
        getCityWeatherButton.enabled = false
        return true
    }
    
    // Pressing the return button on the keyboard should be like
    // pressing the "Get weather for the city above" button.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        getWeatherForCityButtonTapped(getCityWeatherButton)
        return true
    }
    
    // Tapping on the view should dismiss the keyboard.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    
    // MARK: - Utility methods
    // -----------------------
    
    func showSimpleAlert(title title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert
        )
        let okAction = UIAlertAction(
            title: "OK",
            style:  .Default,
            handler: nil
        )
        alert.addAction(okAction)
        presentViewController(
            alert,
            animated: true,
            completion: nil
        )
    }
    
}


extension String {
    
    // A handy method for %-encoding strings containing spaces and other
    // characters that need to be converted for use in URLs.
    var urlEncoded: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())!
    }
    
    // Trim excess whitespace from the start and end of the string.
    var trimmed: String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
}
