//: # Playground project for WWDC 2018 Scholarship
//: Created by *Philipp Zakharchenko* (also known as *Phil Zet*).
/*:
*/
/*:
[My Website](https://philzet.com)

You can find the full source code below. There is no hidden code or additional files. Feel free to explore.

For better experience, view in _landscape_ and _fullscreen_.

![Logo](Logo.png)
*/

import Foundation
import UIKit
import ARKit
import SpriteKit
import AVFoundation
import AudioToolbox
import CoreMedia
import PlaygroundSupport

//: `GenericScene` is used to handle custom initialization of the augmented reality scenes used in this playground.
@available(iOSApplicationExtension 11.0, *)
class GenericScene: ARSCNView {
	
	init() {
		// Setting up the scene
		super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 500), options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue])
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

//: `MainViewController` class is the primary handler of all operations and scenarios in the playground.
@available(iOSApplicationExtension 11.0, *)
class MainViewController: UIViewController, ARSCNViewDelegate {
	
	// Defining instance variables
	let introScene = GenericScene()
	let mainScene = GenericScene()
	var globalMessage = TopMessage()
	
	private var internalTimer = Timer()
	private var videoTimer = Timer()
	private var detectedPlane = false
	private var tutorialCounter = 0
	private var currentTransform = SCNMatrix4()
	
	private var isObjectInteractive = false
	private var isObjectInsertionAllowed = false
	
	private var cube = SCNNode()
	private var cylinder = SCNNode()
	private var cones = [SCNNode]()
	private var videoNode = SCNNode()
	
	private var planeNode = SCNNode()
	private var planeColor = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		configuration.isLightEstimationEnabled = true
		
		mainScene.session.run(configuration)
		
		mainScene.delegate = self
		mainScene.debugOptions = []
		mainScene.autoenablesDefaultLighting = false
		mainScene.automaticallyUpdatesLighting = false
		mainScene.antialiasingMode = .multisampling4X
		
