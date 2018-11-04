//
//  NotebookListViewController.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 08/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit
import CoreData

class NotebookListViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!

    // MARK: - Properties
    var coreDataStack: CoreDataStack!

    var dataSource: [NSManagedObject] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var fetchedResultsController: NSFetchedResultsController<Notebook>!

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        self.showAllNotebooks()
    }

    // MARK: - FetchResults
    
    private func getFetchResultsController(with predicate: NSPredicate = NSPredicate(value: true)) -> NSFetchedResultsController<Notebook> {

        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.predicate = predicate

        let sort = NSSortDescriptor(key: #keyPath(Notebook.creationDate), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.fetchBatchSize = 20

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: #keyPath(Notebook.creationDate  ), cacheName: nil)
    }

    private func setNewFetchedResultsController(_ newfrc: NSFetchedResultsController<Notebook>) {
        let oldfrc = fetchedResultsController
        if(newfrc != oldfrc) {
            fetchedResultsController = newfrc
            newfrc.delegate = self

            do {
                try fetchedResultsController.performFetch()
            }catch let error as NSError {
                print("could not fetch \(error)")
            }
            tableView.reloadData()
        }
    }

    // MARK: - SetUp UI

    private func setupSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search Notebook"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }

    private func UpdateNumberOfTotalNotebooks(with predicate: NSPredicate = NSPredicate(value:true)) {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Notebook")
        fetchRequest.resultType = .countResultType
        // to get all need a predicate, will going to evaluate to made the filters
        fetchRequest.predicate = predicate

        do {
            let countResult = try coreDataStack.managedContext.fetch(fetchRequest)
            let count = countResult.first!.intValue
            totalLabel.text = "\(count)"
        } catch let error as NSError {
            print("Count not fetch: \(error.description)")
        }
    }

    // MARK: - IBActions

    @IBAction func addNotebook(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Notebook", message: "Add new notebook", preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            guard
                let textField = alert.textFields?.first,
                let nameToSave = textField.text
            else { return }

            let notebook = Notebook(context: self.coreDataStack.managedContext)
            notebook.name = nameToSave
            notebook.creationDate = NSDate()

            do {
                try self.coreDataStack.managedContext.save()
            } catch let error as NSError {
                print("TODO error handling: \(error.debugDescription)")
            }
            self.showAllNotebooks()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .default)

        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }


    @IBAction func shareNotebooks(_ sender: Any) {
        
        shareCSVofNotebooks()
    }

    private func shareCSVofNotebooks() {

        coreDataStack.storeContainer.performBackgroundTask { [unowned self] (context) in

            var results: [Notebook] = []

            do {
                results = try self.coreDataStack.managedContext.fetch(Notebook.fetchRequest())

            } catch let error as NSError {
                print("Error:\(error.localizedDescription)")
            }

            let exportPath = NSTemporaryDirectory() + "exportNotebooks.csv"
            let exportURL = URL(fileURLWithPath: exportPath)
            FileManager.default.createFile(atPath: exportPath, contents: Data(), attributes: nil)

            let fileHandle: FileHandle?
            do {
                fileHandle = try FileHandle(forWritingTo: exportURL)
            } catch let error as NSError {
                print(error.localizedDescription)
                fileHandle = nil
            }

            if let fileHandle = fileHandle {
                let csvHeader = "Notebook CreationDate, Notebook Title, Note CreationDate, Note UpdatedDate, Note Title, Note Tags, Note Text\n \n"
                guard let csvNotebookHeaderData = csvHeader.data(using: .utf8, allowLossyConversion: false) else { return }
                fileHandle.write(csvNotebookHeaderData)

                for notebook in results {

                    guard let notes: [Note] = notebook.notes?.array as? [Note]
                    else {
                        fileHandle.seekToEndOfFile()
                        guard let csvNotebookDataLine = notebook.csv().data(using: .utf8, allowLossyConversion: false) else { return }
                        fileHandle.write(csvNotebookDataLine)
                        return
                    }
                    for note: Note in notes {
                        fileHandle.seekToEndOfFile()
                        let csvStringLine = notebook.csv() + "," + note.csv()
                        guard let csvDataLine = csvStringLine.data(using: .utf8, allowLossyConversion: false) else { return }

                        fileHandle.write(csvDataLine)
                    }
                }

                fileHandle.closeFile()
                
                DispatchQueue.main.async { [weak self] in

                    let activityViewController = UIActivityViewController(
                        activityItems: ["CSV with all Notebooks and Notes", URL(fileURLWithPath: exportPath) ],
                        applicationActivities: nil)
                    self?.present(activityViewController, animated: true, completion: nil)
                }

            } else {
                print("data not exported")
            }
        }
    }

}

// MARK: - TableView DataSource

extension NotebookListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let section = fetchedResultsController.sections else { return 1 }
        return section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "NotebookListCell", for: indexPath) as! NotebookListCell

        let notebook = fetchedResultsController.object(at: indexPath)
        cell.configure(with: notebook)

        return cell
    }

    func tableView(_ tableview: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableview: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }

        let notebookToRemove = fetchedResultsController.object(at: indexPath)

        coreDataStack.managedContext.delete(notebookToRemove)

        do {
            try coreDataStack.managedContext.save()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        self.showAllNotebooks()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.name
    }
}

// MARK: - TableView Delegate

extension NotebookListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notebook = fetchedResultsController.object(at: indexPath)

        let notesListVC = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
        show(notesListVC, sender: nil)
    }
}

// MARK: - Search Delegate

extension NotebookListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            showFilteredResults(with: text)
        } else {
            showAllNotebooks()
        }
    }

    private func showFilteredResults(with query: String) {

        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        let frc = getFetchResultsController(with: predicate)
        setNewFetchedResultsController(frc)

        UpdateNumberOfTotalNotebooks(with: predicate)
    }

    private func showAllNotebooks() {

        let frc = getFetchResultsController()
        setNewFetchedResultsController(frc)

        do{
            try coreDataStack.managedContext.fetch(Notebook.fetchRequest())
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }

        UpdateNumberOfTotalNotebooks()
    }
}

// MARK: - Fetch Result Delegate

extension NotebookListViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case.delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {

        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()

    }
}
