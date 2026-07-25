// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwareListViewController.h"

#import "EmulationBootParameter.h"
#import "EmulationViewController.h"
#import "FoundationStringUtil.h"
#import "GameFileCacheManager.h"
#import "GameFilePtrWrapper.h"
#import "SoftwarePropertiesViewController.h"
#import "Swift.h"
#import "WiiSystemUpdateViewController.h"

#import "UICommon/GameFile.h"

@interface SoftwareListViewController ()

@end

@implementation SoftwareListViewController {
  NSString* _wiiUpdateSource;
  bool _wiiUpdateIsOnline;
  UIView* _emptyStateView;
  UIActivityIndicatorView* _loadingIndicator;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.title = @"Library";
  self.collectionView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  self.collectionView.alwaysBounceVertical = true;
  self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

  UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
  refreshControl.accessibilityLabel = @"Refresh game library";
  [refreshControl addTarget:self action:@selector(refreshRequested:) forControlEvents:UIControlEventValueChanged];
  self.collectionView.refreshControl = refreshControl;

  [self configureEmptyState];

  self->_gameFiles = [[GameFileCacheManager sharedManager] getGames];
  [self updateEmptyStateLoading:false];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self reloadGameFiles];
}

- (void)reloadGameFiles {
  [self updateEmptyStateLoading:true];

  [[GameFileCacheManager sharedManager] rescanAndFetchMetadataWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_gameFiles = [[GameFileCacheManager sharedManager] getGames];
      [self.collectionView reloadData];
      [self.collectionView.refreshControl endRefreshing];
      [self updateEmptyStateLoading:false];
    });
  }];
}

- (void)refreshRequested:(UIRefreshControl*)sender {
  [self reloadGameFiles];
}

