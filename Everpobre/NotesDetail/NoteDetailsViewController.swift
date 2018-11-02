//
//  NoteDetailsViewController.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 09/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit
import CoreData

protocol NoteDetailsViewControllerProtocol: class {
    func didSaveNote()
}

class NoteDetailsViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var lastSeenDateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!

 //   let note: Note
//    init(note: Note) {
//        self.note = note
//        super.init(nibName: "NoteDetailsViewController", bundle: nil)
//    }

    enum Kind {
        case new(notebook: Notebook)
        case existing(note: Note)
    }

    let managedContext: NSManagedObjectContext
    let kind: Kind

    weak var delegate: NoteDetailsViewControllerProtocol?

    init(kind: Kind, managedContext: NSManagedObjectContext) {
        self.kind = kind
        self.managedContext = managedContext
        super.init(nibName: "NoteDetailsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureValues()
    }

    private func configure() {
        let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save
            , target: self, action: #selector(saveNote))
        self.navigationItem.rightBarButtonItem = saveButtonItem
        let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        configureValues()
    }

    @objc private func saveNote() {

        func addProperties(to note: Note) -> Note {
            note.title = titleTextField.text
            note.text = descriptionTextView.text

            let imageData: NSData?
            if let image = imageView.image,
                let data = image.pngData() {
                imageData = NSData(data: data)
            } else {
                imageData = nil
            }

            note.image = imageData

            return note
        }

        switch kind {
        case .existing(let note):
            // modify note
            let modifiedNote = addProperties(to: note)
            modifiedNote.lastSeenDate = NSDate()

        case .new(let notebook):
            let note = Note(context: managedContext)
            let modifiedNote = addProperties(to: note)
            modifiedNote.creationDate = NSDate()
            modifiedNote.notebook = notebook

            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
        }


        do {
            try managedContext.save()
            delegate?.didSaveNote()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }


        switch kind {
        case .existing:
            navigationController?.popViewController(animated: true)
        case .new:
            dismiss(animated: true, completion: nil)
        }

    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func pickImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }

    private func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in self.takePhotoWithCamera() })
        let chooseFromLibrary = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in self.choosePhotoFromLibrary() })

        alertController.addAction(cancelAction)
        alertController.addAction(takePhotoAction)
        alertController.addAction(chooseFromLibrary)

        present(alertController, animated: true, completion: nil)
    }

    private func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true

        present(imagePicker, animated: true, completion: nil)
    }

    private func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true

        present(imagePicker, animated: true, completion: nil)
    }

    private func configureValues() {
//        title = "Detail"
//        titleLabel.text = note.title
//        creationDateLabel.text = "Creado: \((note.creationDate as Date?)?.customStringLabel() ?? "ND")"
//        lastSeenDateLabel.text = "Visto: \((note.lastSeenDate as Date?)?.customStringLabel() ?? "ND")"
//        descriptionTextView.text = note.text ?? "Enter text..."

        title = kind.title
        titleTextField.text = kind.note?.title
        //tagsLabel.text = note.tags?.joined(separator: ",")
        creationDateLabel.text = "Creado: \((kind.note?.creationDate as Date?)?.customStringLabel() ?? "ND")"
        lastSeenDateLabel.text = "Visto: \((kind.note?.lastSeenDate as Date?)?.customStringLabel() ?? "ND")"
        descriptionTextView.text = kind.note?.text ?? "Ingrese texto..."

        guard let data = kind.note?.image as Data? else {
            imageView.image = #imageLiteral(resourceName: "120x180.png")
            return
        }
        imageView.image = UIImage(data: data)
    }

}


private extension NoteDetailsViewController.Kind {
    var note: Note? {
        guard case let .existing(note) = self else { return nil }
        return note
    }

    var title: String {
        switch self {
        case .existing:
            return "Detalle"
        case .new:
            return "Nueva Nota"
        }
    }
}

extension NoteDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
            return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
        }

        func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
            return input.rawValue
        }

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let rawImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage

        let imageSize = CGSize(width: self.imageView.bounds.width * UIScreen.main.scale,
                               height: self.imageView.bounds.height * UIScreen.main.scale)

        DispatchQueue.global(qos: .default).async {
            let image = rawImage?.resizedImageWithContentMode(.scaleAspectFill,
                                                              bounds: imageSize, interpolationQuality: .high)
            DispatchQueue.main.async {
                if let image = image {
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.clipsToBounds = true
                    self.imageView.image = image
                }
            }
        }

        dismiss(animated: true, completion: nil)
    }
}
