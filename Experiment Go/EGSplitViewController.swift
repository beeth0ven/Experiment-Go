//
//  EGSplitViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/6/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EGSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func loadView() {
        super.loadView()
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initConfiguration()
    }
    
    func initConfiguration() {
        let controller = detailViewControllers.first! as! UINavigationController
        viewControllers.append(controller)
        controller.topViewController!.navigationItem.leftBarButtonItem = displayModeButtonItem()
        delegate = self
    }
    
    lazy var detailViewControllers =  DetailViewControllerType.allTypes.map { $0.viewController }
    
    func showDetailViewControllerAtIndex(index: Int) {
        let controller = detailViewControllers[index]  as! UINavigationController
        showDetailViewController(controller, sender: nil)
        controller.topViewController!.navigationItem.leftBarButtonItem = displayModeButtonItem()
        controller.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        toggleMasterView()
    }
    
    // MARK: - UISplitView Controller Delegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        return true
    }
    
    
    private enum DetailViewControllerType: String {
        case Home
        case Search
        case Notification
        
        var viewController: UIViewController {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            switch self {
            case .Home:
                return storyboard.instantiateViewControllerWithIdentifier("HomeNav")
            case .Search:
                return storyboard.instantiateViewControllerWithIdentifier("SearchNav")
            case .Notification:
                return storyboard.instantiateViewControllerWithIdentifier("NotificationNav")
            }
        }
        
        static var allTypes: [DetailViewControllerType] {
            return [
                DetailViewControllerType.Home,
                DetailViewControllerType.Search,
                DetailViewControllerType.Notification
            ]
        }
        
        
    }
    
    
}
