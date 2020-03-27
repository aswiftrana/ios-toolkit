//
//  ImageCache.swift
//  LazyImage
//
//  Created by Asad Rana on 3/3/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import Foundation
import UIKit

protocol ImageCacher {
    subscript(key: URL) -> UIImage? { get set }
}

class ImageCache: ImageCacher {
    private let lock = NSLock.init()
    private let cache: NSCache<NSURL, UIImage>
    
    
    init(storageLimitInMBs storageLimit: Int) {
        cache = NSCache.init()
        cache.totalCostLimit = 1024 * 1024 * storageLimit
    }
    
    subscript(key: URL) -> UIImage? {
        get {
            return image(for: key as NSURL)
        }
        set(newImage) {
            if let image = newImage {
                cacheImage(image, forUrl: key as NSURL)
            } else {
                removeImageCache(forUrl: key as NSURL)
            }
        }
    }
    
    func image(for url: NSURL) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: url)
    }
    
    func cacheImage(_ image: UIImage, forUrl url: NSURL) {
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(image, forKey: url)
    }
    
    func removeImageCache(forUrl url: NSURL) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: url)
    }
}
