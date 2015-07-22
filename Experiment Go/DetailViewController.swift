//
//  DetailViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController ,FetchedDataControllerDelegate {
    
    // MARK: - Properties
    
    var experiment: Experiment! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    lazy var fetchedDataController: FetchedDataController = {
       var lazyCreateFetchedDataController = FetchedDataController(experiment: self.experiment, isNewExperimentAdded: self.isNewExperimentAdded)
        lazyCreateFetchedDataController.delegate = self
        return lazyCreateFetchedDataController
    }()
    
    var isNewExperimentAdded = false

    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureBarButtons()
        self.configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        oberveTextField()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopOberveTextField()
    }
    
    // MARK: - User Actions

    override func setEditing(editing: Bool, animated: Bool) {
        if self.editing != editing {
            super.setEditing(editing, animated: true)
            tableView.setEditing(editing, animated: true)
            fetchedDataController.editing = editing
        }
    }

    
    
    @IBAction func save(sender: UIBarButtonItem) {
        dismissSelfAndSveContext(nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissSelfAndSveContext {
            [unowned self] in
            if self.isNewExperimentAdded {
                NSManagedObjectContext.defaultContext().deleteObject(self.experiment!)
            }
        }
    }
    
    private func dismissSelfAndSveContext(completion: (() -> Void)?) {
        presentingViewController?.dismissViewControllerAnimated(true) {
            completion?()
            NSManagedObjectContext.saveDefaultContext()
        }
    }
    
    private func doLikeExperiment() {
        fetchedDataController.addRelationshipObject(User.currentUser(), withSectionIdentifier: .UsersLikeMe)
        fetchedDataController.reloadSectionWithIdentifier(.UserActions)
    }
    
    private func doUnLikeExperiment() {
        fetchedDataController.removeRelationshipObject(User.currentUser(), withSectionIdentifier: .UsersLikeMe)
        fetchedDataController.reloadSectionWithIdentifier(.UserActions)
    }
    
    private func doDeleteExperiment() {
        dismissSelfAndSveContext {
            [unowned self] in
            NSManagedObjectContext.defaultContext().deleteObject(self.experiment!)
        }
    }
    
    
    // MARK: - View Configure
    
    private func configureBarButtons() {
        if !isNewExperimentAdded {
            navigationItem.rightBarButtonItem = editButtonItem()
        } else {
            editing = true
        }
    }
    
    private func updateUI() {
        configureView()
        tableView?.reloadData()
    }
    
    private func configureView() {
        // Update the user interface for the detail item.
        
    }
    
}


extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    private struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
    }
    
       // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedDataController.sections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let experimentSection = fetchedDataController.sections[section]
        return  experimentSection.objects.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        if let object = fetchedDataController.obectAtIndexPath(indexPath) {
            cell = tableView.dequeueReusableCellWithIdentifier(object.cellReuseIdentifier, forIndexPath: indexPath)
                self.configureCell(cell!, useRow: object)
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let experimentSectionInfo = fetchedDataController.sections[section]
        return experimentSectionInfo.identifier.key
    }

    

    func configureCell(cell: UITableViewCell, useRow object: FetchedDataController.Object) {
        
        switch object {
        case .Basic(let title):
            cell.textLabel?.text = title
        case .RightDetail(let title, let detailText):
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detailText
        case .TextField(let title, let editableText):
            if let textFieldTableViewCell = cell as? TextFieldTableViewCell {
                textFieldTableViewCell.titleLabel.text = title
                textFieldTableViewCell.textField.text = editableText
                textFieldTableViewCell.textField.enabled = editing
                textFieldTableViewCell.textField.delegate = self
            }
        case .Button(let type):
            cell.textLabel?.text = type.description
            cell.backgroundColor = type.preferedColor
        }
    }
    
    
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.editingStyle == .Insert {
            self.tableView(tableView, commitEditingStyle: cell.editingStyle, forRowAtIndexPath: indexPath)
        }
        
        // Handle User Actions
        if let object = fetchedDataController.obectAtIndexPath(indexPath)  {
            switch object {
            case .Button(let type):
                performAction(type: type)
            default: break
            }
        }
        
    }
    
    private func performAction(type type: FetchedDataController.ButtonCellType) {
        switch type {
        case .Like:
            doLikeExperiment()
        case .Liking:
            doUnLikeExperiment()
        case .Delete:
            doDeleteExperiment()
        }
        
    }

    // MARK: - Table View Edited Method
    
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let sectionIdentifier = fetchedDataController.sections[indexPath.section].identifier
        switch sectionIdentifier {
        case .Reviews:
            return true
        default: break
        }

        return false
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        let sectionIdentifier = fetchedDataController.sections[indexPath.section].identifier
        
        switch sectionIdentifier {
        case .Reviews:
            let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
            if (indexPath.row == numberOfRows - 1) && tableView.editing {
                return .Insert
            } else {
                return .Delete
            }
        default: break
        }
        
        
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let sectionIdentifier = fetchedDataController.sections[indexPath.section].identifier
        switch sectionIdentifier {
        case .Reviews:
            commitEditingStyle(editingStyle, forReviewAtIndexPath: indexPath)
        default: break
        }
        
    }
    
    private func commitEditingStyle(editingStyle: UITableViewCellEditingStyle, forReviewAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Insert:
            let review = Review.insertNewReview()
            fetchedDataController.addRelationshipObject(review, withSectionIdentifier: .Reviews)
            
        case .Delete:
            fetchedDataController.removeRelationshipObjectAtIndexPath(indexPath)
            
        default: break
        }
    }
    
    // MARK: - Fetched Data Controller Delegate
    
    func controllerWillChangeContent(controller: FetchedDataController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: FetchedDataController, didChangeObjectAtIndexPath indexPath: NSIndexPath, forChangeType type: FetchedDataController.ChangeType) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: FetchedDataController, didChangeSectionAtIndex sectionIndex: Int, forChangeType type: FetchedDataController.ChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Update:
            tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        }
    }

    
    func controllerDidlChangeContent(controller: FetchedDataController) {
        self.tableView.endUpdates()
    }
    
}

extension DetailViewController: UITextFieldDelegate {
    // MARK: - Text Field Delegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func handleTextFieldTextDidChange(notification: NSNotification) {
        guard let textField = notification.object as? UITextField else { return }
        if let textFieldTableViewCell = textFieldTableViewCellWhichContainsTextField(textField) {
            experiment?.setValue(textField.text, forKey: textFieldTableViewCell.titleLabel.text!)
        }
    }
    
    private func oberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self,
            selector: "handleTextFieldTextDidChange:",
            name: UITextFieldTextDidChangeNotification,
            object: nil
        )
    }
    
    private func stopOberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }
    
    func textFieldTableViewCellWhichContainsTextField(textField: UITextField) -> TextFieldTableViewCell? {
        var superView: UIView? = textField
        repeat { superView = superView!.superview }
            while  (superView != nil) && (superView is TextFieldTableViewCell) == false
        return superView == nil ? nil : (superView as! TextFieldTableViewCell)
    }
    
}






