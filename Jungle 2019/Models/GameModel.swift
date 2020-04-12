//
//  GameModel.swift
//  Jungle 2019
//
//  Created by TEDY on 14/9/2019.
//  Copyright © 2019 CityU_Henry. All rights reserved.
//

import Foundation
import GameKit

struct Coord {
    var row: Int
    var column: Int
}

struct GameModel: Codable {
    var turn: Int
    var pieces: [Piece]
    var winner: Player?
    var chosenPiece: Piece?
    
    var records: [[Piece]] = []
    var moveRecords: [String] = []
    
    var isOnlineGame: Bool = false
    
    private(set) var isBlackTurn: Bool
    private var positions: [GridCoordinate] = []
    
    var currentPlayer: Player {
        return isBlackTurn ? .black : .red
    }
    
    var currentOpponent: Player {
        return isBlackTurn ? .red : .black
    }
    
    var messageToDisplay: String {
        if winner != nil {
            if winner == GameModel.Player.black {
                return NSLocalizedString("Black Win", comment: "")
            }
            else if winner == GameModel.Player.red {
                return NSLocalizedString("Red Win", comment: "")
            }
        }
        
        if isBlackTurn {
            return NSLocalizedString("Black's Turn", comment: "")
        }
        else {
            return NSLocalizedString("Red's Turn", comment: "")
        }
    }
    
