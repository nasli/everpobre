//
//  NotebookListCell.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 08/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit

class NotebookListCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var creationDateLabel: UILabel!
    
    override func prepareForReuse() {
            titleLabel.text = nil
            creationDateLabel.text = nil
    }

    func configure(with notebook: Notebook) {
        titleLabel.text = notebook.name

        creationDateLabel.text = "Create: \((notebook.creationDate as Date?)?.customStringLabel() ?? "ND")"
    }
}
