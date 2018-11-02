//
//  NotesListViewController.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 08/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit
import CoreData

class NotesListViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    let notebook: Notebook
    let managedContext: NSManagedObjectContext

//    var notes: [Note] = [] {
//        didSet {
//            tableView.reloadData()
//        }
//    }

//    var notes: [Note] {
//        guard let notes = notebook.notes?.array else { return [] }
//
//        return notes as! [Note]
//    }

    var notes: [Note] {
        didSet {
            tableView.reloadData()
        }
    }

    init(notebook: Notebook, managedContext: NSManagedObjectContext) {
        self.notebook = notebook
        self.managedContext = managedContext
        self.notes = notebook.notes?.array as? [Note] ?? []
       // self.notes = notebook.notes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

     //   self.navigationController?.navigationBar.isTranslucent = false
        
        //title = "Notas de: \(notebook.name)"
        title = "Notas"

        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(addNote))
        navigationItem.rightBarButtonItem = addButtonItem

        setupTableView()
    }

    @objc private func addNote() {
        let newNoteVC = NoteDetailsViewController(kind: .new(notebook:notebook), managedContext: managedContext)
        newNoteVC.delegate = self
        let navVC = UINavigationController(rootViewController: newNoteVC)
        present(navVC, animated: true, completion: nil)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)

        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
}

extension NotesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel!.text = notes[indexPath.row].title

        return cell
    }
}

extension NotesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let detailVC = NoteDetailsViewController(note: notes[indexPath.row])
        let detailVC = NoteDetailsViewController(kind: .existing(note: notes[indexPath.row]), managedContext: managedContext)
        detailVC.delegate = self
        show(detailVC, sender: nil)

    }
}

extension NotesListViewController: NoteDetailsViewControllerProtocol {
    func didSaveNote() {
        notes = (notebook.notes?.array as? [Note]) ?? []
    }
}
