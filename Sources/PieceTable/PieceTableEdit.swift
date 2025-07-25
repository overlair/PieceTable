//
//  File.swift
//  PieceTable
//
//  Created by John Knowles on 7/24/25.
//

import Foundation

public struct PieceTableEdit {
    let replacedRange: Range<PieceTable.Index>
    let replacedText: [unichar]  // text that was overwritten or deleted
    let insertedText: [unichar]  // text that was inserted
}
