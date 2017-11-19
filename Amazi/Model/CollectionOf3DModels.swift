//
//  collectionOf3DModels.swift
//  Amazi
//
//  Created by Tewodros Wondimu on 11/19/17.
//  Copyright © 2017 Tewodros Wondimu. All rights reserved.
//

import Foundation
import ARKit

class CollectionOf3DModels {
    // Properties for the collection
    private var name: String // name of the collection of objects, e.g. pipes - this should match the plist
    private var node: SCNNode = SCNNode() // node that has all the objects in that collection
    private var numberOf3DObjects: Int // a number that gives all the objects in that collection
    private var all3DObjects = [ThreeDimensionalModel]() // all the 3D Model Objects
    
    // initializer for the class
    init(collectionName: String, collectionNode: SCNNode) {
        name = collectionName
        node = collectionNode
        all3DObjects = [ThreeDimensionalModel]()
        numberOf3DObjects = all3DObjects.count
    }
    
    // get the name of the collection
    func getName() -> String {
        return name
    }
    
    // set the name of the collection
    func setName(newName: String) {
        name = newName
    }
    
    // get the node of the collection
    func getNode() -> SCNNode {
        return node
    }
    
    // set the node of the collection
    func setNode(newNode: SCNNode) {
        node = newNode
    }
    
    // get the number of 3d objects of the collection
    func getNumberOfObjects() -> Int {
        return numberOf3DObjects
    }
    
    // set the number of 3d objects of the collection
    func setNumberOfObjects(newNumberOf3DObjects: Int) {
        numberOf3DObjects = newNumberOf3DObjects
    }
    
    // get the node of the collection
    func getAll3DObjects() -> [ThreeDimensionalModel] {
        return all3DObjects
    }
    
    // add a 3D Object to the collection
    func add3DObject(model: ThreeDimensionalModel) {
        all3DObjects.append(model) // add the new model to the number of 3d models available
        numberOf3DObjects += 1 // increment the number of 3d models in the collection
    }
    
    // remove a 3D Object to the collection
    func remove3DObject(model: ThreeDimensionalModel) -> Bool {
        for (index, modelX) in all3DObjects.enumerated() {
            if modelX.getName() == model.getName() {
                all3DObjects.remove(at: index)
                numberOf3DObjects -= 1 // increment the number of 3d models in the collection
                return true
            }
        }
        return false
    }
    
    // find a 3D object in the collection, returns null if there's nothing found
    func find3DModel(modelName: String) -> ThreeDimensionalModel? {
        for model in all3DObjects {
            if model.getName() == modelName {
                return model
            }
        }
        return nil
    }
    
    // replace a 3D model in the collection
    func replace3DModel(model: ThreeDimensionalModel) -> Bool {
        for (index, modelToReplace) in all3DObjects.enumerated() {
            if modelToReplace.getName() == model.getName() {
                all3DObjects[index] = model
                return true
            }
        }
        return false
    }
    
    // Create 3D models from plist
    func build3DModelsFromPlist () -> [ThreeDimensionalModel]  {
        // Find the plist with the collection name
        let path = Bundle.main.path(forResource: name, ofType: "plist")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
        let collectionArray = plist as! [[String:String]]
        var allTheModelsFromPlist = [ThreeDimensionalModel]()
        
        // loop through elements of the array
        for (_, element) in collectionArray.enumerated() {
            // create a 3D model object
            let modelName: String = element["name"]!
            //let temp: element["description"]
            let modelDescription = ["new": "hello"]
            //let theLocation = element["location"]
            let x = 3.0
            let y = 2.0
            let z = 0.0
            let modelLocation = SCNVector3(x, y, z)
            //let theOrientation = element["orientation"]
            let modelOrientation = SCNVector3(x, y, z)
            let model = ThreeDimensionalModel(name: modelName, description: modelDescription, location: modelLocation, orientation: modelOrientation)
            
            // append the new mdoel to all the objects in the collection
            allTheModelsFromPlist.append(model)
        }
        return allTheModelsFromPlist
    }
}
