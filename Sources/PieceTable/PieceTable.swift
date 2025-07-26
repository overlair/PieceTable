// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation


/// A piece table is a range-replaceable collection of GraphemeClusters. At the storage layer, it uses two arrays to store the values:
///
/// 1. Read-only *original contents*
/// 2. Append-only *addedContents*
///
/// It constructs a logical view of the contents from an array of slices of contents from the two arrays.
public struct PieceTable {
    /// The original, unedited contents
    private let originalContents: [GraphemeCluster]
    
    /// All new GraphemeClusters added to the collection.
    private var addedContents: [GraphemeCluster]
    
    /// Identifies which of the two arrays holds the contents of the piece
    private enum PieceSource {
        case original
        case added
    }
    
    /// A contiguous range of text stored in one of the two contents arrays.
    private struct Piece {
        /// Which array holds the text.
        let source: PieceSource
        
        /// Start index of the text inside the contents array.
        var startIndex: Int
        
        /// End index of the text inside the contents array.
        var endIndex: Int
    }
    
    /// The logical contents of the collection, expressed as an array of pieces from either `originalContents` or `newContents`
    private var pieces: [Piece]
    var internalPieceCount: Int { pieces.count }
    
    public init() {
        let string = ""
        self.init(string)
    }
    
    /// Initialize a piece table with the contents of a string.
    public init(_ string: String) {
        // Convert string to array of GraphemeClusters (one cluster per character for now)
        self.originalContents = Array(string.utf16).map { GraphemeCluster([$0]) }
        self.addedContents = []
        self.pieces = [Piece(source: .original, startIndex: 0, endIndex: originalContents.count)]
    }
}

extension PieceTable: Collection {
    public struct Index: Comparable {
        let pieceIndex: Int
        let contentIndex: Int
        
        public static func < (lhs: PieceTable.Index, rhs: PieceTable.Index) -> Bool {
            if lhs.pieceIndex != rhs.pieceIndex {
                return lhs.pieceIndex < rhs.pieceIndex
            }
            return lhs.contentIndex < rhs.contentIndex
        }
    }
    
    public var startIndex: Index { Index(pieceIndex: 0, contentIndex: pieces.first?.startIndex ?? 0) }
    public var endIndex: Index { Index(pieceIndex: pieces.endIndex, contentIndex: 0) }
    
    public func index(after i: Index) -> Index {
        guard i <= endIndex else {
            return endIndex
        }
        let piece = pieces[i.pieceIndex]
        
        // Check if the next content index is within the bounds of this piece...
        if i.contentIndex + 1 < piece.endIndex {
            return Index(pieceIndex: i.pieceIndex, contentIndex: i.contentIndex + 1)
        }
        
        // Otherwise, construct an index that refers to the beginning of the next piece.
        let nextPieceIndex = i.pieceIndex + 1
        if nextPieceIndex < pieces.endIndex {
            return Index(pieceIndex: nextPieceIndex, contentIndex: pieces[nextPieceIndex].startIndex)
        } else {
            return Index(pieceIndex: nextPieceIndex, contentIndex: 0)
        }
    }
    
    /// Gets the array for a source.
    private func sourceArray(for source: PieceSource) -> [GraphemeCluster] {
        switch source {
        case .original:
            return originalContents
        case .added:
            return addedContents
        }
    }
    
    public subscript(position: Index) -> GraphemeCluster {
        let sourceArray = self.sourceArray(for: pieces[position.pieceIndex].source)
        return sourceArray[position.contentIndex]
    }
}

extension PieceTable: RangeReplaceableCollection {
    
    /// This structure holds all of the information needed to change the pieces in a piece table.
    ///
    /// To create the most compact final `pieces` array as possible, we use the following rules when appending pieces:
    ///
    /// 1. No empty pieces -- if you try to insert something empty, we just omit it.
    /// 2. No consecutive adjoining pieces (where replacement[n].endIndex == replacement[n+1].startIndex). If we're about to store
    ///   something like this, we just "extend" replacement[n] to encompass the new range.
    private struct ChangeDescription {
        
        private(set) var values: [Piece] = []
        
        /// The smallest index of an existing piece added to `values`
        var lowerBound: Int?
        
        /// The largest index of an existing piece added to `values`
        var upperBound: Int?
        
        /// Adds a piece to the description.
        mutating func appendPiece(_ piece: Piece) {
            // No empty pieces in our replacements array.
            guard piece.startIndex < piece.endIndex else { return }
            
            // If `piece` starts were `replacements` ends, just extend the end of `replacements`
            if let last = values.last, last.source == piece.source, last.endIndex == piece.startIndex {
                values[values.count - 1].endIndex = piece.endIndex
            } else {
                // Otherwise, stick our new piece into the replacements.
                values.append(piece)
            }
        }
        
