//
//  EditeTagsCollectionViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/13/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EditeTagsCollectionViewController: UICollectionViewController {
    
    var tags = [String]() { didSet { if ( tags != oldValue) { collectionView?.reloadData() } } }
    
    var done: (([String]) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.estimatedItemSize = CGSizeMake(10, 10)
        navigationItem.rightBarButtonItem = doneButtonItem
        navigationItem.rightBarButtonItem?.enabled = false
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        showOrHideToolBarIfNeeded()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return  tags.count + 1 }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TagCollectionViewCell

        if indexPath.row == tags.count {
            cell.type = .Add
        } else {
            cell.type = .Normal ; cell.title = tags[indexPath.item]
        }
        
        return cell
    }
    
    @IBAction func tagClicked(button: UIButton) {
        guard button.currentTitle != "+" else { performSegueWithIdentifier(SegueID.AddTag.rawValue, sender: button) ; return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Edite".localizedString, style: .Default, handler: { _ in self.performSegueWithIdentifier(SegueID.EditeTag.rawValue, sender: button) }))
        alert.addAction(UIAlertAction(title: "Delete".localizedString, style: .Destructive, handler: { _ in
            let indexPath = self.indexPathForCellSubView(button)!
            self.tags.removeAtIndex(indexPath.row)
            self.navigationItem.rightBarButtonItem?.enabled = true
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localizedString, style: .Cancel, handler: nil))
        
        alert.modalPresentationStyle = .Popover
        let ppc = alert.popoverPresentationController
        ppc?.sourceView = button ; ppc?.sourceRect = CGRect(origin: button.bounds.center, size: CGSize(width: 1, height: 1))
        
        presentViewController(alert, animated: true, completion: nil)

    }
    
    
    override func doneClicked() {
        done?(tags)
        navigationController?.popViewControllerAnimated(true)

    }

    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddTag:
            guard let dttvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            dttvc.title = "New Tag".localizedString
            dttvc.done = {
                (text) in
                let trimmedText = text?.stringByTrimmingWhitespaceAndNewline.lowercaseString
                guard !String.isBlank(trimmedText) else { return }
                self.tags.append(text!)
                self.navigationItem.rightBarButtonItem?.enabled = true
            }
            
        case .EditeTag:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let button = sender as! UIButton
            let indexPath = indexPathForCellSubView(button)!
            ettvc.title = "Edite Tag".localizedString
            ettvc.text = button.currentTitle
            ettvc.done = {
                (text) in
                let trimmedText = text?.stringByTrimmingWhitespaceAndNewline.lowercaseString
                guard !String.isBlank(trimmedText) else { return }
                self.tags.removeAtIndex(indexPath.row)
                self.tags.insert(text!, atIndex: indexPath.row)
                self.navigationItem.rightBarButtonItem?.enabled = true
            }
        }
    }
    
    private func indexPathForCellSubView(view: UIView) -> NSIndexPath? {
        var superView = view.superview
        while superView != nil {
            if let cell = superView as? UICollectionViewCell { return collectionView?.indexPathForCell(cell) }
            superView = superView!.superview
        }
        return nil
    }
    
    private enum SegueID: String {  case AddTag , EditeTag }

}



extension CGRect {
    var center: CGPoint {
        return CGPoint(x: origin.x + size.width/2, y: origin.y + size.height/2)
    }
}

