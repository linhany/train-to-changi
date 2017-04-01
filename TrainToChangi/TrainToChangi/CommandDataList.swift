//
//  CommandDataList.swift
//  TrainToChangi
//
//  Created by Yong Lin Han on 23/3/17.
//  Copyright © 2017 nus.cs3217.a0139655u. All rights reserved.
//

import Foundation

// MARK - CommandDataListNode

protocol CommandDataListNode: class {
    var commandData: CommandData { get }
    var next: CommandDataListNode? { get set }
    var previous: CommandDataListNode? { get set }
}

fileprivate class IterativeListNode: CommandDataListNode {
    let commandData: CommandData
    var next: CommandDataListNode?
    var previous: CommandDataListNode?

    init(commandData: CommandData) {
        self.commandData = commandData
    }
}

fileprivate class JumpListNode: CommandDataListNode {
    let commandData: CommandData
    var next: CommandDataListNode?
    var previous: CommandDataListNode?
    weak var jumpTarget: IterativeListNode?

    init(commandData: CommandData, initJumpTarget: Bool = true) {
        self.commandData = commandData
        if initJumpTarget {
            self.jumpTarget = IterativeListNode(commandData: .jumpTarget)
            self.previous = jumpTarget
            self.jumpTarget?.next = self
        }
    }
}

// MARK - CommandDataList

protocol CommandDataList {

    // Appends `commandData` to the end of the list.
    // If `commandData` is a jump-related command, also appends
    // its associated `jumpTarget` in front of it.
    func append(commandData: CommandData)

    // Inserts `commandData` into the list at `index`.
    // If `commandData` is a jump-related command, also inserts
    // its associated `jumpTarget` in front of it.
    // If `atIndex` is >= length of list, appends the commandData to the list.
    // - Precondition: atIndex >= 0
    func insert(commandData: CommandData, atIndex: Int)

    // Removes `commandData` at `index` from the list.
    // If `commandData` at index is a jump-related command, also removes
    // its associated `jumpTarget`.
    // - Precondition: atIndex must be valid: >= 0 and < length of list
    func remove(atIndex: Int) -> CommandData

    // Moves `commandData` from `sourceIndex` to `destIndex`.
    // - Precondition: sourceIndex and destIndex must be valid: >= 0 and < length of list
    func move(sourceIndex: Int, destIndex: Int)

    // Empties the list.
    func removeAll()

    // Returns the `CommandDataList` as an array.
    func toArray() -> [CommandData]

    // Returns an iterator for the CommandDataList.
    func makeIterator() -> CommandDataListIterator

    // Returns a representation of the `CommandDataList` used for storage.
    func asListInfo() -> CommandDataListInfo

    // TODO: ADT _checkrep, make sure both sides are connected, jump and target connected.
}

// TODO: Refactor and define boundary conditions properly
class CommandDataLinkedList: CommandDataList {

    fileprivate typealias Node = CommandDataListNode

    private var head: Node?

    init() {}

    // MARK - API implementations

    fileprivate var isEmpty: Bool {
        return head == nil
    }

    func append(commandData: CommandData) {
        let newNode = initNode(commandData: commandData)
        if let jumpNode = newNode as? JumpListNode {
            guard let jumpTargetNode = jumpNode.jumpTarget else {
                fatalError("All jump nodes should have a jump target!")
            }
            append(jumpTargetNode)
        } else {
            append(newNode)
        }
    }

    func insert(commandData: CommandData, atIndex index: Int) {
        let newNode = initNode(commandData: commandData)
        insert(newNode, atIndex: index)
        if let jumpNode = newNode as? JumpListNode {
            guard let jumpTargetNode = jumpNode.jumpTarget else {
                fatalError("All jump nodes should have a jump target!")
            }
            insert(jumpTargetNode, atIndex: index)
        }
    }

    func move(sourceIndex: Int, destIndex: Int) {
        // TODO: make sure index valid..

        guard let node = node(atIndex: sourceIndex) else {
            return
        }
        move(node, toIndex: destIndex)
    }

    func remove(atIndex index: Int) -> CommandData {
        guard let node = self.node(atIndex: index) else {
            preconditionFailure("Index is not valid.")
        }
        if let jumpNode = node as? JumpListNode {
            guard let jumpTargetNode = jumpNode.jumpTarget else {
                fatalError("All jump nodes should have a jump target!")
            }
            _ = remove(jumpTargetNode)
        } else if let jumpParentNode = jumpParentOf(node) as? JumpListNode {
            _ = remove(jumpParentNode)
        }

        return remove(node)
    }

    func removeAll() {
        head = nil
    }

    func toArray() -> [CommandData] {
        guard var node = head else {
            return []
        }

        var array: [CommandData] = []
        array.append(node.commandData)

        while case let next? = node.next {
            node = next
            array.append(node.commandData)
        }
        return array
    }

    func asListInfo() -> CommandDataListInfo {
        return CommandDataListInfo(array: toArray(), jumpMappings: getJumpMappings())
    }

    // MARK - Private helpers

    fileprivate var first: Node? {
        return head
    }

    private var last: Node? {
        guard var node = head else {
            return nil
        }
        while case let next? = node.next {
            node = next
        }
        return node
    }

    private var count: Int {
        guard var node = head else {
            return 0
        }
        var count = 1
        while case let next? = node.next {
            node = next
            count += 1
        }
        return count
    }

