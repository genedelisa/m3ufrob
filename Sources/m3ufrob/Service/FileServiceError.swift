//___FILEHEADER___
import Foundation

enum FileServiceError: Swift.Error {
    case fileRead(String)
    case fileDecodingFailed
    case fileURLEncodingFailed(query: String)
}
