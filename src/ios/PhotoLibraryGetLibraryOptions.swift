import Foundation

struct PhotoLibraryGetLibraryOptions {
    let thumbnailWidth: Int
    let thumbnailHeight: Int
    let itemsInChunk: Int
    let chunkTimeSec: Double
    let useOriginalFileNames: Bool
    let includeAlbumData: Bool
}
