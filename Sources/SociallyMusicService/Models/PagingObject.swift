//
//  PagingObject.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct PagingObject<T: Codable>: Codable {
    
    let href: String
    var items: [T]
    let limit: Int
    let next: String?
    let offset: Int?
    let previous: String?
    
    let total: Int?
    
    var nextUrl: URL? {
        guard let next = next else {
            return nil
        }
        return URL(string: next)
    }
    
    var prevUrl: URL? {
        guard let previous = previous else {
            return nil
        }
        return URL(string: previous)
    }
}

public struct TrackPagingObject<T: Codable>: Codable {
    let tracks: PagingObject<T>
}
