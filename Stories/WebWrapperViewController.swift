//
//  WebWrapperViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/6/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit

enum JSError: Error {
    case uploadBlobFailed(String)
    case postItemFailed(String)
    case getRecentItemsFailed(String)
    case downloadBlobFailed(String)
}

extension NSNotification.Name {
    static let DidUpdateLoadedItems = Notification.Name("DidUpdateLoadedItems")
}

class WebWrapperViewController: UIViewController, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static var webWrapper: WebWrapperViewController?

    var webView: WKWebView!

    var requestId = 0
    var callbacksByRequestId: [Int: (Any?, Any?) -> Void] = [:]
    var recentItems: [Content] = []

    var loadedItems: Set<Content> = []

    // var callbacksOnLoaded: [() -> Void] = []

    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    // TODO: Should this use cache dir? Document dir only for own blobs?
    lazy var blobsUrl = self.documentsUrl.appendingPathComponent("blobs")

    lazy var loadRecentTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
        self.loadRecentItems()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        let body = message.body as! NSDictionary
        print("body: \(body.description.prefix(500))")
        let method = body["method"]! as! String
        switch method {
        case "loaded":
            print("Web wrapper ready")
            self.seedDownloadedBlobs()
            self.loadRecentTimer.fire()
            /*
            while callbacksOnLoaded.count > 0 {
                callbacksOnLoaded.popLast()!()
            }
            */
        default:
            let requestId = body["id"]! as! Int
            let response = body["response"]
            let error = body["error"]
            let callback = callbacksByRequestId.removeValue(forKey: requestId)!
            callback(error, response)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        WebWrapperViewController.webWrapper = self

        NotificationCenter.default.addObserver(self, selector: #selector(photoTaken(_:)), name: .DidSelectPhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoTaken(_:)), name: .DidSelectVideo, object: nil)

        let contentController = WKUserContentController()
        contentController.add(self, name: "callback")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: CGRect.zero, configuration: config)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.view.subviews.contains(webView) {
            self.view.addSubview(webView)
        }

        webView.evaluateJavaScript("isLoaded", completionHandler: { (isLoaded, error) in
            if isLoaded == nil {
                let webUrl = Bundle.main.bundleURL.appendingPathComponent("web/")
                self.webView.loadFileURL(webUrl.appendingPathComponent("index.html"),
                                    allowingReadAccessTo: webUrl)
            }
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.loadRecentTimer.invalidate()
    }

    @objc func photoTaken(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let image = notification.object as! UIImage
            let data = image.jpegData(compressionQuality: 0.8)!
            self.uploadBlob(data: data, callback: { error, hash in
                self.uploadedBlob(error: error, type: "image", hash: hash)
                if let hash = hash {
                    self.saveBlob(type: "image", hash: hash, blob: data)
                }
            })
        }
    }

    @objc func videoTaken(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let videoURL = notification.object as! URL
            do {
                let data = try Data.init(contentsOf: videoURL)
                self.uploadBlob(data: data, callback: { error, hash in
                    self.uploadedBlob(error: error, type: "video", hash: hash)
                    if let hash = hash {
                        self.saveBlob(type: "video", hash: hash, blob: data)
                    }
                })
            } catch {
                print("Unexpected error: \(error)")
            }
        }
    }

    func uploadedBlob(error: Error?, type: String?, hash: String?) {
        if let hash = hash, let type = type {
            print("Uploaded blob: \(hash)")
            self.postItem(type: type, hash: hash, callback: { error in
                if let error = error {
                    print("Error posting to Near: \(error)")
                    return
                }
                print("postVideo success")
            })
        } else {
            print("Error: \(error ?? JSError.uploadBlobFailed("missing hash"))")
        }
    }

    func uploadBlob(data: Data, callback: @escaping (Error?, String?) -> Void) {
        let base64String = data.base64EncodedString()
        requestId = requestId + 1
        webView.evaluateJavaScript("uploadBlob(\(requestId), '\(base64String)')")
        callbacksByRequestId[requestId] = { error, response in
            if let dataDict = response as? NSDictionary, let hash = dataDict["hash"] as? String {
                callback(nil, hash)
            } else if let error = error as? String {
                callback(JSError.uploadBlobFailed(error), nil)
            } else {
                callback(JSError.uploadBlobFailed("Missing response"), nil)
            }
        }
    }

    func postItem(type: String, hash: String, callback: @escaping (Error?) -> Void) {
        requestId = requestId + 1
        webView.evaluateJavaScript("postItem(\(requestId), '\(type)', '\(hash)')")
        callbacksByRequestId[requestId] = { error, response in
            if let error = error as? String {
                callback(JSError.postItemFailed(error))
            } else {
                callback(nil)
            }
        }
    }

    func getRecentItems(callback: @escaping (Error?, [Content]?) -> Void) {
        requestId = requestId + 1
        webView.evaluateJavaScript("getRecentItems(\(requestId))")
        callbacksByRequestId[requestId] = { error, response in
            if let error = error as? String {
                callback(JSError.getRecentItemsFailed(error), nil)
            } else {
                callback(nil, (response as! NSArray).map { Content(element: $0 as! [String : Any]) })
            }
        }
    }

    func saveBlob(type: String, hash: String, blob: Data) {
        do {
            let itemBlobUrl = self.blobsUrl
                .appendingPathComponent(hash)
                .appendingPathExtension(type == "image" ? "jpg" : "mp4")
            print("Saving blob \(hash) to \(itemBlobUrl)")
            try blob.write(to: itemBlobUrl, options: .atomicWrite)
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    func seedDownloadedBlobs() {
        do {
            let fileManager = FileManager.default
            let blobPaths = try fileManager.contentsOfDirectory(atPath: self.blobsUrl.path)
            for path in blobPaths {
                DispatchQueue.global(qos: .background).async {
                    do {
                        let blob = try Data.init(contentsOf: self.blobsUrl.appendingPathComponent(path))
                        DispatchQueue.main.async {
                            self.uploadBlob(data: blob, callback: { (error, hash) in
                                if let error = error {
                                    print("Error seeding: \(error)")
                                } else {
                                    print("Seeding \(hash!)")
                                }
                            })
                        }
                    } catch {
                        print("Unexpected error: \(error)")
                    }
                }
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }

    func loadRecentItems() {
        print("Loading recent items")
        getRecentItems { (error, content) in
            if let error = error {
                print("Error loading recent items: \(error)")
                return
            }
            self.recentItems = content!

            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: self.blobsUrl.path) {
                do {
                    try fileManager.createDirectory(at: self.blobsUrl, withIntermediateDirectories: false)
                } catch {
                    print("Unexpected error: \(error)")
                }
            }

            for item in self.recentItems {
                let itemBlobUrl = self.blobsUrl
                    .appendingPathComponent(item.contentHash)
                    .appendingPathExtension(item.type == "image" ? "jpg" : "mp4")
                if !fileManager.fileExists(atPath: itemBlobUrl.path) {
                    print("Downloading: \(item.contentHash)")
                    // TODO: Check if already downloading and short-circuit
                    self.downloadBlob(hash: item.contentHash, callback: { (error, blob) in
                        print("Downloaded: \(item.contentHash)")
                        self.saveBlob(type: item.type, hash: item.contentHash, blob: blob!)
                        item.url = itemBlobUrl.absoluteString
                        self.loadedItems.update(with: item)
                        NotificationCenter.default.post(name: NSNotification.Name.DidUpdateLoadedItems, object: self.loadedItems)
                    })
                } else {
                    print("Already downloaded: \(item.contentHash)")
                    item.url = itemBlobUrl.absoluteString
                    self.loadedItems.update(with: item)
                    NotificationCenter.default.post(name: NSNotification.Name.DidUpdateLoadedItems, object: self.loadedItems)
                }
            }
        }
    }

    func downloadBlob(hash: String, callback: @escaping (Error?, Data?) -> Void) {
        requestId = requestId + 1
        webView.evaluateJavaScript("downloadBlob(\(requestId), '\(hash)')")
        callbacksByRequestId[requestId] = { error, response in
            if let error = error as? String {
                callback(JSError.downloadBlobFailed(error), nil)
            } else {
                callback(nil, Data.init(base64Encoded: (response as! String))!)
            }
        }
    }
}

