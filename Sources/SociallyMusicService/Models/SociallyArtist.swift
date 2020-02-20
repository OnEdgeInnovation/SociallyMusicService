//
//  SociallyArtist.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//

import Foundation

public struct SociallyArtist: Codable {
    
    public let name: String
    public let id: String
    public let imageURL: String
    
    init(from artist: Artist) {
        self.name = artist.name
        self.id = artist.id
        self.imageURL = artist.images[0].url.absoluteString
    }
}
