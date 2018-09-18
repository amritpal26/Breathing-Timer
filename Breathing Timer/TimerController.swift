//
//  ViewController.swift
//  Breathing Timer
//
//  Created by Amritpal Singh on 2018-09-08.
//  Copyright © 2018 Amritpal Singh. All rights reserved.
//

import UIKit
import UICircularProgressRing
import AVFoundation
import Firebase

class TimerController: UIViewController {

    let USER_NAME_PREF = "user_name_pref"
    let TIMER_2_PREF = "timer_2_pref"
    let SOUND_PREF = "Sound_Pref"
    let VIBRATION_PREF = "Vibration_Pref"
    
    var timerSeconds: [Int] = []
    var selectedTimer: Int = 30
    var remainingTime: Int = 30
    var selectedRow = 0
    var timer = Timer()
    var ref: DatabaseReference!
    
    var isSoundEnabled = false
    var isVibrationEnabled = false
    //audioPlayers.
    var endAudioPlayer = AVAudioPlayer()
    
    let userDefaults = UserDefaults.standard
    
    enum TimerState{
        case RUNNING, PAUSED, STOPPED
    }
    
    var timerState: TimerState = TimerState.STOPPED
    @IBOutlet weak var timerValue: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressView: UICircularProgressRing!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadData()
        setupSoundAndVibration()
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        ref = Database.database().reference()
//        let date = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "ccc MMM dd, yyyy hh:mm:ss"
//        let result = formatter.string(from: date)
//        ref.child("users").child("user 2").childByAutoId().setValue(result)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer.invalidate()
        progressView.value = 0
        timerLabel.text = "0:00"
        timerValue.setTitle(convertToSecString(totalSeconds: timerSeconds[selectedRow]), for: .normal)
        remainingTime = selectedTimer
        timerState = TimerState.STOPPED
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        isSoundEnabled = userDefaults.bool(forKey: SOUND_PREF)
        isVibrationEnabled = userDefaults.bool(forKey: VIBRATION_PREF)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func PauseBtn(_ sender: Any) {
        if timerState == TimerState.RUNNING{
            timer.invalidate()
            timerState = TimerState.PAUSED
            timerValue.isEnabled = true
            progressView.maxValue = 100
        }
    }
    
    @IBAction func StartBtn(_ sender: Any) {
        if timerState != TimerState.RUNNING{
            runTimer()
            timerValue.isEnabled = false
            progressView.maxValue = CGFloat(selectedTimer)
        }
    }
    
    @IBAction func stopBtn(_ sender: Any) {
        if timerState != TimerState.STOPPED{
            timer.invalidate()
            remainingTime = selectedTimer
            timerState = TimerState.STOPPED
            timerLabel.text = "0:00"
            timerValue.isEnabled = true
            progressView.maxValue = CGFloat(selectedTimer)
            progressView.value = CGFloat(selectedTimer)
        }
    }
    
    @IBAction func timerPick(_ sender: Any) {
        let alert = UIAlertController(title: "Timer", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        alert.isModalInPopover = true
        
        let pickerFrame = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 140))
        
        alert.view.addSubview(pickerFrame)
        pickerFrame.dataSource = self
        pickerFrame.delegate = self
        pickerFrame.selectRow(selectedRow, inComponent: 0, animated: false)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            print("You selected " + String(self.selectedTimer))
            self.selectedTimer = self.timerSeconds[self.selectedRow]
            self.remainingTime = self.selectedTimer
            self.timerValue.setTitle(self.convertToSecString(totalSeconds: self.selectedTimer), for: .normal)
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func loadData(){
        let path = Bundle.main.path(forResource:"pickerData", ofType: "plist")
        let dict:NSDictionary = NSDictionary(contentsOfFile: path!)!
        
        if (dict.object(forKey: "TimerSeconds2") != nil) {
            if let secArray = dict.object(forKey: "TimerSeconds2") as? [Int] {
                timerSeconds = secArray
                print(secArray)
            }
        }
        
        selectedRow = userDefaults.integer(forKey: TIMER_2_PREF)
        print(selectedRow)
        timerValue.setTitle(convertToSecString(totalSeconds: timerSeconds[selectedRow]), for: .normal)
    }
    
    func runTimer(){
        timerState = TimerState.RUNNING
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TimerController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer(){
        if remainingTime > 0{
            remainingTime -= 1
            print(String(remainingTime) + "")
            let timeString = convertToSecString(totalSeconds: remainingTime)
            timerLabel.text = timeString
            progressView.value = CGFloat(selectedTimer - remainingTime)
        }else{
            timer.invalidate()
            timerState = TimerState.STOPPED
            remainingTime = selectedTimer
            playSoundAndVibrate()
            sendDataToDatabase()
        }
    }
    
    func convertToSecString(totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if seconds > 9{
            return String(minutes) + ":" + String(seconds)
        }else{
            return String(minutes) + ":0" + String(seconds)
        }
    }
    
    func setupSoundAndVibration(){
        do{
            let endAudioPath = Bundle.main.path(forResource: "final", ofType: "mp3")
            endAudioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: endAudioPath!))
        }catch{
            print(error)
        }
    }
    
    func playSoundAndVibrate(){
        if isSoundEnabled{
            endAudioPlayer.play()
        }
        if isVibrationEnabled{
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    func sendDataToDatabase(){
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "ccc MMM dd, yyyy hh:mm:ss"
        let result = formatter.string(from: date)
        if userDefaults.object(forKey: USER_NAME_PREF) != nil{
            let userName = userDefaults.string(forKey: USER_NAME_PREF)
            ref.child("users").child(userName!).childByAutoId().setValue(result)
        }else{
            ref.child("users").child("default").childByAutoId().setValue(result)
        }
    }
}

extension TimerController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timerSeconds.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return convertToSecString(totalSeconds: timerSeconds[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        selectedRow = row
    }
}

extension TimerController: UIPickerViewDelegate{
    
}

