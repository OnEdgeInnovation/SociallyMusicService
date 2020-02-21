//
//  AppleMusicService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

/// Hosting service for Apple Music  service calls
public class AppleMusicService: MusicService {
    
    private let baseURL = URL(string: "https://api.music.apple.com/v1/")!
    
    private var userToken: String
    private var devToken: String
    
    public init(devToken: String, userToken: String = "") {
        self.devToken = devToken
        self.userToken = userToken
    }
    
    /// Returns the playlists for the current token
    /// - Parameter result: completion handler returning the array of playlists or error
    public func getPlaylists(result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/library/playlists").absoluteString)
        
        guard let url = component?.url else { return }
        component?.queryItems = [
            URLQueryItem(name: "limit", value: "100")
        ]
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        fetchResources(request: request) { (resultVal: Result<ResponseRoot<ApplePlaylist>, APIServiceError>) in
            switch resultVal {
            case .success(let playlist):
                guard let playlists = playlist.data else {
                    result(.failure(APIServiceError.noData))
                    return
                }
                let ret = playlists.map({SociallyPlaylist(from: $0)})
                result(.success(ret))
            case .failure:
                result(.failure(.apiError))
            }
        }
    }
    
    /// Adds the given context of a track to the playlist
    /// - Parameters:
    ///   - playlistId: The playlist id to add to
    ///   - track: the track context ot be added
    ///   - result: completion handler returning the result
    public func addToPlaylist(playlistId: String, track: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        
        let component = URLComponents(string: baseURL.appendingPathComponent("me/library/playlists/\(playlistId)/tracks").absoluteString)
        
        guard let url = component?.url else { return }
        
        let body: [String: Any] = [
            "data": [["id": track, "type": "songs"]]]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            result(.failure(APIServiceError.invalidCompiledURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        sendRequestNoPayload(request: request) { (resultVal) in
            switch resultVal {
            case .success:
                result(.success([:]))
            case .failure(let err):
                result(.failure(err))
            }
        }
    }
    
    /// Takes an ISRC and returns back the track information
    /// - Parameters:
    ///   - isrc: the ISRC for a track
    ///   - result: completion handler returning the contextt
    public func searchByISRC(isrc: String, countryCode: String = "us", result: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        var component = URLComponents(string: baseURL.appendingPathComponent("catalog/\(countryCode)/songs").absoluteString)
        
        component?.queryItems = [
            URLQueryItem(name: "filter[isrc]", value: isrc)
        ]
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        
        fetchResources(request: request) { (resultVal: Result<ResponseRoot<Track>, APIServiceError>) in
            switch resultVal {
            case .success(let track):
                guard track.data?.count ?? 0 > 0, let track = track.data?[0], let trackAtt = track.attributes else {
                    result(.failure(.noData))
                    return
                }
                let sociallyTrack = SociallyTrack(album: trackAtt.albumName, artist: trackAtt.artistName, name: trackAtt.name, isrc: trackAtt.name, context: track.id, imageURL: trackAtt.artwork.url)
                result(.success(sociallyTrack))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    
    /// Fetch tracks for a given playlist
    /// - Parameters:
    ///   - playlist: the playlist to fetch tracks for
    ///   - result: the completion handler containing the result of tracks or error
    public func getAllTracksForPlaylist(playlist: String, result: @escaping (Result<[SociallyTrack], Error>) -> Void) {
        
        let component = URLComponents(string: baseURL.appendingPathComponent("me/library/playlists/\(playlist)/tracks").absoluteString)
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        
        fetchResources(request: request) { (resultVal: Result<ResponseRoot<Track>, APIServiceError>) in
            switch resultVal {
            case .success(let playlist):
                guard !(playlist.data?.isEmpty ?? true), let tracks = playlist.data else {
                    result(.failure(APIServiceError.noData))
                    return
                }
                
                let SociallyTracks: [SociallyTrack] = tracks.compactMap { (track) -> SociallyTrack? in
                    
                    guard let attributes = track.attributes else { return nil }
                    var imageURL = attributes.artwork.url
                    imageURL = imageURL.replacingOccurrences(of: "{w}x{h}bb", with: "640x640bb")
                    let sociallyTrack = SociallyTrack(album: attributes.albumName, artist: attributes.artistName, name: attributes.name, isrc: attributes.isrc, context: attributes.url.absoluteString, imageURL: imageURL)
                    return sociallyTrack
                }
                
                result(.success(SociallyTracks))
            case .failure:
                result(.failure(APIServiceError.apiError))
            }
        }
    }
    
    /// Takes an id and returns back the Apple Music context for that track
    /// - Parameters:
    ///   - id: the id for a track
    ///   - result: completion handler returning the context
    public func getTrackInfo(id: String, result: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        let countryCode = "us"
        let component = URLComponents(string: baseURL.appendingPathComponent("catalog/\(countryCode)/songs/\(id)").absoluteString)
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        
        fetchResources(request: request) { (result: Result<ResponseRoot<Track>, APIServiceError>) in
            switch result {
            case .success(let track):
                guard let trackAttributes = track.data?[0].attributes else {
                    completion(.failure(.apiError))
                    return
                }
                var imageURL = trackAttributes.artwork.url
                imageURL = imageURL.replacingOccurrences(of: "{w}x{h}bb", with: "640x640bb")
                let sociallyTrack = SociallyTrack(album: trackAttributes.albumName, artist: trackAttributes.artistName, name: trackAttributes.name, isrc: trackAttributes.isrc, context: id, imageURL: imageURL)
                completion(.success(sociallyTrack))
            case .failure:
                completion(.failure(.apiError))
            }
        }
    }
}
