//
//  Unwrappable.swift
//  Task Manager
//
//  Created by Gagan Mac on 21/09/20.
//  Copyright © 2020 IT Manufactory. All rights reserved.
//

import UIKit

typealias ImageCompletionHandler = (Result<UIImage, Error>) -> Void
private typealias ImageCacheKey = NSString

struct ImageProvider {
    static let shared = ImageProvider()
    
    func fetch(from url: String, completionHandler: ImageCompletionHandler? = nil) {
        if let image = cache.object(forKey: url as ImageCacheKey) {
            completionHandler?(.success(image))
        } else {
            downloadImage(from: url) { result in
                result.success { self.cache.setObject($0, forKey: url as ImageCacheKey) }
                completionHandler?(result)
            }
        }
    }
    
    private func downloadImage(from url: String, completionHandler: @escaping ImageCompletionHandler) {
        let webClient = WebClient(baseUrl: url)
        webClient.requestData {
            let imageResult = $0.mapThrow { try UIImage(data: $0).unwrap(errorIfNil: ImageProviderError.malformedData) }
            completionHandler(imageResult)
        }
    }
    
    private let cache: NSCache<ImageCacheKey, UIImage>
    private init() {
        let cache = NSCache<NSString, UIImage>()
        cache.name = "TaskManager.ImageCache"
        cache.countLimit = 200
        self.cache = cache
    }
}

//private extension String {
//    var imageCacheKey: ImageCacheKey {
//        return imageCacheKey as NSString
//    }
//}

extension UIImageView {
    func setImageFrom(url: String) {
        ImageProvider.shared.fetch(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.image = image
            case .failure(let error):
                print(error)
            }
        }
    }
}
