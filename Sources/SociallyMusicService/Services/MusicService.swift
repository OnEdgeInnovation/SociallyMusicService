//
//  SociallyMusicService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public class MusicService {
    
    private let urlSession = URLSession.shared
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    func fetchResources<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, APIServiceError>) -> Void) {
        //Make call
        urlSession.dataTask(with: request) { (result: Result<(URLResponse, Data), Error> ) in
            switch result {
            case .success(let (response, data)):
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    print(response)
                    completion(.failure(.invalidResponse))
                    return
                }
                do {
                    let values = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(values))
                } catch let error {
                    print(error)
                    completion(.failure(.decodeError))
                }
            case .failure:
                completion(.failure(.apiError))
            }
        }.resume()
    }
    
    func sendRequestNoPayload(request: URLRequest, result: @escaping (Result<Bool, APIServiceError>) -> Void) {
        var newRequest = request
        //Add headers
        newRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        newRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //Perform call
        urlSession.dataTask(with: newRequest) { data, response, error in
            if error != nil || data == nil {
                result(.failure(.apiError))
                return
            }
            guard let response = response as? HTTPURLResponse, (204 == response.statusCode || 200 == response.statusCode) else {
                result(.failure(.invalidResponse))
                return
            }
            result(.success(true))
        }.resume()
    }
}
