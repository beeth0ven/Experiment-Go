//
//  DetailViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
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
//        experiment?.setValue("Hallo", forKey: "title")
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
            if let context = self.experiment!.managedObjectContext {
                completion?()
                context.saveContext()
            }
        }
    }
    
    
    
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    private struct Storyboard {
        static let BasicCellReuseIdentifier = "BasicCell"
        static let TextFieldCellReuseIdentifier = "TextFieldCell"
    }
    
    
    struct Section {
        var title: String?
        var rows: [Row]?
    }
    
    enum Row {
        
        case Basic(String)
        case TextField(String, String?)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return Storyboard.BasicCellReuseIdentifier
            case .TextField(_, _):
                return Storyboard.TextFieldCellReuseIdentifier
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.experiment?.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let experimentSection = self.experiment?.sections![section]
        return experimentSection?.rows?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        if let row = self.experiment?.rowAtIndexPath(indexPath) {
            cell = tableView.dequeueReusableCellWithIdentifier(row.cellReuseIdentifier, forIndexPath: indexPath)
                self.configureCell(cell!, useRow: row)
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let experimentSection = self.experiment?.sections![section]
        return experimentSection?.title
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    //
    //     func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    //        if editingStyle == .Delete {
    //            let context = self.fetchedResultsController.managedObjectContext
    //            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath))
    //
    //            do {
    //                try context.save()
    //            } catch {
    //                // Replace this implementation with code to handle the error appropriately.
    //                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    //                //print("Unresolved error \(error), \(error.userInfo)")
    //                abort()
    //            }
    //        }
    //    }
    //
        func configureCell(cell: UITableViewCell, useRow row: Row) {
            
            switch row {
            case .Basic(let title):
                cell.textLabel?.text = title
            case .TextField(let title, let editableText):
                if let textFieldTableViewCell = cell as? TextFieldTableViewCell {
                    textFieldTableViewCell.titleLabel.text = title
                    textFieldTableViewCell.textField.text = editableText
                    textFieldTableViewCell.textField.enabled = editing
                    textFieldTableViewCell.textField.delegate = self
                }
            }
        }
    //
    //    // MARK: - Table View Delegate
    
    
         func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    
}

extension DetailViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let textFieldTableViewCell = textFieldTableViewCellWhichContainsTextField(textField) {
            experiment?.setValue(textField.text, forKey: textFieldTableViewCell.titleLabel.text!)
//            if let ex = self.experiment {
////                ex.title = textField.text
//                ex.setValue(textField.text, forKey: textFieldTableViewCell.titleLabel.text!)
//            }
        }
        
        return true
    }
    
    func textFieldTableViewCellWhichContainsTextField(textField: UITextField) -> TextFieldTableViewCell? {
        var superView: UIView? = textField
        repeat { superView = superView!.superview }
            while  (superView != nil) && (superView is TextFieldTableViewCell) == false
//        guard let textFieldTableViewCell = superView as? TextFieldTableViewCell else { return nil }
        
        return superView == nil ? nil : (superView as! TextFieldTableViewCell)
    }
    
}



private extension Experiment {
    
    var sections: [DetailViewController.Section]? {
        var result: [DetailViewController.Section] = []
        // 0.Propertis
        let titleRow = DetailViewController.Row.TextField(Constants.TitleKey, title)
        let bodyRow = DetailViewController.Row.TextField(Constants.BodyKey, body)
        let propertySection = DetailViewController.Section(title: Constants.PropertyKey, rows: [titleRow, bodyRow])
        result.append(propertySection)
        
        // 1.Relationships
        
        return result
    }
    
    func rowAtIndexPath(indexPath: NSIndexPath) -> DetailViewController.Row?{
        let section = sections![indexPath.section]
        let row = section.rows?[indexPath.row]
        return row
    }
}