        /// 🔧 Allows safe mutation of the last piece (for coalescing).
        mutating func extendLastPiece(by count: Int) {
            guard !values.isEmpty else { return }
            values[values.count - 1].endIndex += count
        }
    }
    
    /// If `index` is valid, then retrieve the piece at that index, modify it, and append it to the change description.
    private func safelyAddToDescription(
        _ description: inout ChangeDescription,
        modifyPieceAt index: Int,
        modificationBlock: (inout Piece) -> Void
    ) {
        guard pieces.indices.contains(index) else { return }
        var piece = pieces[index]
        modificationBlock(&piece)
        description.lowerBound = description.lowerBound.map { Swift.min($0, index) } ?? index
        description.upperBound = description.upperBound.map { Swift.max($0, index) } ?? index
        description.appendPiece(piece)
    }
    
    /// Update the piece table with the changes contained in `changeDescription`
    mutating private func applyChangeDescription(_ changeDescription: ChangeDescription) {
        let range: Range<Int>
        if let minIndex = changeDescription.lowerBound, let maxIndex = changeDescription.upperBound {
            range = minIndex ..< maxIndex + 1
        } else {
            range = pieces.endIndex ..< pieces.endIndex
        }
        pieces.replaceSubrange(range, with: changeDescription.values)
    }
    
    /// Replace a range of GraphemeClusters with `newElements`. Note that `subrange` can be empty (in which case it's just an insert point).
    /// Similarly `newElements` can be empty (expressing deletion).
    ///
    /// Also remember that GraphemeClusters are never really deleted.
    public mutating func replaceSubrange<C, R>(
        _ subrange: R,
        with newElements: C
    ) where C: Collection, R: RangeExpression, GraphemeCluster == C.Element, Index == R.Bound  {
        let range = subrange.relative(to: self)
        
        let isInsertion = range.lowerBound == range.upperBound
        if isInsertion,
           let lastPiece = pieces.last,
           lastPiece.source == .added,
           range.lowerBound.pieceIndex == pieces.count - 1,
           range.lowerBound.contentIndex == lastPiece.endIndex {
            
            addedContents.append(contentsOf: newElements)
            let insertedCount = newElements.count
            
            var extended = lastPiece
            extended.endIndex += insertedCount
            
            var newPieces = pieces
            newPieces.removeLast()
            newPieces.append(extended)
            pieces = newPieces
            
        } else {
            
            var changeDescription = ChangeDescription()
            
            safelyAddToDescription(&changeDescription, modifyPieceAt: range.lowerBound.pieceIndex - 1) { _ in }
            
            safelyAddToDescription(&changeDescription, modifyPieceAt: range.lowerBound.pieceIndex) { piece in
                piece.endIndex = range.lowerBound.contentIndex
            }
            
            if !newElements.isEmpty {
                let index = addedContents.endIndex
                addedContents.append(contentsOf: newElements)
                let addedPiece = Piece(source: .added, startIndex: index, endIndex: addedContents.endIndex)
                changeDescription.appendPiece(addedPiece)
            }
            
            safelyAddToDescription(&changeDescription, modifyPieceAt: range.upperBound.pieceIndex) { piece in
                piece.startIndex = range.upperBound.contentIndex
            }
            
            applyChangeDescription(changeDescription)
        }
    }
    
    @discardableResult
    public mutating func editSubrange<C, R>(
        _ subrange: R,
        with newElements: C
    ) -> PieceTableEdit? where C: Collection, R: RangeExpression, GraphemeCluster == C.Element, Index == R.Bound {
        // Capture the original text for undo
        let range = subrange.relative(to: self)
        
        let replacedText = Array(self[range])
        
        replaceSubrange(subrange, with: newElements)
        
        let insertedText = Array(newElements)
        
        return PieceTableEdit(replacedRange: range, replacedText: replacedText, insertedText: insertedText)
    }
}

extension PieceTable {
    /// Returns the internal index (piece + content offset) corresponding to a linear GraphemeCluster offset.
    public func index(at offset: Int) -> Index? {
        guard offset >= 0 else { return nil }
        
        var remaining = offset
        
        for (pieceIndex, piece) in pieces.enumerated() {
            let length = piece.endIndex - piece.startIndex
            
            if remaining < length {
                let contentIndex = piece.startIndex + remaining
                return Index(pieceIndex: pieceIndex, contentIndex: contentIndex)
            }
            
            remaining -= length
        }
        
        // Allow offset == count (i.e., return endIndex)
        return remaining == 0 ? endIndex : nil
    }
    