    fileprivate func initNode(commandData: CommandData) -> CommandDataListNode {
        return commandData.isJumpCommand
            ? JumpListNode(commandData: commandData)
            : IterativeListNode(commandData: commandData)
    }

    fileprivate func append(_ newNode: Node) {
        guard let lastNode = last else {
            head = newNode
            return
        }
        newNode.previous = lastNode
        lastNode.next = newNode
    }

    fileprivate func node(atIndex index: Int) -> Node? {
        if index >= 0 {
            var node = head
            var i = index
            while node != nil {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }

    private func nodesBeforeAndAfter(index: Int) -> (Node?, Node?) {
        assert(index >= 0)

        var i = index
        var next = head
        var prev: Node?

        while next != nil && i > 0 {
            i -= 1
            prev = next
            next = next!.next
        }
        assert(i == 0)  // if > 0, then specified index was too large

        return (prev, next)
    }

    private func insert(_ newNode: Node, atIndex index: Int) {
        let (prev, next) = nodesBeforeAndAfter(index: index)

        newNode.previous = prev
        newNode.next = next
        prev?.next = newNode
        next?.previous = newNode

        if prev == nil {
            head = newNode
        }
    }

    private func remove(_ node: Node) -> CommandData {
        let prev = node.previous
        let next = node.next

        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev

        node.previous = nil
        node.next = nil

        return node.commandData
    }

    private func move(_ node: Node, toIndex: Int) {
        _ = remove(node)
        insert(node, atIndex: toIndex)
    }

    private func removeLast() -> CommandData {
        assert(!isEmpty)
        return remove(last!)
    }

    private func jumpParentOf(_ node: Node) -> Node? {
        var curr = head
        while curr != nil {
            if let jumpNode = curr as? JumpListNode, jumpNode.jumpTarget === node {
                return jumpNode
            }
            curr = curr?.next
        }
        return nil
    }

    fileprivate func indexOf(_ node: Node) -> Int {
        var curr = head
        var index = 0
        while curr != nil {
            if curr === node {
                return index
            }
            curr = curr?.next
            index += 1
        }
        preconditionFailure("Node must exist!")
    }

    private func getJumpMappings() -> [Int: Int] {
        var map: [Int: Int] = [:]

        var curr = head
        while curr != nil {
            if let jump = curr as? JumpListNode {
                let jumpParentIndex = indexOf(jump)
                guard let jumpTargetNode = jump.jumpTarget else {
                    fatalError("All jump nodes should have a jump target!")
                }
                let jumpTargetIndex = indexOf(jumpTargetNode)
                map[jumpParentIndex] = jumpTargetIndex
            }
            curr = curr?.next
        }
        return map
    }

}

extension CommandDataLinkedList {
    func makeIterator() -> CommandDataListIterator {
        return CommandDataListIterator(self)
    }
}

extension CommandDataLinkedList {
    convenience init(commandDataListInfo: CommandDataListInfo) {
        self.init()
        setUpListNodes(commandDataArray: commandDataListInfo.commandDataArray)
        setUpJumpReferences(jumpMappings: commandDataListInfo.jumpMappings)
    }

    private func setUpListNodes(commandDataArray: [CommandData]) {
        for commandData in commandDataArray {
            let newNode: CommandDataListNode = commandData.isJumpCommand
                    ? JumpListNode(commandData: commandData, initJumpTarget: false)
                    : IterativeListNode(commandData: commandData)
            append(newNode)
        }
    }

    private func setUpJumpReferences(jumpMappings: [Int: Int]) {
        for (jumpParentIndex, jumpTargetIndex) in jumpMappings {
            guard let jumpNode = node(atIndex: jumpParentIndex) as? JumpListNode,
                  let jumpTargetNode = node(atIndex: jumpTargetIndex) as? IterativeListNode else {
                fatalError("Jump Mappings not set up properly!")
            }
            jumpNode.jumpTarget = jumpTargetNode
        }
    }
}

class CommandDataListIterator: Sequence, IteratorProtocol {
    private var commandDataLinkedList: CommandDataLinkedList
    private var isFirstCall: Bool

    private var current: CommandDataListNode? {
        willSet(newNode) {
            guard let newNode = newNode else {
                return
            }
            let index = commandDataLinkedList.indexOf(newNode)
            NotificationCenter.default.post(name: Constants.NotificationNames.moveProgramCounter,
                                            object: nil,
                                            userInfo: ["index": index])
        }
    }

    var index: Int? {
        return current == nil ? nil : commandDataLinkedList.indexOf(current!)
    }

    init(_ commandDataLinkedList: CommandDataLinkedList) {
        self.commandDataLinkedList = commandDataLinkedList
        self.current = commandDataLinkedList.first
        self.isFirstCall = true
    }

    func makeIterator() -> CommandDataListIterator {
        return self
    }

    func next() -> CommandData? {
        if isFirstCall {
            isFirstCall = false
            return current?.commandData
        }

        current = current?.next
        return current?.commandData
    }

    func previous() {
        current = current?.previous
    }

    func jump() {
        guard let current = current as? JumpListNode else {
            preconditionFailure("Cannot jump on a non-jump command")
        }

        self.current = current.jumpTarget
    }

    func moveIterator(to index: Int) {
        current = commandDataLinkedList.node(atIndex: index)
        isFirstCall = true
    }

    func reset() {
        current = commandDataLinkedList.first
        isFirstCall = true
    }

}
