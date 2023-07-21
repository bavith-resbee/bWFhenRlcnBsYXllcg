//
//  MaazterDownloaderModule.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 09/08/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation

@objc(MaazterDownloader)
class MaazterDownloader: RCTEventEmitter {

    @objc
    override static func requiresMainQueueSetup() -> Bool {
        true
    }

    override func supportedEvents() -> [String]! {
        return ["onDownloadChanged", "onDownloadRemoved", "onIdle"]
    }

    @objc
    func add(_ contentUri: String, encKey: String?, quality: String, data: String?, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("E_NOT_IMPLEMENTED", "Not Implemented", NSError(domain: "", code: 200, userInfo: nil))
    }

    @objc
    func remove(_ contentId: String) {

    }

    @objc
    func pause(_ contentId: String, reason: Int = 1) {

    }

    @objc
    func pauseAll() {

    }

    @objc
    func resume(_ contentId: String) {

    }

    @objc
    func resumeAll() {

    }

    @objc
    func getTracks(_ contentUri: String, encKey: String?, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        reject("E_NOT_IMPLEMENTED", "Not Implemented", NSError(domain: "", code: 200, userInfo: nil))
    }

    @objc
    func listDownloads(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {

    }
}
