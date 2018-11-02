//
//  Note+CoreDataClass.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 11/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {

}

extension Note {
    func csv() -> String {
        let exportedTitle = title ?? "Sin Titulo"
        let exportedText = text ?? ""
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel() ?? "ND"

        return "\(exportedCreationDate),\(exportedTitle),\(exportedText)\n"
    }
}
