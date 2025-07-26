import Foundation
import Testing
@testable import PieceTable


import Testing

// Helper function to convert String to [GraphemeCluster]
func stringToGraphemeClusters(_ string: String) -> [GraphemeCluster] {
    return Array(string.utf16).map { GraphemeCluster([$0]) }
}

@Suite
struct BasicTests {

    @Test func testInitialContent() {
        let table = PieceTable("hello world")
        #expect(table.string == "hello world")
    }

    @Test func testInsertAtBeginning() {
        var table = PieceTable("world")
        let index = table.index(at: 0)!
        table.replaceSubrange(index..<index, with: stringToGraphemeClusters("hello "))
        #expect(table.string == "hello world")
    }

    @Test func testInsertAtMiddle() {
        var table = PieceTable("helo")
        let index = table.index(at: 3)!
        table.replaceSubrange(index..<index, with: stringToGraphemeClusters("l"))
        #expect(table.string == "hello")
    }

    @Test func testDeleteSingleCharacter() {
        var table = PieceTable("hello")
        let i = table.index(at: 1)!
        let j = table.index(at: 2)!
        table.replaceSubrange(i..<j, with: [])
        #expect(table.string == "hllo")
    }

    @Test func testDeleteEntireWord() {
        var table = PieceTable("hello world")
        let i = table.index(at: 6)!
        let j = table.index(at: 11)!
        table.replaceSubrange(i..<j, with: [])
        #expect(table.string == "hello ")
    }

    @Test func testReplaceSubstring() {
        var table = PieceTable("hella warld")
        let i = table.index(at: 4)!
        let j = table.index(at: 9)!
        table.replaceSubrange(i..<j, with: stringToGraphemeClusters("o wor"))
        #expect(table.string == "hello world")
    }

    @Test func testCaretVisualization() {
        let table = PieceTable("hello world")
        let slice = table.string(in: NSRange(location: 5, length: 0))
        #expect(slice == "") // range of length 0
    }

    @Test func testSelectionVisualization() {
        let table = PieceTable("hello world")
        let selected = table.string(in: NSRange(location: 3, length: 4))
        #expect(selected == "lo w")
    }

    // --- New Edge Case Tests ---

    @Test func testEmptyInsertDoesNothing() {
        var table = PieceTable("abc")
        let i = table.index(at: 1)!
        table.replaceSubrange(i..<i, with: [])
        #expect(table.string == "abc")
    }

    @Test func testEmptyDeleteDoesNothing() {
        var table = PieceTable("abc")
        let i = table.index(at: 1)!
        table.replaceSubrange(i..<i, with: [])
        #expect(table.string == "abc")
    }

    @Test func testInsertAtEnd() {
        var table = PieceTable("abc")
        let i = table.index(at: 3)!
        table.replaceSubrange(i..<i, with: stringToGraphemeClusters("def"))
        #expect(table.string == "abcdef")
    }

    @Test func testDeleteAtStart() {
        var table = PieceTable("abc")
        let start = table.index(at: 0)!
        let end = table.index(at: 1)!
        table.replaceSubrange(start..<end, with: [])
        #expect(table.string == "bc")
    }

    @Test func testMultipleInserts() {
        var table = PieceTable("a")
        var idx = table.index(at: 1)!
        table.replaceSubrange(idx..<idx, with: stringToGraphemeClusters("b"))
        idx = table.index(at: 2)!
        table.replaceSubrange(idx..<idx, with: stringToGraphemeClusters("c"))
        #expect(table.string == "abc")
    }

    @Test func testDeleteAcrossPieces() {
        var table = PieceTable("hello world")
        let i = table.index(at: 5)!
        let j = table.index(at: 7)!
        table.replaceSubrange(i..<j, with: [])
        #expect(table.string == "helloorld")
    }

    @Test func testCoalesceInsertions() {
        var table = PieceTable("hello")
        let idx = table.index(at: 5)!
        table.replaceSubrange(idx..<idx, with: stringToGraphemeClusters(" world"))
        table.replaceSubrange(idx..<idx, with: stringToGraphemeClusters(" big"))
        #expect(table.string == "hello big world")
    }

    @Test func testFullReplace() {
        var table = PieceTable("abc")
        let start = table.index(at: 0)!
        let end = table.index(at: 3)!
        table.replaceSubrange(start..<end, with: stringToGraphemeClusters("xyz"))
        #expect(table.string == "xyz")
    }

    @Test func testIndexOutOfBounds() {
        let table = PieceTable("abc")
        let idx = table.index(at: 10)
        #expect(idx == nil)
    }

    @Test func testInsertDeleteMix() {
        var table = PieceTable("abc")
        let idx1 = table.index(at: 1)!
        let idx2 = table.index(at: 2)!
        table.replaceSubrange(idx1..<idx2, with: stringToGraphemeClusters("xyz"))
        #expect(table.string == "axyzc")
        let start = table.index(at: 0)!
        let end = table.index(at: 2)!
        table.replaceSubrange(start..<end, with: [])
        #expect(table.string == "yzc")
    }
    
