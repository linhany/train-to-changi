//
// Manages the logic required to update the model when commands are executed.
//

import Foundation
class LogicManager {
    unowned private var model: Model

    init(model: Model) {
        self.model = model
    }

    // Executes the list of commands in `model.commands`.
    func executeCommands() {
        var commandIndex = 0
        //TODO: Clean up this after finishing up JumpCommand
        let commands = CommandTypeParser().parse(model.getCurrentCommands())
        while model.getRunState() == .running {
            let command = commands[commandIndex]
            command.setModel(model)
            let commandResult = commands[commandIndex].execute()
            if !commandResult.isSuccessful {
                model.updateRunState(to: .lost)

                let errorMessage = commandResult.errorMessage!
                NotificationCenter.default.post(name: Notification.Name(
                    rawValue: "gameLost"), object: errorMessage, userInfo: nil)
                break
            }

            commandIndex += 1
        }
    }

    // Reverts the state of the model by one command execution backward.
    func undo() {
        guard model.undo() else {
            fatalError("User should not be allowed to undo")
        }

        //TODO: notify if undo stack is empty - shift to ModelManager?
            NotificationCenter.default.post(name: Notification.Name(
                rawValue: "nothingToUndo"), object: nil, userInfo: nil)

        NotificationCenter.default.post(name: Notification.Name(
            rawValue: "nonEmptyRedoStack"), object: nil, userInfo: nil)
    }

    // Reverts the state of the model by one command execution forward.
    func redo() {
        guard model.redo() else {
            fatalError("User should not be allowed to redo")
        }

        //TODO: notify if redo stack is empty - shift to ModelManager?
            NotificationCenter.default.post(name: Notification.Name(
                rawValue: "nothingToRedo"), object: nil, userInfo: nil)

        NotificationCenter.default.post(name: Notification.Name(
            rawValue: "undoStackIsNotEmpty"), object: nil, userInfo: nil)
    }
}