    init(isBlackTurn: Bool = false) {
        self.isBlackTurn = isBlackTurn
        
        turn = 0
        
        var gridCoordinate: GridCoordinate! = nil
        for row in 0..<9 {
            for column in 0..<7 {
                gridCoordinate = GridCoordinate(row: row, column: column, type: GameModel.getGridType(row: row, column: column), border: GameModel.getGridBorder(row: row, column: column))
                positions.append(gridCoordinate)
            }
        }
        
        pieces = [
            Piece(player: Player.black, coord: GridCoordinate(row: 0, column: 0, type: GridType.Normal, border: GridBorder.Corner), type: PieceType.Lion),
            Piece(player: Player.black, coord: GridCoordinate(row: 0, column: 6, type: GridType.Normal, border: GridBorder.Corner), type: PieceType.Tiger),
            Piece(player: Player.black, coord: GridCoordinate(row: 1, column: 1, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Dog),
            Piece(player: Player.black, coord: GridCoordinate(row: 1, column: 5, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Cat),
            Piece(player: Player.black, coord: GridCoordinate(row: 2, column: 0, type: GridType.Normal, border: GridBorder.Edge), type: PieceType.Rat),
            Piece(player: Player.black, coord: GridCoordinate(row: 2, column: 2, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.LeoPard),
            Piece(player: Player.black, coord: GridCoordinate(row: 2, column: 4, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Wolf),
            Piece(player: Player.black, coord: GridCoordinate(row: 2, column: 6, type: GridType.Normal, border: GridBorder.Edge), type: PieceType.Elepant),
            
            Piece(player: Player.red, coord: GridCoordinate(row: 8, column: 6, type: GridType.Normal, border: GridBorder.Corner), type: PieceType.Lion),
            Piece(player: Player.red, coord: GridCoordinate(row: 8, column: 0, type: GridType.Normal, border: GridBorder.Corner), type: PieceType.Tiger),
            Piece(player: Player.red, coord: GridCoordinate(row: 7, column: 5, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Dog),
            Piece(player: Player.red, coord: GridCoordinate(row: 7, column: 1, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Cat),
            Piece(player: Player.red, coord: GridCoordinate(row: 6, column: 6, type: GridType.Normal, border: GridBorder.Edge), type: PieceType.Rat),
            Piece(player: Player.red, coord: GridCoordinate(row: 6, column: 4, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.LeoPard),
            Piece(player: Player.red, coord: GridCoordinate(row: 6, column: 2, type: GridType.Normal, border: GridBorder.Normal), type: PieceType.Wolf),
            Piece(player: Player.red, coord: GridCoordinate(row: 6, column: 0, type: GridType.Normal, border: GridBorder.Edge), type: PieceType.Elepant)
        ]
        
        records.append(pieces)
        moveRecords.append(NSLocalizedString("Will display last move here", comment: ""))
    }
    
    func checkAnyAvailablePiece(row: Int, column: Int) -> Bool {
        var result = false
        if (!pieces.isEmpty) {
            for index in 0..<pieces.count {
                let piece = pieces[index]
                if (piece.coord.row == row && piece.coord.column == column && piece.player == currentPlayer) {
                    result = true
                    break
                }
            }
        }
        return result
    }
    
    mutating func choosePiece(row: Int, column: Int) {
        chosenPiece = nil
        for index in 0..<pieces.count {
            let piece = pieces[index]
            if piece.coord.row == row && piece.coord.column == column {
                chosenPiece = piece
            }
        }
    }
    
    func getPieceTypeValue(type: PieceType) -> Int {
        switch type {
        case .Rat:
            return 0
        case .Cat:
            return 1
        case .Dog:
            return 2
        case .Wolf:
            return 3
        case .LeoPard:
            return 4
        case .Tiger:
            return 5
        case .Lion:
            return 6
        case .Elepant:
            return 7
        }
    }
    
    // check whether target coord. contains a piece or chosenPiece > that piece
    func checkChosenPieceIsMovable(chosenPiece: Piece, row: Int, column: Int) -> Bool {
        
        var pieceExist = false
        var compareResult = false
        
        for index in 0..<pieces.count {
            let piece = pieces[index]
            if (piece.coord.row == row && piece.coord.column == column && piece.player != chosenPiece.player) {
                pieceExist = true
                if (getPieceTypeValue(type: chosenPiece.type) >= getPieceTypeValue(type: piece.type) && !(chosenPiece.type == PieceType.Elepant && piece.type == PieceType.Rat)) {
                    compareResult = true
                }
                else if (chosenPiece.type == PieceType.Rat && piece.type == PieceType.Elepant) {
                    if chosenPiece.coord.type.rawValue == "River" {
                        compareResult = false
                    } else {
                        compareResult = true
                    }
                }
                else {
                    compareResult = false
                }
                break
            }
        }
        // empty cell/ can move
        if (!pieceExist) {
            return true
        }
        else {
            return compareResult
        }
    }
    
    // row & column is the next step coord.
    mutating func checkAction(row: Int, column: Int) -> Bool {
        if (chosenPiece == nil) {
            print("checkAction: chosenPiece == nil")
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("please select a piece first", comment: ""))
            return false
        }
        
        var result = false
        let gridType = GameModel.getGridType(row: row, column: column)
        
        // differences between next step and chosenPiece
        let verticalValue = abs((chosenPiece?.coord.row)! - row)
        let horizontalValue = abs((chosenPiece?.coord.column)! - column)
        
        // false input (normally never enter)
        if (verticalValue == 0 && horizontalValue == 0) {
            return false
        }
        else if ((verticalValue == 1 && horizontalValue == 0) || (verticalValue == 0 && horizontalValue == 1)) {
            // accepted move distance: 1 grid
            if (gridType == GridType.Normal) {
                result = checkChosenPieceIsMovable(chosenPiece: chosenPiece!, row: row, column: column)
                
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@, %@, %@ %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment:""), NSLocalizedString("Move", comment: ""), convertColumn(column: column), convertRow(row: row)))
            }
            else if (gridType == GridType.River) {
                if (chosenPiece?.type == PieceType.Rat) {
                    result = checkChosenPieceIsMovable(chosenPiece: chosenPiece!, row: row, column: column)
                    
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format:"%@ %@ %@, %@ %@, %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment:""), NSLocalizedString("Swim", comment: ""), convertColumn(column: column), convertRow(row: row), NSLocalizedString("River", comment: "")))
                }
            }
            else if (gridType == GridType.BlackTrap) {
                if currentPlayer == .black {
                    result = true
                }
                else {
                    result = checkChosenPieceIsMovable(chosenPiece: chosenPiece!, row: row, column: column)
                }
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format:"%@ %@ %@, %@ %@, %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment: ""), NSLocalizedString("Move", comment: ""), convertColumn(column: column), convertRow(row: row), NSLocalizedString("Trap", comment: "")))
            }
            else if (gridType == GridType.RedTrap) {
                if currentPlayer == .red {
                    result = true
                }
                else {
                    result = checkChosenPieceIsMovable(chosenPiece: chosenPiece!, row: row, column: column)
                }
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format:"%@ %@ %@, %@ %@, %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment: ""), NSLocalizedString("Move", comment: ""), convertColumn(column: column), convertRow(row: row), NSLocalizedString("Trap", comment: "")))
            }
            else if (gridType == GridType.BlackDen && chosenPiece?.player != .black) {
                result = true
            }
            else if (gridType == GridType.RedDen && chosenPiece?.player != .red) {
                result = true
            }
        }
        else if ((verticalValue > 1 && horizontalValue == 0 ) || (horizontalValue > 1 && verticalValue == 0 )) {
            // check whether the river jump is blocked by others
            if (gridType == .Normal && (chosenPiece?.type == PieceType.Tiger || chosenPiece?.type == PieceType.Lion)) {
                var blockSum = 0
                var pieceSum = 0
                var betweenCellSum = -1
                // horizontal jump
                if (chosenPiece?.coord.row == row && horizontalValue > 1) {
                    betweenCellSum = horizontalValue - 1
                    let maxColumn = max((chosenPiece?.coord.column)!, column)
                    let minColumn = min((chosenPiece?.coord.column)!, column)
                    
                    for betweenColumn in minColumn+1..<maxColumn {
                        if GameModel.getGridType(row: row, column: betweenColumn) == GridType.River {
                            blockSum += 1
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("cant move", comment: ""))
                        }
                        if checkAnyPiece(row: row, column: betweenColumn) {
                            pieceSum += 1
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("Cannot Jump", comment: ""))
                        }
                    }
                }
                else if (chosenPiece?.coord.column == column && verticalValue > 1) {
                    betweenCellSum = verticalValue - 1
                    let maxRow = max((chosenPiece?.coord.row)!, row)
                    let minRow = min((chosenPiece?.coord.row)!, row)
                    for betweenRow in minRow+1..<maxRow {
                        if GameModel.getGridType(row: betweenRow, column: column) == GridType.River {
                            blockSum += 1
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("cant move", comment: ""))
                        }
                        if checkAnyPiece(row: betweenRow, column: column) {
                            pieceSum += 1
                            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("Cannot Jump", comment: ""))
                        }
                    }
                }
                else {
                    print("cannot action on that block!")
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: NSLocalizedString("cant move", comment: ""))
                }
                if (blockSum == betweenCellSum && pieceSum == 0) {
                    print("last checking")
                    result = checkChosenPieceIsMovable(chosenPiece: chosenPiece!, row: row, column: column)

                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format:"%@ %@ %@, %@ %@, %@,     ,     ,", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment: ""), NSLocalizedString("Jump", comment: ""), convertColumn(column: column), convertRow(row: row), NSLocalizedString("Trap", comment: "")))                }
            }
        }
        
