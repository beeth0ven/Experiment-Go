////
////  DetailViewController.swift
////  Test
////
////  Created by luojie on 7/14/15.
////  Copyright © 2015 LuoJie. All rights reserved.
////
//
//import UIKit
//import CoreData
//
//class DetailViewController: UIViewController {
//    
//    // MARK: - Properties
//    
//    var detailItem: RootObject! {
//        didSet {
//            // Update the view.
//            updateUI()
//        }
//        
//    }
//
//    @IBOutlet weak var tableView: UITableView! {
//        didSet {
//            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
//            tableView.rowHeight = UITableViewAutomaticDimension
//        }
//    }
//    
//    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
//
//
//    // MARK: - View Controller Lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//        self.configureBarButtons()
//        updateUI()
//    }
//    
//    
//    // MARK: - View Configure
//    
//    func configureBarButtons() {
//        
//        if navigationController?.viewControllers.first != self {
//            navigationItem.leftBarButtonItem = nil
//            navigationItem.rightBarButtonItem = closeBarButtonItem
//        }
//        
//    }
//    
//    override func prefersStatusBarHidden() -> Bool {
//        return true
//    }
//    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.Default
//    }
//    
//    
//    func updateUI() {
//        tableView?.reloadData()
//    }
//    // MARK: - User Actions
//    
//    @IBAction func close(sender: UIBarButtonItem) {
//        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
//    }
//    
//    override func setEditing(editing: Bool, animated: Bool) {
//        if self.editing != editing {
//            super.setEditing(editing, animated: true)
//            tableView.setEditing(editing, animated: true)
//            // Toggle Editing Mode Only when the detailItem is not new one.
//            if detailItem.inserted == false { toggleEditingMode(editing) }
//        }
//    }
//    
//    private func toggleEditingMode(editing: Bool) {
//        let options: UIViewAnimationOptions = editing ? .TransitionCurlUp : .TransitionCurlDown
//        UIView.transitionWithView(navigationController!.view,
//            duration: 0.4,
//            options: options,
//            animations: {
//                self.configureBarButtons()
//                self.tableView.reloadData()
//            },
//            completion: nil)
//    }
//
//    // MARK: - Table View Data Structure
//    
//
//     var sectionManagers: [SectionManager] {
//        if _sectionManagers != nil { return _sectionManagers! }
//         _sectionManagers = self.identifiersForSections().map(identifierToSectionManager)
//        return _sectionManagers!
//    }
//    
//    var _sectionManagers: [SectionManager]?
//
//    private lazy var identifierToSectionManager: (String) -> SectionManager = { [unowned self] (identifier) -> SectionManager in
//        let style = self.sectionStyleForIdentifier(identifier)
//        var sectionContent: SectionManager.SectionContent
//        switch style {
//        case .Attribute:
//            let keys = self.cellKeysBySectionIdentifier(identifier)!
//            sectionContent = .Keys(keys)
//            
//        default:
//            let sortDescriptors = self.sortDescriptorsForSectionIdentifier(identifier)
//            
//            let fetchedRelationshipController = FetchedRelationshipController (
//                rootObject: self.detailItem!,
//                relationshipKey: identifier,
//                sortDescriptors: sortDescriptors
//            )
//            fetchedRelationshipController.delegate = self
//            
//            do {
//                try fetchedRelationshipController.performFetch()
//            } catch {
//                abort()
//            }
//            
//            sectionContent = .FetchResultController(fetchedRelationshipController)
//            
//        }
//        
//        return SectionManager(identifier: identifier, style: style, content: sectionContent)
//    }
//    
//    private func sectionStyleForIdentifier(identifier: String) -> SectionManager.Style {
//        let relationshipsByName = detailItem.entity.relationshipsByName
//        guard let relationshipDescription = relationshipsByName[identifier] else { return .Attribute }
//        return relationshipDescription.toMany ? .ToManyRelationship : .ToOneRelationship
//    }
//    
//    // MARK: - Method to override
//    private struct Constants {
//        static let AttributeSectionKey = "Attribute"
//    }
//    
//    struct Storyboard {
//        static let TableViewEstimatedRowHeight: CGFloat = 44
//        static let EmptyStyleCellReuseIdentifier = "EmptyStyleCell"
//        static let InsertStyleCellReuseIdentifier = "InsertStyleCell"
//        static let NumberCellReuseIdentifier = "NumberCell"
//        static let BoolCellReuseIdentifier = "BoolCell"
//        static let TextCellReuseIdentifier = "TextCell"
//        static let DateCellReuseIdentifier = "DateCell"
//        static let ImageCellReuseIdentifier = "ImageCell"
//        static let DetailItemCellReuseIdentifier = "DetailItemCell"
//    }
//    
//    
//    // Section
//    func identifiersForSections() -> [String] {
//        if editing == false {
//            // Public read
//            var relationshipNames = detailItem.entity.relationshipsByName.keys.array
//            relationshipNames.insert(Constants.AttributeSectionKey, atIndex: 0)
//            return relationshipNames
//        } else {
//            // Private write
//            return [Constants.AttributeSectionKey]
//        }
//    }
//    
//    func sortDescriptorsForSectionIdentifier(identifier: String) -> [NSSortDescriptor]? {
//        return [NSSortDescriptor(key: "creationDate", ascending: false)]
//    }
//    
//    // Cell
//    func cellKeysBySectionIdentifier(identifier: String) -> [String]? {
//        return detailItem.entity.attributesByName.keys.array
//    }
//    
//    func cellReuseIdentifierFromItemKey(key: String) -> String? {
//        switch key {
//        case "title", "body", "id":
//            return Storyboard.TextCellReuseIdentifier
//            
//        case "creationDate", "modificationDate":
//            return Storyboard.DateCellReuseIdentifier
//            
//        case "imageData":
//            return Storyboard.ImageCellReuseIdentifier
//        case "reviews", "usersLikeMe", "whoPost":
//            return Storyboard.DetailItemCellReuseIdentifier
//            
//        default:
//            return nil
//            
//        }
//    }
//
//    
//}
//
//extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
//    
//    // MARK: - Table View Data Source
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return sectionManagers.count ?? 0
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sectionManager = sectionManagers[section]
//        switch sectionManager.content {
//        case .Keys(let keys):
//            return keys.count ?? 0
//        case .FetchResultController(let fetchedRelationshipController):
//            return fetchedRelationshipController.fetchedObjects?.count ?? 0
//        }
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let sectionManager = sectionManagers[indexPath.section]
//        switch sectionManager.content {
//        case .Keys(let keys):
//            let key = keys[indexPath.row]
//            return attributeCellForKey(key, atIndexPath: indexPath)
//            
//        case .FetchResultController(let fetchedRelationshipController):
//            let object = fetchedRelationshipController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0)) as! RootObject
//            return relationshipCellForKey(sectionManager.identifier, object: object, atIndexPath: indexPath)
//            
//        }
//    }
//    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        let sectionManager = sectionManagers[section]
//        return sectionManager.identifier
//    }
//    
//    private func attributeCellForKey(key: String, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let objectValue = ObjectValue(rootObject: detailItem, key: key)
//        let cell = cellFromItemKey(key, atIndexPath: indexPath) as! ObjectValueTableViewCell
//        cell.objectValue = objectValue
//        return cell
//    }
//    
//    private func relationshipCellForKey(key: String, object: RootObject, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = cellFromItemKey(key, atIndexPath: indexPath) as! RootObjectTableViewCell
//        cell.detailItem = object
//        return cell
//    }
//    
//    func cellFromItemKey(key: String, atIndexPath indexPath: NSIndexPath)  -> UITableViewCell {
//        guard let identifier = cellReuseIdentifierFromItemKey(key) else { return UITableViewCell() }
//        return tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
//    }
//
//    
//    // MARK: - Table View Edited Method
//    
//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        let editingStyle = self.tableView(tableView, editingStyleForRowAtIndexPath: indexPath)
//        return editingStyle == .None ? false : true
//    }
//    
//    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return .None
//    }
//    
//    // MARK: - Table View Delegate
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
//    }
//}
//
//
//extension DetailViewController: NSFetchedResultsControllerDelegate {
//    // MARK: - NSFetched Results Controller Delegate
//    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.beginUpdates()
//    }
//    
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        guard type.rawValue != 0 else { return }
//        guard let fetchedRelationshipController = controller as? FetchedRelationshipController else { return }
//        let section: Int = sectionIndexForIdentifier(fetchedRelationshipController.relationshipKey)!
//        switch type {
//        case .Insert:
//            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndexPath!.row, inSection: section)] , withRowAnimation: .Fade)
//        case .Delete:
//            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath!.row, inSection: section)], withRowAnimation: .Fade)
//        case .Update:
//            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath!.row, inSection: section)], withRowAnimation: .Fade)
//        case .Move:
//            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath!.row, inSection: section)], withRowAnimation: .Fade)
//            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndexPath!.row, inSection: section)], withRowAnimation: .Fade)
//        }
//    }
//    
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.endUpdates()
//    }
//    
//    
//    private func sectionIndexForIdentifier(identifier: String) -> Int? {
//        for (index, sectionManager) in sectionManagers.enumerate() {
//            if sectionManager.identifier == identifier {
//                return index
//            }
//        }
//        return nil
//    }
//    
//
//}
//
//
