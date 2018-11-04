//
//  MKMapView+Annotation.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 04/11/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {

    func stringOfTotalVisibleAnnotations() -> String {
        let visibleAnnotations = self.annotations(in: self.visibleMapRect).map { obj -> MKAnnotation in return obj as! MKAnnotation}

        return String(visibleAnnotations.count)
    }

    func addCenterMapAnnotation(latitude: Double, longitude: Double, title: String = "") {

        let location = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        self.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        self.addAnnotation(annotation)
    }
}
