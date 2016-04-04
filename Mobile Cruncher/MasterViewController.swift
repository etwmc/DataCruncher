//
//  MasterViewController.swift
//  Mobile Cruncher
//
//  Created by Wai Man Chan on 1/4/16.
//
//

import UIKit
import CruncherCore

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()

    var buckets: [CCStorageBucket]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        dispatch_async(mobileMonitorGlobalObj.shareObj.cruncherCoreQueue) { () -> Void in
            self.buckets = (CCKeyValueStorage.sharedStorage().fetchAllBucket()?.sort({ (a: CCStorageBucket, b: CCStorageBucket) -> Bool in
                return a.bucketName.compare(b.bucketName) != .OrderedDescending
            }))
            self.tableView.reloadSections(NSIndexSet.init(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            
        }
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = buckets![indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let buckets = self.buckets {
            return buckets.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        //let object = objects[indexPath.row] as! NSDate
        
        if let buckets = buckets {
            let bucket = buckets[indexPath.row]
            cell.textLabel?.text = bucket.bucketName
            cell.detailTextLabel?.text = NSLocalizedString("Unknown", comment: "Unknown Value")
            if let dataObj = bucket.lastestData(1).firstObject as? CCData {
                do {
                    let data = dataObj.valueForKeyPath("obj.value") as! NSData
                    let dict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                    cell.detailTextLabel?.text = dict.allKeys[0].description + ": " + dict.allValues[0].description
                } catch {}
                
            }
            
        } else {
            cell.textLabel?.text = "Loading"
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if let buckets = buckets {
            let bucket = buckets[indexPath.row]
            return [
                UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete", handler: { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
                    
                }),
                UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Monitor", handler: { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
                    bucket.setMonitor(true)
                    tableView.cellForRowAtIndexPath(indexPath)?.setEditing(false, animated: true)
                })
            ]
        }
        else { return nil }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

