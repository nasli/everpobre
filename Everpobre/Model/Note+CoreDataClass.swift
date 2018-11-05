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

        let exportedCreationDate = (creationDate as Date?)?.customStringLabel().replacingOccurrences(of: ",", with: ".") ?? "ND"
        let exportedUpdatedDate = (lastSeenDate as Date?)?.customStringLabel().replacingOccurrences(of: ",", with: ".") ?? "ND"
        let exportedTitle = (title ?? "").isEmpty ? "" : title
        let exportedTags = tags!.replacingOccurrences(of: ",", with: ".")
        let exportedText = (text ?? "").isEmpty ? "" : text
        let exportedLatitude = latitude?.stringValue ?? ""
        let exportedLongitude = longitude?.stringValue ?? ""

        return "\(exportedCreationDate),\(exportedUpdatedDate),\(exportedTitle!),\(exportedTags),\(exportedText!),\(exportedLatitude),\(exportedLongitude)\n"
    }
}
