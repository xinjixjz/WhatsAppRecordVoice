//
//  WARVViewController.m
//  WhatsAppRecordVoice
//
//  Created by xjz on 14-3-18.
//  Copyright (c) 2014年 xjz. All rights reserved.
//

#import "WARVViewController.h"

@interface WARVViewController ()

@property (nonatomic, strong) NSTimer *testRecordTimer;
@property (nonatomic, assign) NSUInteger testSeconds;
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

- (NSTimer *)testRecordTimer
{
    if (!_testRecordTimer) {
        _testRecordTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateRecordTime:) userInfo:nil repeats:YES];
        self.testSeconds = YES;
    }
    return _testRecordTimer;
}

- (void)updateRecordTime:(NSTimer *)timer
{
    self.testSeconds++;
    NSUInteger sec = self.testSeconds % 60;
    NSString *secondStr = nil;
    if (sec < 10) {
        secondStr = [NSString stringWithFormat:@"0%lu",(unsigned long)sec];
    }
    else{
        secondStr = [NSString stringWithFormat:@"%lu",(unsigned long)sec];
    }
    NSString *mims = [NSString stringWithFormat:@"%lu",self.testSeconds / 60];
    [self.chatPanelView updateTime:[NSString stringWithFormat:@"%@:%@",mims,secondStr]];
}

- (void)chatPanelViewShouldBeginRecord:(WARVChatPanelView *)view
{
    //prepare for recording ..
    [NSThread sleepForTimeInterval:0.3];
    [view didBeginRecord];
    
    //for test
    [[NSRunLoop currentRunLoop] addTimer:self.testRecordTimer forMode:NSDefaultRunLoopMode];
    [self.testRecordTimer fire];
}

- (void)invalidateTestTimer
{
    [self.testRecordTimer invalidate];
    self.testRecordTimer = nil;
}

- (void)chatPanelViewShouldCancelRecord:(WARVChatPanelView *)view
{
    [self invalidateTestTimer];
}

- (void)chatPanelViewShouldFinishedRecord:(WARVChatPanelView *)view
{
    [self invalidateTestTimer];
}

@end
