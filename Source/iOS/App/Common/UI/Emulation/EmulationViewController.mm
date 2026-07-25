// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Core.h"
#import "Core/Host.h"
#import "Core/PowerPC/PowerPC.h"
#import "Core/System.h"

#import "EmulationBootParameter.h"
#import "EmulationCoordinator.h"
#import "HostNotifications.h"
#import "LocalizationUtil.h"
#import "JitManager.h"
#import "NKitWarningViewController.h"

@interface EmulationViewController ()

@end

@implementation EmulationViewController {
  bool _didStartEmulation;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _didStartEmulation = false;
  
  [[EmulationCoordinator shared] registerMainDisplayView:self.rendererView];
  
  self.rendererView.alpha = 1.0f;
  
  // Create right bar button items
  self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopPressed)];
  self.pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pausePressed)];
  self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPressed)];
  self.hideBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"eye.slash"] style:UIBarButtonItemStylePlain target:self action:@selector(hideBarPressed)];

  self.stopButton.accessibilityLabel = @"Stop Emulation";
  self.pauseButton.accessibilityLabel = @"Pause Emulation";
  self.playButton.accessibilityLabel = @"Resume Emulation";
  self.hideBarButton.accessibilityLabel = @"Hide Emulation Menu";
  self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Emulation Settings";
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.pauseButton,
    self.hideBarButton
  ];
  
  [self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTitleChangedNotification) name:DOLHostTitleChangedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEmulationEndNotification) name:DOLEmulationDidEndNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!_didStartEmulation) {
    const PowerPC::CPUCore current_core = Config::Get(Config::MAIN_CPU_CORE);
    const bool is_interpreter_core = current_core == PowerPC::CPUCore::Interpreter || current_core == PowerPC::CPUCore::CachedInterpreter;
    
    if (![JitManager shared].acquiredJit && !is_interpreter_core) {
      JitWaitViewController* jitController = [[JitWaitViewController alloc] initWithNibName:@"JitWait" bundle:nil];
      jitController.delegate = self;
      jitController.modalInPresentation = true;
      
      [self presentViewController:jitController animated:true completion:nil];
    } else if ([self checkIfNeedToShowNKitWarning]) {
      [self showNKitWarning];
    } else {
      [self startEmulationAfterPerformanceCheck];
    }
    
    _didStartEmulation = true;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLHostTitleChangedNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLEmulationDidEndNotification object:nil];
}

- (void)didFinishJitScreenWithResult:(JitWaitViewControllerResult)result sender:(id)sender {
  [self dismissViewControllerAnimated:true completion:^{
    if (result == JitWaitViewControllerResultCancel) {
      [self.navigationController dismissViewControllerAnimated:true completion:nil];
      return;
    }
    
    if (result == JitWaitViewControllerResultNoJitRequested) {
      Config::Set(Config::LayerType::CurrentRun, Config::MAIN_CPU_CORE, PowerPC::CPUCore::CachedInterpreter);
    }
    
    if ([self checkIfNeedToShowNKitWarning]) {
      [self showNKitWarning];
    } else {
      [self startEmulationAfterPerformanceCheck];
    }
  }];
}

- (BOOL)checkIfNeedToShowNKitWarning {
  if (Config::GetBase(Config::MAIN_SKIP_NKIT_WARNING)) {
    return false;
  }
  
  return self.bootParameter.isNKit;
}

- (void)showNKitWarning {
  NKitWarningViewController* nkitController = [[NKitWarningViewController alloc] initWithNibName:@"NKitWarning" bundle:nil];
  nkitController.delegate = self;
  nkitController.modalInPresentation = true;
  
  [self presentViewController:nkitController animated:true completion:nil];
}

- (void)didFinishNKitWarningScreenWithResult:(BOOL)result sender:(id)sender {
  [self dismissViewControllerAnimated:true completion:^{
    if (result) {
      [self startEmulationAfterPerformanceCheck];
    } else {
      [self.navigationController dismissViewControllerAnimated:true completion:nil];
    }
  }];
}