		let env = UIImage(named: "Environment.jpg")
		mainScene.scene.lightingEnvironment.contents = env
		
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.tapHandler(withGestureRecognizer:)))
		mainScene.addGestureRecognizer(tapGestureRecognizer)
		
		self.view.addSubview(mainScene)
		mainScene.frame = view.frame
		
		let audioSession = AVAudioSession.sharedInstance()
		
		// Sound source: https://www.bensound.com
		let audioSource = SCNAudioSource(named: "Soundtrack.m4a")
		let audioPlayer = SCNAudioPlayer(source: audioSource!)
		mainScene.scene.rootNode.addAudioPlayer(audioPlayer)
		
		self.view.addSubview(introScene)
		introScene.frame = self.view.frame
		
		let cubeIntroScene = SCNScene(named: "Intro.scn")
		let intro = cubeIntroScene!.rootNode.childNode(withName: "scene", recursively: false)!
		
		introScene.scene.rootNode.addChildNode(intro)
		introScene.pointOfView = introScene.scene.rootNode.childNode(withName: "scene", recursively: false)!.childNode(withName: "camera0", recursively: false)!
		
		let backgroundImage = UIImage(named: "IntroBackground.jpg")
		introScene.scene.background.contents = backgroundImage
		
		introScene.alpha = 0.0
		mainScene.alpha = 0.0
		self.view.backgroundColor = UIColor.darkGray
		
		showMessages()
		animateIntroStep1()
		
		// Updating the frame – just in case of device orientation changes.
		Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { (timer) in
			self.introScene.frame = self.view.frame
			self.mainScene.frame = self.view.frame
		}
		
	}
	
	// The following methods are used to animate the intro and control its timing.
	
	func animateIntroStep1() {
		
		Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
			UIView.animate(withDuration: 0.5, animations: {
				self.introScene.alpha = 1.0
			}, completion: { (done) in
				if done {
					self.showIntroStep1()
				}
			})
		}
		
	}
	
	func showIntroStep1() {
		let cameraAction = SCNAction.moveBy(x: 0, y: 4, z: 0, duration: 6.0)
		let rotateAction = SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 6.0)
		introScene.pointOfView?.runAction(cameraAction)
		introScene.pointOfView?.runAction(rotateAction)
		
		Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { (timer) in
			
			UIView.animate(withDuration: 1.0, animations: {
				self.introScene.alpha = 0.0
			}, completion: { (done) in
				if done {
					self.animateIntroStep2()
				}
			})
			
		}
	}
	
	func animateIntroStep2() {
		
		introScene.pointOfView = introScene.scene.rootNode.childNode(withName: "scene", recursively: false)!.childNode(withName: "camera1", recursively: false)!
		self.showIntroStep2()
		
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
			UIView.animate(withDuration: 0.5, animations: {
				self.introScene.alpha = 1.0
			}, completion: { (done) in
			})
		}
		
	}
	
	func showIntroStep2() {
		
		let boxNode = introScene.scene.rootNode.childNode(withName: "scene", recursively: false)!.childNode(withName: "box0", recursively: false)!
		let moveAction = SCNAction.moveBy(x: 0, y: 1.1, z: 0, duration: 3.0)

		let cameraAction = SCNAction.moveBy(x: 4, y: 0, z: -1, duration: 12.0)
		introScene.pointOfView?.runAction(cameraAction)
		
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
			let cur = boxNode.rotation
			let rotateAction = SCNAction.rotate(toAxisAngle: SCNVector4Make(0, 1, 0, (cur.w) - Float(M_PI_4 * 0.3)), duration: 1.0)
			boxNode.runAction(rotateAction)
		}
		
		Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { (timer) in
			boxNode.runAction(moveAction)
			Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { (timer) in
				let vector = SCNVector3(x: boxNode.position.x, y: -0.2, z: boxNode.position.z)
				self.insertEffect(fileName: "DustIntro", position: vector, toScene: self.introScene.scene)
				self.insertEffect(fileName: "BokehIntro", position: vector, toScene: self.introScene.scene)
			}
		}
		
		Timer.scheduledTimer(withTimeInterval: 11.0, repeats: false) { (timer) in
			
			UIView.animate(withDuration: 1.0, animations: {
				self.introScene.alpha = 0.0
				self.mainScene.alpha = 1.0
			}, completion: { (done) in
				if done {
					self.introScene.removeFromSuperview()
					self.animateIntroStep2()
				}
			})
			
		}
	}
	
	// This method handles touch events on the mainScene.
	@objc func tapHandler(withGestureRecognizer recognizer: UIGestureRecognizer) {
		
		let tapLocation = recognizer.location(in: mainScene)
		let hitTestResults = mainScene.hitTest(tapLocation, types: .existingPlaneUsingExtent)
		
		guard let hitTestResult = hitTestResults.first else { return }
		let translation = hitTestResult.worldTransform.translation
		let x = translation.x
		let y = translation.y
		let z = translation.z
		
		if self.tutorialCounter == 1 && self.isObjectInsertionAllowed {
			
			tutorialCounter = 2
			
			let cubeScene = SCNScene(named: "Cube.scn")
			self.cube = cubeScene!.rootNode.childNode(withName: "cube", recursively: false)!
			
			self.cube.position = SCNVector3(x,y,z)
			self.cube.childNode(withName: "Sphere0", recursively: false)?.opacity = 0.0
			self.cube.childNode(withName: "Sphere1", recursively: false)?.opacity = 0.0
			self.cube.childNode(withName: "Sphere2", recursively: false)?.opacity = 0.0
			
			mainScene.scene.rootNode.addChildNode(self.cube)
			
			self.insertEffect(fileName: "Bokeh", node: self.cube)
			self.insertEffect(fileName: "Dust", node: self.cube)
			
			planeNode.removeFromParentNode()
			planeColor = UIColor.white.withAlphaComponent(0.0)
			
			self.isObjectInsertionAllowed = false
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if self.tutorialCounter == 4 && self.isObjectInsertionAllowed {
			
			tutorialCounter = 5
			
			let cubeScene = SCNScene(named: "Cylinder.scn")
			self.cylinder = cubeScene!.rootNode.childNode(withName: "cylinder", recursively: false)!
			
			self.cylinder.position = SCNVector3(x,y,z)
			self.cylinder.childNode(withName: "Sphere0", recursively: false)?.opacity = 0.0
			self.cylinder.childNode(withName: "Sphere1", recursively: false)?.opacity = 0.0
			self.cylinder.childNode(withName: "Sphere2", recursively: false)?.opacity = 0.0
			self.cylinder.childNode(withName: "Sphere3", recursively: false)?.opacity = 0.0
			self.cylinder.childNode(withName: "Sphere4", recursively: false)?.opacity = 0.0
			self.cylinder.childNode(withName: "Sphere5", recursively: false)?.opacity = 0.0
			
			mainScene.scene.rootNode.addChildNode(self.cylinder)
			
			self.insertEffect(fileName: "Bokeh", node: self.cylinder)
			self.insertEffect(fileName: "Dust", node: self.cylinder)
			
			planeNode.removeFromParentNode()
			planeColor = UIColor.white.withAlphaComponent(0.0)
			
			self.isObjectInsertionAllowed = false
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if self.tutorialCounter == 8 && self.isObjectInsertionAllowed {
			
			tutorialCounter = 9
			
			let cubeScene = SCNScene(named: "Cone1.scn")
			self.cones.append(cubeScene!.rootNode.childNode(withName: "cone", recursively: false)!)
			
			self.cones[0].position = SCNVector3(x,y,z)
			self.cones[0].childNode(withName: "Sphere0", recursively: false)?.opacity = 0.0
			self.cones[0].childNode(withName: "Sphere1", recursively: false)?.opacity = 0.0
			self.cones[0].childNode(withName: "Sphere2", recursively: false)?.opacity = 0.0
			
			mainScene.scene.rootNode.addChildNode(self.cones[0])
			
			self.insertEffect(fileName: "Bokeh", node: self.cones[0])
			self.insertEffect(fileName: "Dust", node: self.cones[0])
			
			planeNode.removeFromParentNode()
			planeColor = UIColor.white.withAlphaComponent(0.0)
			
			self.isObjectInsertionAllowed = false
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if self.tutorialCounter == 9 && self.isObjectInsertionAllowed {
			
			tutorialCounter = 10
			
			let cubeScene = SCNScene(named: "Cone2.scn")
			self.cones.append(cubeScene!.rootNode.childNode(withName: "cone", recursively: false)!)
			
			self.cones[1].position = SCNVector3(x,y,z)
			self.cones[1].childNode(withName: "Sphere0", recursively: false)?.opacity = 0.0
			self.cones[1].childNode(withName: "Sphere1", recursively: false)?.opacity = 0.0
			self.cones[1].childNode(withName: "Sphere2", recursively: false)?.opacity = 0.0
			
			mainScene.scene.rootNode.addChildNode(self.cones[1])
			
			let position1 = self.cones[0].position
			let position2 = self.cones[1].position
			var newPosition = SCNVector3()
			
			var threshold: Float = 0.1
			
			if Float(position2.x - position1.x) < threshold && Float(position2.x - position1.x) >= 0 {
				newPosition.x = position2.x + threshold
			} else if Float(position2.x - position1.x) > -threshold && Float(position2.x - position1.x) < 0 {
				newPosition.x = position2.x - threshold
			} else {
				newPosition.x = position2.x
			}
			newPosition.y = position2.y
			newPosition.z = position2.z
			
			self.cones[1].position = newPosition
			
			self.insertEffect(fileName: "Dust", node: self.cones[1])
			
			planeNode.removeFromParentNode()
			planeColor = UIColor.white.withAlphaComponent(0.0)
			
			self.isObjectInsertionAllowed = false
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if self.tutorialCounter == 12 && self.isObjectInsertionAllowed {
			
			tutorialCounter = 13
			self.isObjectInsertionAllowed = false
			self.triggerVideo(position: SCNVector3(x ,y, z))
			self.globalMessage.hide()
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if self.tutorialCounter == 3 && self.isObjectInteractive {
			
			let hitTestResultCube = mainScene.hitTest(tapLocation, options: nil)
			
			for hit in hitTestResultCube {
				for node in self.cube.childNodes {
					if hit.node == node {
						self.globalMessage.hide()
						self.onCubeTapped()
						self.tutorialCounter = 4
						break
					}
				}
			}
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
		} else if (self.tutorialCounter == 6 || self.tutorialCounter == 7) && self.isObjectInteractive {
			
			let hitTestResultCylinder = mainScene.hitTest(tapLocation, options: nil)
			var breakAllLoops = false
			
			SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
			
			for hit in hitTestResultCylinder {
				for node in self.cylinder.childNodes {
					if hit.node == node && self.tutorialCounter == 6 && !breakAllLoops {
						self.globalMessage.hide()
						self.onCylinderTapped()
						self.tutorialCounter = 7
						breakAllLoops = true
						break
					} else if hit.node == node && self.tutorialCounter == 7 && !breakAllLoops {
						self.globalMessage.hide()
						self.onCylinderTappedTwice()
						self.tutorialCounter = 8
						breakAllLoops = true
						break
					}
				}
				for node in (self.cylinder.childNode(withName: "container", recursively: false)?.childNodes)! {
					if hit.node == node && self.tutorialCounter == 6 && !breakAllLoops {
						self.globalMessage.hide()
						self.onCylinderTapped()
						self.tutorialCounter = 7
						breakAllLoops = true
						break
					} else if hit.node == node && self.tutorialCounter == 7 && !breakAllLoops {
						self.globalMessage.hide()
						self.onCylinderTappedTwice()
						self.tutorialCounter = 8
						breakAllLoops = true
						break
					}
				}
			}
			
		} else if (self.tutorialCounter == 10 || self.tutorialCounter == 11) && self.isObjectInteractive {
			
			let hitTestResultCube = mainScene.hitTest(tapLocation, options: nil)
			
			var superNode = self.cones[0].childNodes
			if self.tutorialCounter == 11 {
				superNode = self.cones[1].childNodes
			}
			
			for hit in hitTestResultCube {
				for node in superNode {
					if hit.node == node {
						self.globalMessage.hide()
						SystemSoundID.playFileNamed(fileName: "Positive", withExtenstion: "mp3")
						
						if self.tutorialCounter == 10 {
							self.onFirstConeTapped()
							self.tutorialCounter = 11
						} else {
							self.onSecondConeTapped()
							self.tutorialCounter = 12
						}
						
						break
					}
				}
			}
			
		} else {
			SystemSoundID.playFileNamed(fileName: "Negative", withExtenstion: "mp3")
		}
		
	}
	
	// The following methods are used to insert particle systems. Overloading is used to provide multiple call options.
	
	func insertEffect(fileName: String, node: SCNNode) {
		let particleSystem2 = SCNParticleSystem(named: "\(fileName)", inDirectory: nil)
		let systemNode2 = SCNNode()
		systemNode2.addParticleSystem(particleSystem2!)
		systemNode2.position = node.position
		mainScene.scene.rootNode.addChildNode(systemNode2)
	}
	
	func insertEffect(fileName: String, position: SCNVector3, toScene: SCNScene) {
		let particleSystem2 = SCNParticleSystem(named: "\(fileName)", inDirectory: nil)
		let systemNode2 = SCNNode()
		systemNode2.addParticleSystem(particleSystem2!)
		systemNode2.position = position
		toScene.rootNode.addChildNode(systemNode2)
	}
	
	func insertEffect(fileName: String, position: SCNVector3, toScene: SCNScene, factor: Int) {
		let particleSystem2 = SCNParticleSystem(named: "\(fileName)", inDirectory: nil)
		let systemNode2 = SCNNode()
		systemNode2.addParticleSystem(particleSystem2!)
		systemNode2.position = SCNVector3(x: position.x / Float(factor), y: position.y / Float(factor), z: position.z / Float(factor))
		toScene.rootNode.addChildNode(systemNode2)
	}
	
	// The following methods are for ARSCNViewDelegate
	// This method captures the orientation of the camera (used for video).
	func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
		guard let pointOfView = mainScene.pointOfView else { return }
		self.currentTransform = pointOfView.transform
	}
	
	// This method is used to update light based on background lighting conditions.
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		updateLight()
	}
	
	// The following methods work with detection of planes and their addition to the scene.
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

		planeNode.removeFromParentNode()

		guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
		
		let width = CGFloat(planeAnchor.extent.x)
		let height = CGFloat(planeAnchor.extent.z)
		let plane = SCNPlane(width: width, height: height)
		
		plane.materials.first?.diffuse.contents = planeColor
		
		planeNode = SCNNode(geometry: plane)
		
		let x = CGFloat(planeAnchor.center.x)
		let y = CGFloat(planeAnchor.center.y)
		let z = CGFloat(planeAnchor.center.z)
		planeNode.position = SCNVector3(x, y, z)
		planeNode.eulerAngles.x = -.pi / 2
		
		node.addChildNode(planeNode)
		
		self.detectedPlane = true
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

		guard let planeAnchor = anchor as?  ARPlaneAnchor,
			let planeNode = node.childNodes.first,
			let plane = planeNode.geometry as? SCNPlane
			else { return }
		
		let width = CGFloat(planeAnchor.extent.x)
		let height = CGFloat(planeAnchor.extent.z)
		plane.width = width
		plane.height = height
		
		let x = CGFloat(planeAnchor.center.x)
		let y = CGFloat(planeAnchor.center.y)
		let z = CGFloat(planeAnchor.center.z)
		planeNode.position = SCNVector3(x, y, z)
	}
	
	// This method is called every time new lighting environment data becomes available.
	func updateLight() {
		DispatchQueue.main.async {
			guard let estimate = self.mainScene.session.currentFrame?.lightEstimate else {
				return
			}
			
			let intensity = estimate.ambientIntensity / 500
			self.mainScene.scene.lightingEnvironment.intensity = intensity
		}
	}
	
}

extension float4x4 {
	var translation: float3 {
		let translation = self.columns.3
		return float3(translation.x, translation.y, translation.z)
	}
}

//: `TopMessage` is the class that **encapsulates** the message functionalities.
class TopMessage: UIView {
	
	var message = ""
	private var constant = 40
	
	override func awakeFromNib() {
		
		self.frame = CGRect(x: -400, y: self.constant, width: 400, height: 90)
		
		let backgroundView: RoundedVisualEffectView = {
			
			let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
			let blurEffectView = RoundedVisualEffectView(effect: blurEffect)
			blurEffectView.translatesAutoresizingMaskIntoConstraints = false
			let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
			let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
			blurEffectView.frame = self.frame
			blurEffectView.contentView.addSubview(vibrancyView)
			return blurEffectView
			
		}()
		
		self.addSubview(backgroundView)
		
		let label = UILabel(frame: CGRect(x: self.frame.minX + 5.0, y: self.frame.minY + 5.0, width: self.frame.width - 10.0, height: self.frame.height - 10.0))
		label.center = self.center
		label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.medium)
		label.textColor = .white
		label.textAlignment = .center
		label.text = self.message
		label.numberOfLines = 0
		self.addSubview(label)
		
		UIView.animate(withDuration: 0.9, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: [], animations: {
			
			self.frame = CGRect(x: 420, y: self.constant, width: 400, height: 90)
			
		}, completion: nil)
		
	}
	
	// The method used to hide the message. The message will be deleted from the hierarchy automatically.
	func hide() {
		
		UIView.animate(withDuration: 0.9, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: [], animations: {
			
			self.frame = CGRect(x: -400, y: self.constant, width: 400, height: 90)
			
		}, completion: {
			(completed) in
			if completed {
				self.removeFromSuperview()
			}
		})
		
	}
	
}

