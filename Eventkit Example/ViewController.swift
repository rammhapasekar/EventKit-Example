//
//  ViewController.swift
//  Eventkit Example
//
//  Created by Ram Mhapasekar on 09/04/17.
//  Copyright © 2017 rammhapasekar. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    //MARK: @IBOutlet
    
    @IBOutlet weak var calendarsTableView: UITableView!

    @IBOutlet weak var permissionAlertView: UIView!
    
    @IBOutlet weak var addEventBtn: UIBarButtonItem!
    
    
    //MARK:
    
    //Create event store instance
    let eventstore = EKEventStore()
    
    var calendars: [EKCalendar]?
    
    var selectedIndexPath: Int!
    
    //MARK:
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        permissionAlertView.alpha = 0
        
        calendarsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "calenderEventCell")
        
        calendarsTableView.tableFooterView = UIView(frame: .zero)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForCalenderAuthorization),name:NSNotification.Name(rawValue: "EnterForground"), object: nil)
        
        checkForCalenderAuthorization()
    }
    
    
    //MARK:
    //MARK: checkForCalenderAuthorization
    
    func checkForCalenderAuthorization(){
        
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
            
        case EKAuthorizationStatus.notDetermined:
            requestAccessToCalender() //this happens on first-run
        
        case EKAuthorizationStatus.authorized:
            loadCalender()
            refreshTableView()
        
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
        // We need to help them give us permission
            displayPopup()
        }
    }
    
    
    //MARK:
    //MARK: requestAccessToCalender
    
    // This method will check for the permission if not then display popup view and show msg
    func requestAccessToCalender(){
        
        eventstore.requestAccess(to: EKEntityType.event, completion:{(accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.sync(execute: {
                    self.loadCalender()
                    self.refreshTableView()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.displayPopup()
                })
            }
        })
    }
    

    func loadCalender(){
        calendarsTableView.isHidden = false
        addEventBtn.isEnabled = true
        self.calendars = eventstore.calendars(for: EKEntityType.event)
    }
    
    
    func refreshTableView(){
        calendarsTableView.isHidden = false
        addEventBtn.isEnabled = true
        calendarsTableView.reloadData()
    }
    
    
    func displayPopup(){
        
        calendarsTableView.isHidden = true
        
        addEventBtn.isEnabled = false
        
        permissionAlertView.alpha = 1
        
        permissionAlertView.transform = CGAffineTransform(scaleX: 0.3, y: 2)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            
            self.permissionAlertView.transform = .identity
        }){ (success) in
            
        }
    }
    
    
    //MARK: 
    //MARK: gotoSettingsBtnClick
    
    // Present application setting page, so user can allow calender permission
   
    @IBAction func gotoSettingsBtnClick(_ sender: Any) {
    
        permissionAlertView.alpha = 0
        let openSettingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.open(openSettingsUrl!, options: [:], completionHandler: nil)
    }
    
    
    //MARK:
    //MARK: addEventBtnClick
    
    // Will display popup so we can add new event in our application
    @IBAction func addEventBtnClick(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Add New Event", message: "", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save Event", style: .default, handler: {
            alert -> Void in
            
            let firstTextField = alertController.textFields![0] as UITextField
            
            print("event :: \(firstTextField.text)")
            
            // Use Event Store to create a new calendar instance
            // Configure its title
            let newCalendar = EKCalendar(for: .event, eventStore: self.eventstore)
            
            newCalendar.title = firstTextField.text ?? "NA"
            
            //Access list of available sources already in eventstore
            //let sourceInEventstore = self.eventstore.sources
            var localSource:EKSource?
            
            for source in self.eventstore.sources
            {
                if (source.sourceType == EKSourceType.calDAV && source.title == "iCloud")
                {
                    localSource = source;
                    
                    break;  
                }
            }
            
            if (localSource == nil)
            {
                for source in self.eventstore.sources
                {
                    if (source.sourceType == EKSourceType.local)
                    {
                        localSource = source;
                        break;
                    }
                }
            }
            
            if localSource != nil{
                newCalendar.source = localSource!
            }
            
            //Save the calender using the eventstore instance and reload calender entry
            
            do{
                try self.eventstore.saveCalendar(newCalendar, commit: true)
                self.loadCalender()
                self.refreshTableView()
            }
            catch{
                self.showError(error: error)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter event"
        }
    
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    //MARK:
    //MARK: showError
   
    // This method will help you to display alertController
    func showError(error: Error){
    
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(OkAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //MARK:
    //MARK: Tableview methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let calendars = self.calendars {
        
            for _ in 0..<calendars.count{
                
                self.calendars = calendars.filter{ $0.title != ""}
            }
            
            return self.calendars!.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = calendarsTableView.dequeueReusableCell(withIdentifier: "calenderEventCell", for: indexPath)
        if let calendars = self.calendars {
            let calendarName = calendars[(indexPath as NSIndexPath).row].title
            cell.textLabel?.text = calendarName
        } else {
            cell.textLabel?.text = "Unknown Calendar Name"
        }
        cell.textLabel?.backgroundColor = UIColor.clear
        
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
    }

    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        selectedIndexPath = indexPath.row
        
        // 1 Add Edit Action
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit" , handler: { (action:UITableViewRowAction!, indexPath:IndexPath) -> Void in
            
            // 2 Add alertviewController as action to the edit button click
            
            let alertController = UIAlertController(title: "Add New Event", message: "", preferredStyle: .alert)
            
            let saveAction = UIAlertAction(title: "Save Event", style: .default, handler: {
                alert -> Void in
               
                do{
                    //Delete calender entry using eventstore
                    
                    try self.eventstore.removeCalendar((self.calendars?[indexPath.row])!, commit: true)
                    self.loadCalender()
                    self.refreshTableView()
                }
                catch{
                    self.showError(error: error)
                }
                
                let firstTextField = alertController.textFields![0] as UITextField
                
                // Use Event Store to create a new calendar instance
                // Configure its title
                let newCalendar = EKCalendar(for: .event, eventStore: self.eventstore)
                
                newCalendar.title = firstTextField.text ?? "NA"  //title is the event that you  want to add to eventstore
                
                //Access list of available sources already in eventstore
                //let sourceInEventstore = self.eventstore.sources
                var localSource:EKSource?
                
                for source in self.eventstore.sources
                {
                    if (source.sourceType == EKSourceType.calDAV && source.title == "iCloud")
                    {
                        localSource = source;
                        
                        break;
                    }
                }
                
                if (localSource == nil)
                {
                    for source in self.eventstore.sources
                    {
                        if (source.sourceType == EKSourceType.local)
                        {
                            localSource = source;
                            break;
                        }
                    }
                }
                
                if localSource != nil{
                    newCalendar.source = localSource!
                }
                
                //Save the calender using the eventstore instance and reload calender entry
                
                do{
                    try self.eventstore.saveCalendar(newCalendar, commit: true)
                    self.loadCalender()
                    self.refreshTableView()
                }
                catch{
                    self.showError(error: error)
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            
            // Add textfield to the alertview
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Enter event"
                textField.text = self.calendars?[indexPath.row].title
            }
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        
        // 3 Add Delete Action
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:IndexPath) -> Void in
            // 4
            do{
                //Delete calender entry using eventstore
                try self.eventstore.removeCalendar((self.calendars?[indexPath.row])!, commit: true)
                self.loadCalender()
                self.refreshTableView()
            }
            catch{
                self.showError(error: error)
            }

        })
        
        editAction.backgroundColor = UIColor.green
        
        // 5 Add UITableViewRowAction
        return [deleteAction,editAction]
    }
}