- (void)startEmulationAfterPerformanceCheck {
  NSProcessInfo* processInfo = NSProcessInfo.processInfo;
  BOOL lowPowerModeEnabled = processInfo.lowPowerModeEnabled;
  BOOL thermalPressureIsHigh = processInfo.thermalState >= NSProcessInfoThermalStateSerious;

#if DEBUG && TARGET_OS_SIMULATOR
  if ([[processInfo.environment objectForKey:@"DOL_FORCE_PERFORMANCE_WARNING"] boolValue]) {
    lowPowerModeEnabled = true;
  }
#endif

  if (!lowPowerModeEnabled && !thermalPressureIsHigh) {
    [self startEmulation];
    return;
  }

  NSMutableArray<NSString*>* reasons = [[NSMutableArray alloc] init];
  if (lowPowerModeEnabled) {
    [reasons addObject:@"Low Power Mode is enabled. Turn it off in Settings for higher and more stable performance."];
  }
  if (thermalPressureIsHigh) {
    [reasons addObject:@"This device is already under serious thermal pressure. Let it cool before starting for smoother frame pacing."];
  }

  UIAlertController* alert = [UIAlertController
      alertControllerWithTitle:@"Performance Warning"
                       message:[reasons componentsJoinedByString:@"\n\n"]
                preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Back to Library"
                                           style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction* action) {
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Continue Anyway"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction* action) {
    [self startEmulation];
  }]];
  [self presentViewController:alert animated:true completion:nil];
}

- (void)startEmulation {
  [[EmulationCoordinator shared] runEmulationWithBootParameter:self.bootParameter];
}

- (void)updateNavigationBar:(bool)hidden {
  [self.navigationController setNavigationBarHidden:hidden animated:true];
  
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Adjust the safe area insets.
  UIEdgeInsets insets = self.additionalSafeAreaInsets;
  if (hidden) {
    insets.top = 0;
  } else {
    // The safe area should extend behind the navigation bar.
    // This makes the bar "float" on top of the content.
    insets.top = -(self.navigationController.navigationBar.bounds.size.height);
  }
  
  self.additionalSafeAreaInsets = insets;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)stopPressed {
  if (Core::GetState(Core::System::GetInstance()) == Core::State::Starting) {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Emulation Starting" message:@"Emulation is still starting. Please wait for emulation to start before requesting for it to stop." preferredStyle:UIAlertControllerStyleAlert];
  
    [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:true completion:nil];
    
    return;
  }
  
  void (^stop)() = ^{
    Host_Message(HostMessageID::WMUserStop);
  };
  
  if (Config::Get(Config::MAIN_CONFIRM_ON_STOP)) {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Confirm") message:DOLCoreLocalizedString(@"Do you want to stop the current emulation?") preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"No") style:UIAlertActionStyleDefault handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Yes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
      stop();
    }]];
    
    [self presentViewController:alert animated:true completion:nil];
  } else {
    stop();
  }
}

- (void)pausePressed {
  if (!Core::IsRunningOrStarting(Core::System::GetInstance())) {
    return;
  }
  
  [EmulationCoordinator shared].userRequestedPause = true;
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.playButton,
    self.hideBarButton
  ];
}

- (void)playPressed {
  if (!Core::IsRunningOrStarting(Core::System::GetInstance())) {
    return;
  }
  
  [EmulationCoordinator shared].userRequestedPause = false;
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.pauseButton,
    self.hideBarButton
  ];
}

- (void)hideBarPressed {
  [self updateNavigationBar:true];
}

- (void)receiveTitleChangedNotification {
  // Reserved for title-dependent UI updates. Personal builds collect no telemetry.
}

- (void)receiveEmulationEndNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:0.25f animations:^{
      self.rendererView.alpha = 0.0f;
    } completion:^(bool) {
      if (![EmulationCoordinator shared].isExternalDisplayConnected) {
        [[EmulationCoordinator shared] clearMetalLayer];
      }
      
      [self.navigationController dismissViewControllerAnimated:true completion:nil];
    }];
  });
}

@end
