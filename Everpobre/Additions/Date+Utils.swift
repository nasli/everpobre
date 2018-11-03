//
//  Date+Utils.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 09/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import Foundation

extension Date {
    func customStringLabel() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US")

        return "\(dateFormatter.string(from: self as Date))"
    }
}
