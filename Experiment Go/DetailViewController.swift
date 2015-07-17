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
        super.setEditing(editing, animated: true)
        updateUI()
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
        let titleRow = DetailViewController.Row.TextField(Experiment.Constants.TitleKey, title)
        let bodyRow = DetailViewController.Row.TextField(Experiment.Constants.BodyKey, experiment.body)
        let propertySection = DetailViewController.Section(title: Experiment.Constants.PropertyKey, rows: [titleRow, bodyRow])
        result.append(propertySection)
        
        // Section 1: Reviews
        var reviewRows: [DetailViewController.Row] = []
        if var reviews = experiment.reviews?.allObjects as? [Review] {

            reviews.sortInPlace { $0.createDate! > $1.createDate! }

            
            for review in reviews {
                let row = DetailViewController.Row.RightDetail(review.whoReview!.name!, review.body!)
                reviewRows.append(row)
            }
        }

        
        if editing {
            let row = DetailViewController.Row.Basic(Review.Constants.EntityNameKey)
            reviewRows.append(row)
        }
        
        let reviewsSection = DetailViewController.Section(title: Experiment.Constants.ReviewsKey, rows: reviewRows)
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
        let usersLikeMeSection = DetailViewController.Section(title: Experiment.Constants.UsersLikeMeKey, rows: usersLikeMeRows)
        result.append(usersLikeMeSection)
        
        return result
    }

    struct Section {
        var title: String?
        var rows: [Row]?
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
        let section = sections?[indexPath.section]
        return section?.rows?[indexPath.row]
    }
    
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let experimentSection = sections![section]
        return experimentSection.rows?.count ?? 0
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
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Table View Edited Method
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if let sectionTitle = sections?[indexPath.section].title {
            switch sectionTitle {
            case Experiment.Constants.ReviewsKey:
                return true
            default: break
            }
            
        }
        return false

    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        if let sectionTitle = sections?[indexPath.section].title {
            switch sectionTitle {
            case Experiment.Constants.ReviewsKey:
                let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
                return indexPath.row == numberOfRows-1 ? .Insert : .Delete
            default: break
            }
            
        }
        
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.beginUpdates()
        if let sectionTitle = sections?[indexPath.section].title {
            
            switch editingStyle {
            case .Insert:
                switch sectionTitle {
                case Experiment.Constants.ReviewsKey:
                    let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
                default: break
                }
                
                NSManagedObjectContext.saveDefaultContext()
                
            case .Delete:
                switch sectionTitle {
                case Experiment.Constants.ReviewsKey:
                    let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
                default: break
                }
                
                NSManagedObjectContext.saveDefaultContext()
                
                
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

public func ==(date1: NSDate, date2: NSDate) -> Bool { return date1.compare(date2) == NSComparisonResult.OrderedSame }
public func <(date1: NSDate, date2: NSDate) -> Bool { return date1.compare(date2) == NSComparisonResult.OrderedAscending }

extension NSDate: Comparable {}




