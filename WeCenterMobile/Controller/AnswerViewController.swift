//
//  AnswerViewController.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/8/25.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import UIKit

class AnswerViewController: UIViewController, DTAttributedTextContentViewDelegate, DTLazyImageViewDelegate, UIToolbarDelegate {
    let topBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    let bottomBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    let avatarButton = UIButton()
    let nameLabel = UILabel()
    let signatureLabel = UILabel()
    let evaluationButton = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 0))
    var evaluationButtonState: Answer.Evaluation = .None {
        didSet {
            switch evaluationButtonState {
            case .None:
                evaluationButton.setImage(UIImage(named: "Circle-Wave-Line"), forState: .Normal)
                break
            case .Up:
                evaluationButton.setImage(UIImage(named: "Add-Line"), forState: .Normal)
                break
            case .Down:
                evaluationButton.setImage(UIImage(named: "Minus-Line"), forState: .Normal)
                break
            }
        }
    }
    var firstAppear = true
    var contentTextView = DTAttributedTextView()
    var answerID: NSNumber! = nil
    var answer: Answer? = nil
    init(answerID: NSNumber) {
        super.init(nibName: nil, bundle: nil)
        self.answerID = answerID
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        super.loadView()
        view.addSubview(contentTextView)
        view.addSubview(topBar)
        view.addSubview(bottomBar)
        topBar.addSubview(avatarButton)
        topBar.addSubview(nameLabel)
        topBar.addSubview(signatureLabel)
        topBar.addSubview(evaluationButton)
        contentTextView.alwaysBounceVertical = true
        contentTextView.shouldDrawImages = true
        contentTextView.backgroundColor = UIColor.msr_materialGray100()
        contentTextView.textDelegate = self
        contentTextView.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        evaluationButton.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        evaluationButton.msr_addVerticalEdgeAttachedConstraintsToSuperview()
        evaluationButton.msr_addRightAttachedConstraintToSuperview()
        evaluationButton.addTarget(self, action: "toggleEvaluation", forControlEvents: .TouchUpInside)
        evaluationButton.backgroundColor = UIColor.clearColor()
        avatarButton.backgroundColor = UIColor.msr_materialGray100()
        avatarButton.frame = CGRect(x: 10, y: 7, width: 30, height: 30)
        avatarButton.layer.masksToBounds = true
        avatarButton.layer.cornerRadius = avatarButton.bounds.width / 2
        avatarButton.addTarget(self, action: "pushUserViewController", forControlEvents: .TouchUpInside)
        nameLabel.frame.origin = CGPoint(x: avatarButton.frame.origin.x + avatarButton.bounds.width + 10, y: avatarButton.frame.origin.y)
        nameLabel.frame.size = CGSize(width: view.bounds.width - nameLabel.frame.origin.x - evaluationButton.bounds.width, height: avatarButton.bounds.height / 2)
        nameLabel.font = UIFont.systemFontOfSize(12)
        nameLabel.textColor = UIColor.msr_materialGray800()
        signatureLabel.frame = nameLabel.frame
        signatureLabel.frame.origin.y += avatarButton.bounds.height / 2
        signatureLabel.font = nameLabel.font
        signatureLabel.textColor = UIColor.msr_materialGray600()
        view.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        topBar.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        topBar.delegate = self
        bottomBar.msr_shouldTranslateAutoresizingMaskIntoConstraints = false
        bottomBar.delegate = self
        let likeItem = UIBarButtonItem(image: UIImage(named: "Star-Line"), style: .Plain, target: nil, action: nil)
        let uselessItem = UIBarButtonItem(image: UIImage(named: "Flag-Line"), style: .Plain, target: nil, action: nil)
        let commentItem = UIBarButtonItem(image: UIImage(named: "Conversation-Line"), style: .Plain, target: self, action: "pushCommentListViewController")
        let createFlexibleSpaceItem = {
            () -> UIBarButtonItem in
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        // Needs localization
        likeItem.title = "赞"
        uselessItem.title = "没有帮助"
        commentItem.title = "评论"
        bottomBar.items = [
            createFlexibleSpaceItem(),
            likeItem,
            createFlexibleSpaceItem(),
            uselessItem,
            createFlexibleSpaceItem(),
            commentItem,
            createFlexibleSpaceItem()
        ]
    }
    override func viewDidLoad() {
        answer = Answer.get(ID: answerID, error: nil)
        reloadData()
        Answer.fetch(ID: answerID,
            success: {
                answer in
                self.answer = answer
                self.reloadData()
            }, failure: nil)
    }
    override func viewDidAppear(animated: Bool) {
        if firstAppear {
            firstAppear = false
            view.addSubview(topBar)
            view.addSubview(bottomBar)
            contentTextView.contentInset.top += topBar.bounds.height
            contentTextView.contentInset.bottom += bottomBar.bounds.height
            contentTextView.scrollIndicatorInsets.top += topBar.bounds.height
            contentTextView.scrollIndicatorInsets.bottom += bottomBar.bounds.height
            contentTextView.msr_addAllEdgeAttachedConstraintsToSuperview()
            view.msr_addAllEdgeAttachedConstraintsToSuperview()
            view.addConstraint(NSLayoutConstraint(item: topBar, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: bottomBar, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[top][topBar]-(>=0)-[bottomBar][bottom]",
                options: nil,
                metrics: nil,
                views: [
                    "top": topLayoutGuide,
                    "bottom": bottomLayoutGuide,
                    "topBar": topBar,
                    "bottomBar": bottomBar]))
        }
    }
    func reloadData() {
        navigationItem.title = answer?.question?.title
        if answer?.user?.avatar != nil {
            avatarButton.setImage(answer!.user!.avatar, forState: .Normal)
        } else {
            answer?.user?.fetchAvatar(
                success: {
                    self.avatarButton.setImage(self.answer!.user!.avatar, forState: .Normal)
                },
                failure: nil)
        }
        nameLabel.text = answer?.user?.name
        signatureLabel.text = answer?.user?.signature
        evaluationButtonState = answer?.evaluation ?? .None
        evaluationButton.setTitle(answer?.agreementCount?.stringValue, forState: .Normal)
        contentTextView.attributedString = NSAttributedString(
            HTMLData: "<p style='padding: 10px'>\(answer?.body ?? NSString() /* Could not be 'String' here. I don't want to know why. */ )</p>".dataUsingEncoding(NSUTF8StringEncoding),
            options: [
                NSTextSizeMultiplierDocumentOption: 1,
                DTDefaultFontSize: 16,
                DTDefaultTextColor: UIColor.msr_materialGray700(),
                DTDefaultLinkColor: UIColor.msr_materialBlue500(),
                DTDefaultLinkHighlightColor: UIColor.msr_materialPurple300(),
                DTDefaultLineHeightMultiplier: 1.7,
                DTDefaultLinkDecoration: false
            ],
            documentAttributes: nil)
    }
    
    func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, viewForAttachment attachment: DTTextAttachment!, frame: CGRect) -> UIView! {
        if let imageAttachment = attachment as? DTImageTextAttachment {
            let imageView = DTLazyImageView(frame: frame)
            imageView.shouldShowProgressiveDownload = true
            imageView.image = imageAttachment.image
            imageView.url = imageAttachment.contentURL
            imageView.delegate = self
            return imageView
        }
        return nil
    }
    
    func toggleEvaluation() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        // Needs localization
        alertController.addAction(UIAlertAction(title: "赞同", style: .Default) {
            action in
            self.evaluationButtonState = .Up
        })
        alertController.addAction(UIAlertAction(title: "中立", style: .Default) {
            action in
            self.evaluationButtonState = .None
        })
        alertController.addAction(UIAlertAction(title: "反对", style: .Default) {
            action in
            self.evaluationButtonState = .Down
        })
        showViewController(alertController, sender: self)
    }
    
    func lazyImageView(lazyImageView: DTLazyImageView!, didChangeImageSize size: CGSize) {
        let predicate = NSPredicate(format: "contentURL == %@", lazyImageView.url)
        var didUpdate = false
        for attachment in contentTextView.attributedTextContentView.layoutFrame.textAttachmentsWithPredicate(predicate) as! [DTTextAttachment] {
            if attachment.originalSize == CGSizeZero {
                attachment.originalSize = sizeWithImageSize(size)
                didUpdate = true
            }
        }
        if didUpdate {
            contentTextView.relayoutText()
        }
    }
    
    internal func pushUserViewController() {
        if answer?.user != nil {
            msr_navigationController?.pushViewController(UserViewController(user: answer!.user!), animated: true)
        }
    }
    
    private func sizeWithImageSize(size: CGSize) -> CGSize {
        let maxWidth = view.bounds.width - 20
        if size.width > maxWidth {
            let width = maxWidth
            let height = size.height * (width / size.width)
            return CGSize(width: width, height: height)
        } else {
            return size
        }
    }
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        if bar === topBar {
            return .Top
        } else if bar === bottomBar {
            return .Bottom
        }
        return .Any
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    internal func pushCommentListViewController() {
        msr_navigationController!.pushViewController(AnswerCommentListViewController(answer: answer!), animated: true)
    }
    
}
