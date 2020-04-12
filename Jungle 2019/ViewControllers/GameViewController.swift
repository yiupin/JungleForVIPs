//
//  ViewController.swift
//  testing_724_2
//
//  Created by TEDY on 25/7/2019.
//  Copyright © 2019 CityU_Henry. All rights reserved.
//

// viewDidLoad -> viewWillAppear -> viewDidAppear -> viewWillDisapear -> viewDidDisappear

import UIKit
import Speech
import AVFoundation

final class GameViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "zh_Hant_HK"))
    private var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 0: Local Game    1: Online Game
    var gameMode: Int = 0
    var gameModel: GameModel?
    
    var game: GameView?
    
    var chessboardHeight: CGFloat?      // height of GameView
    var chessboardWidth: CGFloat?       // width of GameView
    var gridRect: CGRect?       // CGRect of the GameView
    
    var returnBtnDown: UIButton?
    var returnBtnUp: UIButton?
    var speechBtnDown: UIButton?
    var speechBtnUp: UIButton?
    var restartBtnDown: UIButton?
    var restartBtnUp: UIButton?
    var undoBtnDown: UIButton?
    var undoBtnUp: UIButton?
    var hintBtnDown: UIButton?
    var hintBtnUp: UIButton?
    
    var myLabel: UILabel?
    var myLabel2: UILabel?
    
    var recognizedText : String = ""
    var recognitionLimiter: Timer?
    var recognitionLimitSec: Int = 10
    var detectionTimer: Timer?
    var detectionTimeLimitSec: Int = 2
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var accessibleElements: [Any]?
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        let notificationName = Notification.Name("game")
        NotificationCenter.default.addObserver(self, selector: #selector(gameFunctions(noti:)), name: notificationName, object: nil)
        let notificationName2 = Notification.Name("last move")
        NotificationCenter.default.addObserver(self, selector: #selector(updateLastMoveLabel(noti:)), name: notificationName2, object: nil)
  
        commonInit()
            
        speechRecognizer?.delegate = self
            
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
                
            var isButtonEnabled = false
                
            switch authStatus {  //5
                case .authorized:
                    isButtonEnabled = true
                    
                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")
                    
                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
                @unknown default:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")            }
                
            OperationQueue.main.addOperation() {
                self.speechBtnDown?.isEnabled = isButtonEnabled
                self.speechBtnUp?.isEnabled = isButtonEnabled
            }
        }
            
        initAccessibilityElements()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.InterruptEvent()
    }
    
    func commonInit() {
        let screenSize = UIScreen.main.bounds.size
        calculateGridForSize(size: screenSize)
        
        let bgImageView = UIImageView(frame: UIScreen.main.bounds)
        bgImageView.image = UIImage(named: "img_chess_Background_new")
        self.view.addSubview(bgImageView)
        self.view.sendSubviewToBack(bgImageView)
        
        // add GameView
        if (gameMode == 0) {
            gameModel = GameModel()
            game = GameView(frame: gridRect!, model: gameModel!)
        }
        else if (gameMode == 1) {
            game = GameView(frame: gridRect!, model: gameModel!)
        }
        
        self.view.addSubview(game!)
        
        // add return buttons to MenuView
        let returnBtnImg = UIImage(named: "img_chess_return")
        returnBtnDown = UIButton(type: .custom)
        returnBtnDown?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight!, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        returnBtnDown?.setImage(returnBtnImg, for: .normal)
        returnBtnDown?.addTarget(self, action: #selector(GameViewController.backToMenu), for: .touchUpInside)
        self.view.addSubview(returnBtnDown!)
        
        returnBtnUp = UIButton(type: .custom)
        returnBtnUp?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! * 6 / 7, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        returnBtnUp?.setImage(returnBtnImg, for: .normal)
        returnBtnUp?.addTarget(self, action: #selector(GameViewController.backToMenu), for: .touchUpInside)
        returnBtnUp?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.view.addSubview(returnBtnUp!)

        // add speech input buttons
        speechBtnDown = UIButton(frame: CGRect(x: (screenSize.width -  chessboardWidth! / 2) - chessboardWidth! * 3 / 7 / 2, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight!, width: chessboardWidth! * 3 / 7, height: chessboardWidth! / 7))
        speechBtnDown?.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
        speechBtnDown?.setTitleColor(UIColor.black, for: .normal)
        speechBtnDown?.backgroundColor = UIColor.white
        speechBtnDown?.addTarget(self, action: #selector(GameViewController.speechInput), for: .touchUpInside)
        speechBtnDown?.adjustsImageWhenHighlighted = true
        speechBtnDown?.adjustsImageWhenDisabled = true
        self.view.addSubview(speechBtnDown!)
        
        speechBtnUp = UIButton(frame: CGRect(x: (screenSize.width -  chessboardWidth! / 2) - chessboardWidth! * 3 / 7 / 2, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7, width: chessboardWidth! * 3 / 7, height: chessboardWidth! / 7))
        speechBtnUp?.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
        speechBtnUp?.setTitleColor(UIColor.black, for: .normal)
        speechBtnUp?.backgroundColor = UIColor.white
        speechBtnUp?.addTarget(self, action: #selector(GameViewController.speechInput), for: .touchUpInside)
        speechBtnUp?.adjustsImageWhenHighlighted = true
        speechBtnUp?.adjustsImageWhenDisabled = true
        speechBtnUp?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.view.addSubview(speechBtnUp!)
        
        let restartBtnImgDown = UIImage(named: "img_chess_restart")
        restartBtnDown = UIButton(type: .custom)
        restartBtnDown?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! / 7, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight!, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        restartBtnDown?.setImage(restartBtnImgDown, for: .normal)
        restartBtnDown?.addTarget(self, action: #selector(GameViewController.restartGame), for: .touchUpInside)
        self.view.addSubview(restartBtnDown!)
        
        
        restartBtnUp = UIButton(type: .custom)
        restartBtnUp?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! * 5 / 7, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        restartBtnUp?.setImage(restartBtnImgDown, for: .normal)
        restartBtnUp?.addTarget(self, action: #selector(GameViewController.restartGame), for: .touchUpInside)
        restartBtnUp?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.view.addSubview(restartBtnUp!)
        
        let undoBtnImgDown = UIImage(named: "img_chess_undo")
        undoBtnDown = UIButton(type: .custom)
        undoBtnDown?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! * 5 / 7, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight!, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        undoBtnDown?.setImage(undoBtnImgDown, for: .normal)
        undoBtnDown?.addTarget(self, action: #selector(GameViewController.undoRed), for: .touchUpInside)
        self.view.addSubview(undoBtnDown!)
        
        undoBtnUp = UIButton(type: .custom)
        undoBtnUp?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! * 1 / 7, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        undoBtnUp?.setImage(undoBtnImgDown, for: .normal)
        undoBtnUp?.addTarget(self, action: #selector(GameViewController.undoBlack), for: .touchUpInside)
        undoBtnUp?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.view.addSubview(undoBtnUp!)
        
        let hintBtnDownImg = UIImage(named: "img_chess_hint")
        hintBtnDown = UIButton(type: .custom)
        hintBtnDown?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2 + chessboardWidth! * 6 / 7, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight!, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        hintBtnDown?.setImage(hintBtnDownImg, for: .normal)
        hintBtnDown?.addTarget(self, action: #selector(GameViewController.hint), for: .touchUpInside)
        self.view.addSubview(hintBtnDown!)
        
        hintBtnUp = UIButton(type: .custom)
        hintBtnUp?.frame = CGRect(x: (screenSize.width - chessboardWidth!) / 2, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7, width: chessboardWidth! / 7, height: chessboardWidth! / 7)
        hintBtnUp?.setImage(hintBtnDownImg, for: .normal)
        hintBtnUp?.addTarget(self, action: #selector(GameViewController.hint), for: .touchUpInside)
        hintBtnUp?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.view.addSubview(hintBtnUp!)
        
        if (game?.model.isOnlineGame)! {
            restartBtnDown?.isEnabled = false
            restartBtnUp?.isEnabled = false
            undoBtnDown?.isEnabled = false
            undoBtnUp?.isEnabled = false
        }
        
        myLabel = UILabel(
            frame: CGRect(x: (screenSize.width -  screenSize.width) / 2, y: (screenSize.height - chessboardHeight!) / 2 + chessboardHeight! + chessboardWidth! / 7, width: screenSize.width, height: chessboardWidth! / 7))
        myLabel?.backgroundColor = UIColor.darkGray
        myLabel?.textColor = UIColor.white
        myLabel?.font = UIFont(name: "Helvetica-Light", size: 20)
        myLabel?.textAlignment = .left
        myLabel?.text = NSLocalizedString("Will display last move here", comment: "")
        self.view.addSubview(myLabel!)

        myLabel2 = UILabel(
            frame: CGRect(x: (screenSize.width -  screenSize.width) / 2, y: (screenSize.height - chessboardHeight!) / 2 - chessboardWidth! / 7 * 2, width: screenSize.width, height: chessboardWidth! / 7))
        myLabel2?.backgroundColor = UIColor.darkGray
        myLabel2?.textColor = UIColor.white
        myLabel2?.font = UIFont(name: "Helvetica-Light", size: 20)
        myLabel2?.textAlignment = .left
        myLabel2?.text = NSLocalizedString("Will display last move here", comment: "")
        myLabel2?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)

        self.view.addSubview(myLabel2!)
    }
    
    func calculateGridForSize(size: CGSize) {
        // calculate the gridRect
        if (size.height/size.width < 12/7.1) {
            chessboardHeight = size.height / 12 * 9
            chessboardWidth = size.height / 12 * 7
        }
        else {
            chessboardWidth = size.width
            chessboardHeight = chessboardWidth! / 7 * 9
        }
        self.gridRect = CGRect(x: (size.width - chessboardWidth!) / 2, y: (size.height - chessboardHeight!) / 2, width: chessboardWidth!, height: chessboardHeight!)
    }
    
    // basic game functions
    @objc func gameFunctions(noti: Notification) {
        if let userInfo = noti.userInfo, let message = userInfo[NotificationInfo.message] {
            let content = message as! String
            print(content)
            if (content == "back to menu") {
                backToMenu()
            }
            else if (content == "Black Win" || content == "Red Win") {
                let alert = UIAlertController(title: NSLocalizedString("Game Over", comment: ""), message: NSLocalizedString(content, comment: ""), preferredStyle: UIAlertController.Style.alert)
                let action = UIAlertAction(title: NSLocalizedString("Play Again", comment: ""), style: UIAlertAction.Style.default, handler: {action in self.restartGame()})
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func updateLastMoveLabel(noti: Notification) {
        if let userInfo = noti.userInfo, let message = userInfo[NotificationInfo.message] {
            let content = message as! String
            myLabel?.text = NSLocalizedString(content, comment: "")
            myLabel2?.text = NSLocalizedString(content, comment: "")
        }
    }

    func setGameModel(model: GameModel) {
        self.gameModel = model
    }
    
    func setGameMode(mode: Int) {
        self.gameMode = mode
    }
    
    @objc func undoBlack() {
        game?.model.undo(player: .black)
        game?.updateView()
    }
    
    @objc func hint() {
        textToAction(player: nil, piece: nil, action: "移動", row: nil, column: nil, check: true)
    }
    
    @objc func undoRed() {
        game?.model.undo(player: .red)
        game?.updateView()
    }
    
    @objc func restartGame() {
        game?.removeFromSuperview()
        gameModel = GameModel()
        game = GameView(frame: gridRect!, model: gameModel!)
        self.view.addSubview(game!)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("start the game", comment: "")))
    }
    
    @objc func backToMenu() {
        self.navigationController?.popViewController(animated: false)
    }
    
    // Voice Recognition functions
    @objc func speechInput() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechBtnDown!.isEnabled = false
            speechBtnUp!.isEnabled = false
            reset_audio()
            speechBtnDown!.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
            speechBtnUp!.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
        } else {
            UIAccessibility.post(notification: .screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Start Recording", comment: "")))
            let systemSoundID: SystemSoundID = 1110
            AudioServicesPlaySystemSound(systemSoundID)
            speechBtnDown!.isEnabled = false
            speechBtnUp!.isEnabled = false
            self.startRecording()
            startTimer()
            speechBtnDown!.setTitle(NSLocalizedString("Start Recording", comment: ""), for: .normal)
            speechBtnUp!.setTitle(NSLocalizedString("Start Recording", comment: ""), for: .normal)
        }
    }
    
    func startTimer() {
        self.stopTimer()
        recognitionLimiter = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.recognitionLimitSec),
            target: self,
            selector:#selector(InterruptEvent),
            userInfo: nil,
            repeats: false
        )
    }
    
    func stopTimer() {
        if recognitionLimiter != nil {
            recognitionLimiter?.invalidate()
            recognitionLimiter = nil
        }
    }
    
    func startDetectionTimer() {
        detectionTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.detectionTimeLimitSec),
            target: self,
            selector:#selector(InterruptEvent),
            userInfo: nil,
            repeats: false
        )
    }
    
    func stopDetectionTimer() {
        if detectionTimer != nil {
            detectionTimer?.invalidate()
            detectionTimer = nil
        }
    }
    
    func handleVoiceRecognitionResult(_ resource : String) {
        var player_key: String?
        var piece_key: String?
        var action_key: String?
        var row_key: String?
        var column_key: String?
        var check_key: Bool = false
        
        if resource.contains("藍") == true {
            player_key = "藍"
        } else if resource.contains("紫") == true {
            player_key = "紫"
        }
        let pieces_string = ["獅","虎","狗","貓","鼠","豹","狼","象"]
        for piece in pieces_string {
            if resource.contains(piece) == true {
                piece_key = piece
                break
            }
        }
        let actions_string = ["位置","行到","食","選擇","移動","係邊","去","吃掉"]
        for action in actions_string {
            if resource.contains(action) == true {
                action_key = action
                break
            }
        }
        let row_string = ["1","2","3","4","5","6","7","8","9"]
        for row in row_string {
            if resource.contains(row) == true {
                row_key = row
                break
            }
        }
        let column_string = ["A","B","C","D","E","F","G"]
        for column in column_string {
            if resource.contains(column) == true {
                column_key = column
                break
            }
        }
        if resource.contains("可以") == true {
            check_key = true
        }
        
        textToAction(player: player_key, piece: piece_key, action: action_key, row: row_key, column: column_key, check: check_key)
    }
    
    // ["位置","行到","食","選擇","移動到","係邊","去"]
    func textToAction(player: String?, piece: String?, action: String?, row: String?, column: String?, check: Bool) {
        
        if check {
            if game?.model.chosenPiece == nil {
                 UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("please select piece first", comment: "")))
            } else {
                switch action {
                case "行","移動","去":
                    let moves = game?.model.getAvailableMove()
                    if moves != nil {
                        var post: String = NSLocalizedString("can move to", comment: "")
                        for move in moves! {
                            if (game?.model.checkAnyPiece(row: move.row, column: move.column))! {
                                for piece in (game?.model.pieces)! {
                                    if piece.coord.row == move.row && piece.coord.column == move.column {
                                        post.append(String(format: "%@ %@, %@%@ %@, %@", NSLocalizedString((piece.player.rawValue), comment: ""), NSLocalizedString((piece.type.rawValue), comment: ""), NSLocalizedString((game?.model.convertColumn(column: piece.coord.column))!, comment: ""), (game?.model.convertRow(row: piece.coord.row))!, NSLocalizedString((piece.coord.type.rawValue), comment: ""), NSLocalizedString((piece.coord.border.rawValue), comment: "")))
                                        break
                                    }
                                }
                            } else {
                                let gridCell = game?.model.getPosition(row: move.row, column: move.column)
                                post.append(String(format: "%@%@, %@, %@", NSLocalizedString((game?.model.convertColumn(column: gridCell!.column))!, comment: ""), (game?.model.convertRow(row: gridCell!.row))!, NSLocalizedString((gridCell?.type.rawValue)!, comment: ""), NSLocalizedString((gridCell?.border.rawValue)!, comment: "")))
                            }
                        }
                        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: post)
                    } else {
                        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, it cant move", comment: "")))
                    }
                case "食","吃掉":
                    let moves = game?.model.getAvailableMove()
                    if moves != nil {
                        var post: String = NSLocalizedString("can capture", comment: "")
                        var check = false
                        for move in moves! {
                            if (game?.model.checkAnyPiece(row: move.row, column: move.column))! {
                                for piece in (game?.model.pieces)! {
                                    if piece.coord.row == move.row && piece.coord.column == move.column {
                                        check = true
                                        post.append(String(format: "%@ %@, %@%@ %@, %@", NSLocalizedString((piece.player.rawValue), comment: ""), NSLocalizedString((piece.type.rawValue), comment: ""), NSLocalizedString((game?.model.convertColumn(column: piece.coord.column))!, comment: ""), (game?.model.convertRow(row: piece.coord.row))!, NSLocalizedString((piece.coord.type.rawValue), comment: ""), NSLocalizedString((piece.coord.border.rawValue), comment: "")))
                                        break
                                    }
                                }
                            }
                        }
                        if check {
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: post)
                        } else {
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, it cant capture any pieces", comment: "")))
                        }
                    } else {
                        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, it cant capture any pieces", comment: "")))
                    }
                                
                default:
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't understand", comment: "")))
                }
            }
            return
        }
        
        
        var piece_temp: GameModel.Piece?
        if let player = player, let piece = piece {
            let playerType = convertStringToPlayerType(input: player)
            let pieceType = convertStringToPieceType(input: piece)
            for p in (game?.model.pieces)! {
                if p.player == playerType && p.type == pieceType {
                    piece_temp = p
                }
            }
        }
        
        switch action {
        case "位置","係邊":
            if piece_temp != nil {
                if piece_temp!.eaten {
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@, %@,     ,     ,", NSLocalizedString(piece_temp!.player.rawValue, comment: ""), NSLocalizedString(piece_temp!.type.rawValue, comment:""), NSLocalizedString("has been captured", comment: "")))
                } else {
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@ %@, %@ %@, %@ %@   ,     ,", NSLocalizedString((piece_temp?.player.rawValue)!, comment: ""), NSLocalizedString((piece_temp?.type.rawValue)!, comment:""), NSLocalizedString("'s location is", comment:""), NSLocalizedString((gameModel?.convertColumn(column: piece_temp!.coord.column))!, comment: ""), NSLocalizedString((gameModel?.convertRow(row: (piece_temp?.coord.row)!))!, comment: ""), NSLocalizedString(piece_temp!.coord.type.rawValue, comment: ""), NSLocalizedString(piece_temp!.coord.border.rawValue, comment: "")))
                }
            } else {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't know which piece you are searching for", comment: "")))
            }
        case "選擇":
            if piece_temp != nil {
                if piece_temp!.eaten {
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@, %@,     ,     ,", NSLocalizedString(piece_temp!.player.rawValue, comment: ""), NSLocalizedString(piece_temp!.type.rawValue, comment:""), NSLocalizedString("has been captured", comment: "")))
                } else if piece_temp?.player == game?.model.currentPlayer {
                    game?.touchedGridIndex(gridIndex: GridIndex(row: piece_temp!.coord.row, column: (piece_temp?.coord.column)!))
                } else {
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@%@,     ,     ,", NSLocalizedString("fail to select, now is", comment: ""),NSLocalizedString((game?.model.currentPlayer.rawValue)! + "'s Turn", comment: "")))
                }
            } else {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't know which piece you want to select?", comment: "")))
            }
        case "行","移動","去":
            if piece_temp != nil {
                game?.touchedGridIndex(gridIndex: GridIndex(row: piece_temp!.coord.row, column: (piece_temp?.coord.column)!))
                if game!.chosenOnePiece {
                    if let row = row, let column = column {
                        print(piece_temp?.coord.column != gameModel?.convertColumnBack(column: column))
                        if piece_temp?.coord.row != gameModel?.convertRowBack(row: row) || piece_temp?.coord.column != gameModel?.convertColumnBack(column: column) {
                            game?.touchedGridIndex(gridIndex: GridIndex(row: (gameModel?.convertRowBack(row: row))!, column: (gameModel?.convertColumnBack(column: column))!))
                        } else {
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,   %@%@, %@     ,     ,", NSLocalizedString("cant move", comment: ""), NSLocalizedString((piece_temp?.player.rawValue)!, comment: ""), NSLocalizedString((piece_temp?.type.rawValue)!, comment: ""), NSLocalizedString("is already there", comment: "")))
                        }
                    } else {
                        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't know which position you want to move", comment: "")))
                    }
                }
            } else if game!.chosenOnePiece {
                if let row = row, let column = column {
                    print((gameModel?.convertRowBack(row: row))!)
                    print((gameModel?.convertColumnBack(column: column))!)
                    game?.touchedGridIndex(gridIndex: GridIndex(row: (gameModel?.convertRowBack(row: row))!, column: (gameModel?.convertColumnBack(column: column))!))
                } else {
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't know which position you want to move", comment: "")))
                }
            } else {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("please select piece first", comment: "")))
            }
        default:
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("Sorry, I don't understand", comment: "")))
        }
    }
    
    // 藍=red 紫=black
    func convertStringToPlayerType(input: String) -> GameModel.Player? {
        if input == "藍" {
            return GameModel.Player.red
        } else if input == "紫" {
            return GameModel.Player.black
        }
        return nil
    }
    
    // "獅","虎","狗","貓","鼠","豹","狼","象",
    func convertStringToPieceType(input: String) -> GameModel.PieceType? {
        switch input {
        case "獅":
            return GameModel.PieceType.Lion
        case "虎":
            return GameModel.PieceType.Tiger
        case "狗":
            return GameModel.PieceType.Dog
        case "貓":
            return GameModel.PieceType.Cat
        case "鼠":
            return GameModel.PieceType.Rat
        case "豹":
            return GameModel.PieceType.LeoPard
        case "狼":
            return GameModel.PieceType.Wolf
        case "象":
            return GameModel.PieceType.Elepant
        default:
            return nil
        }
    }
    
    @objc func InterruptEvent() {
        stopDetectionTimer()
        stopTimer()
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
    }
    
    func startRecording() {
        self.game?.isUserInteractionEnabled  = false
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = self.getInputNode()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.contextualStrings = expectedString
        recognitionRequest.shouldReportPartialResults = true

        self.recognizedText = ""
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
                self.stopDetectionTimer()
                self.stopTimer()
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                recognitionRequest.endAudio()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.speechBtnDown!.isEnabled = true
                self.speechBtnDown!.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
                self.speechBtnUp!.isEnabled = true
                self.speechBtnUp!.setTitle(NSLocalizedString("Voice Control", comment: ""), for: .normal)
                self.handleVoiceRecognitionResult(self.recognizedText)
                self.reset_audio()
                self.game?.isUserInteractionEnabled  = true
            }
            self.stopDetectionTimer()
            self.startDetectionTimer()
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speechBtnDown!.isEnabled = true
            speechBtnUp!.isEnabled = true
        } else {
            speechBtnDown!.isEnabled = false
            speechBtnUp!.isEnabled = false
        }
    }
    
    func reset_audio(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            //try audioSession.setMode(AVAudioSession.Mode.default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
    }
    
    func getInputNode() -> AVAudioInputNode {
        return audioEngine.inputNode
    }
    
    
    
    func initAccessibilityElements() {
        if (self.accessibleElements == nil) {
            self.accessibleElements = []
            for _ in 0..<20 {
                let part = UIAccessibilityElement(accessibilityContainer: self)
                self.accessibleElements?.append(part)
            }
        }
        self.setVoiceOver()
    }
    
    
    func setVoiceOver() {
        self.myLabel?.isAccessibilityElement = true
        accessibleElements![0] = myLabel!
        
        self.myLabel2?.isAccessibilityElement = true
        accessibleElements![1] = myLabel2!
        
        // VoiceOver: returnBtnDown
        self.returnBtnDown?.isAccessibilityElement = true
        self.returnBtnDown?.accessibilityLabel = NSLocalizedString("return to game menu", comment: "")
        accessibleElements![2] = returnBtnDown!
        
        // VoiceOver: returnBtnUP
        self.returnBtnUp?.isAccessibilityElement = true
        self.returnBtnUp?.accessibilityLabel = NSLocalizedString("return to game menu", comment: "")
        accessibleElements![3] = returnBtnUp!
        
        // VoiceOver: gameView
        accessibleElements![4] = game!
        
        // VoiceOver: speechBtnDown
        self.speechBtnDown?.isAccessibilityElement = true
        self.speechBtnDown?.accessibilityLabel = NSLocalizedString("Voice Control", comment: "")
        accessibleElements![5] = speechBtnDown!
        
        self.speechBtnUp?.isAccessibilityElement = true
        self.speechBtnUp?.accessibilityLabel = NSLocalizedString("Voice Control", comment: "")
        accessibleElements![6] = speechBtnUp!
        
        // VoiceOver: restartBtnDown
        self.restartBtnDown?.isAccessibilityElement = true
        self.restartBtnDown?.accessibilityLabel = NSLocalizedString("restart", comment: "")
        accessibleElements![7] = restartBtnDown!
        
        // VoiceOver: restartBtnUP
        self.restartBtnUp?.isAccessibilityElement = true
        self.restartBtnUp?.accessibilityLabel = NSLocalizedString("restart", comment: "")
        accessibleElements![8] = restartBtnUp!
        
        // VoiceOver: undoBtnDown
        self.undoBtnDown?.isAccessibilityElement = true
        self.undoBtnDown?.accessibilityLabel = NSLocalizedString("undo", comment: "")
        accessibleElements![7] = undoBtnDown!
        
        // VoiceOver: undoBtnUp
        self.undoBtnUp?.isAccessibilityElement = true
        self.undoBtnUp?.accessibilityLabel = NSLocalizedString("undo", comment: "")
        accessibleElements![8] = undoBtnUp!
        
        // VoiceOver: hintBtnDown
        self.hintBtnDown?.isAccessibilityElement = true
        self.hintBtnDown?.accessibilityLabel = NSLocalizedString("hint", comment: "")
        accessibleElements![9] = hintBtnDown!
        
        // VoiceOver: hintBtnUp
        self.hintBtnUp?.isAccessibilityElement = true
        self.hintBtnUp?.accessibilityLabel = NSLocalizedString("hint", comment: "")
        accessibleElements![10] = hintBtnUp!
        
        self.accessibilityElements = accessibleElements
    }
    

    // Voice Recognition String
    var expectedString: [String] =
        ["紫獅","紫虎","紫狗","紫貓","紫鼠","紫豹","紫狼","紫象",
         "藍獅","藍虎","藍狗","藍貓","藍鼠","藍豹","藍狼","藍象",
         "獅","虎","狗","貓","鼠","豹","狼","象",
         "獅子","老虎","狗","老鼠","豹","柴狼","大象",
         "紫方","藍方",
         "位置","行到","食","選擇","移動到","係邊","去","可以","吃掉",
         "A","B","C","D","E","F","G",
         "1","2","3","4","5","6","7","8","9",
         "A1","A2","A3","A4","A5","A6","A7","A8","A9",
         "B1","B2","B3","B4","B5","B6","B7","B8","B9",
         "C1","C2","C3","C4","C5","C6","C7","C8","C9",
         "D1","D2","D3","D4","D5","D6","D7","D8","D9",
         "E1","E2","E3","E4","E5","E6","E7","E8","E9",
         "F1","F2","F3","F4","F5","F6","F7","F8","F9",
         "G1","G2","G3","G4","G5","G6","G7","G8","G9",
        ]
}

