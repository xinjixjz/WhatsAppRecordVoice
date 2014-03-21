//
//  WARVChatPanelView.m
//  WhatsAppRecordVoice
//
//  Created by xjz on 14-3-18.
//  Copyright (c) 2014年 xjz. All rights reserved.
//

///wangzijuan@baidu.com

#import "WARVChatPanelView.h"
#import <CoreText/CoreText.h>
#import "FBShimmeringView.h"

#define kFloatRecordImageUpTime (0.5f)
#define kFloatRecordImageRotateTime (0.17f)
#define kFloatRecordImageDownTime (0.5f)
#define kFloatGarbageAnimationTime (.3f)
#define kFloatGarbageBeginY (45.0f)
#define kFloatCancelRecordingOffsetX  (100.0f)

void setViewFixedAnchorPoint(CGPoint anchorPoint, UIView *view)
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

@interface WARVSlideView : UIView

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

- (void)updateLocation:(CGFloat)offsetX;

@end

@implementation WARVSlideView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createSubViews];
    }
    
    return self;
}

- (void)createSubViews
{
    self.clipsToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.text = @"滑动删除";
    label.font = [UIFont systemFontOfSize:16.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [self addSubview:label];
    self.textLabel = label;
    
    UIImageView *bkimageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SlideArrow"]];
    CGRect frame = bkimageView.frame;
    frame.origin.x = self.frame.size.width / 2.0 + 33;
    frame.origin.y += 5;
    [bkimageView setFrame:frame];
    [self addSubview:bkimageView];
    self.arrowImageView = bkimageView;
}

- (void)updateLocation:(CGFloat)offsetX
{
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x += offsetX;
    self.textLabel.frame = labelFrame;
    
    CGRect imageFrame = self.arrowImageView.frame;
    imageFrame.origin.x += offsetX;
    self.arrowImageView.frame = imageFrame;
}

@end

@interface WARVGarbageView : UIView

@property (nonatomic, strong) UIImageView *bodyView;
@property (nonatomic, strong) UIImageView *headerView;

@end

@implementation WARVGarbageView


- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 18, 26)];
    if (self) {
        self.bodyView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BucketBodyTemplate"]];
        self.headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BucketLidTemplate"]];
        CGRect frame = self.bodyView.frame;
        frame.origin.y = 1;
        [self.bodyView setFrame:frame];
        [self addSubview:self.headerView];
        setViewFixedAnchorPoint(CGPointMake(0, 1), self.headerView);
        [self addSubview:self.bodyView];
    }
    return self;
}

@end

@interface WARVChatPanelView ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) FBShimmeringView *slideView;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIButton *otherBtn;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) CGPoint trackTouchPoint;
@property (nonatomic, assign) CGPoint firstTouchPoint;
@property (nonatomic, strong) WARVGarbageView *garbageImageView;
@property (nonatomic, assign) BOOL canCancelAnimation;
@property (nonatomic, assign) BOOL isCanceling;

@end

@implementation WARVChatPanelView

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 45)];
    if (self) {
        [self creatSubviews];
        self.canCancelAnimation = NO;
    }
    return self;
}

- (void)creatSubviews
{
    UIImageView *bkimageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bk"]];
    [bkimageView setFrame:self.bounds];
    [self addSubview:bkimageView];
    
    UIButton *other = [UIButton buttonWithType:UIButtonTypeSystem];
    [other setImage:[UIImage imageNamed:@"ButtonAttachMedia7"] forState:UIControlStateNormal];
    [other setTintColor:[UIColor blueColor]];
    [other setFrame:CGRectMake(10, 0, 26, 45)];
    [other addTarget:self action:@selector(sendOtherMsg:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:other];
    self.otherBtn = other;

    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(other.frame.origin.x + other.frame.size.width + 10, 8.5, 230, 26)];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.placeholder = @"说点什么吧...";
    [self addSubview:textField];
    self.textField = textField;
    
    UIButton *voice = [UIButton buttonWithType:UIButtonTypeSystem];
    [voice setImage:[UIImage imageNamed:@"ButtonMic7"] forState:UIControlStateNormal];
    [voice setTintColor:[UIColor blueColor]];
    [voice setFrame:CGRectMake(284, 0, 26, 45)];
    [voice addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [voice addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [voice addTarget:self action:@selector(finishedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    [self addSubview:voice];
    self.voiceBtn = voice;
}

- (void)beginRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    self.textField.hidden = YES;
    self.otherBtn.hidden = YES;
    UITouch *touch = [[event touchesForView:btn] anyObject];
    self.trackTouchPoint = [touch locationInView:self];
    self.firstTouchPoint = self.trackTouchPoint;
    self.isCanceling = NO;
    
    [self showSlideView];
    [self showRecordImageView];
    
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldBeginRecord:)]) {
        [self.delegate chatPanelViewShouldBeginRecord:self];
    }
}


