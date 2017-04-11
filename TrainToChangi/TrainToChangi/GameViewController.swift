//
//  GameViewController.swift
//  TrainToChangi
//
//  Created by Zhi Yuan on 13/3/17.
//  Copyright © 2017 nus.cs3217.a0139655u. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    @IBOutlet weak var trainUIImage: UIImageView!
    @IBOutlet weak var musicButton: UIButton!

    fileprivate var model: Model!
    fileprivate var logic: Logic!
    fileprivate var scene: GameScene!

    @IBAction func musicButtonPressed(_ sender: UIButton) {
        AudioPlayer.sharedInstance.toggleBackgroundMusic()
        if AudioPlayer.sharedInstance.isMute() {
            musicButton.setBackgroundImage(Constants.UI.Music.noMusicImage,
                                           for: UIControlState.normal)
        } else {
            musicButton.setBackgroundImage(Constants.UI.Music.musicImage,
                                           for: UIControlState.normal)
        }
    }

    @IBAction func exitButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: {
            AudioPlayer.sharedInstance.stopBackgroundMusic()
        })
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerObservers()
        presentGameScene()
        animateTrain()
        AudioPlayer.sharedInstance.playBackgroundMusic()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let embeddedVC = segue.destination as? EditorViewController {
            embeddedVC.model = self.model
            embeddedVC.resetGameDelegate = self
        }

        if let embeddedVC = segue.destination as? ControlPanelViewController {
            embeddedVC.model = self.model
            embeddedVC.logic = self.logic
            embeddedVC.resetGameDelegate = self
        }
    }

    private func animateTrain() {
        var trainFrames = [UIImage]()
        for index in 0...Constants.UI.trainView.numTrainFrames {
            let frame = UIImage(named: "train_vert\(index)")!
            trainFrames.append(frame)
        }
        trainUIImage.animationImages = trainFrames
        trainUIImage.animationDuration = Constants.Animation.gameTrainAnimationDuration
        trainUIImage.startAnimating()
    }

    fileprivate func animateTrainWhenGameWon() {
        trainUIImage.stopAnimating()
        trainUIImage.animationImages = Constants.UI.trainView.gameWonTrainFrames
        trainUIImage.animationDuration = Constants.UI.trainView.gameWonTrainAnimationDuration
        trainUIImage.startAnimating()
    }

    fileprivate func initEndGameScreen() -> UIViewController {
        let storyboard = UIStoryboard(name: Constants.UI.mainStoryboardIdentifier, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Constants.UI.endGameViewControllerIdentifier)
        controller.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        controller.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        return controller
    }

    /// Use GameScene to move/animate the game objects
    private func presentGameScene() {
        scene = GameScene(model.currentLevel, size: view.bounds.size)
        guard let skView = view as? SKView else {
            assertionFailure("View should be a SpriteKit View!")
            return
        }
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
}

// MARK -- Event Handling
extension GameViewController {
    fileprivate func registerObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAnimationBegin(notification:)),
            name: Constants.NotificationNames.animationBegan, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAnimationEnd(notification:)),
            name: Constants.NotificationNames.animationEnded, object: nil)
    }

    // Updates `model.runState` to `.running(isAnimating: true).
    @objc fileprivate func handleAnimationBegin(notification: Notification) {
        if model.runState == .running(isAnimating: false) {
            model.runState = .running(isAnimating: true)
        } else if model.runState == .stepping(isAnimating: false) {
            model.runState = .stepping(isAnimating: true)
        }
    }

    // Updates `model.runState` accordingly depending on what is the current
    // `model.runState`.
    @objc fileprivate func handleAnimationEnd(notification: Notification) {
        if model.runState == .running(isAnimating: true) {
            model.runState = .running(isAnimating: false)
        } else if model.runState == .stepping(isAnimating: true) {
            model.runState = .paused
        } else if model.runState == .won {
            animateTrainWhenGameWon()
            scene.playJediGameWonAnimation()

            let controller = self.initEndGameScreen()
            AchievementsManager.sharedInstance.updateAchievements(model: self.model)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.UI.Delay.endGameScreenDisplayDelay), execute: {
                self.present(controller, animated: true, completion: nil)
            })
        }
    }
}

extension GameViewController: MapViewControllerDelegate {
    func initLevel(name: String?) {
        guard let name = name else {
            fatalError("Station must have a name!")
        }
        let levelIndex = indexOfStation(name: name)
        model = ModelManager(levelIndex: levelIndex,
                             levelData: Levels.levelData[levelIndex])
        logic = LogicManager(model: model)
    }

    private func indexOfStation(name: String) -> Int {
        let levelNames = Constants.StationNames.stationNames
        guard let index = levelNames.index(where: { $0 == name }) else {
            preconditionFailure("StationName does not exist!")
        }

        return index
    }
}

extension GameViewController: ResetGameDelegate {

    func resetGame(isAnimating: Bool) {
        model.resetPlayState()
        model.runState = .start // explicit assignment to trigger didSet
        logic.resetPlayState()

        NotificationCenter.default.post(Notification(
            name: Constants.NotificationNames.resetGameScene,
            object: nil, userInfo: ["isAnimating": isAnimating]))
    }

    func tryResetGame() {
        switch model.runState {
        case .paused, .lost:
            resetGame(isAnimating: false)
        default:
            break
        }
    }
}
