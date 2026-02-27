import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let baseURL = Constants.API.baseURL
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.requestTimeout
        config.timeoutIntervalForResource = Constants.API.requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Photos
    func fetchPhotos() async throws -> [PhotoModel] {
        guard let url = URL(string: "\(baseURL)\(Constants.API.photosEndpoint)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil))
            }
            
            // Decode JSON
            let decoder = JSONDecoder()
            let photos = try decoder.decode([PhotoModel].self, from: data)
            return photos
            
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw NetworkError.decodingError
        } catch {
            print("Network error: \(error)")
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Download Image
    func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil))
            }
            
            return data
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}