- (void)mayCancelRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    UITouch *touch = [[event touchesForView:btn] anyObject];
    CGPoint curPoint = [touch locationInView:self];
    if (curPoint.x < self.voiceBtn.frame.origin.x) {
        [(WARVSlideView *)self.slideView.contentView updateLocation:(curPoint.x - self.trackTouchPoint.x)];
    }
    self.trackTouchPoint = curPoint;
    if ((self.firstTouchPoint.x - self.trackTouchPoint.x ) > kFloatCancelRecordingOffsetX) {
        self.isCanceling = YES;
        [btn cancelTrackingWithEvent:event];
        [self cancelRecord];
    }
}

- (void)finishedRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    if (self.isCanceling) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldFinishedRecord:)]) {
        [self.delegate chatPanelViewShouldFinishedRecord:self];
    }

    [self endRecord];
    
    self.recordBtn.hidden = YES;
}

- (void)cancelRecord
{
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldCancelRecord:)]) {
        [self.delegate chatPanelViewShouldCancelRecord:self];
    }
    
    [self.recordBtn.layer removeAllAnimations];
    self.slideView.hidden = YES;
    [self.voiceBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    CGRect orgFrame = self.recordBtn.frame;
    
    if (!self.canCancelAnimation) {
        [self endRecord];
        return;
    }
    
    [UIView animateWithDuration:kFloatRecordImageUpTime delay:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.recordBtn.frame;
        frame.origin.y -= (1.5 * self.recordBtn.frame.size.height);
        self.recordBtn.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            
            [self showGarbage];
            
            [UIView animateWithDuration:kFloatRecordImageRotateTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGAffineTransform transForm = CGAffineTransformMakeRotation(-1 * M_PI);
                self.recordBtn.transform = transForm;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:kFloatRecordImageDownTime delay:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.recordBtn.frame = orgFrame;
                    self.recordBtn.alpha = 0.1f;
                }completion:^(BOOL finished) {
                    self.recordBtn.hidden = YES;
                    [self dismissGarbage];
                }];
            }];
        }
        }];
}

- (void)dismissGarbage
{
    [UIView animateWithDuration:kFloatGarbageAnimationTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.garbageImageView.headerView.transform = CGAffineTransformIdentity;
        CGRect frame = self.garbageImageView.frame;
        frame.origin.y = kFloatGarbageBeginY;
        self.garbageImageView.frame = frame;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self endRecord];
        });
    }];
}

- (void)showGarbage
{
    [self garbageImageView];
    [UIView animateWithDuration:kFloatGarbageAnimationTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform transForm = CGAffineTransformMakeRotation(-1 * M_PI_2);
        self.garbageImageView.headerView.transform = transForm;
        CGRect frame = self.garbageImageView.frame;
        frame.origin.y = (self.bounds.size.height - frame.size.height) / 2.0;
        self.garbageImageView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

- (WARVGarbageView *)garbageImageView
{
    if (!_garbageImageView) {
        WARVGarbageView *imageView = [[WARVGarbageView alloc] init];
        CGRect frame = imageView.frame;
        frame.origin = CGPointMake(_recordBtn.center.x - frame.size.width / 2.0f, kFloatGarbageBeginY);
        [imageView setFrame:frame];
        [self addSubview:imageView];
        _garbageImageView = imageView;
    }
    return _garbageImageView;
}


- (void)showSlideView
{
    self.slideView.hidden = NO;
    CGRect frame = self.slideView.frame;
    CGRect orgFrame = {CGPointMake(CGRectGetMaxX(self.voiceBtn.frame),CGRectGetMinY(frame)),frame.size};
    self.slideView.frame = orgFrame;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.slideView.frame = frame;
    } completion:NULL];
}

