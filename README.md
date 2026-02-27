# UNOLOAssingment
A simple iOS photo gallery application that fetches photos from JSONPlaceholder API and displays them in a table view with Core Data persistence.
## Features
- Fetch photos from JSONPlaceholder API
- Display photos in a scrollable table view
- View photo details with full-size images
- Edit photo titles
- Delete photos
- Offline storage with Core Data
- Image caching for better performance
- Pull-to-refresh functionality
- Pagination support
## Setup Instructions
### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- Swift 5.0 or later
### Installation
1. Clone or download the project
2. Open `UNOLOAssingment.xcodeproj` in Xcode
3. Build and run the project on simulator or device
### First Run
- The app will automatically fetch photos from the API on first launch
- Photos are stored locally using Core Data for offline access
- Pull down to refresh the photo list
## Architecture Overview
### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) architecture pattern:
**Models:**
- `PhotoModel` - Data model for API response
- `Photo` - Core Data entity for local storage
**Views:**
- `PhotosListViewController` - Main photo list screen (XIB-based)
- `PhotoDeetailsViewController` - Photo detail screen (XIB-based)
- `PhotoTableViewCell` - Custom table view cell
**ViewModels:**
- `PhotoViewModel` - Handles business logic and data management
**Managers:**
- `NetworkManager` - API communication
- `CoreDataManager` - Local data persistence
- `ImageCacheManager` - Image caching and loading
### Data Flow
1. App launches and checks for existing photos in Core Data
2. If no photos exist, fetches from JSONPlaceholder API
3. Saves photos to Core Data for offline access
4. Displays photos in table view with cached images
5. User can view details, edit titles, or delete photos
## Project Structure
```
UNOLOAssingment/
├── ViewControllers/
│   ├── PhotosListViewController.swift (XIB-based)
│   └── PhotoDeetailsViewController.swift (XIB-based)
├── ViewModels/
│   └── PhotoViewModel.swift
├── Views/
│   └── PhotoTableViewCell.swift
├── Models/
│   └── PhotoModel.swift
├── CoreData/
│   ├── Photo+CoreDataClass.swift
│   └── Photo+CoreDataProperties.swift
├── Managers/
│   ├── NetworkManager.swift
│   ├── CoreDataManager.swift
│   └── ImageCacheManager.swift
├── Utils/
│   └── Constants.swift
└── Resources/
    ├── UNOLOAssingment.xcdatamodeld
    └── XIB files
```
## Key Components
### NetworkManager
- Handles API requests to JSONPlaceholder
- Fetches photo data with proper error handling
- Downloads images for caching
### CoreDataManager
- Manages local data persistence
- Provides CRUD operations for photos
- Handles data migration and error recovery
### ImageCacheManager
- Caches downloaded images in memory
- Prevents duplicate downloads
- Manages memory usage with size limits
### PhotoViewModel
- Coordinates between views and data layers
- Handles pagination and data loading
- Manages photo operations (update, delete)
## API Integration
**Endpoint:** `https://jsonplaceholder.typicode.com/photos`
**Sample Response:**
```json
{
  "albumId": 1,
  "id": 1,
  "title": "accusamus beatae ad facilis cum similique qui sunt",
  "url": "https://via.placeholder.com/600/92c952",
  "thumbnailUrl": "https://via.placeholder.com/150/92c952"
}
```
## Core Data Model
**Photo Entity:**
- id (Integer 64) - Unique photo identifier
- albumId (Integer 64) - Album identifier
- title (String) - Photo title (editable)
- url (String) - Full-size image URL
- thumbnailUrl (String) - Thumbnail image URL
## Configuration
### App Transport Security
The app includes ATS exceptions for:
- `jsonplaceholder.typicode.com` - API endpoint
- `via.placeholder.com` - Image hosting
### Constants
All configuration values are centralized in `Constants.swift`:
- API endpoints and timeouts
- Cache limits and pagination settings
- UI dimensions and styling
- Error messages and accessibility identifiers
## Assumptions Made
1. **Internet Connection:** App assumes internet connectivity for initial data fetch
2. **Image URLs:** All image URLs from API are valid and accessible
3. **Data Persistence:** Core Data is used for offline storage without cloud sync
4. **Image Format:** All images are in standard web formats (JPEG, PNG)
5. **Memory Management:** Device has sufficient memory for image caching
6. **API Stability:** JSONPlaceholder API structure remains consistent
## Testing
The project includes:
- Unit test target (`UNOLOAssingmentTests`)
- UI test target (`UNOLOAssingmentUITests`)
Run tests using Xcode's test navigator or `Cmd+U`.
## Troubleshooting
**Common Issues:**
1. **Images not loading:** Check internet connection and ATS settings
2. **App crashes on launch:** Verify Core Data model integrity
3. **Navigation issues:** Ensure view controllers are properly embedded in navigation controller
**Debug Tips:**
- Check console logs for network and Core Data errors
- Verify API endpoint accessibility
- Clear app data to reset Core Data store
## Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+
## License
This project is for educational/assignment purposes.