    @Test
    func testEndReplaceSubstring() {
        var table = PieceTable("hella")
        let i = table.index(at: 3)!
        let j = table.index(at: 5)!
        table.replaceSubrange(i..<j, with: stringToGraphemeClusters("l"))
        #expect(table.string == "hell")
    }

    @Test
    func testDeleteEndSubstring() {
        var table = PieceTable("hello warld")
        let i = table.index(at: 5)!
        let j = table.index(at: 11)!
        table.replaceSubrange(i..<j, with: [])
        #expect(table.string == "hello")
    }
}

@Suite
struct StressTests {

    @Test
    func testRepeatedInsertions() {
        var table = PieceTable("")
        let opCount = 10_000
        // let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<opCount {
            let index = table.endIndex // table.index(at: table.count / 2) ?? table.endIndex
            table.replaceSubrange(index..<index, with: stringToGraphemeClusters("x"))
        }

        // let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(table.count == opCount)
        // print("⏱ testRepeatedInsertions: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
        // print("🧩 pieces after insertions: \(table.internalPieceCount)")
    }

    @Test
    func testRepeatedDeletions() {
        let initialString = String(repeating: "x", count: 10_000)
        var table = PieceTable(initialString)
        let opCount = 5000
        // let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<opCount {
            let mid = table.count / 2
            let i = table.index(at: mid - 1)!
            let j = table.index(at: mid)!
            table.replaceSubrange(i..<j, with: [])
        }

        // let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(table.count == initialString.count - opCount)
        // print("⏱ testRepeatedDeletions: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
        // print("🧩 pieces after deletions: \(table.internalPieceCount)")
    }

    @Test
    func testAlternatingInsertDelete() {
        var table = PieceTable("0123456789")
        let opCount = 5000
        // let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<opCount {
            let index = table.index(at: min(5, table.count))!
            if i % 2 == 0 {
                table.replaceSubrange(index..<index, with: stringToGraphemeClusters("x"))
            } else if table.count > 5 {
                let j = table.index(at: min(6, table.count))!
                table.replaceSubrange(index..<j, with: [])
            }
        }

        // let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        // print("⏱ testAlternatingInsertDelete: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
        // print("🧩 pieces after alternating ops: \(table.internalPieceCount)")
    }

    @Test
    func testReplaceAcrossExpandingTable() {
        var table = PieceTable("a")
        let opCount = 200
        // let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<opCount {
            let newContent = String(repeating: "x", count: i)
            let i0 = table.index(at: 0)!
            let i1 = table.index(at: table.count)!
            table.replaceSubrange(i0..<i1, with: stringToGraphemeClusters(newContent))
            #expect(table.count == newContent.count)
        }

        // let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        // print("⏱ testReplaceAcrossExpandingTable: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
        // print("🧩 pieces after full replace cycles: \(table.internalPieceCount)")
    }

    @Test
    func testUndoStress() {
        var table = PieceTable("")
        var undoStack: [(start: Int, end: Int, string: String)] = []

        let opCount = 1000
        for i in 0..<opCount {
            let insert = "\(i)"
            let at = table.count
            let startIndex = table.index(at: at)!
            table.replaceSubrange(startIndex..<startIndex, with: stringToGraphemeClusters(insert))
            undoStack.append((start: at, end: at + insert.count, string: insert))
        }

        // Apply undos in reverse
        for undo in undoStack.reversed() {
            let i = table.index(at: undo.start)!
            let j = table.index(at: undo.end)!
            table.replaceSubrange(i..<j, with: [])
        }

        #expect(table.string == "")
        // print("⏱ testUndoStress: 2×\(opCount) ops completed, pieces: \(table.internalPieceCount)")
    }
}

// Additional tests to verify GraphemeCluster functionality
@Suite
struct GraphemeClusterTests {
    
    @Test
    func testGraphemeClusterCreation() {
        let cluster = GraphemeCluster("a")
        #expect(cluster.string == "a")
        #expect(cluster.count == 1)
    }
    
    @Test
    func testGraphemeClusterFromUnicharArray() {
        let unicharArray: [unichar] = [65, 66, 67] // "ABC"
        let cluster = GraphemeCluster(unicharArray)
        #expect(cluster.string == "ABC")
        #expect(cluster.count == 3)
    }
    
    @Test
    func testStringToGraphemeClusterConversion() {
        let clusters = stringToGraphemeClusters("hello")
        #expect(clusters.count == 5)
        #expect(clusters[0].string == "h")
        #expect(clusters[4].string == "o")
    }
    
    @Test
    func testPieceTableWithEmojis() {
        var table = PieceTable("😀😃😄")
        #expect(table.count == 6) // Each emoji is 2 UTF-16 code units
        
        let index = table.index(at: 2)!
        table.replaceSubrange(index..<index, with: stringToGraphemeClusters("😅"))
        #expect(table.string == "😀😅😃😄")
    }
    
    @Test
    func testPieceTableWithComplexText() {
        var table = PieceTable("Hello 🌍!")
        let originalCount = table.count
        
        let index = table.index(at: 6)! // After "Hello "
        table.replaceSubrange(index..<index, with: stringToGraphemeClusters("beautiful "))
        
        #expect(table.string == "Hello beautiful 🌍!")
        #expect(table.count == originalCount + 10) // "beautiful " is 10 characters
    }
}
