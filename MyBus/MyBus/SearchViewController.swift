//
//  SearchViewController.swift
//  MyBus
//
//  Created by Marcos Vivar on 4/13/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import UIKit
import Mapbox
import RealmSwift

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    
    @IBOutlet var resultsTableView: UITableView!
    @IBOutlet var originTextfield: UITextField!
    @IBOutlet var destinationTextfield: UITextField!
    
    var bestMatches : [String] = []
    var favourites : List<Location>!
    
    @IBOutlet var favoriteOriginButton: UIButton!
    @IBOutlet var favoriteDestinationButton: UIButton!
    
    // MARK: - View Lifecycle Methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.originTextfield.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        self.destinationTextfield.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        // Create realm pointing to default file
        let realm = try! Realm()
        // Retrive favs locations for user
        favourites = realm.objects(User).first?.favourites
        self.resultsTableView.reloadData()
    }
    
    // MARK: - IBAction Methods
    
    @IBAction func favoriteOriginTapped(sender: AnyObject)
    {}
    
    @IBAction func favoriteDestinationTapped(sender: AnyObject)
    {}
    
    @IBAction func searchButtonTapped(sender: AnyObject)
    {
        let originTextFieldValue = originTextfield.text!
        let originStreet = originTextFieldValue[originTextFieldValue.startIndex..<originTextFieldValue.endIndex.advancedBy(-5)]
        let originHouseNumber = Int(originTextFieldValue[originTextFieldValue.endIndex.advancedBy(-4)..<originTextFieldValue.endIndex]) //Just work with a house number of 4 digits
        
        
        // Trying get houseNumber substring with a Regex (TODO)
        if let regex = try? NSRegularExpression(pattern: "(\\d{1,5}$)", options: .CaseInsensitive)
        {
            
            let result = regex.stringByReplacingMatchesInString(originTextFieldValue, options: NSMatchingOptions.WithTransparentBounds, range: NSRange(location:0,
                length:originTextFieldValue.characters.count), withTemplate: "$3")
            print("result : \(result)")
        }
        
        let destinationTextFieldValue = destinationTextfield.text!
        let destinationStreet = destinationTextFieldValue[destinationTextFieldValue.startIndex..<destinationTextFieldValue.endIndex.advancedBy(-5)]
        let destinationNumber = Int(destinationTextFieldValue[destinationTextFieldValue.endIndex.advancedBy(-4)..<destinationTextFieldValue.endIndex])

        //TODO : Extract some pieces of code to clean
        Connectivity.sharedInstance.getCoordinateFromAddress(originStreet, houseNumber: originHouseNumber!) {
            originGeocoded, error in
            print(originGeocoded, error)
            
            var latitudeOrigin : Double
            var longitudeOrigin : Double
            if let lat = originGeocoded!["lat"] as? String {
                latitudeOrigin = Double(lat)!
                if let lng = originGeocoded!["lng"] as? String {
                    longitudeOrigin = Double(lng)!
                    Connectivity.sharedInstance.getCoordinateFromAddress(destinationStreet, houseNumber: destinationNumber!) {
                        destinationGeocoded, error in
                        print("destination \(destinationGeocoded)", error)
                        
                        var latDestination : Double
                        var lngDestination : Double
                        if let lat = destinationGeocoded!["lat"] as? String {
                            latDestination = Double(lat)!
                            if let lng = destinationGeocoded!["lng"] as? String {
                                lngDestination = Double(lng)!
                                Connectivity.sharedInstance.getBusLinesFromOriginDestination(latitudeOrigin, longitudeOrigin: longitudeOrigin, latitudeDestination: latDestination, longitudeDestination: lngDestination) { responseObject, error in
                                    for busRouteResult in responseObject! {
                                        var 🚌 : String = "🚍"
                                        for route in busRouteResult.busRoutes {
                                            let busLineFormatted = route.busLineName!.characters.count == 3 ? route.busLineName!+"  " : route.busLineName!
                                            🚌 = "\(🚌) \(busLineFormatted) ➡"
                                        }
                                        🚌.removeAtIndex(🚌.endIndex.predecessor())
                                        self.bestMatches.append(🚌)
                                    }
                                    self.resultsTableView.reloadData()
                                    
                                    
                                    for busRouteResult in responseObject! {
                                        print(busRouteResult.busRouteType)
                                        if(busRouteResult.busRouteType == 0) //single road
                                        {
                                            print("It is a single bus route")
                                        } else if(busRouteResult.busRouteType == 1) //combined road
                                        {
                                            print("It is a combined route")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        
    }
    
    @IBAction func invertButton(sender: AnyObject)
    {
        let originText = self.originTextfield.text
        self.originTextfield.text = self.destinationTextfield.text
        self.destinationTextfield.text = originText
    }
    
    // MARK: - UITableViewDataSource Methods
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        switch indexPath.section
        {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesIdentifier", forIndexPath: indexPath) as UITableViewCell
            return buildFavCell(indexPath, cell: cell)
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("BestMatchesIdentifier", forIndexPath: indexPath) as! BestMatchTableViewCell
            cell.name.text = self.bestMatches[indexPath.row]
            return cell
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("BestMatchesIdentifier", forIndexPath: indexPath) as UITableViewCell
            
            return cell
        }
    }
    
    func buildFavCell(indexPath: NSIndexPath, cell : UITableViewCell) -> UITableViewCell
    {
        let fav = favourites[indexPath.row]
        let cellLabel : String
        let address = "\(fav.streetName) \(fav.houseNumber)"
        if(fav.name.isEmpty){
            cellLabel = address
        } else
        {
            cellLabel = fav.name
            cell.detailTextLabel?.text = address
        }
        cell.textLabel?.text = cellLabel
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            if let listFavs = favourites{
                return listFavs.count
            }
            return 0
        case 1:
            return bestMatches.count
            
        default:
            return bestMatches.count
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0:
            return "Favorites"
        case 1:
            return "Best Matches"
            
        default:
            return "Best Matches"
        }
    }
    
    // MARK: - UITableViewDelegate Methods
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let uiTextField = self.originTextfield.isFirstResponder() ? self.originTextfield : self.destinationTextfield
        switch indexPath.section
        {
        case 0:
            uiTextField.text = "\(favourites[indexPath.row].streetName) \(favourites[indexPath.row].houseNumber)"
        case 1:
            uiTextField.text = "\(bestMatches[indexPath.row]) "
            // Change & update keyboard type
            uiTextField.keyboardType = UIKeyboardType.NumberPad
            uiTextField.resignFirstResponder()
            uiTextField.becomeFirstResponder()
        default: break
        }
    }
    
    // MARK: - Textfields Methods
    
    func textFieldDidChange(sender: UITextField){
        if(sender.text?.characters.count > 2)
        {
            Connectivity.sharedInstance.getStreetNames(forName: sender.text!) { (streets, error) in
                if error == nil {
                    self.bestMatches = []
                    for street in streets! {
                        self.bestMatches.append(street.name)
                    }
                    self.resultsTableView.reloadData()
                }
            }
        } else if (sender.text?.characters.count == 0)
        {
            self.bestMatches = []
            self.resultsTableView.reloadData()
            self.originTextfield.keyboardType = UIKeyboardType.Alphabet
            self.originTextfield.resignFirstResponder()
            self.originTextfield.becomeFirstResponder()
        }
    }
    
    // MARK: - Memory Management Methods
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}