- (void)configureEmptyState {
  _emptyStateView = [[UIView alloc] initWithFrame:CGRectZero];
  _emptyStateView.backgroundColor = [UIColor clearColor];

  UIImageSymbolConfiguration* iconConfiguration =
      [UIImageSymbolConfiguration configurationWithPointSize:54 weight:UIImageSymbolWeightMedium];
  UIImageView* iconView = [[UIImageView alloc]
      initWithImage:[UIImage systemImageNamed:@"gamecontroller.fill" withConfiguration:iconConfiguration]];
  iconView.tintColor = [UIColor systemBlueColor];
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  iconView.accessibilityIgnoresInvertColors = true;

  UIView* iconBackdrop = [[UIView alloc] initWithFrame:CGRectZero];
  iconBackdrop.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.10];
  iconBackdrop.layer.cornerRadius = 42;
  iconBackdrop.layer.cornerCurve = kCACornerCurveContinuous;
  iconBackdrop.translatesAutoresizingMaskIntoConstraints = false;
  iconView.translatesAutoresizingMaskIntoConstraints = false;
  [iconBackdrop addSubview:iconView];
  [NSLayoutConstraint activateConstraints:@[
    [iconBackdrop.widthAnchor constraintEqualToConstant:84],
    [iconBackdrop.heightAnchor constraintEqualToConstant:84],
    [iconView.centerXAnchor constraintEqualToAnchor:iconBackdrop.centerXAnchor],
    [iconView.centerYAnchor constraintEqualToAnchor:iconBackdrop.centerYAnchor]
  ]];

  UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  titleLabel.text = @"Your games, beautifully organized";
  titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
  titleLabel.adjustsFontForContentSizeCategory = true;
  titleLabel.textColor = [UIColor labelColor];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.numberOfLines = 0;

  UILabel* detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  detailLabel.text = @"Import a GameCube or Wii disc image you dumped yourself. RVZ is recommended for smaller files without sacrificing compatibility.";
  detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  detailLabel.adjustsFontForContentSizeCategory = true;
  detailLabel.textColor = [UIColor secondaryLabelColor];
  detailLabel.textAlignment = NSTextAlignmentCenter;
  detailLabel.numberOfLines = 0;

  UIButton* importButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [importButton setTitle:@"  Import a Game" forState:UIControlStateNormal];
  [importButton setImage:[UIImage systemImageNamed:@"plus.circle.fill"] forState:UIControlStateNormal];
  importButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  importButton.titleLabel.adjustsFontForContentSizeCategory = true;
  importButton.tintColor = [UIColor whiteColor];
  importButton.backgroundColor = [UIColor systemBlueColor];
  importButton.layer.cornerRadius = 14;
  importButton.layer.cornerCurve = kCACornerCurveContinuous;
  importButton.contentEdgeInsets = UIEdgeInsetsMake(14, 22, 14, 22);
  importButton.accessibilityLabel = @"Import a Game";
  importButton.accessibilityHint = @"Opens the Files picker";
  [importButton addTarget:self
                   action:NSSelectorFromString(@"addButtonPressed:")
         forControlEvents:UIControlEventTouchUpInside];

  UILabel* legalLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  legalLabel.text = @"Games and system software are not included.";
  legalLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
  legalLabel.adjustsFontForContentSizeCategory = true;
  legalLabel.textColor = [UIColor tertiaryLabelColor];
  legalLabel.textAlignment = NSTextAlignmentCenter;
  legalLabel.numberOfLines = 0;

  UIStackView* stack = [[UIStackView alloc]
      initWithArrangedSubviews:@[iconBackdrop, titleLabel, detailLabel, importButton, legalLabel]];
  stack.axis = UILayoutConstraintAxisVertical;
  stack.alignment = UIStackViewAlignmentCenter;
  stack.spacing = 14;
  [stack setCustomSpacing:22 afterView:iconBackdrop];
  [stack setCustomSpacing:24 afterView:detailLabel];
  [stack setCustomSpacing:12 afterView:importButton];
  stack.translatesAutoresizingMaskIntoConstraints = false;
  [_emptyStateView addSubview:stack];

  [NSLayoutConstraint activateConstraints:@[
    [stack.centerXAnchor constraintEqualToAnchor:_emptyStateView.centerXAnchor],
    [stack.centerYAnchor constraintEqualToAnchor:_emptyStateView.centerYAnchor constant:-36],
    [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:_emptyStateView.leadingAnchor constant:32],
    [stack.trailingAnchor constraintLessThanOrEqualToAnchor:_emptyStateView.trailingAnchor constant:-32],
    [titleLabel.widthAnchor constraintLessThanOrEqualToConstant:520],
    [detailLabel.widthAnchor constraintLessThanOrEqualToConstant:520],
    [legalLabel.widthAnchor constraintLessThanOrEqualToConstant:520]
  ]];

  _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  _loadingIndicator.hidesWhenStopped = true;
  _loadingIndicator.accessibilityLabel = @"Scanning game library";
}

- (void)updateEmptyStateLoading:(BOOL)isLoading {
  if (isLoading && _gameFiles.count == 0) {
    [_loadingIndicator startAnimating];
    self.collectionView.backgroundView = _loadingIndicator;
  } else if (_gameFiles.count == 0) {
    [_loadingIndicator stopAnimating];
    self.collectionView.backgroundView = _emptyStateView;
  } else {
    [_loadingIndicator stopAnimating];
    self.collectionView.backgroundView = nil;
  }
}

- (void)loadGameFile:(GameFilePtrWrapper*)gameFileWrapper {
  std::shared_ptr<const UICommon::GameFile> game = gameFileWrapper.gameFile;
  
  std::shared_ptr<const UICommon::GameFile> second_game = nullptr;
  std::shared_ptr<const UICommon::GameFile> match_without_revision = nullptr;
  
  if (DiscIO::IsDisc(game->GetPlatform())) {
    for (GameFilePtrWrapper* otherWrapper in self->_gameFiles) {
      std::shared_ptr<const UICommon::GameFile> other_game = otherWrapper.gameFile;
      
      if (game->GetGameID() == other_game->GetGameID() &&
          game->GetDiscNumber() != other_game->GetDiscNumber()) {
        if (game->GetRevision() == other_game->GetRevision()) {
          second_game = other_game;
          break;
        } else {
          match_without_revision = other_game;
        }
      }
    }
  }
  
  if (second_game == nullptr) {
    second_game = match_without_revision;
  }
  
  _bootParameter = [[EmulationBootParameter alloc] init];
  _bootParameter.bootType = EmulationBootTypeFile;
  _bootParameter.path = CppToFoundationString(game->GetFilePath());
  _bootParameter.secondPath = second_game != nullptr ? CppToFoundationString(second_game->GetFilePath()) : nil;
  _bootParameter.isNKit = gameFileWrapper.gameFile->IsNKit();
  
  [self performSegueWithIdentifier:@"emulation" sender:nil];
}

