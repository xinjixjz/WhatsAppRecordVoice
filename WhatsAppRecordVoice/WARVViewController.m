//
//  WARVViewController.m
//  WhatsAppRecordVoice
//
//  Created by xjz on 14-3-18.
//  Copyright (c) 2014年 xjz. All rights reserved.
//

#import "WARVViewController.h"

@interface WARVViewController ()

@property (nonatomic, strong) WARVChatPanelView *chatPanelView;

@end

@implementation WARVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    WARVChatPanelView *view = [[WARVChatPanelView alloc] init];
    view.delegate = self;
    [view showInView:self.view];
    self.chatPanelView = view;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)chatPanelViewShouldBeginRecord:(WARVChatPanelView *)view
{
    //prepare for recording ..
    [self performSelector:@selector(prepareForRecord) withObject:nil afterDelay:1.5f];
}

- (void)prepareForRecord
{
    [self.chatPanelView didBeginRecord];
}

- (void)chatPanelViewShouldCancelRecord:(WARVChatPanelView *)view
{
    //if system didn't prepare for record
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareForRecord) object:nil];
}

- (void)chatPanelViewShouldFinishedRecord:(WARVChatPanelView *)view
{
    //if system didn't prepare for record
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareForRecord) object:nil];
}

@end
