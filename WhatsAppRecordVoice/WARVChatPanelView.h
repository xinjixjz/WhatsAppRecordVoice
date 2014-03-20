//
//  WARVChatPanelView.h
//  WhatsAppRecordVoice
//
//  Created by xjz on 14-3-18.
//  Copyright (c) 2014年 xjz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WARVChatPanelView;

@protocol WARVChatPanelViewDelegate <NSObject>

@required

- (void)chatPanelViewShouldBeginRecord:(WARVChatPanelView *)view;
- (void)chatPanelViewShouldCancelRecord:(WARVChatPanelView *)view;
- (void)chatPanelViewShouldFinishedRecord:(WARVChatPanelView *)view;

@end

@interface WARVChatPanelView : UIView

- (void)showInView:(UIView *)view;

- (void)didBeginRecord;
- (void)updateTime:(NSString *)time;

@property (nonatomic, weak) id<WARVChatPanelViewDelegate> delegate;

@end
