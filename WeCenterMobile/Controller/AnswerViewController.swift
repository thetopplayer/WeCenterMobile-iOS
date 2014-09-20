//
//  AnswerViewController.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/8/25.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import UIKit

class AnswerViewController: UIViewController, DTAttributedTextContentViewDelegate, DTLazyImageViewDelegate, UIToolbarDelegate {
    let topBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 44))
    let bottomBar = UIToolbar(frame: CGRect(x: 0, y: UIScreen.mainScreen().bounds.height - 44, width: UIScreen.mainScreen().bounds.width, height: 44))
    let avatarButton = BFPaperButton()
    let nameLabel = UILabel()
    let signatureLabel = UILabel()
    let evaluationButton = BFPaperButton()
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
    var wrapper: UIView! {
        return view.superview
    }
    var contentTextView: DTAttributedTextView {
        return view as DTAttributedTextView
    }
    var answerID: NSNumber! = nil
    var data: (question: Question, answer: Answer, user: User)? = nil
    init(answerID: NSNumber) {
        super.init(nibName: nil, bundle: nil)
        self.answerID = answerID
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        view = DTAttributedTextView(frame: UIScreen.mainScreen().bounds)
        topBar.addSubview(avatarButton)
        topBar.addSubview(nameLabel)
        topBar.addSubview(signatureLabel)
        topBar.addSubview(evaluationButton)
        contentTextView.alwaysBounceVertical = true
        contentTextView.shouldDrawImages = true
        contentTextView.backgroundColor = UIColor.materialGray100()
        contentTextView.textDelegate = self
        evaluationButton.frame = CGRect(x: view.bounds.width - 80, y: 0, width: 80, height: topBar.bounds.height)
        evaluationButton.addTarget(self, action: "toggleEvaluation", forControlEvents: .TouchUpInside)
        evaluationButton.backgroundColor = UIColor.clearColor()
        avatarButton.backgroundColor = UIColor.materialGray100()
        avatarButton.frame = CGRect(x: 10, y: 7, width: 30, height: 30)
        avatarButton.layer.masksToBounds = true
        avatarButton.layer.cornerRadius = avatarButton.bounds.width / 2
        nameLabel.frame.origin = CGPoint(x: avatarButton.frame.origin.x + avatarButton.bounds.width + 10, y: avatarButton.frame.origin.y)
        nameLabel.frame.size = CGSize(width: view.bounds.width - nameLabel.frame.origin.x - evaluationButton.bounds.width, height: avatarButton.bounds.height / 2)
        nameLabel.font = UIFont.systemFontOfSize(12)
        nameLabel.textColor = UIColor.materialGray800()
        signatureLabel.frame = nameLabel.frame
        signatureLabel.frame.origin.y += avatarButton.bounds.height / 2
        signatureLabel.font = nameLabel.font
        signatureLabel.textColor = UIColor.materialGray600()
        topBar.delegate = self
        bottomBar.delegate = self
        let likeItem = UIBarButtonItem(image: UIImage(named: "Star-Line"), style: .Plain, target: nil, action: nil)
        let uselessItem = UIBarButtonItem(image: UIImage(named: "Flag-Line"), style: .Plain, target: nil, action: nil)
        let commentItem = UIBarButtonItem(image: UIImage(named: "Conversation-Line"), style: .Plain, target: nil, action: nil)
        let createFlexibleSpaceItem: () -> UIBarButtonItem = {
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
        Answer.fetchDataForAnswerViewControllerByAnswerID(answerID,
            strategy: .CacheOnly,
            success: {
                data in
                self.data = data
                self.reloadData()
                Answer.fetchDataForAnswerViewControllerByAnswerID(self.answerID,
                    strategy: .NetworkOnly,
                    success: {
                        data in
                        self.data = data
                        self.reloadData()
                    },
                    failure: nil)
            },
            failure: nil)
    }
    override func viewDidAppear(animated: Bool) {
        if firstAppear {
            firstAppear = false
            wrapper!.addSubview(topBar)
            wrapper!.addSubview(bottomBar)
            topBar.frame.origin.y += msr_navigationBar!.bounds.height
            contentTextView.contentInset.top += topBar.bounds.height
            contentTextView.contentInset.bottom += bottomBar.bounds.height
            contentTextView.scrollIndicatorInsets.top += topBar.bounds.height
            contentTextView.scrollIndicatorInsets.bottom += bottomBar.bounds.height
        }
    }
    func reloadData() {
        navigationItem.title = data?.question.title
        if data?.user.avatar != nil {
            avatarButton.setImage(data!.user.avatar, forState: .Normal)
        } else {
            data?.user.fetchAvatarImage(
                success: {
                    self.avatarButton.setImage(self.data!.user.avatar, forState: .Normal)
                },
                failure: nil)
        }
        nameLabel.text = data?.user.name
        signatureLabel.text = data?.user.signature
        evaluationButtonState = data?.answer.evaluation ?? .None
        evaluationButton.setTitle(data?.answer.agreementCount?.stringValue, forState: .Normal)
        var string = ""
        if data?.answer.body != nil {
            string = "<p style='padding: 10px'>\(data!.answer.body!)</p>"
        }
        contentTextView.attributedString = NSAttributedString(
            HTMLData: string.dataUsingEncoding(NSUTF8StringEncoding),
            options: [
                NSTextSizeMultiplierDocumentOption: 1,
                DTDefaultFontSize: 16,
                DTDefaultTextColor: UIColor.materialGray700(),
                DTDefaultLinkColor: UIColor.materialBlue500(),
                DTDefaultLinkHighlightColor: UIColor.materialPurple300(),
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
        for attachment in contentTextView.attributedTextContentView.layoutFrame.textAttachmentsWithPredicate(predicate) as [DTTextAttachment] {
            if attachment.originalSize == CGSizeZero {
                attachment.originalSize = sizeWithImageSize(size)
                didUpdate = true
            }
        }
        if didUpdate {
            contentTextView.relayoutText()
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
    
    func positionForBar(bar: UIBarPositioning!) -> UIBarPosition {
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
    
}
