//
//  NewNotesListViewController.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 23/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class NewNotesListViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var numberOfVisibleAnnotations: UILabel!
    
    @IBOutlet weak var numberVisibleAnnotationsStackView: UIStackView!
    // MARK: - Properties
    
    let notebook: Notebook
    let coreDataStack: CoreDataStack!

    var notes: [Note] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    let transition = Animator()

    // MARK: - Initialization

    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.notes = (notebook.notes?.array as? [Note]) ?? []
        self.coreDataStack = coreDataStack
        super.init(nibName: "NewNotesListViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "NotesListCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "NotesListCollectionViewCell")

        setupUI()
    }

    // MARK: - SetUp UI

    private func setupUI() {
        title = "Notas"
        self.view.backgroundColor = .white

        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        let exportButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareCSVofNotes))

        self.navigationItem.rightBarButtonItems = [addButtonItem, exportButtonItem]
    }

    @objc private func addNote() {
        let newNoteVC = NoteDetailsViewController(kind: .new(notebook: notebook), managedContext: coreDataStack.managedContext)
        newNoteVC.delegate = self
        let navVC = UINavigationController(rootViewController: newNoteVC)
        self.present(navVC, animated: true, completion: nil)
    }

    @objc private func shareCSVofNotes() {

        coreDataStack.storeContainer.performBackgroundTask { [unowned self] (context) in

            var results: [Note] = []

            do {
                results = try self.coreDataStack.managedContext.fetch(self.notesFetchRequest(from: self.notebook))

            } catch let error as NSError {
                print("Error:\(error.localizedDescription)")
            }

            let exportPath = NSTemporaryDirectory() + "export.csv"
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
                let csvHeader = "CreationDate, Year, Title, Tags, Text\n"
                guard let csvHeaderData = csvHeader.data(using: .utf8, allowLossyConversion: false) else { return }
                fileHandle.write(csvHeaderData)
                for note in results {
                    fileHandle.seekToEndOfFile()
                    guard let csvDataLine = note.csv().data(using: .utf8, allowLossyConversion: false) else { return }
                    fileHandle.write(csvDataLine)
                }

                fileHandle.closeFile()
                DispatchQueue.main.async { [weak self] in

                    let notebookName = self?.notebook.name
                    let activityViewController = UIActivityViewController(
                        activityItems: ["CSV with all Notes of Notebook: \(notebookName!).",URL(fileURLWithPath: exportPath) ],
                        applicationActivities: nil)
                    self?.present(activityViewController, animated: true, completion: nil)
                }

            } else {
                print("data not exported")
            }
        }
    }

    // MARK: - Alert
    private func showExportFinishedAlert(_ exportPath: String) {
        let message = "CSV file is in \(exportPath)"
        let alertController = UIAlertController(title: "Exported", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(dismissAction)

        present(alertController, animated: true)
    }

    // MARK: - FetchRequest Note
    private func notesFetchRequest(from notebook: Notebook) -> NSFetchRequest<Note> {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        return fetchRequest
    }

    // MARK: - IBActions
    @IBAction func segmentedControlTapped(_ sender: Any) {

        switch segmentedControl.selectedSegmentIndex {
        case 0:
            print("First Segment Selected")
            map.isHidden = true
            
        case 1:
            print("Second Segment Selected")
            map.isHidden = false
            showAnnotationsInMap()

        default:
            break
        }
    }

    func showAnnotationsInMap() {
        for note in notes {
            if let latitude = note.latitude, let longitude = note.longitude {
                map.addCenterMapAnnotation(latitude: latitude as! Double, longitude: longitude as! Double, title: note.title!)
            }
        }
    }

}

// MARK:- UICollectionView DataSource

extension NewNotesListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesListCollectionViewCell", for: indexPath) as! NotesListCollectionViewCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewNotesListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 150)
    }
}


// MARK: - UICollectionViewDelegate

extension NewNotesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailVC = NoteDetailsViewController(kind: .existing(note: notes[indexPath.row]), managedContext: coreDataStack.managedContext)
        detailVC.delegate = self
        //self.show(detailVC, sender: nil)

        //custom animation
        let navVC = UINavigationController(rootViewController: detailVC)
        navVC.transitioningDelegate = self
        present(navVC, animated: true, completion: nil)
    }
}

// MARK:- NoteDetailsViewControllerProtocol implementation

extension NewNotesListViewController: NoteDetailsViewControllerProtocol {
    func didSaveNote() {
        notes = (notebook.notes?.array as? [Note]) ?? []
    }
}

// MARK:- Custom Animation - UIViewControllerTransitioningDelegate

extension NewNotesListViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        let indexPath = (collectionView.indexPathsForSelectedItems?.first!)!
        let cell = collectionView.cellForItem(at: indexPath)
        transition.originFrame = cell!.superview!.convert(cell!.frame, to: nil)

        transition.presenting = true

        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

extension NewNotesListViewController: MKMapViewDelegate {

}
