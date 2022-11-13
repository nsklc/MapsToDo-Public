//
//  GeoJsonAndKmlTemplates.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 18.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

struct GeoJsonAndKmlTemplates {
    
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
    
    func makeKMLFile(exportType: String, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, completion: @escaping () -> Void ) {
        
        var content = ""
        
        if exportType == "all" || exportType == "fields" {
            fieldsController.fields?.forEach({ (field) in
                content += makeFieldsKMLString(field: field)
                content += "\n"
            })
        }
        
        if exportType == "all" || exportType == "lines" {
            linesController.lines?.forEach({ (line) in
                content += makeLinesKMLString(line: line)
                content += "\n"
            })
        }
        
        if exportType == "all" || exportType == "places" {
            placesController.places?.forEach({ (place) in
                content += makePlacesKMLString(place: place)
                content += "\n"
            })
        }
        
        let json = """
                    <?xml version="1.0" encoding="UTF-8"?>
                    <kml xmlns="http://www.opengis.net/kml/2.2">
                      <Document>
                        \(content)
                      </Document>
                    </kml>
                    """
        print(json)
        
        let filename = getDocumentsDirectory().appendingPathComponent("mapstodo.kml")
        
        do {
            try json.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            completion()
        } catch {
            print(error.localizedDescription)
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    func makeGeojsonFile(exportType: String, fieldsController: FieldsController, linesController: LinesController, placesController: PlacesController, completion: @escaping () -> Void ) {
        
        var json = """
                    {
                        "type": "FeatureCollection",
                        "features": [
                    """
        
        if exportType == "all" || exportType == "fields" {
            fieldsController.fields?.forEach({ (field) in
                json += makeFieldsGeoJSONString(field: field)
                json += ","
            })
        }
        
        if exportType == "all" || exportType == "lines" {
            linesController.lines?.forEach({ (line) in
                json += makeLinesGeoJSONString(line: line)
                json += ","
            })
        }
        
        if exportType == "all" || exportType == "places" {
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
        
//        let json = """
//                        \(makeFieldsGeoJSONString(field: field))
//                    """
        print(json)
        
        
        let filename = getDocumentsDirectory().appendingPathComponent("mapstodo.geojson")

        do {
            try json.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            completion()
        } catch {
            print(error.localizedDescription)
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    
    private func makeFieldsGeoJSONString(field: Field) -> String {
        
        //print(field.title)
        
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

        
        //print(json)
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
        
        //print(json)
        return json
        
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func makeFieldsKMLString(field: Field) -> String {
        
        var coordinates = ""
        field.polygonMarkersPositions.forEach { (position) in
            
            //print(String(format: "[%lf, %lf],", position.latitude, position.longitude))
            //coordinates += String(format: "[%lf, %lf],\n", position.latitude, position.longitude)
            coordinates += String(format: "%lf,%lf\n", position.longitude, position.latitude)
        }
        //coordinates.remove(at: coordinates.lastIndex(of: ",")!)
        //json += coordinates
        
//        fieldsColor.remove(at: fieldsColor.firstIndex(of: "#")!)
        
        let color1 = UIColor(hexString: field.color)!
        
//        print(color1.hexString(.AABBGGRR))
        
        
//        let color2 = CIColor(color: color1)
//        let color3 = String(format: "#%02X%02X%02X%02X", color2.alpha, color2.blue, color2.green, color2.red)
//        print(color3)
        
        let json = """
                                    <Style id="\(field.title)">
                                         <LineStyle>
                                           <width>0.5</width>
                                         </LineStyle>
                                         <PolyStyle>
                                           <color>\(color1.hexString(.AABBGGRR))</color>
                                         </PolyStyle>
                                       </Style>
                                   <Placemark>
                                    <name>\(field.title)</name>
                                    <styleUrl>#\(field.title)</styleUrl>
                                        <visibility>1</visibility>
                                        <Polygon>
                                          <extrude>1</extrude>
                                          <altitudeMode>relativeToGround</altitudeMode>
                                          <outerBoundaryIs>
                                            <LinearRing>
                                                <coordinates>
                                                    \(coordinates)
                                                </coordinates>
                                           </LinearRing>
                                         </outerBoundaryIs>
                                       </Polygon>
                                     </Placemark>
                        """
        
        //print(json)
        return json
        
    }
    
    private func makeLinesKMLString(line: Line) -> String {
        
        var coordinates = ""
        line.polylineMarkersPositions.forEach { (position) in
            
            //print(String(format: "[%lf, %lf],", position.latitude, position.longitude))
            //coordinates += String(format: "[%lf, %lf],\n", position.latitude, position.longitude)
            coordinates += String(format: "%lf,%lf\n", position.longitude, position.latitude)
        }
        //coordinates.remove(at: coordinates.lastIndex(of: ",")!)
        //json += coordinates
        
        let color1 = UIColor(hexString: line.color)!
        
//        print(color1.hexString(.AABBGGRR))
        
        let json = """
                                    <Style id="\(line.title)">
                                         <LineStyle>
                                           <width>0.5</width>
                                         </LineStyle>
                                         <PolyStyle>
                                           <color>\(color1.hexString(.AABBGGRR))</color>
                                         </PolyStyle>
                                       </Style>
                                   <Placemark>
                                       <name>\(line.title)</name>
                                       <styleUrl>#\(line.title)</styleUrl>
                                       <LineString>
                                         <tessellate>1</tessellate>
                                         <coordinates>
                                           \(coordinates)
                                         </coordinates>
                                       </LineString>
                                     </Placemark>
                        """
        
        //print(json)
        return json
        
    }
    
    private func makePlacesKMLString(place: Place) -> String {
        
        var coordinates = ""
        //            place.polylineMarkersPositions.forEach { (position) in
        //
        //                //print(String(format: "[%lf, %lf],", position.latitude, position.longitude))
        //                //coordinates += String(format: "[%lf, %lf],\n", position.latitude, position.longitude)
        //                coordinates += String(format: "[%lf, %lf], ", position.latitude, position.longitude)
        //            }
        if let lat = place.markerPosition?.latitude, let lon = place.markerPosition?.longitude {
            coordinates += String(format: "%lf, %lf", lon, lat)
        }
        
        let json = """
                    <Placemark>
                       <name>\(place.title)</name>
                       <description>Attached to the ground. Intelligently places itself at the
                         height of the underlying terrain.</description>
                        <styleUrl>#\(place.title)</styleUrl>
                       <Point>
                         <coordinates>\(coordinates)</coordinates>
                       </Point>
                     </Placemark>
                """
        
        //print(json)
        return json
        
    }
}
extension UIColor {
    enum HexFormat {
        case RGB
        case ARGB
        case RGBA
        case RRGGBB
        case AARRGGBB
        case RRGGBBAA
        case AABBGGRR
    }

    enum HexDigits {
        case d3, d4, d6, d8
    }

    func hexString(_ format: HexFormat = .RRGGBBAA) -> String {
        let maxi = [.RGB, .ARGB, .RGBA].contains(format) ? 16 : 256

        func toI(_ f: CGFloat) -> Int {
            return min(maxi - 1, Int(CGFloat(maxi) * f))
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = toI(r)
        let gi = toI(g)
        let bi = toI(b)
        let ai = toI(a)

        switch format {
        case .RGB:       return String(format: "#%X%X%X", ri, gi, bi)
        case .ARGB:      return String(format: "#%X%X%X%X", ai, ri, gi, bi)
        case .RGBA:      return String(format: "#%X%X%X%X", ri, gi, bi, ai)
        case .RRGGBB:    return String(format: "#%02X%02X%02X", ri, gi, bi)
        case .AARRGGBB:  return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
        case .RRGGBBAA:  return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
        case .AABBGGRR: return String(format: "%02X%02X%02X%02X", ai, bi, gi, ri)
        }
    }

    func hexString(_ digits: HexDigits) -> String {
        switch digits {
        case .d3: return hexString(.RGB)
        case .d4: return hexString(.RGBA)
        case .d6: return hexString(.RRGGBB)
        case .d8: return hexString(.RRGGBBAA)
        }
    }
}
