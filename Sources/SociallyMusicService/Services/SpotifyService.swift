//
//  SpotifyService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

public class SpotifyService: MusicService {
    
    private let baseURL = URL(string: "https://api.spotify.com/v1/")!
    private var token: String
    
    public init(token: String) {
        self.token = token
    }
    
    public func searchByISRC(isrc: String, completion: @escaping (String) -> Void) {
        var component = URLComponents(string: baseURL.appendingPathComponent("search").absoluteString)
        
        component?.queryItems = [
            URLQueryItem(name: "q", value: "isrc:\(isrc)"),
            URLQueryItem(name: "type", value: "track")
        ]
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: request) { (result: Result<TrackPagingObject<TrackItem>, APIServiceError>) in
            switch result {
            case .success(let pagingObj):
                completion(pagingObj.tracks.items[0].uri)
            case .failure:
                completion("")
            }
        }
    }
    
    public func getPlaylists(result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        var arr = [Playlist]()
        var url: URL?
        let group = DispatchGroup()
        var shouldContinue = true
        while shouldContinue {
            group.enter()
            getPlaylists(url: url) { (actResult: Result<PagingObject<Playlist>, APIServiceError>) in
                switch actResult {
                case .success(let pagingObj):
                    arr += pagingObj.items
                    if let nextUrl = pagingObj.nextUrl {
                        url = nextUrl
                    } else {
                        shouldContinue = false
                        result(.success(arr.map({SociallyPlaylist(from: $0)})))
                    }
                case .failure:
                    shouldContinue = false
                    result(.failure(.invalidResponse))
                }
                group.leave()
            }
            group.wait()
        }
    }
    
    public func addToPlaylist(playlistId: String, track: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "uris", value: "\(track)")
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        
        var urlreq = URLRequest(url: finURL)
        urlreq.httpMethod = "POST"
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, completion: result)
    }
    
    public func deleteFromPlaylist(_ playlistId: String, trackId: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "tracks", value: "\([["uri": trackId]])")
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(APIServiceError.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, completion: result)
    }
    
    public func fetchTopArtists(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .longTerm, completion: @escaping (Result<[SociallyArtist], APIServiceError>) -> Void) {
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/artists").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            completion(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq) { (result: Result<PagingObject<Artist>, APIServiceError>) in
            switch result {
            case .failure(let err):
                print("Failed getting results \(err)")
            case .success(let pagingObject):
                completion(.success(pagingObject.items.map({SociallyArtist(from: $0)})))
            }
        }
    }
    
    public func fetchTopSongs(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .mediumTerm, completion: @escaping (Result<[SociallyTrack], APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/tracks").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            completion(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq) { (result: Result<PagingObject<TrackItem>, APIServiceError>) in
            switch result {
            case .failure(let err):
                print("Failed getting results \(err)")
            case .success(let pagingObject):
                completion(.success(pagingObject.items.map({SociallyTrack(from: $0)})))
            }
        }
    }
    
    public func fetchRecentlyPlayed(limit: Int = 10, result: @escaping (Result<PagingObject<SociallyTrack>, APIServiceError>) -> Void) {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/player/recently-played").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, completion: result)
    }
    
    public func fetchCurrentTrack(completion: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        //Get proper URL
        let url = baseURL.appendingPathComponent("me/player/currently-playing")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        //Make the call
        fetchResources(request: request) { (result: Result<TrackResult, APIServiceError>) in
            switch result {
            case .success(let trackResult):
                let track = SociallyTrack(album: trackResult.item.album.name, artist: trackResult.item.artists[0].name, name: trackResult.item.name, isrc: trackResult.item.externalIds?.isrc ?? "", context: trackResult.item.uri, imageURL: trackResult.item.album.images?[0].url.absoluteString ?? "")
                completion(.success(track))
            case .failure:
                completion(.failure(.apiError))
            }
        }
    }
}

// MARK: Helpers
extension SpotifyService {
    
    private func getPlaylists(userId: String? = nil, limit: Int = 50, offset: Int = 0, url: URL? = nil, result: @escaping (Result<PagingObject<Playlist>, APIServiceError>) -> Void) {
        
        if let url = url {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            fetchResources(request: request, completion: result)
            return
        }
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/playlists").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, completion: result)
    }
    
    private func getTracksForPlaylist(_ playlistId: String, url: URL?, result: @escaping (Result<PagingObject<PlaylistTrack>, APIServiceError>) -> Void) {
        if let url = url {
            fetchResources(request: URLRequest(url: url), completion: result)
            return
        }
        
        let component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, completion: result)
    }
    
    private func getAllTracksForPlaylist(_ playlistId: String, result: @escaping (Result<[SociallyTrack], Error>) -> Void) {
        var arr = [TrackItem]()
        var url: URL?
        let group = DispatchGroup()
        var shouldContinue = true
        
        while shouldContinue {
            group.enter()
            getTracksForPlaylist(playlistId, url: url) { (actResult) in
                switch actResult {
                case .success(let pagObj):
                    arr += pagObj.items.compactMap({$0.track})
                    if let nextUrl = pagObj.nextUrl {
                        url = nextUrl
                    } else {
                        shouldContinue = false
                        result(.success(arr.map({SociallyTrack(from: $0)})))
                    }
                case .failure:
                    shouldContinue = false
                    result(.failure(APIServiceError.invalidResponse))
                }
                group.leave()
            }
            group.wait()
        }
    }
}
