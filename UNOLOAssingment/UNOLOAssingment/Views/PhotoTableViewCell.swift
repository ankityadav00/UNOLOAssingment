import UIKit

// MARK: - Photo Table View Cell
class PhotoTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    static let identifier = "PhotoTableViewCell"
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.UI.cornerRadius
        imageView.backgroundColor = UIColor.systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(activityIndicator)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        setupConstraints()
        
        selectionStyle = .default
        accessoryType = .disclosureIndicator
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            photoImageView.widthAnchor.constraint(equalToConstant: 80),
            photoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            stackView.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: photoImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor)
        ])
    }
    
    func configure(with photo: Photo, viewModel: PhotoViewModel) {
        titleLabel.text = photo.title
        subtitleLabel.text = "Album ID: \(photo.albumId) • Photo ID: \(photo.id)"
        
        // Reset image
        photoImageView.image = viewModel.getPlaceholderImage()
        activityIndicator.startAnimating()
        
        // Load image
        viewModel.loadImage(for: photo) { [weak self] image in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                if let image = image {
                    self?.photoImageView.image = image
                } else {
                    self?.photoImageView.image = viewModel.getErrorImage()
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        activityIndicator.stopAnimating()
    }
}

extension PhotoTableViewCell {
    
    /// Set loading state
    func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            photoImageView.image = nil
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    /// Update title without reloading image
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
}
