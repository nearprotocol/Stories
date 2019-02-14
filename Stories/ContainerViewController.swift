//
//  ContainerViewController.swift
//  Stories
//
//  Created by Vladimir Grichina on 2/14/19.
//  Copyright © 2019 NEAR Protocol. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {
    lazy var cameraController: CameraViewController = {
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        let cameraController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        return cameraController
    }()
    lazy var webWrapperController: WebWrapperViewController = {
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: "WebWrapper") as! WebWrapperViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addChild(cameraController)
        self.view.addSubview(cameraController.view)
        cameraController.view.frame = self.view.bounds
        cameraController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.addChild(self.webWrapperController)
        self.view.addSubview(self.webWrapperController.view)
        self.webWrapperController.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
}
