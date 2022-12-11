//
//  geojsonHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 7.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import Foundation
import GoogleMapsUtils
import GoogleMaps

class ImportGeoOrKmlFileHelper {
    
    static var app: ImportGeoOrKmlFileHelper = {
        return ImportGeoOrKmlFileHelper()
    }()
    
}

class GeoJSON {
    private var mapView: GMSMapView!
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
    }
    
    var gmuLineStrings = [GMULineString]()
    var gmuPolygons = [GMUPolygon]()
    var gmPoints = [GMUPoint]()
    
    func renderGeoJSON(url: URL, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, mapView: GMSMapView, completion: @escaping () -> Void ) {
        //guard let path = Bundle.main.path(forResource: "GeoJSON_sample", ofType: "json") else {
        //  return
        //}
        
        //let url = URL(fileURLWithPath: path)
        
        let geoJsonParser = GMUGeoJSONParser(url: url)
        
        geoJsonParser.parse()
        
        print(geoJsonParser.features.count)
        //if geoJsonParser.features.count > 100 {
        //  return
        //}
        
//        let dispatchQueue = DispatchQueue.global(qos: .unspecified)
        
        var counter = 0
        
        for feature in geoJsonParser.features {
            
            autoreleasepool {
                
                print(counter)
                counter += 1
                if let feature = feature as? GMUFeature {
                    //print(feature.properties?.keys)
                    //print(feature.properties?.values)
                    
                    var title = "untitled"
                    var color = UIColor.flatBlueDark().hexValue()
                    var group = ""
                    
                    if let name = feature.properties?["name"] {
                        title = name.description
                    } else if let name = feature.properties?["title"] {
                        title = name.description
                    }
                    
                    if let color1 = feature.properties?["fill"] as? String {
                        color = color1
                    } else if let color1 = feature.properties?["color"] as? String{
                        color = color1
                    } else if let color1 = feature.properties?["fillColor"] as? String{
                        color = color1
                    } else if let color1 = feature.properties?["marker-color"] as? String{
                        color = color1
                    }
                    
                    if let group1 = feature.properties?["group"] as? String {
                        group = group1
                    }
                    
                    if let fillColor = feature.style?.fillColor {
                        color = fillColor.hexValue()
                    }
                    if let title1 = feature.style?.title {
                        title = title1
                    }
                    
                    if let polyline = feature.geometry as? GMULineString {
                        
                        var markers = [GMSMarker]()
                        for i in 0...polyline.path.count()-1 {
                            let marker = GMSMarker(position: polyline.path.coordinate(at: i))
                            markers.append(marker)
                        }
                        markers.removeDuplicates()
                        if linesController.lines!.count < K.freeAccountLimitations.overlayLimit {
                            if markers.count > 1 {
                                
                                linesController.addLine(title: title, color: color, initialMarkers: markers, mapView: mapView, isGeodesic: true, id: nil)
                                
                            }
                        }
                    } else if let polygon = feature.geometry as? GMUPolygon {
                        // First path is represents the exterior ring. Any subsequent elements representinterior rings (or holes).
                        
                        if let path = polygon.paths.first {
                            
                            var markers = [GMSMarker]()
                            for i in 0...path.count()-1 {
                                let marker = GMSMarker(position: path.coordinate(at: i))
                                markers.append(marker)
                            }
                            markers.removeDuplicates()
                            
                            if fieldsController.fields!.count < K.freeAccountLimitations.overlayLimit {
                                if markers.count > 2 {
                                    
                                    fieldsController.addField(title: title, groupTitle: group, color: color, initialMarkers: markers, id: nil, isGeodesic: true)
                                    
                                }
                            }
                            
                        }
                        
                    } else if let place = feature.geometry as? GMUPoint {
                        
                        let marker = GMSMarker(position: place.coordinate)
                        
                        if placesController.places!.count < K.freeAccountLimitations.overlayLimit {
                            placesController.addPlace(title: title, color: color, mapView: mapView, initialMarker: marker, id: nil, iconSize: nil)
                        }
                        
                        
                    }
                }
            }
        }
        completion()
    }
    
    func renderKml(url: URL, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, mapView: GMSMapView, completion: @escaping () -> Void ) {
        
        let kmlParser = GMUKMLParser(url: url)
        
        kmlParser.parse()
       
        for mark in kmlParser.placemarks {
            
            if let mark = mark as? GMUPlacemark {
                
                let title = mark.title ?? mark.style?.title ?? "untitled"
                
                var color = mark.style?.fillColor?.hexValue() ?? mark.style?.strokeColor?.hexValue() ?? UIColor.flatBlueDark().hexValue()
                
                if let style = kmlParser.styles.first(where: {$0.styleID == mark.title}) {
                    color = style.fillColor?.hexValue() ?? UIColor.flatBlueDark().hexValue()
                }
                
                if let polygon = mark.geometry as? GMUPolygon {
                    // First path is represents the exterior ring. Any subsequent elements representinterior rings (or holes).
                    if let path = polygon.paths.first {
                        print(path.coordinate(at: 0))
                        var markers = [GMSMarker]()
                        for i in 0...path.count()-1 {
                            let marker = GMSMarker(position: path.coordinate(at: i))
                            markers.append(marker)
                        }
                        markers.removeDuplicates()
                        
                        if fieldsController.fields!.count < K.freeAccountLimitations.overlayLimit {
                            if markers.count > 2 {
                                fieldsController.addField(title: title, groupTitle: "", color: color, initialMarkers: markers, id: nil, isGeodesic: true)
                            }
                        }
                    }
                    
                } else if let polyline = mark.geometry as? GMULineString {
                    
                    var markers = [GMSMarker]()
                    for i in 0...polyline.path.count()-1 {
                        let marker = GMSMarker(position: polyline.path.coordinate(at: i))
                        markers.append(marker)
                    }
                    markers.removeDuplicates()
                    if linesController.lines!.count < K.freeAccountLimitations.overlayLimit {
                        if markers.count > 2 {
                            
                            linesController.addLine(title: title, color: color, initialMarkers: markers, mapView: mapView, isGeodesic: true, id: nil)
                        }
                    }
                    
                    
                } else if let place = mark.geometry as? GMUPoint {
                    
                    let marker = GMSMarker(position: place.coordinate)
                    
                    if placesController.places!.count < K.freeAccountLimitations.overlayLimit {
                        placesController.addPlace(title: title, color: color, mapView: mapView, initialMarker: marker, id: nil, iconSize: nil)
                    }
                }
            }
        }
        completion()
    }
}
