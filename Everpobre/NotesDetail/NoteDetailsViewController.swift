//
//  NoteDetailsViewController.swift
//  Everpobre
//
//  Created by Noelia Alvarez on 09/10/2018.
//  Copyright © 2018 Noelia Alvarez. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation

protocol NoteDetailsViewControllerProtocol: class {
    func didSaveNote()
}

class NoteDetailsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var lastSeenDateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var addMyLocationButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var tagsTextField: UITextField!
    
    // MARK: - Properties
    enum Kind {
        case new(notebook: Notebook)
        case existing(note: Note)
    }

    let managedContext: NSManagedObjectContext
    let kind: Kind

    weak var delegate: NoteDetailsViewControllerProtocol?

    var locationManager = CLLocationManager()
    var location: CLLocationCoordinate2D?

    // MARK: - Initialization
    init(kind: Kind, managedContext: NSManagedObjectContext) {
        self.kind = kind
        self.managedContext = managedContext
        self.location = nil
        super.init(nibName: "NoteDetailsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocation()
        setupUI()
        syncModelWithView()
    }


    // MARK: - SetUp

    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func setupUI() {
        let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save
            , target: self, action: #selector(saveNote))
        self.navigationItem.rightBarButtonItem = saveButtonItem
        let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem = cancelButtonItem

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

            if location != nil {
                note.latitude = self.location!.latitude as NSNumber
                note.longitude = self.location!.longitude as NSNumber
            } else {
                note.latitude = nil
                note.longitude = nil
            }

            note.tags = tagsTextField.text

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

        dismiss(animated: true, completion: nil)
    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Sync
    private func syncModelWithView() {

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

        map.isHidden = true
        if let latitude = kind.note?.latitude, let longitude = kind.note?.longitude {
            map.isHidden = false
            addCenterMapAnnotation(latitude: Double(truncating: latitude), longitude: Double(truncating: longitude))
        }
        
        // TODO: Replace with Tags objects
        tagsTextField.text = kind.note?.tags

    }

    // MARK: - IBActions

    @IBAction private func pickImage(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }


    @IBAction func addMyLocationTapped(_ sender: Any) {

        map.isHidden = false

        if CLLocationManager.locationServicesEnabled() {
            print("Location Services Enabled")
            let status  = CLLocationManager.authorizationStatus()
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else if status == .restricted || status == .denied {
                print("Location Services NOT Authorized")

                let alert = UIAlertController(title: "Location Services NOT Authorized", message: "Please enable Location Services in Settings", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            }
            locationManager.startUpdatingLocation()
        } else {
            print("Location Services NOT Enabled")
        }
    }

    // MARK: - Photo Menu

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

    // MARK: - Map Annotation
    func addCenterMapAnnotation(latitude: Double, longitude: Double) {

        let location = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        self.map.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        map.addAnnotation(annotation)
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

// MARK: - NoteDetailsViewController.Kind
private extension NoteDetailsViewController.Kind {
    var note: Note? {
        guard case let .existing(note) = self else { return nil }
        return note
    }

    var title: String {
        switch self {
        case .existing:
            return "Details"
        case .new:
            return "New note"
        }
    }
}

// MARK: - Location
extension NoteDetailsViewController: CLLocationManagerDelegate, MKMapViewDelegate {


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        locationManager.stopUpdatingLocation()

        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)

        addCenterMapAnnotation(latitude: location.latitude, longitude: location.longitude)

        self.location = location

    }
}
