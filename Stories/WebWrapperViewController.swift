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

class WebWrapperViewController: UIViewController, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static var webWrapper: WebWrapperViewController?

    var webView: WKWebView!

    var requestId = 0
    var callbacksByRequestId: [Int: (Any?, Any?) -> Void] = [:]
    var recentItems: [Content] = []
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        let body = message.body as! NSDictionary
        print("body: \(body)")
        let method = body["method"]! as! String
        switch method {
        case "loaded":
            print("Web wrapper ready")
            loadRecentItems()
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
        self.view.addSubview(webView)

        let webUrl = Bundle.main.bundleURL.appendingPathComponent("web/")
        webView.loadFileURL(webUrl.appendingPathComponent("index.html"),
                            allowingReadAccessTo: webUrl)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func photoTaken(_ notification: Notification) {
        let image = notification.object as! UIImage
        self.uploadBlob(data: image.jpegData(compressionQuality: 0.8)!, callback: { error, hash in
            self.uploadedBlob(error: error, type: "image", hash: hash)
        })
    }

    @objc func videoTaken(_ notification: Notification) {
        let videoURL = notification.object as! URL
        do {
            let data = try Data.init(contentsOf: videoURL)
            self.uploadBlob(data: data, callback: { error, hash in
                self.uploadedBlob(error: error, type: "video", hash: hash)
            })
        } catch {
            print("Unexpected error: \(error)")
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
            if let dataDict = response as? NSDictionary {
                callback(nil, dataDict["hash"] as? String)
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

    func loadRecentItems() {
        getRecentItems { (error, content) in
            if let error = error {
                print("Error loading recent items: \(error)")
                return
            }
            self.recentItems = content!

            let fileManager = FileManager.default
            // TODO: Should this use cache dir? Document dir only for own blobs?
            let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let blobUrl = documentsUrl.appendingPathComponent("blobs")
            if !fileManager.fileExists(atPath: blobUrl.path) {
                do {
                    try fileManager.createDirectory(at: blobUrl, withIntermediateDirectories: false)
                } catch {
                    print("Unexpected error: \(error)")
                }
            }

            for item in self.recentItems {
                let itemBlobUrl = blobUrl.appendingPathComponent(item.hash)
                if fileManager.fileExists(atPath: itemBlobUrl.path) {
                    print("Downloading: \(item.hash)")
                    self.downloadBlob(hash: item.hash, callback: { (error, blob) in
                        blob!.write(to: itemBlobUrl, atomically: true)
                        print("Downloaded: \(item.hash)")
                    })
                } else {
                    print("Already downloaded: \(item.hash)")
                }
            }
        }
    }

    func downloadBlob(hash: String, callback: @escaping (Error?, NSData?) -> Void) {
        requestId = requestId + 1
        webView.evaluateJavaScript("downloadBlob(\(requestId), '\(hash)')")
        callbacksByRequestId[requestId] = { error, response in
            if let error = error as? String {
                callback(JSError.downloadBlobFailed(error), nil)
            } else {
                callback(nil, NSData.init(base64Encoded: (response as! String))!)
            }
        }
    }
}

