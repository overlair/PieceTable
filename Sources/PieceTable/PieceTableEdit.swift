//
//  File.swift
//  PieceTable
//
//  Created by John Knowles on 7/24/25.
//

import Foundation

public struct PieceTableEdit {
    public let replacedRange: Range<PieceTable.Index>
    public let replacedText: [unichar]  // text that was overwritten or deleted
    public let insertedText: [unichar]  // text that was inserted
}
