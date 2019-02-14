//
//  ContainerViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/14/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)

        let cameraController = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
        self.addChild(cameraController)
        self.view.addSubview(cameraController.view)
        cameraController.view.frame = self.view.bounds
        cameraController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let webWrapperController = storyboard.instantiateViewController(withIdentifier: "WebWrapper")
        self.addChild(webWrapperController)
        self.view.addSubview(webWrapperController.view)
        webWrapperController.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
}
