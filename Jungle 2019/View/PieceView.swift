//
//  PieceView2.swift
//  Jungle 2019
//
//  Created by TEDY on 19/9/2019.
//  Copyright © 2019 CityU_Henry. All rights reserved.
//

import Foundation
import UIKit

class PieceView: UIView {
    var piece: GameModel.Piece?
    
    init(frame: CGRect, piece: GameModel.Piece) {
        super.init(frame: frame)
        self.piece = piece
        self.setup()
        self.setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(2.0)
        
        let faceImage = UIImage(named: self.getPieceImageString()!)
        if ((faceImage) != nil) {
            let imageRect = rect.insetBy(dx: 0, dy: 0)
            faceImage?.draw(in: imageRect)
        }
    }
    
    func getPieceImageString() -> String? {
        if piece!.type == GameModel.PieceType.Rat {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Rat_b"
            } else {
                return "img_chess_Rat_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Cat {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Cat_b"
            } else {
                return "img_chess_Cat_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Dog {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Dog_b"
            } else {
                return "img_chess_Dog_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Wolf {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Wolf_b"
            } else {
                return "img_chess_Wolf_r"
            }
        }
        else if piece!.type == GameModel.PieceType.LeoPard {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Leopard_b"
            } else {
                return "img_chess_Leopard_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Tiger {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Tiger_b"
            } else {
                return "img_chess_Tiger_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Lion {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Lion_b"
            } else {
                return "img_chess_Lion_r"
            }
        }
        else if piece!.type == GameModel.PieceType.Elepant {
            if piece?.player == GameModel.Player.black {
                return "img_chess_Elephant_b"
            } else {
                return "img_chess_Elephant_r"
            }
        }
        else {
            return nil
        }
    }
    
    func setup() {
        self.backgroundColor = nil
        self.isOpaque = false
        self.contentMode = UIView.ContentMode.redraw
    }
    
    override func awakeFromNib() {
        self.setup()
    }
}

