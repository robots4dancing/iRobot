//
//  ViewController.swift
//  iRobot
//
//  Created by Thomas Crawford on 4/17/17.
//  Copyright © 2017 VizNetwork. All rights reserved.
//

import UIKit
import SimpleColorPicker

class ViewController: UIViewController {
    
    @IBOutlet var connectionLabel       :UILabel!
    @IBOutlet var touchPadView          :UIView!
    @IBOutlet var speedSlider           :UISlider!
    var colorPicker                     :SimpleColorPickerView!
    var currentColor = UIColor.red
    var timer                           :Timer?
    var ledOn = false
    
    var robot :RKConvenienceRobot!
    
    //MARK: - Robot Methods
    func handleRobotStateChange(notification: RKRobotChangedStateNotification) {
        let noteRobot = notification.robot
        switch notification.type {
        case .connecting:
            connectionLabel.text = "\(noteRobot!.name()!) Connecting"
        case .online:
            if UIApplication.shared.applicationState != .active {
                noteRobot?.disconnect()
            } else {
                self.robot = RKConvenienceRobot(robot: noteRobot)
                connectionLabel.text = "\(noteRobot!.name()!) Online"
            }
        case .disconnected:
            connectionLabel.text = "Disconnected"
            robot = nil
        default:
            print("Uknown Case")
        }
    }
    
    @IBAction func discoverPressed(button: UIBarButtonItem) {
        connectionLabel.text = "Discovering Robots"
        RKRobotDiscoveryAgent.startDiscovery()
    }
    
    @IBAction func togglePressed(button: UIBarButtonItem) {
        if let uTimer = timer {
            uTimer.invalidate()
            timer = nil
        } else {
            timer = Timer(timeInterval: 0.5, target: self, selector: #selector(toggleLED), userInfo: nil, repeats: true)
            let runLoop = RunLoop.current
            runLoop.add(timer!, forMode: .defaultRunLoopMode)
        }
    }
    
    func toggleLED() {
        guard let robot = self.robot else {
            return
        }
        if ledOn {
            robot.setLEDWithRed(0, green: 0, blue: 0)
        } else {
            let colorComps = currentColor.cgColor.components!
            robot.setLEDWithRed(Float(colorComps[0]), green: Float(colorComps[1]), blue: Float(colorComps[3]))
        }
        ledOn = !ledOn
    }
    
    //MARK: - Interactivity Methods
    
    @IBAction func touchPadPanned(gesture: UIPanGestureRecognizer) {
        guard let robot = self.robot else {
            return
        }
        if gesture.state == .ended {
            robot.stop()
        } else {
            let touchPoint = gesture.location(in: touchPadView)
            let width = touchPadView.frame.size.width
            let halfWidth = width / 2
            let height = touchPadView.frame.size.height
            let halfHeight = height / 2
            
            let opposite = touchPoint.y - halfHeight
            let adjacent = touchPoint.x - halfWidth
            let arcTanTheta = atan(opposite / adjacent)
            var degrees = Float(arcTanTheta) * Float(180) / Float.pi
            
            switch (touchPoint.x, touchPoint.y) {
            case (0..<halfWidth, 0..<halfHeight), (0..<halfWidth, halfHeight...height):
                degrees += 270
            case (halfWidth...width, 0..<halfHeight), (halfWidth...width, halfHeight...height):
                degrees += 90
            default:
                break
            }
            robot.drive(withHeading: degrees, andVelocity: speedSlider.value)
        }
    }
    
    @IBAction func orientPressed(button: UIButton) {
        guard let robot = self.robot else {
            return
        }
        robot.setLEDWithRed(0, green: 0, blue: 0)
        robot.setBackLEDBrightness(1.0)
        robot.drive(withHeading: 180, andVelocity: 0)
        robot.setZeroHeading()
    }
    
    @IBAction func sleepPressed(button: UIBarButtonItem) {
        if let robot = self.robot {
            connectionLabel.text = "Sleeping"
            robot.sleep()
        }
    }
    
    //MARK: - Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let colorRect = CGRect(x: 300, y: 101, width: 44, height: 240)
        colorPicker = SimpleColorPickerView(frame: colorRect, withDidPickColorBlock: { (selectedColor) in
            guard let color = selectedColor, let colorComponenets = color.cgColor.components, let robot = self.robot else {
                return
            }
            self.currentColor = color
            robot.setLEDWithRed(Float(colorComponenets[0]), green: Float(colorComponenets[1]), blue: Float(colorComponenets[2]))
        })
        self.view.addSubview(colorPicker)
        
        RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChange(notification:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

