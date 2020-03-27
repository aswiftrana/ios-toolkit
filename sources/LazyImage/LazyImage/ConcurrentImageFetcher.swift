//
//  ConcurrentImageFetcher.swift
//  LazyImage
//
//  Created by Asad Rana on 3/4/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import UIKit
import Combine
import Networking

protocol ImageFetcher {
    func fetchImage(for url: URL) -> AnyPublisher<UIImage?, Never>
}

private struct InflightRequest {
    let stream: AnyPublisher<UIImage?, Never>
    let cleanupSink: Cancellable
}

class ConcurrentImageFetcher: ImageFetcher {
    private var inflightRequests = [URL: InflightRequest]()
    private let networkClient = Client.init()
    private let lock = NSLock.init()

    func fetchImage(for url: URL) -> AnyPublisher<UIImage?, Never> {
        guard let components = URLComponents.init(url: url, resolvingAgainstBaseURL: false) else {
            return Just(nil)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        self.lock.lock(); defer { self.lock.unlock() }
        if let imagePublisher = inflightRequests[url]?.stream {
            return imagePublisher
        }
        
        let imagePublisher = networkClient.get(components: components)
            .map { UIImage.init(data: $0) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
        
        let cleanupSink = imagePublisher
            .receive(on: DispatchQueue.global())
            .sink { [weak self] image in
                guard let self = self else { return }
                    
                self.lock.lock(); defer { self.lock.unlock() }
                self.inflightRequests[url] = nil
            }
        
        inflightRequests[url] = InflightRequest.init(stream: imagePublisher,
                                                     cleanupSink: cleanupSink)
        return imagePublisher

    }
}
