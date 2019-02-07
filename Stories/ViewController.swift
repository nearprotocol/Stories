//
//  ViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/6/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        
        let body = message.body as! NSDictionary
        let method = body["method"]! as! String
        if method == "loaded" {
            let base64String = "Hello, World".data(using: .utf8)!.base64EncodedString()
            webView.evaluateJavaScript("uploadBlob('myBlob', '\(base64String)')")
        }
        
        print("body: \(body)")
    }
    
    var webView: WKWebView!

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
            webView = WKWebView(frame: self.view.bounds, configuration: config)
            self.view.addSubview(webView)
            
            let webUrl = Bundle.main.bundleURL.appendingPathComponent("browser-add-readable-stream/")
            webView.loadFileURL(webUrl.appendingPathComponent("index.html"),
                                allowingReadAccessTo: webUrl)
        } catch {
            print(error)
        }
    }
}

