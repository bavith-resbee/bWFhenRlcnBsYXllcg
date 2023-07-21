//
//  PlayerResourceLoaderDelegate.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 23/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation
import AVFoundation

class PlayerResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let scheme = "mp-proto"
    private let encKeyURL = "mp-proto://key.provider.custom/enc.key"
    
    private var encKey: String
    private var url: URL

    public var qualities: Array<Quality> = []
    
    init(url: URL, encKey: String) {
        self.url = url
        self.encKey = encKey
    }
    
    func getInitialURL() -> URL {
        var u = URLComponents(url: url, resolvingAgainstBaseURL: true)
        u?.scheme = self.scheme
        return (u?.url)!
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                                 shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

        let requestedUrl = loadingRequest.request.url?.absoluteString;
        
        if requestedUrl == encKeyURL {
            let data = Data(encKey.utf8)
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()
            return true;
        }
        
        let url = URL(string: (requestedUrl!.replacingOccurrences(of: scheme, with: "https")))!
        
        print(url.absoluteString)

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard var data = data else { return }
            
            if (loadingRequest.isCancelled) {
                return;
            }
            
            if (loadingRequest.request.url?.pathExtension == "m3u8") {
                var m3u8 = String(data: data, encoding: .utf8)?.split(whereSeparator: \.isNewline).map { str -> Array<String> in
                    String(str).split(separator: ":", maxSplits: 1).map(String.init)
                }
                
                if (m3u8 != nil) {
                    for (index, item) in m3u8!.enumerated() {
                        let tag = item[0]
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .uppercased()
                        
                        switch(tag) {
                        case "#EXT-X-STREAM-INF":
                            let url = m3u8![index + 1][0]
                            if (url.starts(with: "http") && !url.starts(with: "#")) {
                                var u = URLComponents(string: url)
                                u?.scheme = self.scheme
                                m3u8![index + 1][0] = u?.url!.absoluteString ?? url
                            }

                            let attributes = item[1].split(separator: ",")
                            attributes.forEach { attribute in
                                let v = attribute.split(separator: "=")
                                if (v[0] == "RESOLUTION") {
                                    let res = v[1].split(separator: "x").map({i in Int(i) ?? 0})
                                    self.qualities.append(Quality(width: res[0], height: res[1]))
                                }
                            }
                            
                        case "#EXTINF":
                            let url = m3u8![index + 1][0]
                            if (!url.starts(with: "http") && !url.starts(with: "#")) {
                                let newUrl = URLComponents(string: url)?.url(relativeTo: response?.url)?.absoluteString
                                m3u8![index + 1][0] = newUrl!
                            }
                            
                        case "#EXT-X-KEY":
                            var attributes = item[1]
                                .split(separator: ",")
                                .map(String.init)
                            
                            for (index, item) in attributes.enumerated() {
                                let attribute = item.split(separator: "=", maxSplits: 1).map(String.init)
                                let key = attribute[0]
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .uppercased()
                                
                                if (key == "URI") {
                                    attributes[index] = "URI=\"" + self.encKeyURL + "\""
                                }
                            }
                            m3u8![index] = ["#EXT-X-KEY", String(attributes.joined(separator: ","))]
                        default: break
                        }
                    }
                }

                let m3u8String = m3u8?.map { item -> String in String(item.joined(separator: ":")) }.joined(separator: "\n").utf8
                data = Data(m3u8String!)
            }
            
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()
        }

        task.resume()
      
        return true
    }
}
