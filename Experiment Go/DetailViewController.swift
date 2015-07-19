//
//  DetailViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    var isNewExperimentAdded = false
    
    var experiment: Experiment! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureBarButtons() {
        if !isNewExperimentAdded {
            navigationItem.rightBarButtonItem = editButtonItem()
        } else {
            editing = true
        }
    }
    
    func updateUI() {
        configureView()
        tableView?.reloadData()
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        
    }
    
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
    
    
    override func setEditing(editing: Bool, animated: Bool) {
        if self.editing != editing {
            super.setEditing(editing, animated: true)
            tableView.setEditing(editing, animated: true)
            toggleTableViewEditingMode(editing)
        }
    }
    
    private func toggleTableViewEditingMode(editing: Bool) {
        guard let sections = self.sections else { return }
        for (sectionIndex, section) in sections.enumerate() {
            if section.entityToAddWhileEditingWithNameKey != nil {
                tableView.beginUpdates()
                var indexPath: NSIndexPath!
                if editing {
                    indexPath = NSIndexPath(forRow: section.rowsWhenEditing.count - 1, inSection: sectionIndex)
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } else {
                    indexPath = NSIndexPath(forRow: section.rows.count, inSection: sectionIndex)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
                tableView.endUpdates()
            }
            
        }
        
    }
    
    
    @IBAction func save(sender: UIBarButtonItem) {
        dismissSelfAndSveContext(nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissSelfAndSveContext {
            [unowned self] _ in
            if let context = self.experiment!.managedObjectContext {
                if self.isNewExperimentAdded {
                    context.deleteObject(self.experiment!)
                }
            }
        }
        
        
    }
    
    private func dismissSelfAndSveContext(completion: (() -> Void)?) {
        presentingViewController?.dismissViewControllerAnimated(true) {
            completion?()
            NSManagedObjectContext.saveDefaultContext()
        }
    }
    
}


extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    private struct Storyboard {
        static let BasicCellReuseIdentifier = "BasicCell"
        static let RightDetailReuseIdentifier = "RightDetailCell"
        static let TextFieldCellReuseIdentifier = "TextFieldCell"
        static let TableViewEstimatedRowHeight: CGFloat = 44
        
    }
    
    // MARK: - Table View Data Struct
    var sections: [DetailViewController.Section]? {
        var result: [DetailViewController.Section] = []
        
        // Section 0: Property
        let titleRow = DetailViewController.Row.TextField(Experiment.Constants.TitleKey, experiment.title)
        
        let bodyRow = DetailViewController.Row.TextField(Experiment.Constants.BodyKey, experiment.body)
        let propertySection = DetailViewController.Section(title: Experiment.Constants.PropertyKey, rows: [titleRow, bodyRow], entityToAddWhileEditingWithNameKey: nil)
        result.append(propertySection)
        
        // Section 1: Reviews
        var reviewRows: [DetailViewController.Row] = []
        if let reviews = experiment.reviewsAsArray {
            for review in reviews {
                let row = DetailViewController.Row.RightDetail(review.whoReview!.name!, review.createDate!.description)
                reviewRows.append(row)
            }
        }
        

        let reviewsSection = DetailViewController.Section(title: Experiment.Constants.ReviewsKey, rows: reviewRows, entityToAddWhileEditingWithNameKey: Review.Constants.EntityNameKey)
        result.append(reviewsSection)
        
        
        // Section 2: UsersLikeMe
        var usersLikeMeRows: [DetailViewController.Row] = []
        if experiment.usersLikeMe?.count > 0 {
            for object in experiment.usersLikeMe! {
                if let userLikeMe = object as? User {
                    let row = DetailViewController.Row.Basic(userLikeMe.name!)
                    usersLikeMeRows.append(row)
                }
            }
        }
        
        let usersLikeMeSection = DetailViewController.Section(title: Experiment.Constants.UsersLikeMeKey, rows: usersLikeMeRows, entityToAddWhileEditingWithNameKey: nil)
        result.append(usersLikeMeSection)
        
        return result
    }

    struct Section {
        var title: String?
        var rows: [Row]!
        var entityToAddWhileEditingWithNameKey: String?
        
        var rowsWhenEditing: [Row]! {
            var result = rows
            if let entityName = entityToAddWhileEditingWithNameKey {
                let row = DetailViewController.Row.Basic(entityName)
                result.append(row)
            }
            return result
        }
        
    }
    
    enum Row {
        
        case Basic(String)
        case RightDetail(String, String)
        case TextField(String, String?)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return Storyboard.BasicCellReuseIdentifier
            case .RightDetail(_, _):
                return Storyboard.RightDetailReuseIdentifier
            case .TextField(_, _):
                return Storyboard.TextFieldCellReuseIdentifier
            }
        }
    }
    
    
    func rowAtIndexPath(indexPath: NSIndexPath) -> DetailViewController.Row?{
        let section =  sections?[indexPath.section]
        let rows = tableView.editing == false ? section?.rows  : section?.rowsWhenEditing
        return rows?[indexPath.row]
    }
    
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let experimentSection = sections![section]
        return tableView.editing == false ? experimentSection.rows.count  : experimentSection.rowsWhenEditing.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        if let row = rowAtIndexPath(indexPath) {
            cell = tableView.dequeueReusableCellWithIdentifier(row.cellReuseIdentifier, forIndexPath: indexPath)
                self.configureCell(cell!, useRow: row)
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let experimentSection = sections![section]
        return experimentSection.title
    }

    

    func configureCell(cell: UITableViewCell, useRow row: Row) {
        
        switch row {
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
        }
    }
    
    
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.editingStyle == .Insert {
           self.tableView(tableView, commitEditingStyle: cell.editingStyle , forRowAtIndexPath: indexPath)
        }
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
    }
    
    
    // MARK: - Table View Edited Method
    
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if tableView.editing {
            if let sectionTitle = sections?[indexPath.section].title {
                switch sectionTitle {
                case Experiment.Constants.ReviewsKey:
                    return true
                default: break
                }
                
            }
        }

        return false
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        if let sectionTitle = sections?[indexPath.section].title {
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
            
        }
        
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.beginUpdates()
        if let sectionTitle = sections?[indexPath.section].title {
            
            
            switch sectionTitle {
            case Experiment.Constants.ReviewsKey:
                switch editingStyle {
                case .Insert:
                    Review.insertNewReviewInExperiment(experiment)
                    let indexPathToInsert = NSIndexPath(forRow: 0, inSection: indexPath.section)
                    tableView.insertRowsAtIndexPaths([indexPathToInsert], withRowAnimation: .Fade)

                    NSManagedObjectContext.saveDefaultContext()
                    
                case .Delete:
                    let context = NSManagedObjectContext.defaultContext()
                    context.deleteObject(experiment.reviewsAsArray![indexPath.row])
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                    NSManagedObjectContext.saveDefaultContext()
                    
                default: break
                }

                
            default: break
            }
            
            
            
        }
        tableView.endUpdates()

    }

}

extension DetailViewController: UITextFieldDelegate {
    
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

public func ==(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedSame }
public func <(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedAscending }

extension NSDate: Comparable {}




