//
//  File.swift
//  PieceTable
//
//  Created by John Knowles on 7/25/25.
//

import Foundation

public extension String {
    var graphemeClusters: [GraphemeCluster] {
            var clusters: [GraphemeCluster] = []
            
            // Foundation does the heavy lifting for us
            self.enumerateSubstrings(in: self.startIndex..<self.endIndex,
                                   options: [.byComposedCharacterSequences, .localized]) { substring, _, _, _ in
                if let substring = substring {
                    clusters.append(GraphemeCluster(Array(substring.utf16)))
                }
            }
            
            return clusters
        }
}