- (void)showRecordImageViewGradient
{
    CABasicAnimation *basicAnimtion = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [basicAnimtion setRepeatCount:1000000];
    [basicAnimtion setDuration:1.0];
    basicAnimtion.autoreverses = YES;
    basicAnimtion.fromValue = [NSNumber numberWithFloat:1.0f];
    basicAnimtion.toValue = [NSNumber numberWithFloat:0.1f];
    [self.recordBtn.layer addAnimation:basicAnimtion forKey:nil];
}

- (void)showRecordImageView
{
    self.recordBtn.alpha = 1.0;
    self.recordBtn.hidden = NO;
    CGRect frame = self.recordBtn.frame;
    CGRect orgFrame = CGRectMake(CGRectGetMinX(self.voiceBtn.frame), frame.origin.y, frame.size.width, frame.size.height);
    self.recordBtn.frame = orgFrame;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.recordBtn.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            
        }
    }];
}

- (void)endRecord
{
    self.textField.hidden = NO;
    self.isCanceling = NO;
    self.canCancelAnimation = NO;
    
    if (_recordBtn) {
        [self.recordBtn.layer removeAllAnimations];
        [self.recordBtn removeFromSuperview];
        self.recordBtn = nil;
    }
    
    if (_slideView) {
        [self.slideView removeFromSuperview];
        self.slideView = nil;
    }
    
    if (_timeLabel) {
        [self.timeLabel removeFromSuperview];
        self.timeLabel = nil;
    }
    
    if (_garbageImageView) {
        [self.garbageImageView removeFromSuperview];
        self.garbageImageView = nil;
    }
    
    [self.voiceBtn addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [self.voiceBtn addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [self.voiceBtn addTarget:self action:@selector(finishedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    CGRect frame = self.otherBtn.frame;
    CGFloat offset = self.textField.frame.origin.x - frame.origin.x;
    frame.origin.x -= 100;
    [self.otherBtn setFrame:frame];
    self.otherBtn.hidden = NO;
    
    CGFloat textFieldMaxX = CGRectGetMaxX(self.textField.frame);
    self.textField.hidden = NO;
    frame = self.textField.frame;
    frame.origin.x = self.otherBtn.frame.origin.x + offset;
    frame.size.width = textFieldMaxX - frame.origin.x;
    [self.textField setFrame:frame];
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect nframe = self.otherBtn.frame;
        nframe.origin.x += 100;
        [self.otherBtn setFrame:nframe];
        
        nframe = self.textField.frame;
        nframe.origin.x = self.otherBtn.frame.origin.x + offset;
        nframe.size.width = textFieldMaxX - nframe.origin.x;
        [self.textField setFrame:nframe];
    }];
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(43, 0, 81, 45)];
        _timeLabel.textColor = [UIColor blackColor];
        _timeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (FBShimmeringView *)slideView
{
    if (!_slideView) {
        _slideView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(90, self.textField.frame.origin.y, 120, self.textField.frame.size.height)];
        WARVSlideView *contentView = [[WARVSlideView alloc] initWithFrame:_slideView.bounds];
        _slideView.contentView = contentView;
        [self addSubview:_slideView];
        
        _slideView.shimmeringDirection = FBShimmerDirectionLeft;
        _slideView.shimmeringSpeed = 60.0f;
        _slideView.shimmeringHighlightWidth = 0.29f;
        _slideView.shimmering = YES;
    }
    
    return _slideView;
}

- (UIButton *)recordBtn
{
    if (!_recordBtn) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_recordBtn setImage:[UIImage imageNamed:@"MicRecBtn"] forState:UIControlStateNormal];
        CGRect frame = self.otherBtn.frame;
        [_recordBtn setFrame:frame];
        [_recordBtn setTintColor:[UIColor redColor]];
        [self addSubview:_recordBtn];
    }
    
    return _recordBtn;
}


-(void)sendOtherMsg:(id)sender
{
    UIActionSheet *alertView = [[UIActionSheet alloc] initWithTitle:Nil delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照或录影",@"选择图片",@"选择视频",@"共享位置",@"共享联系人", nil];
    [alertView showInView:self];
}

- (void)showInView:(UIView *)view
{
    if (view) {
        CGRect frame = self.frame;
        frame.origin.x = 0;
        frame.origin.y = view.bounds.size.height - frame.size.height;
        [self setFrame:frame];
        
        [view addSubview:self];
    }
}

- (void)didBeginRecord
{
    self.canCancelAnimation = YES;
    [self timeLabel];
    [self showRecordImageViewGradient];
}

- (void)updateTime:(NSString *)time
{
    self.timeLabel.text = time;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
