//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import Foundation
import SwiftUI

class DummyVC: UIViewController {
  override var canBecomeFirstResponder: Bool { true }
  override var prefersStatusBarHidden: Bool { true }
  public override var prefersHomeIndicatorAutoHidden: Bool { true }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow? = nil
  private var _ctrl = DummyVC()
  private var _lockCtrl: UIViewController? = nil
  private var _spCtrl = SpaceController()
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions)
  {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }
    
    _spCtrl.sceneRole = session.role
    
    self.window = UIWindow(windowScene: windowScene)
    _spCtrl.restoreWith(stateRestorationActivity: session.stateRestorationActivity)
    window?.rootViewController = _spCtrl
    window?.makeKeyAndVisible()
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    guard let window = window else {
      return
    }
    
    // 1. Local Auth AutoLock Check
    
    if LocalAuth.shared.lockRequired {
      if let lockCtrl = _lockCtrl {
        if window.rootViewController != lockCtrl {
          window.rootViewController = lockCtrl
        }
        
        return
      }
      
      let unlockAction = scene.session.role == .windowApplication ? LocalAuth.shared.unlock : nil
      
      _lockCtrl = UIHostingController(rootView: LockView(unlockAction: unlockAction))
      window.rootViewController = _lockCtrl
      
      unlockAction?()

      return
    }

    _lockCtrl = nil
    LocalAuth.shared.stopTrackTime()
    
    // 2. Set space controller back and refresh layout
    
    let spCtrl = _spCtrl
    
    if window.rootViewController != spCtrl {
      window.rootViewController = spCtrl
    }
    
    guard let term = spCtrl.currentTerm() else {
      return
    }
    
    term.resumeIfNeeded()
    term.view?.setNeedsLayout()
    
    // We can present config or stuck view. 
    guard spCtrl.presentedViewController == nil else {
      return
    }
    
    // 3. Stuck Key Check
    
    let input = SmarterTermInput.shared
    if let key = input.stuckKey() {
      debugPrint("BK:", "stuck!!!")
      input.setTrackingModifierFlags([])
      
      if input.isHardwareKB && key == .commandLeft {
        let ctrl = UIHostingController(rootView: StuckView(keyCode: key, dismissAction: {
          spCtrl.onStuckOpCommand()
        }))
        
        ctrl.modalPresentationStyle = .formSheet
        spCtrl.stuckKeyCode = key
        spCtrl.present(ctrl, animated: false)

        return
      }
    }
    
    spCtrl.stuckKeyCode = nil
    
    // 4. Focus Check
    
    if term.termDevice.view?.isFocused() == false,
      !input.isRealFirstResponder,
      input.window === window {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
        if scene.activationState == .foregroundActive,
          !input.isRealFirstResponder {
          spCtrl.focusOnShellAction()
        }
      }
      
      return
    }
    
    if input.window === window {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
        if scene.activationState == .foregroundActive,
          term.termDevice.view?.isFocused() == false {
          spCtrl.focusOnShellAction()
        }
      }

      return
    }
    
    SmarterTermInput.shared.reportStateReset()
  }
  
  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    _setDummyVC()
    return _spCtrl.stateRestorationActivity()
  }
  
  private func _setDummyVC() {
    if let _ = _spCtrl.presentedViewController {
      return
    }
    // Trick to reset stick cmd key.
    _ctrl.view.frame = _spCtrl.view.frame
    window?.rootViewController = _ctrl
    _ctrl.view.addSubview(_spCtrl.view)
  }

}
