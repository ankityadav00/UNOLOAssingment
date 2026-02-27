//
//  PhotosListViewController.swift
//  UNOLOAssingment
//
//  Created by Ankit Yadav on 27/02/26.
//

import UIKit

class PhotosListViewController: UIViewController {

    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel = PhotoViewModel()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshPhotos), for: .valueChanged)
        return refresh
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupViewModel()
        loadPhotos()
    }
    
    private func setupUI() {
        title = "Photos"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshPhotos)
        )
        
        view.addSubview(loadingIndicator)
        tableView.refreshControl = refreshControl
        
        setupConstraints()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PhotoTableViewCell.self, forCellReuseIdentifier: PhotoTableViewCell.identifier)
        tableView.rowHeight = 104
        tableView.separatorStyle = .singleLine
        tableView.accessibilityIdentifier = Constants.Accessibility.photoCell
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
        ])
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    @objc private func refreshPhotos() {
        viewModel.refreshPhotos()
    }
    
    private func loadPhotos() {
        viewModel.loadPhotos()
    }
    
    private func updateEmptyState() {
        let isEmpty = viewModel.photosCount == 0
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func showErrorAlert(with error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadPhotos()
        })
        
        present(alert, animated: true)
    }
    
    private func showDeleteConfirmation(for indexPath: IndexPath) {
        guard let photo = viewModel.photo(at: indexPath.row) else { return }
        
        let alert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.viewModel.deletePhoto(at: indexPath.row)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PhotosListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.photosCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PhotoTableViewCell.identifier, for: indexPath) as? PhotoTableViewCell,
              let photo = viewModel.photo(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        cell.configure(with: photo, viewModel: viewModel)
        cell.accessibilityIdentifier = "\(Constants.Accessibility.photoCell)_\(indexPath.row)"
        
        if viewModel.shouldLoadMoreData(for: indexPath) {
            viewModel.loadMorePhotos()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let photo = viewModel.photo(at: indexPath.row) else { return }
        
        let detailVC = PhotoDeetailsViewController(photo: photo, viewModel: viewModel)
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            showDeleteConfirmation(for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

extension PhotosListViewController: PhotoViewModelDelegate {
    
    func photosDidLoad() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
    
    func photosDidFailToLoad(with error: Error) {
        DispatchQueue.main.async {
            self.showErrorAlert(with: error)
            self.updateEmptyState()
        }
    }
    
    func photoDidUpdate(at index: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell,
               let photo = self.viewModel.photo(at: index) {
                cell.updateTitle(photo.title ?? "")
            }
        }
    }
    
    func photoDidDelete(at index: Int) {
        DispatchQueue.main.async {
            guard index >= 0 && index < self.viewModel.photosCount else {
                self.tableView.reloadData()
                self.updateEmptyState()
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
            self.updateEmptyState()
        }
    }
    
    func loadingStateDidChange(isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading && self.viewModel.photosCount == 0 {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: - PhotoDetailViewControllerDelegate
extension PhotosListViewController: PhotoDeetailsViewControllerDelegate {
    func photoDetailsDidUpdateTitle(photo: Photo) {
        if let index = viewModel.photos.firstIndex(where: { $0.id == photo.id }) {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: index, section: 0)
                if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell {
                    cell.updateTitle(photo.title ?? "")
                }
            }
        }
    }
    
    func photoDetailsDidDeletePhoto(photo: Photo) {

        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
}
