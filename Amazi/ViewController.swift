//
//  ViewController.swift
//  Amazi
//
//  Created by Tewodros Wondimu on 10/31/17.
//  Copyright © 2017 Tewodros Wondimu. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ARSCNViewDelegate {
    
    // All the menu items
    let menuArray: [String] = ["Pump", "Solar", "Crop", "Well", "Pipe"]
    
    var selectedItem: String?
    var selectedNode = SCNNode()
    var selectedNodePreviousPosition = SCNVector3()
    var selectedNodePreviousOrientation = SCNQuaternion()
    var selectedCollectionNode = SCNNode()
    var selectedNodeStatus: Bool = false
    
    // Outlets for the different elements
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var statusBlurViewDetails: UIVisualEffectView!
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var statusDetails: UITextView!
    @IBOutlet weak var statusViewBar: UIView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var detailsImageView: UIImageView!
    @IBOutlet weak var detailsItemName: UILabel!
    @IBOutlet weak var detailsItemDetailTextView: UITextView!
    @IBOutlet weak var detailsPrice: UILabel!
    @IBOutlet weak var detailsDimensions: UILabel!
    @IBOutlet weak var detailsBlurView: UIVisualEffectView!
    
    let details: [String: [String: String]] =
        ["Crop":
            ["name": "Crop", "price": "$12.40", "details": "Maize, also known as corn, is a cereal grain first domesticated by indigenous peoples in southern Mexico about 10,000 years ago. The leafy stalk of the plant produces separate pollen and ovuliferous inflorescences or ears, which are fruits, yielding kernels or seeds.Maize has become a staple food in many parts of the world, with total production surpassing that of wheat or rice. However, not all of this maize is consumed directly by humans. Some of the maize production is used for corn ethanol, animal feed and other maize products, such as corn starch and corn syrup. The six major types of corn are dent corn, flint corn, pod corn, popcorn, flour corn, and sweet corn", "dimensions": "4x4"],
         "Pump":
            ["name": "Pump", "price": "price", "details": "LIFAN Power USA prides itself in standing behind all LIFAN products with a industry leading 3 Year Limited Warranty and offers the highest level of service and support with a complete parts and service network. Ready to tackle the dirtiest jobs at the toughest job sites, Stanley trash water pumps are ready to go anywhere, with heavy-duty 1-1/4 in. steel roll cages and included wheel kit. Each model grinds debris up to half the diameter of its inlet/outlet, and has a large tank for longer run times.", "dimensions": "1x2x2"],
         "Well":
            ["name": "Well", "price": "price", "details": "details", "dimensions": "dimensions"]
        ]
    
    // Properties
    var firstItem = true
    var disableRotation = false
    var disableScale = false
    var terrain = SCNNode()
    var objectsNode = SCNNode()
    
    // A property to record the last rotated state of an object
    var lastRotation: CGFloat = 0
    
    // Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the data source and delegate of the collection view
        self.menuCollectionView.dataSource = self
        self.menuCollectionView.delegate = self
        self.menuCollectionView.isHidden = true
        
        self.addButton.isHidden = true
        
        self.sceneView.delegate = self
        
        // show feature points and the world origin when the application loads up
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints];
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints];
        
        // Lets scene kit automatically add lighting (omnidirectional)
        self.sceneView.autoenablesDefaultLighting = true
        
        // enable horizontal plane detection
        configuration.planeDetection = .horizontal;
        
        // Run the configuration on the sceneView Session
        self.sceneView.session.run(configuration);
        
        // Set up to recognize gesture
        self.registerGestureRecognizer()
        
        self.setupStatusBar()
    }
    
    func setupStatusBar() {
        self.statusBlurViewDetails.layer.cornerRadius = 10;
        self.statusBlurViewDetails.layer.masksToBounds = true;
        
        self.addButton.layer.cornerRadius = 10;
        self.addButton.layer.masksToBounds = true;
        
        self.statusLabel.text = "Scanning"
        self.statusDetails.text = "Move your device slowly to find a flat surface"
        
        self.menuCollectionView.layer.cornerRadius = 10;
        self.menuCollectionView.layer.masksToBounds = true;
        
        self.detailsBlurView.layer.cornerRadius = 10;
        self.detailsBlurView.layer.masksToBounds = true;
        self.detailsBlurView.isHidden = true
        self.detailsBlurView.alpha = 0.0
        
        self.detailsItemName.text = "default name"
        self.detailsPrice.text = "0.1"
        self.detailsDimensions.text = "X Dimensions"
        self.detailsItemDetailTextView.text = "Something something"
    }
    
    func updateDetailsBar(name: String, price: String, details: String, dimensions: String) {
        self.detailsImageView.image = UIImage(named: name)
        self.detailsItemName.text = name
        self.detailsPrice.text = price
        self.detailsDimensions.text = dimensions
        self.detailsItemDetailTextView.text = details
    }
    
    func updateStatusBar(statusLabelText: String, statusDetailsText: String, length: Double, action: String) {
        self.statusLabel.text = statusLabelText
        self.statusDetails.text = statusDetailsText
        UIView.animate(withDuration: 1.5, animations: {
            self.statusBlurViewDetails.alpha = 1.0
        })
        
        // If the message is supposed to stay on screen
        if length != 0.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + length) {
                UIView.animate(withDuration: 1.5, animations: {
                    self.statusBlurViewDetails.alpha = 0.0
                })
            }
        }
        
        // Change the button action based on the action sent
        buttonFactor(action: action)
    }
    
    // Change the title of the button based on the last action performed
    func buttonFactor(action: String) {
        self.addButton.isHidden = false
        
        switch action {
            case "Add":
                self.addButton.setTitle("Add", for: .normal)
            case "Confirm":
                self.addButton.setTitle("Confirm", for: .normal)
            case "Done":
                self.addButton.setTitle("Done", for: .normal)
            case "None":
                self.addButton.isHidden = true
            default:
                updateStatusBar(statusLabelText: "Unknown", statusDetailsText: "An unknown action was taken", length: 5.0, action: "None")
        }
    }
    
    func addCollectionOfModels(chosenModel: String) {
        let collectionOfModels = CollectionOf3DModels(collectionName: chosenModel)
        let models = collectionOfModels.build3DModelsFromPlist()
        collectionOfModels.setAll3DObjects(objects: models)
        selectedCollectionNode = collectionOfModels.buildNodeWith3DObjects()
        selectedCollectionNode.name = chosenModel
        collectionOfModels.setNode(newNode: selectedCollectionNode)
    }
    
    // Create a terrain object
    func createTerrainObject() -> SCNNode {
        let terrainHeight: CGFloat = 0.8
        let terrainWidth: CGFloat = 0.8
        let terrainLength: CGFloat = 0.05
        let terrainPostion = (terrainLength / 2) + 0.001
        
        let terrainNode = SCNNode(geometry: SCNPlane(width: terrainWidth, height: terrainHeight))
        terrainNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Terrain")
        terrainNode.geometry?.firstMaterial?.isDoubleSided = true
        terrainNode.eulerAngles = SCNVector3(Float(90.degreesToRadians), 0,0)
        terrainNode.position = SCNVector3(0, terrainPostion, 0)
        
        let terrainParentNode = SCNNode(geometry: SCNBox(width: terrainWidth, height: terrainLength, length: terrainHeight, chamferRadius: 0))
        terrainParentNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Soil")
        terrainParentNode.addChildNode(terrainNode)
        
        // An object that has the dirt and surface
        let allTerrain = terrainParentNode.flattenedClone()
        
        return allTerrain
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        switch sender.titleLabel!.text! {
        case "Add":
            addItem(inNode: objectsNode, nodesToAdd: self.selectedItem!)
            
            self.addButton.isHidden = true
        case "Confirm":
            self.disableRotation = true
            self.disableScale = true
            self.addButton.isHidden = true
            self.menuCollectionView.isHidden = false
            self.updateStatusBar(statusLabelText: "Welcome to Amazi", statusDetailsText: "To get started, tap on one of the items below", length: 10.0, action: "None")
        case "Done":
            self.removeHightlightedItem()
            self.addButton.isHidden = true
            UIView.animate(withDuration: 1.5, animations: {
                self.detailsBlurView.alpha = 0.0
            }, completion: {
                (value: Bool) in
                self.detailsBlurView.isHidden = true
            })
        default:
            print("An empty button was pressed")
        }
    }
    
    func registerGestureRecognizer() {
        // Allows to detect pan gestures
        // let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        
        // Allows to detect tap gestures
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        // Allows to detect pinch gestures 
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        
        // Allows to detect rotate gestures
        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotated))
        
        // Add all the gesture recognizers to the sceneView
        //self.sceneView.addGestureRecognizer(panGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(rotateGestureRecognizer)
    }
    
    // method for when a person pan an object in the scene
    @objc func panned(sender: UITapGestureRecognizer) {
        // get the sceneview that was pinched on
        let sceneView = sender.view as! ARSCNView
        
        // location that was panned in the scene view
        let panLocation = sender.location(in: sceneView)
        
        // check whether the pan matches the location of an object
        let hitTest = sceneView.hitTest(panLocation)
        
        // Check if an object was rotated
        if(!hitTest.isEmpty) {
            // get the result from the hit test
            //let results: SCNHitTestResult = hitTest.first!
            
            // get the node from the result
            // let node = results.node
            
        }
        else {
            print("Object was not panned")
        }
    }
    
    // method for when a person rotates an object in the scene
    @objc func rotated(sender: UIRotationGestureRecognizer) {
        // get the sceneview that was pinched on
        let sceneView = sender.view as! ARSCNView
        
        // location that was rotated in the scene view
        let rotateLocation = sender.location(in: sceneView)
        
        // check whether the rotation matches the location of an object
        let hitTest = sceneView.hitTest(rotateLocation)
        
        // Check if an object was rotated
        if(!hitTest.isEmpty && self.disableRotation == false) {
            // get the result from the hit test
            let results: SCNHitTestResult = hitTest.first!
            
            // get the node from the result
            let node = results.node
            
            if sender.state == .changed {
                
                // Rotate only the terrain
                if node.name == "Terrain" || node.name == "Objects Node" || node.parent!.name == "Objects Node" {
                    // run the rotate action on objects node
                    let theRotation = Float(sender.rotation)
                    terrain.eulerAngles.y -= theRotation
                    objectsNode.eulerAngles.y -= theRotation
                }
                
                sender.rotation = 0
                
            } else if sender.state == .ended {
                // Save the last rotation
                lastRotation = sender.rotation
            }
        }
        else {
            print("Object was not rotated")
        }
    }
    
    // method for when a person pinches an object in the scene
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        // get the sceneview that was pinched on
        let sceneView = sender.view as! ARSCNView
        
        // location that was pinched in the scene view
        let pinchLocation = sender.location(in: sceneView)
        
        // check whether your pinch matches the location of an object
        let hitTest = sceneView.hitTest(pinchLocation)
        
        // Check if an object was pinched
        if (!hitTest.isEmpty && self.disableScale == false) {
            // get the result from the hit test
            let results: SCNHitTestResult = hitTest.first!
            
            // get the node from the result
            let node = results.node
            
            
            // based on how far the person pinched on the screen scale the object immediately
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            
            // Scale only the terrain
            if node.name == "Terrain" || node.name == "Objects Node" || node.parent!.name == "Objects Node" {
                // run the pinch action on the node
                terrain.runAction(pinchAction)
                objectsNode.runAction(pinchAction)
            }
            
            if node.name == "selectedNode" {
                self.selectedNode = node
            }
            
            // Make the scale size constant, so that it doesn't keep gettting bigger
            sender.scale = 1.0
            
            // go to the scene and click on flatten node if you have a scn object that has children
        }
        else {
            print("The pinch hit test did not work")
        }
    }
    
    // taps on a plane
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        if (firstItem) {
            let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            if (!hitTest.isEmpty) {
                let hitTestResult = hitTest.first!
                
                    terrain = addTerrain(hitTestResult: hitTestResult)
                
                    self.updateStatusBar(statusLabelText: "Scale and Rotate", statusDetailsText: "Pinch and Rotate to adjust the size of the land, once you're done, tap confirm", length: 10.0, action: "Confirm")
                
                    // Hide feature points and disable plane detection once the terrain has been placed
                    sceneView.debugOptions = [];
                    configuration.planeDetection = [];
                    self.sceneView.session.run(configuration);
                
                    // once the terrain has been created, create a node on top of it
                    objectsNode.position = SCNVector3(terrain.position.x, terrain.position.y + 0.002, terrain.position.z)
                    objectsNode.orientation = terrain.orientation
                    //let object = createTerrainObject()
                    //objectsNode.addChildNode(object)
                    objectsNode.name = "Objects Node"
                    self.sceneView.scene.rootNode.addChildNode(objectsNode)
            }
            else {
                print("No match")
            }
        } else {
            let hitTest = sceneView.hitTest(tapLocation)
            let hitTestResult = hitTest.first!
            
            // get the node from the result
            let node = hitTestResult.node
            
            // If the node that was tapped is a snapshot, remove it from the scene
            if (node.name == "snapshot") {
                // Save the image to the camera roll
                let snapshotTaken = node.geometry?.firstMaterial?.diffuse.contents as! UIImage
                UIImageWriteToSavedPhotosAlbum(snapshotTaken, self, #selector(snapshotSaved(_:didFinishSavingWithError:contextInfo:)), nil)
                
                node.removeFromParentNode()
            } else if (node.name != "terrain") {
                if selectedNodeStatus {
                    self.removeHightlightedItem()
                    
                    if (self.selectedNode.animationKeys.isEmpty) {
                        highlightItem(node: node)
                    }
                }
                else {
                    highlightItem(node: node)
                }
            } else {
                print("No match")
            }
        }
    }
    
    func removeHightlightedItem() {
        self.selectedNode.removeAction(forKey: "rotateSelectedNode")
        self.selectedNode.orientation = selectedNodePreviousOrientation
        animateNode(node: self.selectedNode, fromValue: self.selectedNode.position, toValue: selectedNodePreviousPosition)
        self.selectedNode.position = selectedNodePreviousPosition
        selectedNodeStatus = false
    }
    
    // diplays an item with it's details
    func highlightItem(node: SCNNode) {
        self.detailsBlurView.isHidden = false
        UIView.animate(withDuration: 1.5, animations: {
            self.detailsBlurView.alpha = 1.0
        })
        if let name = node.parent?.name {
            
            let objectDetails: [String: String]
            switch name {
                case "Crop":
                    objectDetails = self.details["Crop"]!
                case "Pump":
                    objectDetails = self.details["Pump"]!
                case "Well":
                    objectDetails = self.details["Well"]!
                default:
                    objectDetails = self.details["Crop"]!
            }
            let objectName = objectDetails["name"]
            let price = objectDetails["price"]
            let details = objectDetails["details"]
            let dimensions = objectDetails["dimensions"]
            self.updateDetailsBar(name: objectName!, price: price!, details: details!, dimensions: dimensions!)
            print("The name of the node's parent is \(name)")
        }
        
        selectedNodePreviousPosition = node.position
        let moveNodeTo = SCNVector3(node.position.x,node.position.y + 0.1,node.position.z)
        
        animateNode(node: node, fromValue: selectedNodePreviousPosition, toValue: moveNodeTo)
        node.position = moveNodeTo
        
        // rotate the node around itself
        let nodeRotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 8)
        let rotateForever = SCNAction.repeatForever(nodeRotateAction)
        node.runAction(rotateForever, forKey: "rotateSelectedNode")
        selectedNodePreviousOrientation = node.orientation
        self.selectedNode = node
        self.selectedNodeStatus = true
        
        buttonFactor(action: "Done")
    }
    
    func addTerrain(hitTestResult: ARHitTestResult) -> SCNNode {
        let terrain = createTerrainObject()
        terrain.name = "Terrain"
        
        // encodes information
        let transform = hitTestResult.worldTransform
        
        // position of the horizontal surface
        let thirdColumn = transform.columns.3
        terrain.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        
        self.sceneView.scene.rootNode.addChildNode(terrain)
        
        firstItem = false
        
        return terrain
    }
    
    // Add the terrain to a plane when the application starts
    func addItem(inNode: SCNNode, nodesToAdd: String) {
        
        
        self.addCollectionOfModels(chosenModel: nodesToAdd)
        let nodeToAdd = selectedCollectionNode
        
        // let atPosition = inTerrain.position
        //nodeToAdd.removeAction(forKey: "rotateSelectedNode")
        //nodeToAdd.name = "addedNode"
        self.selectedNode = nodeToAdd
        
        

        //let x = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        // let z = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        
        let x = -0.4, z = -0.4
        
        self.objectsNode.addChildNode(nodeToAdd)
        
        let moveFrom = SCNVector3(
            self.objectsNode.presentation.position.x,
            self.objectsNode.presentation.position.y + 1,
            self.objectsNode.presentation.position.z
        )
        let moveNodeTo = SCNVector3(x,0.051,z)
        
        animateNode(node: nodeToAdd, fromValue: moveFrom, toValue: moveNodeTo)
        nodeToAdd.position = moveNodeTo
    
        if (nodeToAdd.animationKeys.isEmpty) {
        }
    }
    
    // generates a random number given a minimum and maximum value
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func animateNode(node: SCNNode, fromValue: SCNVector3, toValue: SCNVector3) {
        // to make the object make a shaky spin we modify the position
        let move = CABasicAnimation(keyPath: "position")
        
        // presentation is the current state of the object in the sceneview
        // this records the starting point of the animation
        move.fromValue = fromValue
        
        // to change the duration of the animation
        move.duration = 1
        
        // this shows where you want the node to go relative to the world origin
        // spin.toValue = SCNVector3(0,0,-2)
        
        // if you want to go from the current position of the node,
        move.toValue = toValue
        
        // add the animation to the node
        node.addAnimation(move, forKey: "position")
    }
    
    func showItem() {
        // find out the item is currently selected
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Model.scnassets/\(selectedItem).scn")
            
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            
            // the current location and orientation of the camera view
            guard let pointOfView = sceneView.pointOfView else {return}
            
            self.addButton.isHidden = false
            
            // the location and orientation are encoded in a transform matrix
            let transform = pointOfView.transform
            
            // Orientation is where your phone is facing
            // extract the orientation from the tranform matrix
            // the third column in the transform matrix is the orientation
            // x is located in row 1
            // y is located in row 2
            // z is located in row 3
            // When trying to see the value for orientation, you'll find looking up give you a -ve value, switch that by multiplying the transform matrix by -ve
            let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
            
            // Location is where your phone is located relative to the sceneView and how it's moving transitionally
            // location is also a 3d field
            // the fourth column in the tranform matrix is the location
            // x is located in row 1
            // y is located in row 2
            // z is located in row 3
            let location = SCNVector3(transform.m41, transform.m42, transform.m43)
            
            // to get the current position we combine the orientation and location
            let currentPositionOfCamera = orientation + location
            
            node.position = currentPositionOfCamera
            node.name = "selectedNode"
            
            // rotate the node around itself
            let nodeRotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 8)
            let rotateForever = SCNAction.repeatForever(nodeRotateAction)
            node.runAction(rotateForever, forKey: "rotateSelectedNode")
            self.selectedNode = node
            
            //self.sceneView.scene.rootNode.addChildNode(self.selectedNode)
        }
        
    }
    
    func removeItem() {
        if (self.selectedNode.name == "selectedNode") {
            self.selectedNode.removeFromParentNode()
        }
        self.addButton.isHidden = true
    }
    
    // When ever a button is pressed you change the background to the color green
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! menuCollectionViewCell
        cell.collectionViewInnerView.backgroundColor = UIColor.green
        
        self.selectedItem = menuArray[indexPath.row]
        
        // Remove anything that's already on screen
        if selectedNodeStatus {
            self.removeHightlightedItem()
            UIView.animate(withDuration: 1.5, animations: {
                self.detailsBlurView.alpha = 0.0
            }, completion: {
                (value: Bool) in
                self.detailsBlurView.isHidden = true
            })
        }
        
        self.updateStatusBar(statusLabelText: "\(self.selectedItem!) was chosen", statusDetailsText: "To place the item on the terrain tap the \"Add\" button on the right", length: 10.0, action: "Add")
        
        showItem();
    }
    
    // Change the color of the button when it is pressed
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! menuCollectionViewCell
        
        // Change the background color of the cell
        cell.collectionViewInnerView.backgroundColor = UIColor.lightGray
        removeItem()
    }
    
    // Set the number of items in the menu collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuArray.count
    }
    
    // Assign a value to each cell in the collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // deque returns a cell type based on the identifier item
        // indexpath is concerned with which cell we're configuring
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menuItem", for: indexPath) as! menuCollectionViewCell
        
        // Sets the label of the uicollection view to the name in the items array
        cell.collectionViewLabel.text = self.menuArray[indexPath.row]
        cell.collectionViewInnerView.layer.cornerRadius = 10
        cell.collectionViewInnerView.layer.masksToBounds = true
        
        return cell
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        
        // renderer is done in a separate thread so run everything that has to do with UI in the main queue
        DispatchQueue.main.async {
//            self.statusLabel.isHidden = false
//            self.statusLabel.text = "Plane detected"
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                UIView.animate(withDuration: 1.5, animations: {
                    self.statusBlurViewDetails.alpha = 0.0
                })
                self.updateStatusBar(statusLabelText: "Plane Detected", statusDetailsText: "Please tap on the surface to place the land terrain", length: 0.0, action: "None")
                //self.statusLabel.isHidden = true
            }
        }
    }

    // When the snap button click the
    @IBAction func takeSnapshot(_ sender: Any) {
        // Get the camera transform
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        // Create an image plane with a snapshot of the view
        let imagePlane = SCNPlane(width: sceneView.bounds.width / 6000, height: sceneView.bounds.height / 6000)
        let snapshotTaken = sceneView.snapshot()
        imagePlane.firstMaterial?.diffuse.contents = snapshotTaken
        imagePlane.firstMaterial?.lightingModel = .constant
        
        // Create a plane node and add it to the scene
        let planeNode = SCNNode(geometry: imagePlane)
        planeNode.name = "snapshot"
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        // Set the transform of the node to be 10cm in front of the camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.1
        planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
    }
    
    @objc func snapshotSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        
        if error == nil {
            self.updateStatusBar(statusLabelText: "Image Saved", statusDetailsText: "The image has been saved to your camera roll, tap to dismiss", length: 10, action: "None")
        } else {
            self.updateStatusBar(statusLabelText: "Error Saving Image", statusDetailsText: "There was an error saving the image, please try again", length: 10, action: "None")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}

// Modifies the binary operator + to add two SCNVector3s and create one SCNVector3
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

