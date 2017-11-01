//
//  ViewController.swift
//  Amazi
//
//  Created by Tewodros Wondimu on 10/31/17.
//  Copyright © 2017 Tewodros Wondimu. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, ARSCNViewDelegate {
    
    // All the menu items
    let menuArray: [String] = ["Well", "Drip", "Solar", "vase"]
    var selectedItem: String?
    
    // Outlets for the different elements
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var statusViewBar: UIView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // Properties
    var lastRotation: CGFloat = 0 // A property to record the last rotated state of an object
    
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    var selectedObject: VirtualObject?
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: VirtualObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The scene view to hit test against when moving virtual content.
    var virtualObjectSceneView: VirtualObjectInteraction
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?
    
    // Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the data source and delegate of the collection view
        self.menuCollectionView.dataSource = self
        self.menuCollectionView.delegate = self
        
        self.virtualObjectSceneView = VirtualObjectInteraction(sceneView: sceneView)
        self.sceneView.delegate = self
        
        // show feature points and the world origin when the application loads up
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints];
        
        // enable horizontal plane detection
        configuration.planeDetection = .horizontal;
        
        // Run the configuration on the sceneView Session
        self.sceneView.session.run(configuration);
        
        // Set up to recognize gesture
        self.registerGestureRecognizer()
    }
    
    
    func registerGestureRecognizer() {
        
        // Allows to detect tap gestures
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        // Allows to detect pinch gestures
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        
        // Allows to detect rotate gestures
        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotated))
        
        // Allows to detect pan gestures
        let panGestureRecognizer = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.delegate = self
        
        // Add all the gesture recognizers to the sceneView
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(rotateGestureRecognizer)
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for interaction with a new object.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)
            
            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            
            // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
            
            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
            break
            
        default:
            // Clear the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }
    
    /**
     If a drag gesture is in progress, update the tracked object's position by
     converting the 2D touch location on screen (`currentTrackingPosition`) to
     3D world space.
     This method is called per frame (via `SCNSceneRendererDelegate` callbacks),
     allowing drag gestures to move virtual objects regardless of whether one
     drags a finger across the screen or moves the device through space.
     - Tag: updateObjectToCurrentTrackingPosition
     */
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else { return }
        translate(object, basedOn: position, infinitePlane: true)
    }
    
    /// - Tag: DragVirtualObject
    private func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = virtualObjectSceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        
        /*
         Plane hit test results are generally smooth. If we did *not* hit a plane,
         smooth the movement to prevent large jumps.
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
    
    
    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = virtualObjectSceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        return virtualObjectSceneView.virtualObject(at: gesture.center(in: view))
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
        if(!hitTest.isEmpty) {
            // get the result from the hit test
            let results: SCNHitTestResult = hitTest.first!
            
            // get the node from the result
            let node = results.node
            
            // Original rotation stores the rotation when the object begins rotating
            var originalRotation = CGFloat()
            if sender.state == .began {
                sender.rotation = lastRotation
                
                // stores the rotation at the time when the view is about to begin rotating.
                originalRotation = sender.rotation
            } else if sender.state == .changed {
                var newRotation: CGFloat = 0.0
                
                // Check which way the object is being rotated, left to right or right to left
                if sender.rotation > 0 {
                    // rotate from the current rotation
                    newRotation = (sender.rotation * 0.01) + originalRotation
                    print("rotating right")
                } else
                {
                    // rotate from the current rotation and multiply by -1 to rotate the object in the right direction
                    newRotation = -1 * ((sender.rotation * 0.01) + originalRotation)
                    print("rotating left")
                }
                
                print("The object is rotated by \(newRotation)")
                // based on how far the person rotated on the screen rotate in the y-axis the object immediately
                let rotateAction = SCNAction.rotateBy(x: 0, y: newRotation, z: 0, duration: 0)
                
                // run the rotate action on the node
                node.runAction(rotateAction)
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
        if (!hitTest.isEmpty) {
            // get the result from the hit test
            let results: SCNHitTestResult = hitTest.first!
            
            // get the node from the result
            let node = results.node
            
            // based on how far the person pinched on the screen scale the object immediately
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            
            // run the pinch action on the node
            node.runAction(pinchAction)
            
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
        
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if (!hitTest.isEmpty) {
            print("touched a horizontal surface")
            addItem(hitTestResult: hitTest.first!)
        }
        else {
            print("No match")
        }
    }
    
    // Add the terrain to a plane when the application starts
    func addItem(hitTestResult: ARHitTestResult) {
        // find out the item is currently selected
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Model.scnassets/\(selectedItem).scn")
            
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            
            // encodes information
            let transform = hitTestResult.worldTransform
            
            // position of the horizontal surface
            let thirdColumn = transform.columns.3
            
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    // When ever a button is pressed you change the background to the color green
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.green
        
        self.selectedItem = menuArray[indexPath.row]
    }
    
    // Change the color of the button when it is pressed
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
        // Change the background color of the cell
        cell?.backgroundColor = UIColor.orange;
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
        
        return cell
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        
        // renderer is done in a separate thread so run everything that has to do with UI in the main queue
        DispatchQueue.main.async {
            self.statusLabel.isHidden = false
            self.statusLabel.text = "Plane detected"
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.statusLabel.isHidden = true
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

