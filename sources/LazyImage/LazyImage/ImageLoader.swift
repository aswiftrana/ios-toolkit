//
//  ImageLoader.swift
//  LazyImage
//
//  Created by Asad Rana on 3/3/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import Foundation
import UIKit
import Combine

public class ImageLoader {
    private var cache: ImageCacher
    private let requester: ImageFetcher
    private var requests = [URL: Cancellable]()
    private var lock = NSLock()
    
    public convenience init() {
        self.init(cache: ImageCache.init(storageLimitInMBs: 100),
                  requester: ConcurrentImageFetcher.init())
    }
    
    init(cache: ImageCacher, requester: ImageFetcher) {
        self.cache = cache
        self.requester = requester
    }
    
    public func loadImage(with url: URL) -> AnyPublisher<UIImage?, Never> {
        if let image = cache[url] {
            return Just(image)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        let request = requester.fetchImage(for: url)
        
        lock.lock(); defer { lock.unlock() }
        guard requests[url] == nil else {
            return request
        }
        
        let cancellable = request.sink { [weak self] image in
            guard let self = self else { return }
            self.cache[url] = image
            
            self.lock.lock(); defer { self.lock.unlock() }
            self.requests[url] = nil
        }
        
        requests[url] = cancellable
        return request
    }
}
