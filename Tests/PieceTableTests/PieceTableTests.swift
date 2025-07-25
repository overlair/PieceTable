import Foundation
import Testing
@testable import PieceTable


@Suite
struct BasicTests {

    @Test func testInitialContent() {
        let table = PieceTable("hello world")
        #expect(table.string == "hello world")
    }

    @Test func testInsertAtBeginning() {
        var table = PieceTable("world")
        let index = table.index(at: 0)!
        table.replaceSubrange(index..<index, with: Array("hello ".utf16))
        #expect(table.string == "hello world")
    }

    @Test func testInsertAtMiddle() {
        var table = PieceTable("helo")
        let index = table.index(at: 3)!
        table.replaceSubrange(index..<index, with: Array("l".utf16))
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
        table.replaceSubrange(i..<j, with: Array("o wor".utf16))
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
        table.replaceSubrange(i..<i, with: Array("def".utf16))
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
        table.replaceSubrange(idx..<idx, with: Array("b".utf16))
        idx = table.index(at: 2)!
        table.replaceSubrange(idx..<idx, with: Array("c".utf16))
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
        table.replaceSubrange(idx..<idx, with: Array(" world".utf16))
        table.replaceSubrange(idx..<idx, with: Array(" big".utf16))
        #expect(table.string == "hello big world")
    }

    @Test func testFullReplace() {
        var table = PieceTable("abc")
        let start = table.index(at: 0)!
        let end = table.index(at: 3)!
        table.replaceSubrange(start..<end, with: Array("xyz".utf16))
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
        table.replaceSubrange(idx1..<idx2, with: Array("xyz".utf16))
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
         table.replaceSubrange(i..<j, with: Array("l".utf16))
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
struct tressTests {

    @Test
        func testRepeatedInsertions() {
            var table = PieceTable("")
            let opCount = 10_000
//            let startTime = CFAbsoluteTimeGetCurrent()

            for i in 0..<opCount {
                let index = table.endIndex // table.index(at: table.count / 2) ?? table.endIndex
                table.replaceSubrange(index..<index, with: Array("x".utf16))
            }

//            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            #expect(table.count == opCount)
//            print("⏱ testRepeatedInsertions: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
//            print("🧩 pieces after insertions: \(table.internalPieceCount)")
        }

        @Test
        func testRepeatedDeletions() {
            let initialString = String(repeating: "x", count: 10_000)
            var table = PieceTable(initialString)
            let opCount = 5000
//            let startTime = CFAbsoluteTimeGetCurrent()

            for _ in 0..<opCount {
                let mid = table.count / 2
                let i = table.index(at: mid - 1)!
                let j = table.index(at: mid)!
                table.replaceSubrange(i..<j, with: [])
            }

//            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            #expect(table.count == initialString.count - opCount)
//            print("⏱ testRepeatedDeletions: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
//            print("🧩 pieces after deletions: \(table.internalPieceCount)")
        }

        @Test
        func testAlternatingInsertDelete() {
            var table = PieceTable("0123456789")
            let opCount = 5000
//            let startTime = CFAbsoluteTimeGetCurrent()

            for i in 0..<opCount {
                let index = table.index(at: min(5, table.count))!
                if i % 2 == 0 {
                    table.replaceSubrange(index..<index, with: Array("x".utf16))
                } else if table.count > 5 {
                    let j = table.index(at: min(6, table.count))!
                    table.replaceSubrange(index..<j, with: [])
                }
            }

//            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
//            print("⏱ testAlternatingInsertDelete: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
//            print("🧩 pieces after alternating ops: \(table.internalPieceCount)")
        }

        @Test
        func testReplaceAcrossExpandingTable() {
            var table = PieceTable("a")
            let opCount = 200
//            let startTime = CFAbsoluteTimeGetCurrent()

            for i in 0..<opCount {
                let newContent = String(repeating: "x", count: i)
                let i0 = table.index(at: 0)!
                let i1 = table.index(at: table.count)!
                table.replaceSubrange(i0..<i1, with: Array(newContent.utf16))
                #expect(table.count == newContent.count)
            }

//            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
//            print("⏱ testReplaceAcrossExpandingTable: \(elapsed)s (avg: \(elapsed / Double(opCount))s)")
//            print("🧩 pieces after full replace cycles: \(table.internalPieceCount)")
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
                table.replaceSubrange(startIndex..<startIndex, with: Array(insert.utf16))
                undoStack.append((start: at, end: at + insert.count, string: insert))
            }

            // Apply undos in reverse
            for undo in undoStack.reversed() {
                let i = table.index(at: undo.start)!
                let j = table.index(at: undo.end)!
                table.replaceSubrange(i..<j, with: [])
            }

            #expect(table.string == "")
//            print("⏱ testUndoStress: 2×\(opCount) ops completed, pieces: \(table.internalPieceCount)")
        }
}


