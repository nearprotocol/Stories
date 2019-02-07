//
//  ViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/6/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var webView: WKWebView!
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        
        let body = message.body as! NSDictionary
        let method = body["method"]! as! String
        if method == "loaded" {
            uploadBlob(data: "Hello, World".data(using: .utf8)!)
        }
        
        print("body: \(body)")
    }
    

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        //
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let contentController = WKUserContentController()
            contentController.add(self, name: "callback")
            let config = WKWebViewConfiguration()
            config.userContentController = contentController
            webView = WKWebView(frame: CGRect.zero, configuration: config)
            self.view.addSubview(webView)
            
            let webUrl = Bundle.main.bundleURL.appendingPathComponent("browser-add-readable-stream/")
            webView.loadFileURL(webUrl.appendingPathComponent("index.html"),
                                allowingReadAccessTo: webUrl)
        } catch {
            print(error)
        }
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
        uploadBlob(data: image.jpegData(compressionQuality: 0.8)!)
        // TODO: Does it make sense?
        self.dismiss(animated: true, completion: nil)
    }

    func uploadBlob(data: Data) {
        let base64String = data.base64EncodedString()
        webView.evaluateJavaScript("uploadBlob('myBlob', '\(base64String)')")
    }
}