    /// Total number of GraphemeClusters represented in the piece table.
    public var count: Int {
        pieces.reduce(0) { $0 + ($1.endIndex - $1.startIndex) }
    }
}

extension PieceTable {
    // Convert NSRange to PieceTable range
    public func range(from nsRange: NSRange) -> Range<Index>? {
        guard let startIndex = self.index(at: nsRange.location),
              let endIndex = self.index(at: nsRange.location + nsRange.length) else {
            return nil
        }
        return startIndex..<endIndex
    }
    
    // Convert PieceTable range to NSRange
    public func nsRange(from range: Range<Index>) -> NSRange? {
        guard let startOffset = self.offset(of: range.lowerBound),
              let endOffset = self.offset(of: range.upperBound) else {
            return nil
        }
        return NSRange(location: startOffset, length: endOffset - startOffset)
    }
    
    // Helper to get offset from index
    public func offset(of index: Index) -> Int? {
        var current = startIndex
        var offset = 0
        
        while current < index && current < endIndex {
            current = self.index(after: current)
            offset += 1
        }
        
        return current == index ? offset : nil
    }
}

extension PieceTable {
    public var string: String {
        var result = [unichar]()
        
        for piece in pieces {
            let sourceArray: [GraphemeCluster]
            switch piece.source {
            case .original:
                sourceArray = originalContents
            case .added:
                sourceArray = addedContents
            }
            
            guard piece.startIndex <= piece.endIndex,
                  piece.startIndex >= 0,
                  piece.endIndex <= sourceArray.count else {
                print("⚠️ Skipping invalid piece: \(piece)")
                continue
            }
            
            if piece.startIndex == piece.endIndex {
                continue // skip empty
            }
            
            let slice = sourceArray[piece.startIndex..<piece.endIndex]
            for cluster in slice {
                result.append(contentsOf: cluster.unicharArray)
            }
        }
        
        validatePieces()
        
        return String(utf16CodeUnits: result, count: result.count)
    }
    
    func validatePieces() {
        for piece in pieces {
            let array = piece.source == .original ? originalContents : addedContents
            assert(piece.startIndex <= piece.endIndex, "Invalid piece range")
            assert(piece.startIndex >= 0 && piece.endIndex <= array.count, "Piece out of bounds")
        }
    }
    
    public func debugString(in range: NSRange?) -> String {
        var result = [String]()
        var offset = 0
        
        for piece in pieces {
            let sourceArray = piece.source == .original ? originalContents : addedContents
            let start = piece.startIndex
            let end = piece.endIndex
            
            for i in start..<end {
                // Insert caret *before* this cluster if needed
                if let range = range, range.length == 0, offset == range.location {
                    result.append("|")
                }
                
                // Insert selection start
                if let range = range, offset == range.location, range.length > 0 {
                    result.append("{")
                }
                
                // Insert selection end
                if let range = range, offset == range.upperBound, range.length > 0 {
                    result.append("}")
                }
                
                let cluster = sourceArray[i]
                result.append(cluster.string)
                
                offset += 1
            }
        }
        
        // Handle caret at end of buffer
        if let range = range, range.length == 0, range.location == offset {
            result.append("|")
        } else if let range = range, range.length > 0, offset == range.upperBound {
            result.append("}")
        }
        
        return result.joined()
    }
    
    public func string(in range: NSRange) -> String {
        guard range.length > 0 else { return "" }
        
        var result = String.UnicodeScalarView()
        var remaining = range.length
        var offset = 0
        
        for piece in pieces {
            let pieceLength = piece.endIndex - piece.startIndex
            
            // Skip pieces before the range
            if offset + pieceLength <= range.location {
                offset += pieceLength
                continue
            }
            
            // Compute slice range within the piece
            let localStart = Swift.max(0, range.location - offset)
            let localEnd = Swift.min(pieceLength, range.location + range.length - offset)
            
            if localStart < localEnd {
                let source = piece.source == .original ? originalContents : addedContents
                let slice = source[piece.startIndex + localStart ..< piece.startIndex + localEnd]
                for cluster in slice {
                    result.append(contentsOf: String.UnicodeScalarView(cluster.unicharArray.compactMap { UnicodeScalar($0) }))
                }
                remaining -= (localEnd - localStart)
            }
            
            if remaining <= 0 { break }
            offset += pieceLength
        }
        
        return String(result)
    }
}
