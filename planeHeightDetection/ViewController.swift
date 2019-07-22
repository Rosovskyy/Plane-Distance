//
//  ViewController.swift
//  planeHeightDetection
//
//  Created by Volpis on 7/22/19.
//  Copyright © 2019 Volpis. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Properties
    let configuration = ARWorldTrackingConfiguration()
    private let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    private var currPlaneId: Int = 0
    var sphereNodes = [SCNNode]()
    var lowestPlane: ARPlaneAnchor?
    
    // MARK: - IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneViewConfiguration()
    }
    
    // MARK: - Private
    private func sceneViewConfiguration() {
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin
        ]
        
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        self.createRandomSpheres()
    }
    
    // MARK: - Functionality
    func createPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let scenePlaneGeometry = ARSCNPlaneGeometry(device: metalDevice!)
        scenePlaneGeometry?.update(from: planeAnchor.geometry)
        let planeNode = SCNNode(geometry: scenePlaneGeometry)
        planeNode.name = "\(currPlaneId)"
        planeNode.opacity = 0.25
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        currPlaneId += 1
        return planeNode
    }
    
    func createRandomSpheres() {
        for elem in 0..<5 {
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.1))
            sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            sphereNode.position = SCNVector3(Double(elem) * 0.3, 0, 0)
            
            self.sphereNodes.append(sphereNode)
            self.sceneView.scene.rootNode.addChildNode(sphereNode)
        }
    }
    
    func distanceToLowest(node: SCNNode) -> Float {
        let nodeHeight = node.transform.m42
        let planeHeight = lowestPlane!.transform.columns.3.y
        return abs(nodeHeight) + abs(planeHeight)
    }
    
    // MARK: - Scene view delegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeNode = createPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        if lowestPlane != nil {
            if lowestPlane!.transform.columns.3.y > planeAnchor.transform.columns.3.y {
                lowestPlane = planeAnchor
            }
        } else {
            lowestPlane = planeAnchor
        }
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        let planeNode = createPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        print("Removing plane anchor")
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
}
