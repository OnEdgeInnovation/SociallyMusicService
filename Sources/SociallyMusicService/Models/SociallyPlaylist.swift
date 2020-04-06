//
//  SociallyPlaylist.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public struct SociallyPlaylist: Codable {
    
    public let playlistUri: String
    public let playlistId: String
    public let name: String
    public var imageURL: URL?
    public let description: String
    public let authorName: String
    public let authorId: String
    
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
    
    init?(from resource: Resource<PlaylistAttributes>) {
        guard let attr = resource.attributes else { return nil }
        self.name = attr.name
        self.authorName = attr.curatorName ?? ""
        self.description = attr.description?.short ?? ""
        self.authorId = resource.id
        
        // apple decided to use cc instead of bb with playlist images, god knows why
        if let urlstr = attr.artwork?.url.replacingOccurrences(of: "{w}x{h}cc", with: "640x640cc"), let url = URL(string: urlstr) {
            self.imageURL = url
        }
        self.playlistId = attr.playParams.id
        self.playlistUri = ""
    }
    
    init?(from playlist: ApplePlaylist?) {
        guard let playlist = playlist else { return nil }
        self.playlistId = playlist.id
        self.name = playlist.attributes?.name ?? ""
        self.authorName = ""
        if let urlStr = playlist.attributes?.artwork?.url {
            let url = urlStr.replacingOccurrences(of: "{w}x{h}bb", with: "640x640bb")
            self.imageURL = URL(string: url)
        } else {
            imageURL = nil
        }
        self.description = playlist.attributes?.description?.standard ?? ""
        self.authorId = ""
        self.playlistUri = ""
    }
}
