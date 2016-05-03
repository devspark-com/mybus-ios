//
//  Connectivity.swift
//  MyBus
//
//  Created by Marcos Vivar on 4/13/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import Alamofire
import SwiftyJSON

private let _sharedInstance = Connectivity()

private let municipalityAccessToken = "rwef3253465htrt546dcasadg4343"

private let myBusAccessToken = "94a08da1fecbb6e8b46990538c7b50b2"

private let municipalityBaseURL = "http://gis.mardelplata.gob.ar/opendata/ws.php?method=rest"

private let myBusBaseURL = "http://www.mybus.com.ar/api/v1/"

private let streetNamesEndpointURL = "\(municipalityBaseURL)&endpoint=callejero_mgp&token=\(municipalityAccessToken)&nombre_calle="

private let addressToCoordinateEndpointURL = "\(municipalityBaseURL)&endpoint=callealtura_coordenada&token=\(municipalityAccessToken)"

private let coordinateToAddressEndpointURL = "\(municipalityBaseURL)&endpoint=coordenada_calleaaltura&token=\(municipalityAccessToken)"

private let availableBusLinesFromOriginDestinationEndpointURL = "\(myBusBaseURL)NexusApi.php?"

private let singleResultRoadEndpointURL = "\(myBusBaseURL)SingleRoadApi.php?"

private let combinedResultRoadEndpointURL = "\(myBusBaseURL)CombinedRoadApi.php?"

private let rechargeCardPointsEndpointURL = "\(myBusBaseURL)RechargeCardPointApi.php?"


public class Connectivity: NSObject
{
    // MARK: - Instantiation
    public class var sharedInstance: Connectivity
    {
        return _sharedInstance
    }
    
    override init() { }
    
    // MARK: Municipality Endpoints
    func getStreetNames(forName streetName: String, completionHandler: ([Street]?, NSError?) -> ())
    {
        let escapedStreet = streetName.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())! as String
        let streetNameURLString = "\(streetNamesEndpointURL)\(escapedStreet)"
        
        let request = NSMutableURLRequest(URL: NSURL(string: streetNameURLString)!)
        request.HTTPMethod = "GET"
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .Success(let value):
                var streetsNames : [Street] = [Street]()
                let json = JSON(value)
                if let streets = json.array {
                    for street in streets {
                        streetsNames.append(Street(json: street))
                    }
                }
                completionHandler(streetsNames, nil)
            case .Failure(let error):
                print("\nError: \(error)")
                completionHandler(nil, error)
            }
        }
    }
    
    public func getCoordinateFromAddress(streetName : String, houseNumber : Int, completionHandler: (NSDictionary?, NSError?) -> ())
    {
        print("Address to resolve geocoding: \(streetName), \(houseNumber)")
        getStreetNames(forName: streetName) {
            streetObject, error in
            let address = streetObject![0]
            let coordinateFromAddressURLString = "\(addressToCoordinateEndpointURL)&codigocalle=\(address.code)&altura=\(houseNumber)"
            let request = NSMutableURLRequest(URL: NSURL(string: coordinateFromAddressURLString)!)
            request.HTTPMethod = "GET"
            
            Alamofire.request(request).responseJSON { response in
                switch response.result {
                case .Success(let value):
                    completionHandler(value as? NSDictionary, nil)
                case .Failure(let error):
                    completionHandler(nil, error)
                }
            }
        }
        
    }
    
    public func getAddressFromCoordinate(latitude : Double, longitude: Double, completionHandler: (NSDictionary?, NSError?) -> ())
    {
        print("You tapped at: \(latitude), \(longitude)")
        let addressFromCoordinateURLString = "\(coordinateToAddressEndpointURL)&latitud=\(latitude)&longitud=\(longitude)"
        
        let request = NSMutableURLRequest(URL: NSURL(string: addressFromCoordinateURLString)!)
        request.HTTPMethod = "GET"
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .Success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .Failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    // MARK: MyBus Endpoints
    func getBusLinesFromOriginDestination(latitudeOrigin : Double, longitudeOrigin : Double, latitudeDestination : Double, longitudeDestination : Double, completionHandler : ([BusRouteResult]?, NSError?) -> ())
    {
        let availableBusLinesFromOriginDestinationURLString = "\(availableBusLinesFromOriginDestinationEndpointURL)lat0=\(latitudeOrigin)&lng0=\(longitudeOrigin)&lat1=\(latitudeDestination)&lng1=\(longitudeDestination)&tk=\(myBusAccessToken)"
        let request = NSMutableURLRequest(URL: NSURL(string: availableBusLinesFromOriginDestinationURLString)!)
        request.HTTPMethod = "GET"
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .Success(let value):
                let json = JSON(value)
                let type = json["Type"].intValue
                let results = json["Results"]
                let busResults : [BusRouteResult]
                
                busResults = BusRouteResult.parseResults(results, type: type)
                
                completionHandler(busResults, nil)
            case .Failure(let error):
                completionHandler(nil, error)
            }
        }
        
    }
    
    public func getSingleResultRoadApi(idLine : Int, direction : Int, stop1: Int, stop2 : Int, completionHandler : (NSDictionary?, NSError?) -> ())
    {
        let singleResultRoadURLString = "\(singleResultRoadEndpointURL)idline=\(idLine)&direction=\(direction)&stop1=\(stop1)&stop2=\(stop2)&tk=\(myBusAccessToken)"
        
        let request = NSMutableURLRequest(URL: NSURL(string: singleResultRoadURLString)!)
        request.HTTPMethod = "GET"
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .Success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .Failure(let error):
                completionHandler(nil, error)
            }
        }
        
    }
    
    public func getCombinedResultRoadApi(idLine1 : Int, idLine2 : Int, direction1 : Int, direction2: Int, L1stop1: Int, L1stop2 : Int, L2stop1: Int, L2stop2 : Int, completionHandler : (NSDictionary?, NSError?) -> ())
    {
        let combinedResultRoadURLString = "\(combinedResultRoadEndpointURL)idline1=\(idLine1)&idline2=\(idLine2)&direction1=\(direction1)&direction2=\(direction2)&L1stop1=\(L1stop1)&L1stop2=\(L1stop2)&L2stop1=\(L2stop1)&L2stop2=\(L2stop2)&tk=\(myBusAccessToken)"
        
        let request = NSMutableURLRequest(URL: NSURL(string: combinedResultRoadURLString)!)
        request.HTTPMethod = "GET"
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .Success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .Failure(let error):
                completionHandler(nil, error)
            }
        }
        
    }
    
}