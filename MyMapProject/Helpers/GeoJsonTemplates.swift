//
//  GeoJsonTemplates.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 18.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

struct GeoJsonTemplates {
    
    static let standard: String = """
            {
                "type": "Feature",
                "geometry": {
                "type": "Polygon",
                "coordinates": [[
                    [-180.0, 10.0], [20.0, 90.0], [180.0, -5.0], [-30.0, -90.0]
                    ]]
                },
                "style": {
                    "__comment": "all SVG styles allowed",
                    "fill":"red",
                    "stroke-width":"3",
                    "fill-opacity":0.6
                },
                "className": {
                    "baseVal":"A class name"
                }
            }
            """
    
    func makeGeojsonFile(exportType: ExportTypes, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, completion: @escaping () -> Void ) {
        
        var json = """
                    {
                        "type": "FeatureCollection",
                        "features": [
                    """
        
        if exportType == .all || exportType == .fields {
            fieldsController.fields?.forEach({ (field) in
                json += makeFieldsGeoJSONString(field: field)
                json += ","
            })
        }
        
        if exportType == .all || exportType == .lines {
            linesController.lines?.forEach({ (line) in
                json += makeLinesGeoJSONString(line: line)
                json += ","
            })
        }
        
        if exportType == .all || exportType == .places {
            placesController.places?.forEach({ (place) in
                json += makePlacesGeoJSONString(place: place)
                json += ","
            })
        }
        
        if let index = json.lastIndex(of: ",") {
            json.remove(at: index)
        }
    
        json += """
                ]
            }
            """
        
        let filename = getDocumentsDirectory().appendingPathComponent("mapstodo.geojson")

        do {
            try json.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            completion()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    private func makeFieldsGeoJSONString(field: Field) -> String {
        var coordinates = ""
        field.polygonMarkersPositions.forEach { (position) in
            coordinates += String(format: "[%lf, %lf], ", position.longitude, position.latitude)
        }
        coordinates.remove(at: coordinates.lastIndex(of: ",")!)
        
        let json = """
                                   {
                                       "type": "Feature",
                                       "properties": {
                                           "fill": "\(field.color)",
                                           "name": "\(field.title)",
                                           "group": "\(field.parentGroup.first!.title)"
                                       },
                                       "geometry": {
                                           "type": "Polygon",
                                           "coordinates": [
                                               [
                                                   \(coordinates)
                                               ]
                                           ]
                                       }
                                   }
                        """
        
        //print(json)
        return json
        
    }
    
    private func makeLinesGeoJSONString(line: Line) -> String {
        
        var coordinates = ""
        line.polylineMarkersPositions.forEach { (position) in
            
            coordinates += String(format: "[%lf, %lf], ", position.longitude, position.latitude)
        }
        coordinates.remove(at: coordinates.lastIndex(of: ",")!)
        
        let json = """
                                   {
                                       "type": "Feature",
                                       "properties": {
                                           "fill": "\(line.color)",
                                           "name": "\(line.title)"
                                       },
                                       "geometry": {
                                           "type": "LineString",
                                           "coordinates": [
                                               
                                                   \(coordinates)
                                               
                                           ]
                                       }
                                   }
                        """
        return json
        
    }
    
    private func makePlacesGeoJSONString(place: Place) -> String {
        
        var coordinates = ""

        if let lat = place.markerPosition?.latitude, let lon = place.markerPosition?.longitude {
            coordinates += String(format: "[%lf, %lf] ", lon, lat)
        }
        
        let json = """
                                   {
                                       "type": "Feature",
                                       "properties": {
                                           "fill": "\(place.color)",
                                           "name": "\(place.title)"
                                       },
                                       "geometry": {
                                           "type": "Point",
                                           "coordinates":
                                                   \(coordinates)
                                               
                                       }
                                   }
                        """
        return json
        
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}
