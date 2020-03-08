//
//  SociallyMusicServiceTests.swift
//  SociallyMusicServiceTests
//
//  Created by Zach McGuckin on 2/13/20.
//  Copyright © 2020 Zach McGuckin. All rights reserved.
//

import XCTest
@testable import SociallyMusicService

class SociallyMusicServiceTests: XCTestCase {
    let classToTest = AppleMusicService()
    override func setUp() {
        classToTest.setToken(devToken: "", userToken: "")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodableAppleLibraryTracks() {
        let expectation = XCTestExpectation(description: "Tracks are decodable from a playlist")
        classToTest.getAllTracksForPlaylist(playlist: "") { (result) in
            switch result {
            case .success(let tracks):
                print(tracks)
                expectation.fulfill()
            case .failure(let err):
                print(err)
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    func testTopArtists() {
        let expectation = XCTestExpectation(description: "Heavy rotation history is decodable")
        
        classToTest.getTopArtists { (result) in
            print(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTopTracks() {
           let expectation = XCTestExpectation(description: "Heavy rotation history is decodable")
           
           classToTest.getTopTracks { (result) in
               print(result)
               expectation.fulfill()
           }

           wait(for: [expectation], timeout: 20.0)
       }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