//        if (result) {
//            isBlackTurn = !isBlackTurn
//        }
        return result
    }
    
    func checkAvailableMove(piece: Piece) -> Bool {
        var result = false
        let row = piece.coord.row
        let column = piece.coord.column
        let surroundings = [
            Coord(row: row+1, column: column),  // up
            Coord(row: row-1, column: column),  // down
            Coord(row: row, column: column-1),  // left
            Coord(row: row, column: column+1)   // right
        ]
        
        for temp in surroundings {
            if temp.row > 0 || temp.column > 0 {
                if checkChosenPieceIsMovable(chosenPiece: piece, row: temp.row, column: temp.column) {
                    result = true
                    break
                }
                if piece.type == .Lion || piece.type == .Tiger {
                    if GameModel.getGridType(row: temp.row, column: temp.column) == GridType.River {
                        var target: Coord
                        var check = true
                        if temp.row != row {
                            if temp.row < row {
                                target = Coord(row: row-3, column: column)
                                for i in target.row+1..<row {
                                    if checkAnyPiece(row: i, column: column) {
                                        check = false
                                    }
                                }
                                if check {
                                    if checkChosenPieceIsMovable(chosenPiece: piece, row: target.row, column: target.column) {
                                        result = true
                                        break
                                    }
                                }
                            }
                            else if temp.row > row {
                                target = Coord(row: row+3, column: column)
                                for i in row+1..<target.row {
                                    if checkAnyPiece(row: i, column: column) {
                                        check = false
                                    }
                                }
                                if check {
                                    if checkChosenPieceIsMovable(chosenPiece: piece, row: target.row, column: target.column) {
                                        result = true
                                        break
                                    }
                                }
                            }
                        }
                        else {
                            if temp.column < column {
                                target = Coord(row: row, column: column-4)
                                for i in target.column+1..<column {
                                    if checkAnyPiece(row: row, column: i) {
                                        check = false
                                    }
                                }
                                if check {
                                    if checkChosenPieceIsMovable(chosenPiece: piece, row: target.row, column: target.column) {
                                        result = true
                                        break
                                    }
                                }
                            }
                            else if temp.column > column {
                                target = Coord(row: row, column: column+4)
                                for i in column+1..<target.column {
                                    if checkAnyPiece(row: row, column: i) {
                                        check = false
                                    }
                                }
                                if check {
                                    if checkChosenPieceIsMovable(chosenPiece: piece, row: target.row, column: target.column) {
                                        result = true
                                        break
                                    }
                                }
                            }
                        
                        }
                    }
                }
            }
        }
        return result
    }
    
    mutating func checkWinner() {
        if checkAnyPiece(row: 0, column: 3) {
            self.winner = Player.red
        }
        else if checkAnyPiece(row: 8, column: 3) {
            self.winner = Player.black
        }
        
        var blackPieces = false
        var redPieces = false
        for piece in pieces {
            if piece.player == .black && piece.coord.row >= 0 && piece.coord.column >= 0 {
                if checkAvailableMove(piece: piece) {
                    blackPieces = true
                }
            }
            if piece.player == .red && piece.coord.row >= 0 && piece.coord.column >= 0 {
                if checkAvailableMove(piece: piece) {
                    redPieces = true
                }
            }
        }
        if !blackPieces {
            self.winner = Player.red
        }
        else if !redPieces {
            self.winner = Player.black
        }
    }
    
    mutating func move(row: Int, column: Int) {
        isBlackTurn = !isBlackTurn
        let index = getPieceIndex(row: (chosenPiece?.coord.row)!, column: (chosenPiece?.coord.column)!)
        if (index != -1) {
            if (checkAnyPiece(row: row, column: column)) {
                let index = getPieceIndex(row: row, column: column)
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@ %@ %@,     ,     ", NSLocalizedString((pieces[index].player.rawValue), comment: ""), NSLocalizedString((pieces[index].type.rawValue), comment: ""), NSLocalizedString("is captured", comment: "")))
                pieces[index].coord.row = -10
                pieces[index].coord.column = -10
            }
            pieces[index].coord.row = row
            pieces[index].coord.column = column
            pieces[index].coord.type = GameModel.getGridType(row: row, column: column)
            pieces[index].coord.border = GameModel.getGridBorder(row: row, column: column)
            
            moveRecords.append(String(format: "%@%@%@%@%@", NSLocalizedString((chosenPiece?.player.rawValue)!, comment: ""), NSLocalizedString((chosenPiece?.type.rawValue)!, comment:""), NSLocalizedString("Move", comment: ""), convertColumn(column: column), convertRow(row: row)))
            
            chosenPiece = nil
            turn += 1
            records.append(pieces)
            
        }
    }
    
    mutating func undo(player: Player) {
        if turn == 0 {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("cant undo", comment: "")))
            return
        }
        if (turn >= 2) && (currentPlayer == player) && ((player == .black && turn%2 == 1) || (player == .red && turn%2 == 0)) {
            _ = records.popLast()
            _ = records.popLast()
            turn -= 2
            pieces = records.last!
            _ = moveRecords.popLast()
            _ = moveRecords.popLast()
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("undo successfully", comment: "")))
            return
        } else if ((turn > 1 && (currentPlayer != player)) || (player == .red && turn == 1)) {
            _ = records.popLast()
            turn -= 1
            pieces = records.last!
            _ = moveRecords.popLast()
            isBlackTurn = !isBlackTurn
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("undo successfully", comment: "")))
            return
        }
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: String(format: "%@,     ,     ,", NSLocalizedString("cant undo", comment: "")))
    }

    mutating func getAvailableMove() -> [GridIndex]? {
        if chosenPiece == nil {
            return nil
        }
        var moves: [GridIndex] = []
        for row in 0..<9 {
            for column in 0..<7 {
                if checkAction(row: row, column: column) {
                    moves.append(GridIndex(row: row, column: column))
                }
            }
        }
        
        return moves
    }
    
    func checkAnyPiece(row: Int, column: Int) ->Bool {
        for piece in pieces {
            if piece.coord.row == row && piece.coord.column == column {
                return true
            }
        }
        return false
    }
    
    func getPieceIndex(row: Int, column: Int) -> Int {
        var index = 0
        for piece in pieces {
            if piece.coord.row == row && piece.coord.column == column {
                return index
            }
            index += 1
        }
        return -1
    }
    
    static func getGridType(row: Int, column: Int) -> GridType {
        if column == 3 {
            if row == 0 {
                return GridType.BlackDen
            } else if row == 8 {
                return GridType.RedDen
            }
        }
        
        if ((column == 2 || column == 4) && row == 0) || (column == 3 && row == 1) {
            return GridType.BlackTrap
        } else if ((column == 2 || column == 4) && row == 8) || (column == 3 && row == 7) {
            return GridType.RedTrap
        }
        
        if row >= 3 && row <= 5 {
            if column != 0 && column != 3 && column != 6 {
                return GridType.River
            }
        }
        return GridType.Normal
    }
    
    static func getGridBorder(row: Int, column: Int) -> GridBorder {
        if (row == 0 && column == 0 || row == 0 && column == 6 || row == 8 && column == 0 || row == 8 && column == 6)
        {
            return GridBorder.Corner
        }
        else if (row == 0 || row == 8 || column == 0 || column == 6)
        {
            return GridBorder.Edge
        }
        else
        {
            return GridBorder.Normal
        }
    }
    
    func getPosition(row: Int, column: Int) -> GridCoordinate? {
        for i in 0..<positions.count {
            if (positions[i].row == row && positions[i].column == column) {
                return positions[i]
            }
        }
        return nil
    }
    
    func convertRow(row: Int) -> String {
        let result = 9 - row
        return String(result)
    }
    
    func convertRowBack(row: String) -> Int {
        let temp = Int(row) ?? 0
        let result = 9 - temp
        return result
    }
    	
    func convertColumn(column: Int) -> String {
        switch column {
        case 0:
            return "A"
        case 1:
            return "B"
        case 2:
            return "C"
        case 3:
            return "D"
        case 4:
            return "E"
        case 5:
            return "F"
        case 6:
            return "G"
        default:
            return ""
        }
    }
    
    func convertColumnBack(column: String) -> Int {
        switch column {
        case "A":
            return 0
        case "B":
            return 1
        case "C":
            return 2
        case "D":
            return 3
        case "E":
            return 4
        case "F":
            return 5
        case "G":
            return 6
        default:
            return -1
        }
    }
    
}



extension GameModel {
    enum Player: String, Codable {
        case black = "Black"
        case red = "Red"
    }
    
//    enum State: Int, Codable {
//        case Placement
//        case movement
//    }
    
    enum GridType: String, Codable {
        case Normal = "Normal"
        case River = "River"
        case BlackTrap = "Black's Trap"
        case BlackDen = "Black's Den"
        case RedTrap = "Red's Trap"
        case RedDen = "Red's Den"
    }
    
    enum GridBorder: String, Codable {
        case Corner = "Corner"
        case Edge = "Edge"
        case Normal = ""
    }
    
    enum PieceType: String, Codable {
        case Rat = "Rat"
        case Cat = "Cat"
        case Dog = "Dog"
        case Wolf = "Wolf"
        case LeoPard = "Leopard"
        case Tiger = "Tiger"
        case Lion = "Lion"
        case Elepant = "Elephant"
    }
    
    struct GridCoordinate: Codable, Equatable {
        var row, column: Int
        var type: GridType
        var border: GridBorder
    }
    
    struct Piece: Codable, Equatable {
        let player: Player
        var coord: GridCoordinate
        let type: PieceType
        var eaten: Bool {
            return (coord.column < 0 || coord.row < 0)
        }
        
    }
    
    
}