//: `RoundedVisualEffectView` is used to create `UIVisualEffectView`s with corner radius.
class RoundedVisualEffectView: UIVisualEffectView {
	
	override func layoutSubviews() {
		super.layoutSubviews()
		updateMaskLayer()
	}
	
	func updateMaskLayer() {
		let shapeLayer = CAShapeLayer()
		shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10).cgPath
		self.layer.mask = shapeLayer
	}
}

//: `SystemSound` extension for playing a sound effect from a specified file
extension SystemSoundID {
	
	static func playFileNamed(fileName: String, withExtenstion fileExtension: String) {
		var sound: SystemSoundID = 0
		if let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
			AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
			AudioServicesPlaySystemSound(sound)
		}
	}
	
}

//: This `MainViewController` extension encloses the methods that work with _scenario_ and _time handling_.
@available(iOSApplicationExtension 11.0, *)
extension MainViewController {
	
	// This is the initial method that is called to start executing the scenario.
	func showMessages() {
		
		var c = 2.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Hello!"
			self.introScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.3
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Stereometry can be frustrating. As a student, I understand this."
			self.introScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.5
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "But not with Augmented Reality."
			self.introScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Welcome to a demo of using AR in a geometry class."
			self.introScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			if !self.detectedPlane {
				
				self.globalMessage.message = "First, let's detect a horizontal surface. I'll highlight it for you as soon as I find it. Try moving around a little."
				self.mainScene.addSubview(self.globalMessage)
				self.globalMessage.awakeFromNib()
				
			}
			
			self.internalTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
				
				if self.detectedPlane && self.tutorialCounter == 0 {
					self.globalMessage.hide()
					self.onPlaneDetected()
					self.tutorialCounter = 1
				}
				
			}
			
		}
		
	}
	
	// This method gets called as soon as a new ARPlane has been detected.
	func onPlaneDetected() {
		internalTimer.invalidate()
		var c = 0.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Awesome! A surface has been detected. Now let's add something."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			self.isObjectInsertionAllowed = true
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			self.globalMessage.message = "Tap anywhere on the plane to add a cube."
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
			self.internalTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
				
				if self.detectedPlane && self.tutorialCounter == 2 {
					self.globalMessage.hide()
					self.onCubeInserted()
					self.tutorialCounter = 3
				}
				
			}
			
		}
	}
	
	// This method gets called as soon as the user taps the surface to insert a cube.
	func onCubeInserted() {
		
		internalTimer.invalidate()
		var c = 0.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Great!"
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "We can dissect a cube by selecting three points on its surface."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				
				let action = SCNAction.fadeIn(duration: 1.0)
				self.cube.childNode(withName: "Sphere0", recursively: false)?.runAction(action)
				self.cube.childNode(withName: "Sphere1", recursively: false)?.runAction(action)
				self.cube.childNode(withName: "Sphere2", recursively: false)?.runAction(action)
				
				let materialTemp = self.cube.childNode(withName: "Cube1", recursively: false)?.geometry?.materials[0]
				let material = self.cube.childNode(withName: "Cube1", recursively: false)?.geometry?.materials[1]
				self.cube.childNode(withName: "Cube1", recursively: false)?.geometry?.firstMaterial = material
				
				let changeColor = SCNAction.customAction(duration: 1.0) { (node, elapsedTime) -> () in
					let percentage = elapsedTime
					let color = UIColor(red: 16/255 + (220-16)/255 * percentage, green: 149/255 + (57-149)/255 * percentage, blue: 230/255 + (20-230)/255 * percentage, alpha: 1)
					material!.diffuse.contents = color
					
					node.geometry!.firstMaterial = material
				}
				
				self.cube.childNode(withName: "Cube1", recursively: false)?.runAction(changeColor)
				
				Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
					msg.hide()
				}
				
			}
			
		}
		
		c += 5.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Now tap the cube to dissect it!"
			self.isObjectInteractive = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
		}
		
	}
	
	// This method gets called as soon as the user taps the cube to continue the scenario.
	func onCubeTapped() {
		
		self.isObjectInteractive = false
		
		let dissection = self.cube.childNode(withName: "Cube1", recursively: false)!
		
		let moveDissection = SCNAction.moveBy(x: 0, y: 0.16, z: 0, duration: 3.0)
		dissection.runAction(moveDissection)
		
		let action = SCNAction.fadeOut(duration: 1.0)
		self.cube.childNode(withName: "Sphere0", recursively: false)?.runAction(action)
		self.cube.childNode(withName: "Sphere1", recursively: false)?.runAction(action)
		self.cube.childNode(withName: "Sphere2", recursively: false)?.runAction(action)
		
		self.insertEffect(fileName: "Dust", node: self.cube)
		
		var c = 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "It's way easier to dissect objects when they're real, isn't it?"
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Alright, let's move on."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			let dissection = self.cube.childNode(withName: "Cube1", recursively: false)!
			
			let moveDissection = SCNAction.moveBy(x: 0, y: -0.16, z: 0, duration: 0.5)
			dissection.runAction(moveDissection)
			
			Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
				self.insertEffect(fileName: "Explosion", node: self.cube)
				SystemSoundID.playFileNamed(fileName: "Explosion", withExtenstion: "mp3")
			}
			
			Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { (timer) in
				self.cube.removeFromParentNode()
			}
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			self.globalMessage.message = "Tap anywhere on the surface to add a cylinder."
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
			self.isObjectInsertionAllowed = true
			
			self.internalTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
				
				if self.detectedPlane && self.tutorialCounter == 5 {
					self.globalMessage.hide()
					self.onCylinderInserted()
					self.tutorialCounter = 6
				}
				
			}
			
		}
		
	}
	
	// This method gets called as soon as the user inserts the cylinder.
	func onCylinderInserted() {
		
		internalTimer.invalidate()
		var c = 0.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Fantastic!"
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Once again, we can dissect our cylinder by selecting three points on its surface."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				
				let action = SCNAction.fadeIn(duration: 1.0)
				self.cylinder.childNode(withName: "Sphere3", recursively: false)?.runAction(action)
				self.cylinder.childNode(withName: "Sphere4", recursively: false)?.runAction(action)
				self.cylinder.childNode(withName: "Sphere5", recursively: false)?.runAction(action)
				
				let materialTemp = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)?.geometry?.materials[0]
				let material = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)?.geometry?.materials[1]
				self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)?.geometry?.firstMaterial = material
				
				let changeColor = SCNAction.customAction(duration: 1.0) { (node, elapsedTime) -> () in
					let percentage = elapsedTime
					let color = UIColor(red: 128/255 + (255-128)/255 * percentage, green: 97/255 + (111-97)/255 * percentage, blue: 255/255 + (86-255)/255 * percentage, alpha: 1)
					material!.diffuse.contents = color
					
					node.geometry!.firstMaterial = material
				}
				
				self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)?.runAction(changeColor)
				
				Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
					msg.hide()
				}
				
			}
			
		}
		
		c += 5.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Now you can dissect this cylinder! (Tap it)"
			self.isObjectInteractive = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
		}
		
	}
	
	// This method gets called as soon as the user taps the cylinder
	func onCylinderTapped() {
		
		self.isObjectInteractive = false
		
		let dissection = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)!
		
		let moveDissection = SCNAction.moveBy(x: 2.0, y: 0, z: -0.5, duration: 3.0)
		dissection!.runAction(moveDissection)
		
		let action = SCNAction.fadeOut(duration: 1.0)
		self.cylinder.childNode(withName: "Sphere3", recursively: false)?.runAction(action)
		self.cylinder.childNode(withName: "Sphere4", recursively: false)?.runAction(action)
		self.cylinder.childNode(withName: "Sphere5", recursively: false)?.runAction(action)
		
		self.insertEffect(fileName: "Dust", node: self.cylinder)
		
		var c = 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "So this cross section has the shape of a circle."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "But we can dissect a cylinder to get an ellipse."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				
				let action = SCNAction.fadeIn(duration: 1.0)
				self.cylinder.childNode(withName: "Sphere0", recursively: false)?.runAction(action)
				self.cylinder.childNode(withName: "Sphere1", recursively: false)?.runAction(action)
				self.cylinder.childNode(withName: "Sphere2", recursively: false)?.runAction(action)
				
				let materialTemp = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)?.geometry?.materials[0]
				let material = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)?.geometry?.materials[1]
				self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)?.geometry?.firstMaterial = material
				
				let changeColor = SCNAction.customAction(duration: 1.0) { (node, elapsedTime) -> () in
					let percentage = elapsedTime
					let color = UIColor(red: 128/255 + (255-128)/255 * percentage, green: 97/255 + (93-97)/255 * percentage, blue: 255/255 + (228-255)/255 * percentage, alpha: 1)
					material!.diffuse.contents = color
					
					node.geometry!.firstMaterial = material
				}
				
				self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)?.runAction(changeColor)
				
				Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
					msg.hide()
				}
				
			}
			
		}
		
		c += 5.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Tap it once again and let's see."
			self.isObjectInteractive = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
		}
		
	}
	
	// This method gets called as soon as the cylinder has been tapped twice.
	func onCylinderTappedTwice() {
		
		self.isObjectInteractive = false
		
		let dissection = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)!
		
		let moveDissection = SCNAction.moveBy(x: -2.0, y: 1.5, z: -1.0, duration: 3.0)
		dissection!.runAction(moveDissection)
		
		let action = SCNAction.fadeOut(duration: 1.0)
		self.cylinder.childNode(withName: "Sphere0", recursively: false)?.runAction(action)
		self.cylinder.childNode(withName: "Sphere1", recursively: false)?.runAction(action)
		self.cylinder.childNode(withName: "Sphere2", recursively: false)?.runAction(action)
		
		self.insertEffect(fileName: "Dust", node: self.cylinder)
		
		var c = 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "As you can see, this cross section forms an ellipse."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "It's time to move on."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
				
				let dissection = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder1", recursively: false)!
				
				let moveDissection = SCNAction.moveBy(x: -2.0, y: 0, z: 0.5, duration: 0.4)
				dissection!.runAction(moveDissection)
				
				let dissectionSecond = self.cylinder.childNode(withName: "container", recursively: false)?.childNode(withName: "Cylinder2", recursively: false)!
				
				let moveDissectionSecond = SCNAction.moveBy(x: 2.0, y: -1.5, z: 1.0, duration: 0.4)
				dissectionSecond!.runAction(moveDissectionSecond)
				
				Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
					self.insertEffect(fileName: "Explosion", node: self.cylinder)
					SystemSoundID.playFileNamed(fileName: "Explosion", withExtenstion: "mp3")
				}
				
				Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { (timer) in
					self.cylinder.removeFromParentNode()
				}
				
				Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
					msg.hide()
				}
				
			}
			
		}
		
		c += 5.0
		
		Timer.scheduledTimer(withTimeInterval: c + 1, repeats: false) { (timer) in
			
			self.globalMessage.message = "Tap anywhere on the surface to add a cone."
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
			self.isObjectInsertionAllowed = true
			
			self.internalTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
				
				if self.detectedPlane && self.tutorialCounter == 9 {
					self.globalMessage.hide()
					self.onFirstConeInserted()
				}
				
			}
			
		}
		
	}
	
	// This method gets called when the user inserts the 1st cone.
	func onFirstConeInserted() {
		
		internalTimer.invalidate()
		var c = 1.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Great! We'll need 2 cones, so please add one more."
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
			self.isObjectInsertionAllowed = true
			
			self.internalTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
				
				if self.detectedPlane && self.tutorialCounter == 10 {
					self.globalMessage.hide()
					self.onSecondConeInserted()
				}
				
			}
			
		}
		
	}
	
	// This method gets called as soon as the 2nd cone has been inserted.
	func onSecondConeInserted() {
		
		internalTimer.invalidate()
		var c = 0.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Awesome!"
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 2.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Generally, when we dissect a cone, we get a parabola-shaped cross section."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 3.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "Let's pick 3 points and see."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
			Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
				
				let action = SCNAction.fadeIn(duration: 1.0)
				self.cones[0].childNode(withName: "Sphere0", recursively: false)?.runAction(action)
				self.cones[0].childNode(withName: "Sphere1", recursively: false)?.runAction(action)
				self.cones[0].childNode(withName: "Sphere2", recursively: false)?.runAction(action)
				
				let materialTemp = self.cones[0].childNode(withName: "Cone1", recursively: false)?.geometry?.materials[0]
				let material = self.cones[0].childNode(withName: "Cone1", recursively: false)?.geometry?.materials[1]
				self.cones[0].childNode(withName: "Cone1", recursively: false)?.geometry?.firstMaterial = material
				
				let changeColor = SCNAction.customAction(duration: 1.0) { (node, elapsedTime) -> () in
					let percentage = elapsedTime
					let color = UIColor(red: 16/255 + (255-16)/255 * percentage, green: 180/255 + (146-180)/255 * percentage, blue: 180/255 + (86-180)/255 * percentage, alpha: 1)
					material!.diffuse.contents = color
					
					node.geometry!.firstMaterial = material
				}
				
				self.cones[0].childNode(withName: "Cone1", recursively: false)?.runAction(changeColor)
				
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Now tap the first cone to dissect it."
			self.isObjectInteractive = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
		}
		
	}
	
	// This method gets called as soon as the first cone gets tapped.
	func onFirstConeTapped() {
		
		self.isObjectInteractive = false
		
		let dissection = self.cones[0].childNode(withName: "Cone1", recursively: false)!
		
		let moveDissection = SCNAction.moveBy(x: 0.0, y: -1.5, z: 0.0, duration: 3.0)
		dissection.runAction(moveDissection)
		
		let action = SCNAction.fadeOut(duration: 1.0)
		self.cones[0].childNode(withName: "Sphere0", recursively: false)?.runAction(action)
		self.cones[0].childNode(withName: "Sphere1", recursively: false)?.runAction(action)
		self.cones[0].childNode(withName: "Sphere2", recursively: false)?.runAction(action)
		
		self.insertEffect(fileName: "Dust", node: self.cones[0])
		
		var c = 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "This cross section forms a parabola."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "But for cones, we can get different cross sections. Once again, we'll need 3 points..."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
				msg.hide()
			}
			
			Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
				
				let action = SCNAction.fadeIn(duration: 1.0)
				self.cones[1].childNode(withName: "Sphere0", recursively: false)?.runAction(action)
				self.cones[1].childNode(withName: "Sphere1", recursively: false)?.runAction(action)
				self.cones[1].childNode(withName: "Sphere2", recursively: false)?.runAction(action)
				
				let materialTemp = self.cones[1].childNode(withName: "Cone1", recursively: false)?.geometry?.materials[0]
				let material = self.cones[1].childNode(withName: "Cone1", recursively: false)?.geometry?.materials[1]
				self.cones[1].childNode(withName: "Cone1", recursively: false)?.geometry?.firstMaterial = material
				
				let changeColor = SCNAction.customAction(duration: 1.0) { (node, elapsedTime) -> () in
					let percentage = elapsedTime
					let color = UIColor(red: 29/255 + (160-29)/255 * percentage, green: 182/255 + (131-182)/255 * percentage, blue: 102/255 + (255-102)/255 * percentage, alpha: 1)
					material!.diffuse.contents = color
					
					node.geometry!.firstMaterial = material
				}
				
				self.cones[1].childNode(withName: "Cone1", recursively: false)?.runAction(changeColor)
				
			}
			
		}
		
		c += 4.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Tap the second cone and let's see."
			self.isObjectInteractive = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
		}
		
	}
	
	// This method gets called as soon as the user taps the 2nd cone.
	func onSecondConeTapped() {
		
		self.isObjectInteractive = false
		
		let dissection = self.cones[1].childNode(withName: "Cone1", recursively: false)!
		
		let moveDissection = SCNAction.moveBy(x: -1.5, y: 0.0, z: 0.0, duration: 3.0)
		dissection.runAction(moveDissection)
		
		let action = SCNAction.fadeOut(duration: 1.0)
		self.cones[1].childNode(withName: "Sphere0", recursively: false)?.runAction(action)
		self.cones[1].childNode(withName: "Sphere1", recursively: false)?.runAction(action)
		self.cones[1].childNode(withName: "Sphere2", recursively: false)?.runAction(action)
		
		self.insertEffect(fileName: "Dust", node: self.cones[1])
		
		var c = 3.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "So, this cross section forms a triangle."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
		c += 4.5
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = "I hope you've enjoyed this demo! Let's continue."
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timer) in
				
				var c = 0
				for cone in self.cones {
					
					let dissection = cone.childNode(withName: "Cone1", recursively: false)!
					
					var moveDissection = SCNAction.moveBy(x: 0.0, y: 1.5, z: 0.0, duration: 0.4)
					if c == 1 {
						moveDissection = SCNAction.moveBy(x: 1.5, y: 0.0, z: 0.0, duration: 0.4)
					}
					dissection.runAction(moveDissection)
					
					Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
						self.insertEffect(fileName: "Explosion", node: cone)
					}
					
					Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { (timer) in
						cone.removeFromParentNode()
					}
					
					c += 1
					
				}
				
				Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
					SystemSoundID.playFileNamed(fileName: "Explosion", withExtenstion: "mp3")
				}
				
				Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
					msg.hide()
				}
				
			}
			
		}
		
		c += 5.0
		
		Timer.scheduledTimer(withTimeInterval: c, repeats: false) { (timer) in
			
			self.globalMessage.message = "Let's get to know each other! Tap the plane to insert a video."
			self.isObjectInsertionAllowed = true
			self.mainScene.addSubview(self.globalMessage)
			self.globalMessage.awakeFromNib()
			
			self.fadeOutAudio()
			
		}
		
	}
	
	// This method is used to create a fade-out effect for background music, before inserting the video.
	func fadeOutAudio() {
		
		if self.mainScene.scene.rootNode.audioPlayers[0].audioNode!.engine!.mainMixerNode.outputVolume > 0.1 {
			self.mainScene.scene.rootNode.audioPlayers[0].audioNode!.engine!.mainMixerNode.outputVolume = self.mainScene.scene.rootNode.audioPlayers[0].audioNode!.engine!.mainMixerNode.outputVolume - 0.1
			
			let mainQueue = DispatchQueue.main
			mainQueue.asyncAfter(deadline: .now() + 0.15) {
				self.fadeOutAudio()
			}
			
		} else {
			self.mainScene.scene.rootNode.audioPlayers[0].audioNode!.engine!.mainMixerNode.outputVolume = 0
		}
		
	}
	
	// This method inserts an AR video to a given vector position.
	func triggerVideo(position: SCNVector3) {
		
		let spriteKitScene = SKScene(size: CGSize(width: mainScene.frame.width, height: mainScene.frame.height))
		spriteKitScene.scaleMode = .aspectFit
		
		let videoUrl = Bundle.main.url(forResource: "Video", withExtension: "mp4")!
		let videoPlayer = AVPlayer(url: videoUrl)
		
		videoPlayer.actionAtItemEnd = .none
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.playerEnded),
			name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
			object: nil)
		
		let videoSpriteKitNode = SKVideoNode(avPlayer: videoPlayer)
		videoSpriteKitNode.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
		videoSpriteKitNode.size = spriteKitScene.size
		videoSpriteKitNode.yScale = -1.0
		videoSpriteKitNode.play()
		spriteKitScene.addChild(videoSpriteKitNode)
		
		let background = SCNPlane(width: 0.25, height: 0.14)
		background.cornerRadius = background.width / 15
		videoNode = SCNNode(geometry: background)
		videoNode.geometry!.firstMaterial?.diffuse.contents = spriteKitScene
		videoNode.eulerAngles = SCNVector3(x: 0, y: 90, z: 0)
		videoNode.transform = self.currentTransform
		videoNode.position = position
		mainScene.scene.rootNode.addChildNode(videoNode)
		
		videoTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { (timer) in
			
			let rand = self.randomArray()
			
			let pos = SCNVector3(x: self.videoNode.position.x * 1000 + Float(rand[0]), y: self.videoNode.position.y * 1000 + Float(rand[1]), z: self.videoNode.position.z * 1000 + Float(rand[2]))
			
			self.insertEffect(fileName: "Firework", position: pos, toScene: self.mainScene.scene, factor: 500)
			
			let duration = CMTimeGetSeconds(videoPlayer.currentItem!.asset.duration)
			let currentTime = CMTimeGetSeconds(videoPlayer.currentTime())
			
			if (currentTime / duration) > 0.98 {
				let moveScreen = SCNAction.move(by: SCNVector3(x: 0, y: 2, z: 0), duration: 2.0)
				self.videoNode.runAction(moveScreen)
			}
		}
		
		self.insertEffect(fileName: "Dust", node: videoNode)
		
	}
	
	// This method generates a random array. Used for fireworks.
	func randomArray() -> [Int] {
		return [Int(arc4random_uniform(500)) - 250, Int(arc4random_uniform(250)), Int(arc4random_uniform(500)) - 250]
	}
	
	// This method gets called when the video player finishes playback.
	@objc func playerEnded() {
		
		self.videoTimer.invalidate()
		self.videoNode.removeFromParentNode()
		
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
			
			var msg = TopMessage()
			msg.message = """
			Thanks for watching!
			I hope to see you at WWDC! 😄
			"""
			self.mainScene.addSubview(msg)
			msg.awakeFromNib()
			
			Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { (timer) in
				msg.hide()
			}
			
		}
		
	}
	
}

//: This code starts the execution of the playground.
if #available(iOSApplicationExtension 11.0, *) {

    let viewController = MainViewController()
    PlaygroundPage.current.liveView = viewController
    PlaygroundPage.current.needsIndefiniteExecution = true

}
