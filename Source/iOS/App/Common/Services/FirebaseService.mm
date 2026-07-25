// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirebaseService.h"

@implementation FirebaseService

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  // Telemetry is intentionally disabled in personal/sideloaded builds.
  return true;
}

@end
