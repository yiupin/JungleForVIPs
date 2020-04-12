//
//  GameView.swift
//  Jungle 2019
//
//  Created by TEDY on 17/9/2019.
//  Copyright © 2019 CityU_Henry. All rights reserved.
//

import Foundation
import UIKit

struct GridIndex {
    var row: Int
    var column: Int
}

class GameView: UIView {
    var model: GameModel
    
    // voiceover
    var accessibleElements: [Any]?
    
    var blockSize: CGSize?
    
    var touchedBlockIndex: GridIndex?
    var pieceViews: [PieceView]?
    
    var chosenPiece: GameModel.Piece?
    var chosenOnePiece: Bool = false
    
    private var isSendingTurn = false
    
    init(frame: CGRect, model: GameModel) {
        self.model = model
        super.init(frame: frame)
        self.blockSize = CGSize(width: self.bounds.size.width/7, height: self.bounds.size.width/7)

        self.touchedBlockIndex?.row = NSNotFound
        self.touchedBlockIndex?.column = NSNotFound
        self.pieceViews = []
        self.setPiece()
        self.initAccessibilityElements()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        for row in 0..<9 {
            for column in 0..<7 {
                self.drawBlock(row: row, column: column)
            }
        }
        updateLastMove()
        self.setVoiceOver()
    }
    
    func drawBlock(row: Int, column: Int) {
        let startX = self.bounds.origin.x + (self.blockSize?.width)! * CGFloat(column)
        let startY = self.bounds.origin.y + (self.blockSize?.height)! * CGFloat(row)
        let blockFrame = CGRect(x: startX, y: startY, width: (self.blockSize?.width)!, height: (self.blockSize?.height)!)
        
        // draw cellground
        if ((row % 2 == 0 && column % 2 == 0) || (row % 2 == 1 && column % 2 == 1)) {
            let bgCellImage1 = UIImage(named: "img_chess_cellground_1")
            bgCellImage1?.draw(in: blockFrame)
        }
        else {
            let bgCellImage2 = UIImage(named: "img_chess_cellground_2")
            bgCellImage2?.draw(in: blockFrame)
        }
        
        let gridCell = self.model.getPosition(row: row, column: column)
        
        if gridCell != nil {
            if gridCell?.type == GameModel.GridType.River {
                let riverImage = UIImage(named: "img_chess_River")
                riverImage?.draw(in: blockFrame)
            }
            else if gridCell?.type == GameModel.GridType.BlackDen {
                let denImage = UIImage(named: "img_chess_Den_b")
                denImage?.draw(in: blockFrame)
            }
            else if gridCell?.type == GameModel.GridType.RedDen {
                let denImage = UIImage(named: "img_chess_Den_r")
                denImage?.draw(in: blockFrame)
            }
            else if gridCell?.type == GameModel.GridType.BlackTrap {
                let denImage = UIImage(named: "img_chess_Trap_b")
                denImage?.draw(in: blockFrame)
            }
            else if gridCell?.type == GameModel.GridType.RedTrap {
                let denImage = UIImage(named: "img_chess_Trap_r")
                denImage?.draw(in: blockFrame)
            }
        }
    }
    
    func blockFrameForPiece(piece: GameModel.Piece) -> CGRect {
        let startX = self.bounds.origin.x + (self.blockSize?.width)! * CGFloat(piece.coord.column)
        let startY = self.bounds.origin.y + (self.blockSize?.height)! * CGFloat(piece.coord.row)
        let blockFrame = CGRect(x: startX, y: startY, width: (self.blockSize?.width)!, height: (self.blockSize?.height)!)
        return blockFrame
    }
    
    func setBlockAtRowAndColumn(row: Int, column: Int) {
        if !model.checkAnyPiece(row: row, column: column) {
            let startX = self.bounds.origin.x + (self.blockSize?.width)! * CGFloat(column)
            let startY = self.bounds.origin.y + (self.blockSize?.height)! * CGFloat(row)
            let blockFrame = CGRect(x: startX, y: startY, width: (self.blockSize?.width)!, height: (self.blockSize?.height)!)
            let gridCell = self.model.getPosition(row: row, column: column)
            
            let part = self.accessibleElements![7 * row + column] as! UIAccessibilityElement
            part.isAccessibilityElement = true
            part.accessibilityLabel = String(format: "%@%@, %@, %@", NSLocalizedString(model.convertColumn(column: gridCell!.column), comment: ""), model.convertRow(row: gridCell!.row), NSLocalizedString((gridCell?.type.rawValue)!, comment: ""), NSLocalizedString((gridCell?.border.rawValue)!, comment: ""))
            part.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(blockFrame, in: self)
        }
        else {
            let part = self.accessibleElements![7 * row + column] as! UIAccessibilityElement
            part.isAccessibilityElement = false
        }
    }
    
