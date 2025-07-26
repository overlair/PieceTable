//
//  File.swift
//  PieceTable
//
//  Created by John Knowles on 7/24/25.
//

import Foundation

public struct PieceTableEdit {
    public let replacedRange: Range<PieceTable.Index>
    public let replacedText: [GraphemeCluster]
    public let insertedText: [GraphemeCluster]
}
