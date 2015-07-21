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
       var lazyCreateFetchedDataController = FetchedDataController(experiment: self.experiment)
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
    
    private func doLike() {
        print("doLike")
    }
    
    private func doUnLike() {
        print("doUnLike")
    }
    
    private func doDelete() {
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
        let experimentSection = fetchedDataController.sections[section]
        return experimentSection.name
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
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
    }
    
    private func performAction(type type: FetchedDataController.ButtonCellType) {
        switch type {
        case .Like:
            doLike()
        case .UnLike:
            doUnLike()
        case .Delete:
            doDelete()
        }
    }

    // MARK: - Table View Edited Method
    
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let sectionTitle = fetchedDataController.sections[indexPath.section].name
        
        switch sectionTitle {
        case Experiment.Constants.ReviewsKey:
            return true
        default: break
        }

        return false
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        let sectionTitle = fetchedDataController.sections[indexPath.section].name
        
        switch sectionTitle {
        case Experiment.Constants.ReviewsKey:
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
        
        tableView.beginUpdates()
        let sectionTitle = fetchedDataController.sections[indexPath.section].name
            
            switch sectionTitle {
            case Experiment.Constants.ReviewsKey:
                switch editingStyle {
                case .Insert:
                    let review = Review.insertNewReview()
                    fetchedDataController.addRelationshipObject(review, inSection: indexPath.section)
                    
                case .Delete:
                    fetchedDataController.removeRelationshipObjectAtIndexPath(indexPath)
                    
                default: break
                }

                
            default: break
            }
            
            
            
        
        tableView.endUpdates()

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






