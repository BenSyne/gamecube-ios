// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class MainDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  private func importFirstURL(from contexts: Set<UIOpenURLContext>) {
    guard let url = contexts.first?.url else { return }

    // Defer presentation until the scene's root controller is attached.
    DispatchQueue.main.async {
      ImportFileManager.shared().importFile(at: url)
    }
  }
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    MainSceneCoordinator.shared().mainScene = scene as? UIWindowScene
    importFirstURL(from: connectionOptions.urlContexts)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    importFirstURL(from: URLContexts)
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    MainSceneCoordinator.shared().mainScene = nil
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    ServiceManager.shared.applicationDidBecomeActive()
    
    BootNoticeManager.shared().presentToSceneIfNecessary()
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    ServiceManager.shared.applicationWillResignActive()
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    //
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    ServiceManager.shared.applicationDidEnterBackground()
  }
}
