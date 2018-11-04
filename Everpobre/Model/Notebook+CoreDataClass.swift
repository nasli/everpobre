//
//  Notebook+CoreDataClass.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 11/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Notebook)
public class Notebook: NSManagedObject {

}

extension Notebook {
    func csv() -> String {
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel().replacingOccurrences(of: ",", with: ".") ?? "ND"
        let exportedTitle = name!

        return "\(exportedCreationDate),\(exportedTitle)"
    }
}
