import Foundation

struct PhotoLibraryGetLibraryOptions {
    let thumbnailWidth: Int
    let thumbnailHeight: Int
    let itemsInChunk: Int
    let chunkTimeSec: Double
    let useOriginalFileNames: Bool
    let includeImages: Bool
    let includeAlbumData: Bool
    let includeCloudData: Bool
    let includeVideos: Bool
    let maxItems: Int
}
