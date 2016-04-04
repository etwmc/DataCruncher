//
//  CruncherPartViewController.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 28/10/2015.
//
//

import UIKit
import CruncherCore

public class CruncherPart: NSObject {
    let name: String
    var tick = 0 as UInt16
    var duration: UInt16 = 0
    var timer: NSTimer?
    let actualProcess: CCProcessor
    var viewController: CruncherPartViewController?
    
    init(processor: CCProcessor) {
        actualProcess = processor
        name = NSStringFromClass(processor.dynamicType)
    }
}

public class CruncherPartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var partTitleLabel: UILabel!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var inputPortTableView: UITableView!
    @IBOutlet var outputPortTableView: UITableView!
    
    public var part: CruncherPart? {
        didSet {
            if partTitleLabel != nil {
                //If UI has attached
                reloadPart()
            }
        }
    }
    
    func reloadPart() {
        partTitleLabel.text = part?.name
        
        if let part = part {
            inputPortTableView.hidden   = !CCProcessorType_hasInput(part.actualProcess.type)
            outputPortTableView.hidden  = !CCProcessorType_hasOutput(part.actualProcess.type)
            //Calculate row height
            let maximumPortNumber = max(part.actualProcess.numberOfInput(), part.actualProcess.numberOfOutput())
            let tableHeight = Float(maximumPortNumber>0)*Float(inputPortTableView.sectionHeaderHeight)+Float(maximumPortNumber)*Float(inputPortTableView.rowHeight)
            let viewHeight: Float
            if tableHeight > (150-29) {
                viewHeight = tableHeight+29
            } else {
                viewHeight = 150
            }
            
            let origin = view.frame.origin
            view.frame = CGRect(origin: origin, size: CGSizeMake(300, CGFloat(viewHeight)))
            
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.layer.borderWidth = 1
        self.view.layer.borderColor = UIColor.blackColor().CGColor;
        self.view.layer.cornerRadius = 6
        self.view.layer.masksToBounds = true
        
        reloadPart()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let visualEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: visualEffect)
        blurView.frame = self.view.frame
        //self.view.addSubview(blurView)
        
        let nib = UINib(nibName: "CruncherPortTableViewCell", bundle: nil)
        inputPortTableView.registerNib(nib, forCellReuseIdentifier: "Port");
        outputPortTableView.registerNib(nib, forCellReuseIdentifier: "Port");
        
        let backgroundView = UIView(frame: CGRectZero)
        backgroundView.backgroundColor = UIColor.clearColor()
        
        //inputPortTableView.backgroundView = backgroundView
        //outputPortTableView.backgroundView = backgroundView
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true;
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true;
    }
    
    func partStart() {
        
    }
    
    func partRemainTimeUpdate(time: UInt16) {
        timerLabel.text = String(time)+"s"
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if tableView == inputPortTableView {
            if CCProcessorType_hasInput(part!.actualProcess.type) {
                return 1
            }
        }
        else if tableView == outputPortTableView {
            if CCProcessorType_hasOutput(part!.actualProcess.type) {
                return 1
            }
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == inputPortTableView {
            return "Input"
        }
        else if tableView == outputPortTableView {
            return "Output"
        }
        return nil
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == inputPortTableView {
            if let val = part?.actualProcess.numberOfInput() { return Int(val) }
        }
        else if tableView == outputPortTableView {
            if let val = part?.actualProcess.numberOfOutput() { return Int(val) }
        }
        return 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Port", forIndexPath: indexPath) as! CruncherPortTableViewCell
        let port: Port
        if tableView == inputPortTableView {
            port = InputPort()
        } else {
            port = OutputPort()
        }
        port.name = "Port"
        cell.configureCell(port)
        return cell
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.inputPortTableView.frame.width, height: self.inputPortTableView.sectionHeaderHeight))
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 10
        return label
    }
    
}
