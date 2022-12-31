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

class GeoJSON {
    private var mapView: GMSMapView!
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
    }
    
    var gmuLineStrings = [GMULineString]()
    var gmuPolygons = [GMUPolygon]()
    var gmPoints = [GMUPoint]()
    
    func renderGeoJSON(url: URL, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, mapView: GMSMapView, completion: @escaping () -> Void ) {
        //        guard let path = Bundle.main.path(forResource: "GeoJSON_sample", ofType: "json") else {
        //          return
        //        }
        //
        //        let url = URL(fileURLWithPath: path)
        
        let geoJsonParser = GMUGeoJSONParser(url: url)
        
        geoJsonParser.parse()
        
        print(geoJsonParser.features.count)
        
        var counter = 0
        
        for feature in geoJsonParser.features {
            
            autoreleasepool {
                
                print(counter)
                counter += 1
                if let feature = feature as? GMUFeature {
                    // print(feature.properties?.keys)
                    // print(feature.properties?.values)
                    
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
                    } else if let color1 = feature.properties?["color"] as? String {
                        color = color1
                    } else if let color1 = feature.properties?["fillColor"] as? String {
                        color = color1
                    } else if let color1 = feature.properties?["marker-color"] as? String {
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
                        addLines(linesController: linesController, polyline, title, color)
                    } else if let polygon = feature.geometry as? GMUPolygon {
                        addFields(fieldsController: fieldsController, polygon, title, group, color)
                    } else if let place = feature.geometry as? GMUPoint {
                        addPlaces(placesController: placesController, place, title, color)
                    }
                }
            }
        }
        completion()
    }
    
    private func addFields(fieldsController: FieldsController, _ polygon: GMUPolygon, _ title: String, _ group: String, _ color: String) {
        // First path is represents the exterior ring. Any subsequent elements representinterior rings (or holes).
        
        if let path = polygon.paths.first {
            
            var markers = [GMSMarker]()
            for index in 0...path.count()-1 {
                let marker = GMSMarker(position: path.coordinate(at: index))
                markers.append(marker)
            }
            markers.removeDuplicates()
            
            if let fields = fieldsController.fields,
               fields.count < K.FreeAccountLimitations.overlayLimit {
                if markers.count > 2 {
                    
                    fieldsController.addField(title: title, groupTitle: group, color: color, initialMarkers: markers, id: nil, isGeodesic: true)
                    
                }
            }
        }
    }
    
    private func addLines(linesController: LinesController, _ polyline: GMULineString, _ title: String, _ color: String) {
        var markers = [GMSMarker]()
        for index in 0...polyline.path.count()-1 {
            let marker = GMSMarker(position: polyline.path.coordinate(at: index))
            markers.append(marker)
        }
        markers.removeDuplicates()
        if let lines = linesController.lines,
           lines.count < K.FreeAccountLimitations.overlayLimit {
            if markers.count > 1 {
                
                linesController.addLine(title: title, color: color, initialMarkers: markers, mapView: mapView, isGeodesic: true, id: nil)
                
            }
        }
    }
    
    private func addPlaces(placesController: PlacesController, _ place: GMUPoint, _ title: String, _ color: String) {
        let marker = GMSMarker(position: place.coordinate)
        
        if let places = placesController.places,
           places.count < K.FreeAccountLimitations.overlayLimit {
            placesController.addPlace(title: title, color: color, mapView: mapView, initialMarker: marker, id: nil, iconSize: nil)
        }
    }
}
