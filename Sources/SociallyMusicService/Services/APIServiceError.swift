//
//  APIServiceError.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public enum APIServiceError: Error {
    case apiError
    case invalidResponse
    case noData
    case decodeError
    case tokenNilError
    case invalidCompiledURL
}
