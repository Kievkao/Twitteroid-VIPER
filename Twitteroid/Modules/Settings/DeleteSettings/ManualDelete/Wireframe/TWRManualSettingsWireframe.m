//
//  TWRManualDeleteSettingsWireframe.m
//  Twitteroid
//
//  Created by Andrii Kravchenko on 6/2/16.
//  Copyright © 2016 Kievkao. All rights reserved.
//

#import "TWRManualSettingsWireframe.h"
#import "TWRManualSettingsViewController.h"
#import "TWRManualSettingsPresenter.h"
#import "TWRManualSettingsInteractor.h"

#import "TWRStorageManagerProtocol.h"

@interface TWRManualSettingsWireframe()

@property (weak, nonatomic) TWRManualSettingsViewController *manualSettingsViewController;
@property (strong, nonatomic) id<TWRStorageManagerProtocol> storageManager;

@end

@implementation TWRManualSettingsWireframe

- (void)presentSettingsScreenFromViewController:(UIViewController*)viewController {
    self.manualSettingsViewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:[TWRManualSettingsViewController identifier]];

    TWRManualSettingsPresenter* presenter = [TWRManualSettingsPresenter new];

    presenter.wireframe = self;
    presenter.view = self.manualSettingsViewController;

    TWRManualSettingsInteractor *interactor = [[TWRManualSettingsInteractor alloc] initWithStorageManager:self.storageManager];
    presenter.interactor = interactor;

    self.manualSettingsViewController.eventHandler = presenter;

    [viewController.navigationController pushViewController:self.manualSettingsViewController animated:YES];
}

- (void)dismissSettingsScreen {
    [self.manualSettingsViewController.navigationController popViewControllerAnimated:YES];
}

@end
