//
//  WARVChatPanelView.h
//  WhatsAppRecordVoice
//
//  Created by xjz on 14-3-18.
//  Copyright (c) 2014年 xjz. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 WARVChatPanelView *view = [[WARVChatPanelView alloc] init];
 view.delegate = delegate;
 [view showInView:superView];
 */

@class WARVChatPanelView;

@protocol WARVChatPanelViewDelegate <NSObject>

@required

//tell you that you should begin recording
- (void)chatPanelViewShouldBeginRecord:(WARVChatPanelView *)view;
//tell you that you view should cancel recording
- (void)chatPanelViewShouldCancelRecord:(WARVChatPanelView *)view;
//tell you that you view should finish recording
- (void)chatPanelViewShouldFinishedRecord:(WARVChatPanelView *)view;

@end

@interface WARVChatPanelView : UIView

- (void)showInView:(UIView *)view;

//you should call this method when you have prepared for record
- (void)didBeginRecord;

//delegate
@property (nonatomic, weak) id<WARVChatPanelViewDelegate> delegate;

@end