- (void)loadGameCubeIPLForRegion:(DiscIO::Region)region {
  _bootParameter = [[EmulationBootParameter alloc] init];
  _bootParameter.bootType = EmulationBootTypeGCIPL;
  _bootParameter.iplRegion = region;
  
  [self performSegueWithIdentifier:@"emulation" sender:nil];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
  return self->_gameFiles.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
  SoftwareListCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"softwareCell" forIndexPath:indexPath];
  GameFilePtrWrapper* gameFileWrapper = [self->_gameFiles objectAtIndex:indexPath.item];
  
  NSString* gameName = CppToFoundationString(gameFileWrapper.gameFile->GetName(UICommon::GameFile::Variant::LongAndPossiblyCustom));
  
  const UICommon::GameCover& cover = gameFileWrapper.gameFile->GetCoverImage();
  
  UIImage* image;
  if (cover.buffer.empty()) {
    image = [UIImage imageNamed:@"NoCover"];
  } else {
    NSData* data = [NSData dataWithBytes:cover.buffer.data() length:cover.buffer.size()];
    image = [UIImage imageWithData:data];
  }
  
  cell.imageView.image = image;
  cell.nameLabel.text = gameName;
  cell.isAccessibilityElement = true;
  cell.accessibilityLabel = gameName;
  cell.accessibilityHint = @"Double tap to play. Touch and hold for game options.";
  
  return cell;
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
  GameFilePtrWrapper* gameFileWrapper = [self->_gameFiles objectAtIndex:indexPath.item];
  
  [self loadGameFile:gameFileWrapper];
}

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
  UIEdgeInsets insets = [self collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:indexPath.section];
  CGFloat spacing = [self collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
  CGFloat availableWidth = CGRectGetWidth(collectionView.bounds) -
      collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right -
      insets.left - insets.right;
  CGFloat idealWidth = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 160.f : 146.f;
  NSInteger columns = MAX(2, MIN(7, (NSInteger)floor((availableWidth + spacing) / (idealWidth + spacing))));
  CGFloat itemWidth = floor((availableWidth - spacing * (columns - 1)) / columns);
  return CGSizeMake(itemWidth, floor(itemWidth * 4.f / 3.f) + 58.f);
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
  CGFloat horizontal = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 32.f : 16.f;
  return UIEdgeInsetsMake(20.f, horizontal, 32.f, horizontal);
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                    layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
  return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 22.f : 14.f;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                    layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
  return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 28.f : 20.f;
}

#pragma mark Segue

- (void)performSegueForWiiUpdateWithSource:(NSString*)source isOnline:(bool)online {
  _wiiUpdateSource = source;
  _wiiUpdateIsOnline = online;
  
  [self performSegueWithIdentifier:@"wiiUpdate" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"emulation"]) {
    UINavigationController* navigationController = segue.destinationViewController;
    EmulationViewController* viewController = navigationController.viewControllers[0];
    
    viewController.bootParameter = _bootParameter;
  } else if ([segue.identifier isEqualToString:@"wiiUpdate"]) {
    WiiSystemUpdateViewController* updateController = segue.destinationViewController;
    
    updateController.updateSource = _wiiUpdateSource;
    updateController.isOnlineUpdate = _wiiUpdateIsOnline;
  } else if ([segue.identifier isEqualToString:@"properties"]) {
    UINavigationController* navigationController = segue.destinationViewController;
    SoftwarePropertiesViewController* propertiesController = navigationController.viewControllers[0];
    
    propertiesController.gameFileWrapper = _selectedFile;
  }
}

@end
