// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirstRunInitializationService.h"

#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "Core/Config/MainSettings.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/Wiimote.h"

#import "Core/Config/GraphicsSettings.h"
#import "VideoCommon/VideoConfig.h"

#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/InputConfig.h"

#import "BootNoticeManager.h"
#import "UnofficialBuildNoticeViewController.h"

@implementation FirstRunInitializationService

- (void)importDefaultProfileForInputConfig:(InputConfig*)config {
  ControllerEmu::EmulatedController* controller = config->GetController(0);
  
  const std::string builtInPath = config->GetSysProfileDirectoryPath() + "Touchscreen.ini";
  
  Common::IniFile iniFile;
  iniFile.Load(builtInPath);
  
  controller->LoadConfig(iniFile.GetOrCreateSection("Profile"));
  controller->UpdateReferences(g_controller_interface);
  
  config->SaveConfig();
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  NSUserDefaults* userDefaults = NSUserDefaults.standardUserDefaults;
  
  NSURL* defaultsPath = [[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"];
  NSDictionary* defaultsDict = [NSDictionary dictionaryWithContentsOfURL:defaultsPath];
  [userDefaults registerDefaults:defaultsDict];
  
  NSInteger launchTimes = [userDefaults integerForKey:@"launch_times"];
  
  [userDefaults setInteger:launchTimes + 1 forKey:@"launch_times"];
  
  if (launchTimes == 0) {
    [self importDefaultProfileForInputConfig:Pad::GetConfig()];
    [self importDefaultProfileForInputConfig:Wiimote::GetConfig()];
    
    Config::SetBase(Config::MAIN_GFX_BACKEND, "Metal");
    Config::SetBase(Config::GFX_SHADER_CACHE, true);
    Config::SetBase(Config::GFX_WAIT_FOR_SHADERS_BEFORE_STARTING, false);
    Config::SetBase(Config::GFX_SHADER_COMPILATION_MODE,
                    ShaderCompilationMode::AsynchronousSkipRendering);
    
    BOOL shouldPresentUnofficialNotice = true;
#if DEBUG && TARGET_OS_SIMULATOR
    // Keep first-run initialization in simulator smoke tests while allowing
    // the harness to proceed without tapping through a one-time notice.
    shouldPresentUnofficialNotice =
        ![[NSProcessInfo.processInfo.environment objectForKey:@"DOL_SUPPRESS_BOOT_NOTICE"] boolValue];
#endif
    if (shouldPresentUnofficialNotice) {
      [[BootNoticeManager shared] enqueueViewController:[[UnofficialBuildNoticeViewController alloc] initWithNibName:@"UnofficialBuildNotice" bundle:nil]];
    }
  }
  
  return true;
}

@end
