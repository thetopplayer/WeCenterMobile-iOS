//
//  MainViewController.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/7/26.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import GBDeviceInfo
import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MSRSidebarDelegate {
    lazy var contentViewController: MSRNavigationController = {
        [weak self] in
        let vc = MSRNavigationController(rootViewController: HomeViewController(user: User.currentUser!))
        vc.view.backgroundColor = UIColor.whiteColor()
        return vc
    }()
    lazy var sidebar: MSRSidebar = {
        [weak self] in
        let display = GBDeviceInfo.deviceInfo().display
        let widths: [GBDeviceDisplay: CGFloat] = [
            .DisplayUnknown: 200,
            .DisplayiPad: 200,
            .DisplayiPhone35Inch: 220,
            .DisplayiPhone4Inch: 220,
            .DisplayiPhone47Inch: 260,
            .DisplayiPhone55Inch: 300]
        let v = MSRSidebar(width: widths[display]!, edge: .Left)
        v.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
        v.backgroundView!.msr_shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        v.backgroundView!.msr_shadowOffset = CGPointZero
        v.backgroundView!.msr_shadowRadius = 5
        v.backgroundView!.msr_shadowOpacity = 0
        v.overlay = UIView()
        v.overlay!.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        v.delegate = self
        return v
    }()
    lazy var tableView: UITableView = {
        [weak self] in
        let v = UITableView(frame: CGRectZero, style: .Plain)
        v.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.clearColor()
        v.delegate = self
        v.dataSource = self
        v.separatorColor = UIColor.clearColor()
        v.separatorStyle = .None
        v.showsVerticalScrollIndicator = true
        v.delaysContentTouches = false
        v.msr_wrapperView?.delaysContentTouches = false
        if let self_ = self {
            v.addSubview(self_.userView)
            v.contentInset.top = self_.userView.minHeight
        }
        return v
    }()
    lazy var userView: SidebarUserView = {
        [weak self] in
        let v = NSBundle.mainBundle().loadNibNamed("SidebarUserView", owner: nil, options: nil).first as! SidebarUserView
        v.update(user: User.currentUser, updateImage: true)
        return v
    }()
    lazy var cells: [SidebarCategoryCell] = {
        [weak self] in
        return map([
            ("User", "个人中心"),
            ("Home", "首页"),
            ("Explore", "发现"),
            ("Settings", "设置"),
            ("About", "关于")]) {
                let cell = NSBundle.mainBundle().loadNibNamed("SidebarCategoryCell", owner: self?.tableView, options: nil).first as! SidebarCategoryCell
                cell.update(image: UIImage(named: "Sidebar" + $0.0)!, title: $0.1)
                return cell
            }
    }()
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    override func loadView() {
        super.loadView()
        contentViewController.interactivePopGestureRecognizer.requireGestureRecognizerToFail(sidebar.screenEdgePanGestureRecognizer)
        addChildViewController(contentViewController)
        view.addSubview(contentViewController.view)
        view.insertSubview(sidebar, aboveSubview: contentViewController.view)
        sidebar.contentView.addSubview(tableView)
        tableView.msr_addAllEdgeAttachedConstraintsToSuperview()
        automaticallyAdjustsScrollViewInsets = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0), animated: false, scrollPosition: .None)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "currentUserPropertyDidChange:", name: CurrentUserPropertyDidChangeNotificationName, object: nil)
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if tableView.indexPathForSelectedRow() == indexPath {
            return nil
        }
        return indexPath
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sidebar.collapse()
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                contentViewController.setViewControllers([UserViewController(user: User.currentUser!)], animated: true)
                break
            case 1:
                contentViewController.setViewControllers([HomeViewController(user: User.currentUser!)], animated: true)
                break
            case 2:
                contentViewController.setViewControllers([ExploreViewController()], animated: true)
                break
            case 3:
                break
            default:
                break
            }
        }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let inset = scrollView.contentInset.top
        userView.frame = CGRect(x: 0, y: min(-inset, offset), width: scrollView.bounds.width, height: userView.minHeight + max(0, -(offset + inset)))
    }
    func msr_sidebarDidCollapse(sidebar: MSRSidebar) {
        setNeedsStatusBarAppearanceUpdate()
    }
    func msr_sidebarDidExpand(sidebar: MSRSidebar) {
        setNeedsStatusBarAppearanceUpdate()
    }
    func msr_sidebar(sidebar: MSRSidebar, didShowAtPercentage percentage: CGFloat) {
        let limitedPercentage = max(0, min(1, percentage))
        sidebar.backgroundView!.msr_shadowOpacity = limitedPercentage
    }
    func currentUserPropertyDidChange(notification: NSNotification) {
        let key = notification.userInfo![KeyUserInfoKey] as! String
        if key == "avatarData" || key == "name" {
            userView.update(user: User.currentUser, updateImage: key == "avatarData")
        }
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return sidebar.collapsed ? contentViewController.preferredStatusBarStyle() : .LightContent
    }
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
