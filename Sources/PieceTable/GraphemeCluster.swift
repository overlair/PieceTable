//
//  GraphemeClusterr=.swift
//  PieceTable
//
//  Created by John Knowles on 7/25/25.
//
import Foundation

public struct GraphemeCluster {
    /// The original, unedited contents
    private let contents: [unichar]
    
    public init(_ contents: [unichar]) {
        self.contents = contents
    }
    
    public init(_ string: String) {
        self.contents = Array(string.utf16)
    }
    
    public var unicharArray: [unichar] {
        return contents
    }
    
    public var string: String {
        return String(utf16CodeUnits: contents, count: contents.count)
    }
    
    public var count: Int {
        return contents.count
    }
    
    public subscript(index: Int) -> unichar {
        return contents[index]
    }
}
