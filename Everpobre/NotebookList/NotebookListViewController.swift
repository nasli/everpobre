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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!

    //var managedContext: NSManagedObjectContext! // Beware to have a value before presenting the VC
    var coreDataStack: CoreDataStack!

//    var model: [deprecated_Notebook] = [] {
//        didSet {
//            tableView.reloadData()
//        }
//    }

    var dataSource: [NSManagedObject] = [] {
        didSet {
            tableView.reloadData()
        }
    }
//    {
//        do {
//            return try managedContext.fetch(Notebook.fetchRequest())
//        } catch let error as NSError {
//            print(error.localizedDescription)
//            return []
//        }
//    }

    private var fetchedResultsController: NSFetchedResultsController<Notebook>!

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

    override func viewDidLoad() {
        super.viewDidLoad()
//        model = deprecated_Notebook.dummyNotebookModel
//        navigationController?.navigationBar.prefersLargeTitles = true
//        navigationController?.navigationItem.largeTitleDisplayMode = .always

        //reloadView()
        configureSearchController()
        self.showAll()
    }

    private func configureSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search Notebook"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }

//    private func reloadView() {
//
//        do {
//            dataSource = try managedContext.fetch(Notebook.fetchRequest())
//        } catch let error as NSError {
//            print(error.localizedDescription)
//            dataSource = []
//        }
//
//        populateTotalLabel()
//
//        tableView.reloadData()
//    }

    private func populateTotalLabel(with predicate: NSPredicate = NSPredicate(value:true)) {
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

            //self.tableView.reloadData()
            //self.reloadView()
            self.showAll()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .default)

        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}

extension NotebookListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let section = fetchedResultsController.sections else { return 1 }
        return section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return model.count
//       return dataSource.count
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "NotebookListCell", for: indexPath) as! NotebookListCell

//        cell.configure(with: model[indexPath.row])
//        let notebook = dataSource[indexPath.row] as! Notebook
        let notebook = fetchedResultsController.object(at: indexPath)
        cell.configure(with: notebook)

        return cell
    }

    func tableView(_ tableview: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableview: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        guard let notebookToRemove = dataSource[indexPath.row] as? Notebook,
//            editingStyle == .delete
//        else { return }

        guard editingStyle == .delete else { return }

        let notebookToRemove = fetchedResultsController.object(at: indexPath)

        coreDataStack.managedContext.delete(notebookToRemove)

        do {
            try coreDataStack.managedContext.save()
            //tableview.deleteRows(at: [indexPath], with: .automatic)

        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }

        //tableView.reloadData()
        //self.reloadView()
        self.showAll()

    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.name
    }
}

extension NotebookListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let notebook = model[indexPath.row]
//        let notebook = dataSource[indexPath.row] as! Notebook
        let notebook = fetchedResultsController.object(at: indexPath)

        let notesListVC = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
        show(notesListVC, sender: nil)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "pushdetail" {
//            let vc = segue.destination as! NotesListViewController
//            let indexPath = tableView.indexPathForSelectedRow!
//            vc.notebook = model[indexPath].notebook
//
//        }
//    }
}

extension NotebookListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            showFilteredResults(with: text)
        } else {
            showAll()
        }
    }

    private func showFilteredResults(with query: String) {
//        let fetchRequest = NSFetchRequest<Notebook>(entityName: "Notebook")
//        fetchRequest.resultType = .managedObjectResultType
//        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
//        fetchRequest.predicate = predicate
//
//        do {
//            dataSource = try managedContext.fetch(fetchRequest)
//
//        } catch let error as NSError {
//            print("Could not fetch \(error)")
//            dataSource = []
//        }
//
//        populateTotalLabel(with: predicate)

        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        let frc = getFetchResultsController(with: predicate)
        setNewFetchedResultsController(frc)

        populateTotalLabel(with: predicate)

    }

    private func showAll() {

//        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: Notebook.fetchRequest()) { [weak self] (result) in
//
//            guard let notebooks = result.finalResult else {
//                self?.dataSource = []
//                return
//            }
//            self?.dataSource = notebooks
//        }
//
//        do{
//           // dataSource = try managedContext.fetch(Notebook.fetchRequest())
//            try managedContext.execute(asyncFetchRequest)
//        } catch let error as NSError {
//            print("Could not fetch \(error)")
//            dataSource = []
//        }

//        fetchedResultsController = getFetchResultsController()
//        fetchedResultsController.delegate = self
        let frc = getFetchResultsController()
        setNewFetchedResultsController(frc)

        do{
            try coreDataStack.managedContext.fetch(Notebook.fetchRequest())
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }


        populateTotalLabel()
    }
}

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
