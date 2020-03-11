//
//  Client.swift
//  Networking
//
//  Created by Asad Rana on 2/29/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import Foundation
import Combine

public protocol ClientProtocol {
    func get(components: URLComponents) -> AnyPublisher<Data, ClientError>
    func getAndDecode<T>(components: URLComponents) -> AnyPublisher<T, ClientError>
        where T : Decodable
    func getAndDecode<T, V>(components: URLComponents, decoder: V) -> AnyPublisher<T, ClientError>
        where T : Decodable, V : TopLevelDecoder, V.Input == Data
}

public enum ClientError: Error, Equatable {
    case invalidURL
    case network(code: Int, reason: String)
    case decoding
    case unknown
}

public class Client: ClientProtocol {

    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(components: URLComponents) -> AnyPublisher<Data, ClientError> {
        guard let url = components.url else {
            return Fail.init(error: ClientError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ClientError.unknown
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    let reason = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    throw ClientError.network(code: httpResponse.statusCode, reason: reason)
                }
                
                return data
            }
            .mapError { error -> ClientError  in
                if let error = error as? ClientError {
                    return error
                }
                                
                if let error = error as? URLError {
                    return .network(code: error.code.rawValue, reason: error.localizedDescription)
                }
                
                return .unknown
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public func getAndDecode<T>(components: URLComponents) -> AnyPublisher<T, ClientError> where T : Decodable {
        return getAndDecode(components: components, decoder: JSONDecoder.init())
    }
    
    public func getAndDecode<T, V>(components: URLComponents, decoder: V) -> AnyPublisher<T, ClientError>
        where T : Decodable, V : TopLevelDecoder, V.Input == Data {
        return get(components: components)
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> ClientError in
                if let error = error as? ClientError {
                    return error
                }
                
                if error is DecodingError {
                    return .decoding
                }
                
                return .unknown
            }
            .eraseToAnyPublisher()
    }
}


extension ClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .decoding:
            return "Unable to decode response to specified class"
        case .invalidURL:
            return "Invalid URL supplied to Client"
        case .network(let code, let reason):
            return "Network Error(\(code)) \(reason)"
        case .unknown:
            return "Unknow error occured while making request"
        }
    }
}
