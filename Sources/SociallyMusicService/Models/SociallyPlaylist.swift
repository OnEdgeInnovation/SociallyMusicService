//
//  SociallyPlaylist.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct SociallyPlaylist: Codable {
    
    let playlistUri: String
    let playlistId: String
    let name: String
    var imageURL: URL?
    let description: String
    let authorName: String
    let authorId: String
    
    init(from playlist: Playlist) {
        self.name = playlist.name
        if !playlist.images.isEmpty {
            self.imageURL = playlist.images[0].url
        }
        self.description = playlist.description
        self.authorId = playlist.owner.id
        self.authorName = playlist.owner.displayName
        self.playlistId = playlist.id
        self.playlistUri = playlist.uri
    }
    
    init(from playlist: ApplePlaylist) {
        self.playlistId = playlist.id
        self.name = playlist.attributes?.name ?? ""
        self.authorName = ""
        self.imageURL = nil
        self.description = playlist.attributes?.description?.standard ?? ""
        self.authorId = ""
        self.playlistUri = ""
    }
}
