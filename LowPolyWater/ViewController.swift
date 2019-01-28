//
//  ViewController.swift
//  LowPolyWater
//
//  Created by Teemu Harju on 27/01/2019.
//  Copyright © 2019 Teemu Harju. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var cellSizeSlider: UISlider!
    @IBOutlet weak var cellSizeValueLabel: UILabel!
    @IBOutlet weak var amplitudeSlider: UISlider!
    @IBOutlet weak var amplitudeValueLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var speedValueLabel: UILabel!

    private let waterMaterial = SCNMaterial()

    @IBAction func showTilesButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            switch button.state {
            case [.normal, .highlighted]:
                button.isSelected = true
                button.titleLabel?.text = "Hide Tiles"
                showTiles()
            case let states where states.contains(.selected):
                button.isSelected = false
                button.titleLabel?.text = "Show Tiles"
                hideTiles()
            default:
                break
            }
        }
    }

    @IBAction func cellSizeValueChanged(_ sender: Any) {
        waterMaterial.setValue(cellSizeSlider.value, forKey: "cellSize")
        cellSizeValueLabel.text = String(format: "%.2f", cellSizeSlider.value)
    }

    @IBAction func amplitudeValueChanged(_ sender: Any) {
        waterMaterial.setValue(amplitudeSlider.value, forKey: "amplitude")
        amplitudeValueLabel.text = String(format: "%.2f", amplitudeSlider.value)
    }

    @IBAction func speedValueChanged(_ sender: Any) {
        waterMaterial.setValue(speedSlider.value, forKey: "speed")
        speedValueLabel.text = String(format: "%.2f", speedSlider.value)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMaterial()

        initializeScene()

        cellSizeValueLabel.text = String(format: "%.2f", cellSizeSlider.value)
        amplitudeValueLabel.text = String(format: "%.2f", amplitudeSlider.value)
        speedValueLabel.text = String(format: "%.2f", speedSlider.value)

    }

    private func setupMaterial() {
        let waterShader = SCNProgram()
        waterShader.vertexFunctionName = "water_vertex"
        waterShader.fragmentFunctionName = "water_fragment"

        waterMaterial.program = waterShader

        waterMaterial.setValue(SCNVector3(x: 0.0, y: -1.0, z: 1.0), forKey: "lightPosition")
        waterMaterial.setValue(speedSlider.value, forKey: "speed")
        waterMaterial.setValue(amplitudeSlider.value, forKey: "amplitude")
        waterMaterial.setValue(cellSizeSlider.value, forKey: "cellSize")
    }

    private func initializeScene() {
        scnView.backgroundColor = UIColor(red: 153.0 / 255.0, green: 204.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)

        scnView.scene = SCNScene()
        scnView.isPlaying = true
        scnView.autoenablesDefaultLighting = true

        let camera = SCNCamera()
        camera.zFar = 10000.0
        camera.fieldOfView = 45.0

        let boatScene = SCNScene(named: "art.scnassets/boat.scn")!
        let boatNode = boatScene.rootNode.childNode(withName: "boat", recursively: false)!
        boatNode.removeFromParentNode()
        boatNode.position = SCNVector3(x: 1024.0 * 6, y: 1024.0 * 3, z: 0.0)
        boatNode.scale = SCNVector3(x: 100.0, y: 100.0, z: 100.0)
        boatNode.eulerAngles = SCNVector3(x: 90.0 * (.pi / 180.0), y: 0.0 , z: -35.0 * (.pi / 180.0))

        scnView.scene!.rootNode.addChildNode(boatNode)

        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.position = SCNVector3(x: 1024.0 * 6, y: 0.0, z: 500.0)
        cameraNode.camera = camera
        cameraNode.constraints = [SCNLookAtConstraint(target: boatNode)]

        scnView.scene!.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode

        for x in 0...12 {
            for y in 0...6 {
                let waterNode = SCNNode()
                waterNode.position = SCNVector3(x: SCNFloat(x) * 1024.0, y: SCNFloat(y) * 1024.0, z: 0.0)
                waterNode.name = "water-\(y)-\(x)"
                waterNode.geometry = WaterPlane.create(withSideLength: 1024.0, segmentCount: 8)
                waterNode.geometry?.materials = [waterMaterial]
                scnView.scene!.rootNode.addChildNode(waterNode)
            }
        }
    }

    private func showTiles() {
        scnView.scene!.rootNode.enumerateChildNodes {
            (node, stop) in

            if node.name!.starts(with: "water") {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.6

                node.scale = SCNVector3(x: 0.9, y: 0.9, z: 1.0)

                SCNTransaction.commit()
            }
        }
    }

    private func hideTiles() {
        scnView.scene!.rootNode.enumerateChildNodes {
            (node, stop) in

            if node.name!.starts(with: "water") {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.6

                node.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)

                SCNTransaction.commit()
            }
        }
    }
}
