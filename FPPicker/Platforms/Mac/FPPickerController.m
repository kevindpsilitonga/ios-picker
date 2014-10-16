//
//  FPPickerController.m
//  FPPicker
//
//  Created by Ruben Nine on 18/08/14.
//  Copyright (c) 2014 Filepicker.io. All rights reserved.
//

#define FPPickerController_protected

#import "FPPickerController.h"
#import "FPInternalHeaders.h"
#import "FPSourceListController.h"
#import "FPSourceViewController.h"
#import "FPFileDownloadController.h"

@interface FPPickerController () <NSSplitViewDelegate,
                                  NSWindowDelegate,
                                  FPFileTransferControllerDelegate>

@property (nonatomic, weak) IBOutlet NSImageView *fpLogo;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *displayStyleSegmentedControl;
@property (nonatomic, weak) IBOutlet FPSourceViewController *sourceViewController;
@property (nonatomic, weak) IBOutlet FPSourceListController *sourceListController;

@property (nonatomic, assign) NSModalSession modalSession;

@end

@implementation FPPickerController

#pragma mark - Public Methods

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.fpLogo.image = [[FPUtils frameworkBundle] imageForResource:@"logo_small"];
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self = [[self.class alloc] initWithWindowNibName:@"FPPickerController"];

        self.shouldUpload = YES;
        self.shouldDownload = YES;
    }

    return self;
}

- (void)open
{
    self.modalSession = [NSApp beginModalSessionForWindow:self.window];

    [NSApp runModalSession:self.modalSession];
}

#pragma mark - Actions

- (IBAction)openFiles:(id)sender
{
//    if ([self.sourceViewController pickSelectedItems])

    // Validate selection by looking for directories

    NSArray *selectedItems = self.sourceViewController.selectedItems;
    FPBaseSourceController *sourceController = self.sourceViewController.sourceController;

    if (!selectedItems)
    {
        return;
    }

    for (NSDictionary *item in selectedItems)
    {
        if ([item[@"is_dir"] boolValue])
        {
            // Display alert with error

            NSError *error = [FPUtils errorWithCode:200
                              andLocalizedDescription:@"Selection must not contain any directories."];

            [FPUtils presentError:error
                  withMessageText:@"Selection error"];

            return;
        }
    }

    FPFileDownloadController *fileDownloadController = [[FPFileDownloadController alloc] initWithItems:selectedItems];

    fileDownloadController.delegate = self;
    fileDownloadController.sourceController = sourceController;

    [fileDownloadController process];

    [self.window close];
}

- (IBAction)close:(id)sender
{
    [self.sourceViewController cancelAllOperations];
    [self.window close];
}

#pragma mark - FPFileTransferControllerDelegate Methods

- (void)FPFileTransferControllerDidFinish:(FPFileTransferController *)transferController
                                     info:(id)info
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(FPPickerController:didFinishPickingMultipleMediaWithResults:)])
    {
        [self.delegate FPPickerController:self
         didFinishPickingMultipleMediaWithResults:info];
    }
}

- (void)FPFileTransferControllerDidFail:(FPFileTransferController *)transferController
                                  error:(NSError *)error
{
    DLog(@"Error: %@", error);
}

- (void)FPFileTransferControllerDidCancel:(FPFileTransferController *)transferController
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(FPPickerControllerDidCancel:)])
    {
        [self.delegate FPPickerControllerDidCancel:self];
    }
}

#pragma mark - NSWindowDelegate Methods

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.sourceListController.sourceNames = self.sourceNames;
    self.sourceListController.dataTypes = self.dataTypes;

    [self.sourceListController loadAndExpandSourceListIfRequired];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if (self.modalSession)
    {
        [NSApp endModalSession:self.modalSession];
    }
}

#pragma mark - NSSplitViewDelegate Methods

- (BOOL)           splitView:(NSSplitView *)splitView
    shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    return YES;
}

- (BOOL)     splitView:(NSSplitView *)splitView
    canCollapseSubview:(NSView *)subview
{
    return NO;
}

- (CGFloat)      splitView:(NSSplitView *)splitView
    constrainMinCoordinate:(CGFloat)proposedMinimumPosition
               ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 150)
    {
        proposedMinimumPosition = 150;
    }

    return proposedMinimumPosition;
}

- (CGFloat)      splitView:(NSSplitView *)splitView
    constrainMaxCoordinate:(CGFloat)proposedMinimumPosition
               ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition > 225)
    {
        proposedMinimumPosition = 225;
    }

    return proposedMinimumPosition;
}

@end