    func setPiece() {
        for piece in model.pieces {
            let blockFrame = self.blockFrameForPiece(piece: piece)
            let pieceView = PieceView(frame: blockFrame, piece: piece)
            pieceView.isAccessibilityElement = true
            pieceView.accessibilityLabel = String(format: "%@ %@, %@%@ %@, %@", NSLocalizedString((piece.player.rawValue), comment: ""), NSLocalizedString((piece.type.rawValue), comment: ""), NSLocalizedString(model.convertColumn(column: piece.coord.column), comment: ""), model.convertRow(row: piece.coord.row), NSLocalizedString((piece.coord.type.rawValue), comment: ""), NSLocalizedString((piece.coord.border.rawValue), comment: ""))
            pieceViews?.append(pieceView)
        }
        
        for pieceView in pieceViews! {
            self.addSubview(pieceView)
        }
    }
    
    func updateView() {
        var index = 0
        for piece in model.pieces {
            let blockFrame = self.blockFrameForPiece(piece: piece)
            UIView.animate(withDuration: 0.5, animations: {
                self.pieceViews![index].frame = blockFrame
            })
            self.pieceViews![index].piece = piece
            self.pieceViews![index].backgroundColor = nil
            self.pieceViews![index].accessibilityLabel = String(format: "%@ %@, %@%@ %@, %@", NSLocalizedString((piece.player.rawValue), comment: ""), NSLocalizedString((piece.type.rawValue), comment: ""), NSLocalizedString(model.convertColumn(column: piece.coord.column), comment: ""), model.convertRow(row: piece.coord.row), NSLocalizedString((piece.coord.type.rawValue), comment: ""), NSLocalizedString((piece.coord.border.rawValue), comment: ""))

            index += 1
        }
        self.setNeedsDisplay()
    }
 
    private func returnToMenu() {
        NotificationCenter.default.post(name: .gameMessage, object: nil, userInfo: [NotificationInfo.message: "back to menu"])
    }
    
    private func updateLastMove() {
        NotificationCenter.default.post(name: .updateLastMoveMessage, object: nil, userInfo: [NotificationInfo.message: model.moveRecords.last!])
    }

