//
//  ViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/6/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit

enum JSError: Error {
    case uploadBlobFailed(String)
}

class ViewController: UIViewController, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var webView: WKWebView!

    var requestId = 0
    var callbacksByRequestId: [Int: (Any?, Any?) -> Void] = [:]
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        let body = message.body as! NSDictionary
        print("body: \(body)")
        let method = body["method"]! as! String
        switch method {
        case "loaded":
            // TODO: handle this, e.g. by delaying all actual calls until loaded
            print("IPFS ready")
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
    
    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // TODO: Does it make sense?
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // TODO: Use edited image?
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.uploadBlob(data: image.jpegData(compressionQuality: 0.8)!, callback: { error, hash in
            if let hash = hash {
                print("Uploaded image: \(hash)")
                self.postVideo(hash: hash, callback: { error in
                    if let error = error {
                        print("Error posting to Near: \(error)")
                        return
                    }
                    print("postVideo success")
                })
            } else {
                print("Error: \(error ?? JSError.uploadBlobFailed("missing hash"))")
            }
        })
        // TODO: Does it make sense?
        self.dismiss(animated: true, completion: nil)
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

    func postVideo(hash: String, callback: @escaping (Error?) -> Void) {
        requestId = requestId + 1
        webView.evaluateJavaScript("postVideo(\(requestId), '\(hash)')")
        callbacksByRequestId[requestId] = { error, response in
            if let error = error as? String {
                callback(JSError.uploadBlobFailed(error))
            } else {
                callback(nil)
            }
        }
    }

}

