//
//  TagsTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/13/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TagsTableViewCell: UITableViewCell, UICollectionViewDataSource {
    
    var tags: [String]? { didSet { collectionView.reloadData() } }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
            layout.estimatedItemSize = CGSizeMake(84, 32)
            collectionView.dataSource = self
        }
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return tags?.count > 0 ? 1 : 0 }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return tags!.count }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TagCollectionViewCell
        cell.button.setTitle(tags![indexPath.item], forState: .Normal)
        return cell
    }
}