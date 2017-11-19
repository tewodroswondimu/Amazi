//
//  a3DModel.swift
//  Amazi
//
//  Created by Tewodros Wondimu on 11/19/17.
//  Copyright © 2017 Tewodros Wondimu. All rights reserved.
//

import Foundation
import ARKit

class ThreeDimensionalModel {
    private var name: String // name of the 3D object, e.g. knob
    private var description: [String: String] // describes the 3D Model
    private var location: SCNVector3 // location of the 3D model
    private var orientation: SCNVector3 // orientation of the 3D model
    private var node: SCNNode // node for the 3D model
    
    // initalizer for the class
    init (name: String, price: String, dimensions: String, location: SCNVector3, orientation: SCNVector3, node: SCNNode) {
        self.name = name
        self.description = ["name": name, "price": price, "dimensions": dimensions]
        self.location = location
        self.orientation = orientation
        self.node = node
    }
    
    // get the name of the 3D Model
    func getName() -> String {
        return name
    }
    
    // set the name of the 3D Model
    func setName(newName: String) {
        name = newName
    }
    
    // get the description of the 3D Model
    func getDescription() -> [String: String] {
        return description
    }
    
    // set the description of the 3D Model
    func setDescription(newDescription: [String: String]) {
        description = newDescription
    }
    
    // get the node of the model
    func getNode() -> SCNNode {
        return node
    }
    
    // set the node of the model
    func setNode(newNode: SCNNode) {
        node = newNode
    }
    
    // get the location of the 3D Model
    func getLocation() -> SCNVector3 {
        return location
    }
    
    // set the location of the 3D Model
    func setLocation(newLocation: SCNVector3) {
        location = newLocation
    }
    
    // get the orientation of the 3D Model
    func getOrientation() -> SCNVector3 {
        return orientation
    }
    
    // set the orientation of the 3D Model
    func setOrientation(newOrientation: SCNVector3) {
        orientation = newOrientation
    }
    
    // build a node for the model data you have
    func buildNodeForModel () -> SCNNode {
        let fileName = name + ".scn"
        let modelScene = SCNScene(named: "Model.scnassets/" + fileName)
        let modelNode = modelScene?.rootNode.childNode(withName: name, recursively: false)
        modelNode?.position = location
        return modelNode!
    }
}
