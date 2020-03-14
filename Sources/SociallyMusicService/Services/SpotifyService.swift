//
//  SpotifyService.swift
//  SociallyMusicService
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import Foundation

/// Hosting service for Spotify service calls
public class SpotifyService: MusicService {
    
    private let baseURL = URL(string: "https://api.spotify.com/v1/")!
    private var token: String?
    
    /// Initializer for the Spotify Service
    public override init() {}
    
    /// Sets the token to the new access token give
    /// - Parameter accessToken: The new token value to update to
    public func setToken(accessToken: String) {
        self.token = accessToken
    }
    
    /// Takes in an authorization code received and returns back the token object
    /// - Parameters:
    ///   - code: The authorization code for the user
    ///   - redirectURL: The application's redirect url
    ///   - clientID: The application's client id
    ///   - clientSecret: The application's client id
    ///   - completion: completion handler returning the token object or error
    public func authRequest(code: String, redirectURL: URL, clientID: String, clientSecret: String, result: @escaping (Result<TokenObject, APIServiceError>) -> Void) {
        let requestBody = "code=\(code)&grant_type=authorization_code&redirect_uri=\(redirectURL.absoluteString)"
        guard let authString = "\(clientID):\(clientSecret)".data(using: .ascii)?.base64EncodedString(options: .endLineWithLineFeed) else {
            result(.failure(.invalidCompiledURL))
            return
        }
        let endpoint = URL(string: "https://accounts.spotify.com/api/token")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        urlRequest.httpMethod = "POST"
        
        let authHeaderValue = "Basic \(authString)"
        urlRequest.addValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = requestBody.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data, _, error) in
            if let data = data,
                let authResponse = try? JSONDecoder().decode(TokenObject.self, from: data), error == nil {
                result(.success(authResponse))
            } else {
                result(.failure(.apiError))
            }
        })
        task.resume()
    }
    
    /// Takes the refresh token and the encrypted client secret,a nd returns access token
    /// - Parameters:
    ///   - refreshToken: the refresh token for the user
    ///   - clientSecretEncrypted: the encrypted client secret
    ///   - result: completion handler returning the token object or error
    public func updateToken(refreshToken: String, clientSecretEncrypted: String, result: @escaping (Result<String, APIServiceError>) -> Void) {
        var url = URLComponents(string: "https://accounts.spotify.com/api/token")
        //Add body
        let params: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        url?.queryItems = params
        var urlreq = URLRequest(url: (url?.url)!)
        //Add header
        urlreq.setValue("Basic " + clientSecretEncrypted, forHTTPHeaderField: "Authorization")
        urlreq.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        urlreq.httpMethod = "POST"
        
        //Make call
        urlSession.dataTask(with: urlreq) { (resultVal: Result<(URLResponse, Data), Error> ) in
            switch resultVal {
            case .success(let (response, data)):
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    result(.failure(.apiError))
                    return
                }
                do {
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    guard let token = json?["access_token"] as? String else {
                        result(.failure(.apiError))
                        return
                    }
                    result(.success(token))
                }
            case .failure:
                result(.failure(.apiError))
            }
        }.resume()
    }
    
    /// Returns the playlists for the current token
    /// - Parameter result: completion handler returning the array of playlists or error
    public func getPlaylists(result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        var arr = [Playlist]()
        var url: URL?
        let group = DispatchGroup()
        var shouldContinue = true
        while shouldContinue {
            group.enter()
            getMyPlaylists(url: url) { (actResult: Result<PagingObject<Playlist>, APIServiceError>) in
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
    
    /// Given a Spotify user, returns their public playlists
    /// - Parameters:
    ///   - userId: The Spotify id for the user
    ///   - limit: How many playlists to get, default of 20, max of 50
    ///   - offset: Where to start the playlist count
    ///   - result: The completion handler
    public func getUserPlaylists(of userId: String, limit: Int = 20, offset: Int = 0, result: @escaping (Result<[SociallyPlaylist], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("users/\(userId)/playlists").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq) { (resultVal: Result<PagingObject<Playlist>, APIServiceError>) in
            switch resultVal {
            case .failure(let err):
                result(.failure(err))
            case .success(let pagingObject):
                result(.success(pagingObject.items.map({SociallyPlaylist(from: $0)})))
            }
        }
    }
    
    /// Adds the given context of a track to the playlist
    /// - Parameters:
    ///   - playlistId: The playlist id to add to
    ///   - track: the track context ot be added
    ///   - result: completion handler returning the result
    public func addToPlaylist(playlistId: String, track: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
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
        fetchResources(request: urlreq, result: result)
    }
    
    /// Deletes a track from the playlist
    /// - Parameters:
    ///   - playlistId: The id of the playlist
    ///   - trackId: The id of the track
    ///   - result: completion handler returning the result
    public func deleteFromPlaylist(_ playlistId: String, trackId: String, result: @escaping (Result<[String: String], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
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
        fetchResources(request: urlreq, result: result)
    }
    
    /// Fetch the users top artists from Spotify given the parameters
    /// - Parameters:
    ///   - limit: How many tracks to fetch
    ///   - offset: The offset from the beginning
    ///   - timeRange: How long of time to consider
    ///   - result: completion handler returning the result
    public func fetchTopArtists(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .longTerm, result: @escaping (Result<[SociallyArtist], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/artists").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq) { (resultVal: Result<PagingObject<Artist>, APIServiceError>) in
            switch resultVal {
            case .failure(let err):
                result(.failure(err))
            case .success(let pagingObject):
                result(.success(pagingObject.items.map({SociallyArtist(from: $0)})))
            }
        }
    }
    
    /// Fetch the users top tracks from Spotify given the parameters
    /// - Parameters:
    ///   - limit: How many tracks to fetch
    ///   - offset: The offset from the beginning
    ///   - timeRange: How long of time to consider
    ///   - result: completion handler returning the result
    public func fetchTopSongs(limit: Int = 20, offset: Int = 0, timeRange: TimeRange = .mediumTerm, result: @escaping (Result<[SociallyTrack], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        let params: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "time_range", value: timeRange.rawValue)
        ]
        
        var component = URLComponents(string: baseURL.appendingPathComponent("me/top/tracks").absoluteString)
        component?.queryItems = params
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq) { (resultVal: Result<PagingObject<TrackItem>, APIServiceError>) in
            switch resultVal {
            case .failure(let err):
                result(.failure(err))
            case .success(let pagingObject):
                result(.success(pagingObject.items.map({SociallyTrack(from: $0)})))
            }
        }
    }
    
    /// Fetches the last 10 played tracks for the user
    /// - Parameters:
    ///   - result: completion handler returning the result
    public func fetchRecentlyPlayed(result: @escaping (Result<[SociallyTrack], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        let limit = 10
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
        fetchResources(request: urlreq) { (resultVal: Result<PagingObject<PlayHistoryObject>, APIServiceError>) in
            switch resultVal {
            case .failure(let error):
                result(.failure(error))
            case .success(let pagingObject):
                let ids = pagingObject.items.map { $0.track.id }
                self.getMultipleTracksInfo(ids: ids) { (tracks) in
                    switch tracks {
                    case .success(let trackList):
                        result(.success(trackList))
                    case .failure(let error):
                        result(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Fetches track the current user is listening to
    /// - Parameter completion: completion handler returning the result
    public func fetchCurrentTrack(result: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        //Get proper URL
        let url = baseURL.appendingPathComponent("me/player/currently-playing")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        //Make the call
        fetchResources(request: request) { (resultVal: Result<TrackResult, APIServiceError>) in
            switch resultVal {
            case .success(let trackResult):
                let track = SociallyTrack(album: trackResult.item.album.name, artist: trackResult.item.artists[0].name, name: trackResult.item.name, isrc: trackResult.item.externalIds?.isrc ?? "", context: trackResult.item.uri, imageURL: trackResult.item.album.images?[0].url.absoluteString ?? "")
                result(.success(track))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// Fetches the Spotify user for the current token
    /// - Parameter result: completion handler for this call
    public func fetchCurrentUserId(result: @escaping (Result<String, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        //Get proper URL
        let url = baseURL.appendingPathComponent("me")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        //Make the call
        fetchResources(request: request) { (resultVal: Result<UserResult, APIServiceError>) in
            switch resultVal {
            case .success(let user):
                result(.success(user.id))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// Takes an ISRC and returns back the track information
    /// - Parameters:
    ///   - isrc: the ISRC for a track
    ///   - result: completion handler returning the contextt
    public func searchByISRC(isrc: String, result: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        var component = URLComponents(string: baseURL.appendingPathComponent("search").absoluteString)
        
        component?.queryItems = [
            URLQueryItem(name: "q", value: "isrc:\(isrc)"),
            URLQueryItem(name: "type", value: "track")
        ]
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: request) { (resultVal: Result<TrackPagingObject<TrackItem>, APIServiceError>) in
            switch resultVal {
            case .success(let pagingObj):
                if pagingObj.tracks.items.isEmpty {
                    result(.failure(.noData))
                    return
                }
                result(.success(SociallyTrack(from: pagingObj.tracks.items[0])))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// Takes an id and returns back the Spotify context for that track
    /// - Parameters:
    ///   - ids: the array of ids you'd like to get info on
    ///   - result: completion handler returning the contextt
    public func getMultipleTracksInfo(ids: [String], result: @escaping (Result<[SociallyTrack], APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        var component = URLComponents(string: baseURL.appendingPathComponent("tracks").absoluteString)
        
        component?.queryItems = [
            URLQueryItem(name: "ids", value: ids.joined(separator: ","))
        ]
        
        guard let url = component?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: request) { (resultVal: Result<TrackItemList, APIServiceError>) in
            switch resultVal {
            case .success(let list):
                result(.success(list.tracks.map({SociallyTrack(from: $0)})))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// Takes an id and returns back the Spotify context for that track
    /// - Parameters:
    ///   - id: the id for a track
    ///   - result: completion handler returning the context
    public func getTrackInfo(id: String, result: @escaping (Result<SociallyTrack, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        let component = URLComponents(string: baseURL.appendingPathComponent("tracks/\(id)").absoluteString)
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        
        var request = URLRequest(url: finURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: request) { (resultVal: Result<TrackItem, APIServiceError>) in
            switch resultVal {
            case .success(let track):
                result(.success(SociallyTrack(from: track)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// Returns all the tracks for a playlist given the id
    /// - Parameters:
    ///   - playlistId: The id of the playlist
    ///   - result: The completion handler result containing the array of tracks or error
    public func getAllTracksForPlaylist(_ playlistId: String, result: @escaping (Result<[SociallyTrack], APIServiceError>) -> Void) {
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
                    result(.failure(.invalidResponse))
                }
                group.leave()
            }
            group.wait()
        }
    }
}

// MARK: Helpers
extension SpotifyService {
    
    private func getMyPlaylists(limit: Int = 50, offset: Int = 0, url: URL? = nil, result: @escaping (Result<PagingObject<Playlist>, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        if let url = url {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            fetchResources(request: request, result: result)
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
        fetchResources(request: urlreq, result: result)
    }
    
    private func getTracksForPlaylist(_ playlistId: String, url: URL?, result: @escaping (Result<PagingObject<PlaylistTrack>, APIServiceError>) -> Void) {
        guard let token = token else {
            result(.failure(.tokenNilError))
            return
        }
        
        if let url = url {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            fetchResources(request: request, result: result)
            return
        }
        
        let component = URLComponents(string: baseURL.appendingPathComponent("playlists/\(playlistId)/tracks").absoluteString)
        
        guard let finURL = component?.url else {
            result(.failure(.invalidCompiledURL))
            return
        }
        var urlreq = URLRequest(url: finURL)
        urlreq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        fetchResources(request: urlreq, result: result)
    }
}
