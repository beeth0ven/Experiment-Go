//
//  EGSplitViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/6/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EGSplitViewController: UISplitViewController {
    
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

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initConfiguration()
    }
    
    func initConfiguration() {
        let controller = detailViewControllers.first! as! UINavigationController
        viewControllers.append(controller)
        controller.topViewController!.navigationItem.leftBarButtonItem = displayModeButtonItem()
    }
    
    lazy var detailViewControllers: [UIViewController] = {
        return DetailViewControllerType.allTypes.map { $0.viewController }
    }()
    
    func showDetailViewControllerAtIndex(index: Int) {
        let controller = detailViewControllers[index]  as! UINavigationController
        showDetailViewController(controller, sender: nil)
        controller.topViewController!.navigationItem.leftBarButtonItem = displayModeButtonItem()
        controller.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        toggleMasterView()
    }
    
}
