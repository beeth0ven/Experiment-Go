//
//  TagsCollectionViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/13/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TagsCollectionViewController: UICollectionViewController {
    var tags = ["luo jie", "iPad Mini", "Air", "iPad Air", "iPhone 6"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.estimatedItemSize = CGSizeMake(84, 32)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return tags.count }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TagCollectionViewCell
        cell.button.setTitle(tags[indexPath.item], forState: .Normal)
        return cell
    }
}