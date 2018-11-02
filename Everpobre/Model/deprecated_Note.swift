//
//  Note.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 08/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import Foundation

struct deprecated_Note {
    let title: String
    let text: String
    let tags: [String]?
    let creationDate: Date
    let lastSeenDate: Date?

    static let dummyNotesModel: [deprecated_Note] = [
        deprecated_Note(title: "Primera nota", text: "", tags: nil, creationDate: Date(), lastSeenDate: nil),
        deprecated_Note(title: "Segunda nota", text: "Test", tags: nil, creationDate: Date(), lastSeenDate: nil),
        deprecated_Note(title: "Tercera nota", text: "Texto de prueba", tags: nil, creationDate: Date(), lastSeenDate: nil),
        deprecated_Note(title: "Cuarta nota", text: "Algo de contenido", tags: nil, creationDate: Date(), lastSeenDate: nil),
        deprecated_Note(title: "Quinta nota", text: "", tags: nil, creationDate: Date(), lastSeenDate: nil)
    ]
}
