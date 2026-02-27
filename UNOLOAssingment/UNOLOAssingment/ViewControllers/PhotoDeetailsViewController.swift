//
//  PhotoDeetailsViewController.swift
//  UNOLOAssingment
//
//  Created by Ankit Yadav on 27/02/26.
//

import UIKit

protocol PhotoDeetailsViewControllerDelegate: AnyObject {
    func photoDetailsDidUpdateTitle(photo: Photo)
    func photoDetailsDidDeletePhoto(photo: Photo)
}

class PhotoDeetailsViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var infoLabel: UILabel!
    
    weak var delegate: PhotoDeetailsViewControllerDelegate?
    
    private let photo: Photo
    private let viewModel: PhotoViewModel
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var originalTitle: String?
    
    init(photo: Photo, viewModel: PhotoViewModel) {
        self.photo = photo
        self.viewModel = viewModel
        super.init(nibName: "PhotoDeetailsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadPhotoData()
        loadImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveChangesIfNeeded()
    }
    
    private func setupUI() {
        title = "Photo Details"
        view.backgroundColor = .systemBackground
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = Constants.UI.cornerRadius
        imageView.clipsToBounds = true
        imageView.accessibilityIdentifier = Constants.Accessibility.photoImage
        
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter photo title..."
        textField.delegate = self
        textField.accessibilityIdentifier = Constants.Accessibility.photoTitle
        
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .secondaryLabel
        infoLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        view.addSubview(activityIndicator)
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = Constants.Accessibility.saveButton
        
        let deleteButton = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        deleteButton.accessibilityIdentifier = Constants.Accessibility.deleteButton
        deleteButton.tintColor = .systemRed
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped)),
            deleteButton
        ]
        
        navigationItem.hidesBackButton = false
    }
    
    private func loadPhotoData() {
        originalTitle = photo.title
        
        textField.text = photo.title
        
        let infoText = """
        Photo ID: \(photo.id)
        Album ID: \(photo.albumId)
        
        Original URL: \(photo.url ?? "N/A")
        Thumbnail URL: \(photo.thumbnailUrl ?? "N/A")
        """
        infoLabel.text = infoText
    }
    
    private func loadImage() {
        activityIndicator.startAnimating()
        
        viewModel.loadFullSizeImage(for: photo) { [weak self] image in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                if let image = image {
                    self?.imageView.image = image
                } else {
                    // Fallback to placeholder
                    self?.imageView.image = self?.viewModel.getErrorImage()
                }
            }
        }
    }
    
    @objc private func saveButtonTapped() {
        saveChanges()
    }
    
    @objc private func deleteButtonTapped() {
        showDeleteConfirmation()
    }
    
    private func saveChangesIfNeeded() {
        let currentTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if currentTitle != originalTitle && !currentTitle.isEmpty {
            saveChanges()
        }
    }
    
    private func saveChanges() {
        guard let newTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !newTitle.isEmpty else {
            showAlert(title: "Invalid Title", message: Constants.ErrorMessages.invalidTitle)
            return
        }
        
        if newTitle.count > Constants.UI.maxTitleLength {
            showAlert(title: "Title Too Long", message: "Title must be less than \(Constants.UI.maxTitleLength) characters.")
            return
        }
        
        photo.title = newTitle
        originalTitle = newTitle
        
        delegate?.photoDetailsDidUpdateTitle(photo: photo)
        
        if let index = viewModel.photos.firstIndex(where: { $0.id == photo.id }) {
            viewModel.updatePhotoTitle(at: index, newTitle: newTitle)
        }
        
        let alert = UIAlertController(title: "Success", message: "Photo title updated successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePhoto()
        })
        
        present(alert, animated: true)
    }
    
    private func deletePhoto() {
        delegate?.photoDetailsDidDeletePhoto(photo: photo)
        
        if let index = viewModel.photos.firstIndex(where: { $0.id == photo.id }) {
            viewModel.deletePhoto(at: index)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension PhotoDeetailsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= Constants.UI.maxTitleLength
    }
}

extension PhotoDeetailsViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
}
