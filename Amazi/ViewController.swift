//
//  ViewController.swift
//  Amazi
//
//  Created by Tewodros Wondimu on 10/31/17.
//  Copyright © 2017 Tewodros Wondimu. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    // All the menu items
    let menuArray: [String] = ["Well", "Drip", "Solar"]
    var selectedItem: String?
    
    // Outlets for the different elements
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var statusViewBar: UIView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // enable horizontal plane detection
        configuration.planeDetection = .horizontal;
        
        // Run the configuration on the sceneView Session
        self.sceneView.session.run(configuration);
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