    // touch events
    func touchedGridIndexFromTouches(touches: Set<UITouch>) -> GridIndex {
        var result = GridIndex(row: -1, column: -1)
        let touch = touches.first!
        let location = touch.location(in: self)
        
        if (self.bounds.contains(location)) {
            result.column = Int(location.x * 7.0 / (self.frame.size.width))
            result.row = Int(location.y * 9.0 / (self.frame.size.height))
        }
        return result
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchedBlockIndex = self.touchedGridIndexFromTouches(touches: touches)
          self.touchedGridIndex(gridIndex: self.touchedBlockIndex!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touched = self.touchedGridIndexFromTouches(touches: touches)
        if (touched.row != self.touchedBlockIndex?.row || touched.column != self.touchedBlockIndex?.column) {
            self.touchedBlockIndex = touched
            self.touchedGridIndex(gridIndex: self.touchedBlockIndex!)
        }
    }

    
    func touchedGridIndex(gridIndex: GridIndex) {
        if model.isOnlineGame {
            guard !isSendingTurn && GameCenterHelper.helper.canTakeTurnForCurrentMatch else {
                return
            }
        }
        
        guard model.winner == nil else {
            return
        }
        
        if self.model.checkAnyPiece(row: gridIndex.row, column: gridIndex.column) && model.pieces[model.getPieceIndex(row: gridIndex.row, column: gridIndex.column)].player == model.currentPlayer {
            selectPiece(gridIndex: gridIndex)
        }
        else if chosenOnePiece {
            if self.model.checkAction(row: gridIndex.row, column: gridIndex.column) {
                // check move
                self.model.move(row: gridIndex.row, column: gridIndex.column)
                
                self.chosenPiece = nil
                self.chosenOnePiece = false
                
                if self.model.winner != nil {
                    
                }
                for v in self.subviews {
                    if v.restorationIdentifier == "green" {
                        v.removeFromSuperview()
                    }
                }
                updateView()
                
                model.checkWinner()
                if model.isOnlineGame {
                    isSendingTurn = true
                    if model.winner != nil {
                        GameCenterHelper.helper.win(model) { error in
                            defer {
                                self.isSendingTurn = false
                            }
                            if let e = error {
                                print("Error winning match: \(e.localizedDescription)")
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("finish game, we now return to game menu", comment: "")))
                                self.returnToMenu()
                            }
                        }
                    } else {
                        GameCenterHelper.helper.endTurn(model) { error in
                            defer {
                                self.isSendingTurn = false
                            }
                            if let e = error {
                                print("Error ending turn: \(e.localizedDescription)")
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("successful move, we now return to game menu", comment: "")))
                                self.returnToMenu()
                            }
                        }
                    }
                }
                else {
                    if model.winner != nil {
                        if model.winner == GameModel.Player.black {
                            NotificationCenter.default.post(name: .gameMessage, object: nil, userInfo: [NotificationInfo.message: "Black Win"])
                        }
                        else if model.winner == GameModel.Player.red {
                            NotificationCenter.default.post(name: .gameMessage, object: nil, userInfo: [NotificationInfo.message: "Red Win"])
                        }
                    }
                }
            } else {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("cant move", comment: "")))
            }
        } else if self.model.checkAnyPiece(row: gridIndex.row, column: gridIndex.column) && model.pieces[model.getPieceIndex(row: gridIndex.row, column: gridIndex.column)].player != model.currentPlayer {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@%@,     ,     ,", NSLocalizedString("fail to select, now is", comment: ""),NSLocalizedString(model.currentPlayer.rawValue + "'s Turn", comment: "")))
        } else if !chosenOnePiece {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("please select a piece first", comment: "")))
        }
    }
    
    func selectPiece(gridIndex: GridIndex) {
        self.model.choosePiece(row: gridIndex.row, column: gridIndex.column)
        self.chosenOnePiece = true
        self.chosenPiece = self.model.chosenPiece
        for pieceView in pieceViews! {
            if pieceView.piece?.coord.row == chosenPiece?.coord.row && pieceView.piece?.coord.column == chosenPiece?.coord.column {
                pieceView.backgroundColor = UIColor.red
            } else {
                pieceView.backgroundColor = nil
            }
        }
        setAvailableMove()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@, %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment:""), NSLocalizedString("is chosen", comment: "")))
    }
    
    func setAvailableMove() {
        for v in self.subviews {
            if v.restorationIdentifier == "green" {
                v.removeFromSuperview()
            }
        }
        setVoiceOver()
        let moves = model.getAvailableMove()
        if moves != nil {
            for move in moves! {
                let startX = self.bounds.origin.x + (self.blockSize?.width)! * CGFloat(move.column)
                let startY = self.bounds.origin.y + (self.blockSize?.height)! * CGFloat(move.row)
                let blockFrame = CGRect(x: startX, y: startY, width: (self.blockSize?.width)!, height: (self.blockSize?.height)!)
                let colorView = UIView(frame: blockFrame)
                colorView.restorationIdentifier = "green"
                if model.checkAnyPiece(row: move.row, column: move.column) {
                    for pieceView in pieceViews! {
                        let piece = pieceView.piece
                        if piece!.coord.row == move.row && piece!.coord.column == move.column {
                            pieceView.accessibilityLabel = String(format: "%@ %@, %@%@ %@, %@, %@", NSLocalizedString((piece!.player.rawValue), comment: ""), NSLocalizedString((piece!.type.rawValue), comment: ""), NSLocalizedString(model.convertColumn(column: piece!.coord.column), comment: ""), model.convertRow(row: piece!.coord.row), NSLocalizedString((piece!.coord.type.rawValue), comment: ""), NSLocalizedString((piece!.coord.border.rawValue), comment: ""), NSLocalizedString("can capture", comment: ""))
                            break
                        }
                    }
                } else {
                    let gridCell = self.model.getPosition(row: move.row, column: move.column)
                    let part = self.accessibleElements![7 * move.row + move.column] as! UIAccessibilityElement
                    part.isAccessibilityElement = true
                    part.accessibilityLabel = String(format: "%@%@, %@, %@ %@", NSLocalizedString(model.convertColumn(column: gridCell!.column), comment: ""), model.convertRow(row: gridCell!.row), NSLocalizedString((gridCell?.type.rawValue)!, comment: ""), NSLocalizedString((gridCell?.border.rawValue)!, comment: ""), NSLocalizedString("can move", comment: ""))
                    part.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(blockFrame, in: self)
                    self.accessibilityElements = accessibleElements
                }
                colorView.backgroundColor = UIColor.green
                colorView.alpha = 0.5
                self.addSubview(colorView)
            }
        }
    }
    
    
    
    
    // init accessibleElements
    func initAccessibilityElements() {
        if (self.accessibleElements == nil) {
            self.accessibleElements = []
            for _ in 0..<100 {
                let part = UIAccessibilityElement(accessibilityContainer: self)
                self.accessibleElements?.append(part)
            }
        }
    }
    
    func setVoiceOver() {
        // VoiceOVer: pieces
        accessibleElements![70] = pieceViews!
        
        // VoiceOver: blocks
        for row in 0..<9 {
            for column in 0..<7 {
                self.setBlockAtRowAndColumn(row: row, column: column)
            }
        }
        self.accessibilityElements = accessibleElements
    }
}

extension Notification.Name {
    static let gameMessage = Notification.Name("game")
    static let updateLastMoveMessage = Notification.Name("last move")
}
