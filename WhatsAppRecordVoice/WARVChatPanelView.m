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

#define kFloatRecordImageUpTime (0.5f)
#define kFloatRecordImageRotateTime (0.17f)
#define kFloatRecordImageDownTime (0.5f)
#define kFloatGarbageAnimationTime (.35f)
#define kIntGarbageAnimationKeyframeCount (15)


#define WARVLabel_FRS 10
static const CGFloat gradientWidth = 0.2;
static const CGFloat gradientDimAlpha = 0.5;

@interface WARVLabel : UILabel
{
    NSTimer *animationTimer;
    CGFloat gradientLocations[3];
    int animationTimerCount;
    BOOL _animated;
}

@property (nonatomic, assign, getter = isAnimated) BOOL animated;

@end

@implementation WARVLabel

- (BOOL) isAnimated {
    return _animated;
}

- (void) setAnimated:(BOOL)animated {
    if (_animated != animated) {
        _animated = animated;
        if (_animated) {
            [self startTimer];
        } else {
            [self stopTimer];
        }
    }
}

// animationTimer methods
- (void)animationTimerFired:(NSTimer*)theTimer {
	// Let the timer run for 2 * FPS rate before resetting.
	// This gives one second of sliding the highlight off to the right, plus one
	// additional second of uniform dimness
	if (++animationTimerCount == (2 * WARVLabel_FRS)) {
		animationTimerCount = 0;
	}
	
	// Update the gradient for the next frame
	[self setGradientLocations:((CGFloat)animationTimerCount/(CGFloat)WARVLabel_FRS)];
}

- (void) startTimer {
	if (!animationTimer) {
		animationTimerCount = 0;
		[self setGradientLocations:0];
		animationTimer = [NSTimer
						   scheduledTimerWithTimeInterval:1.0/WARVLabel_FRS
						   target:self
						   selector:@selector(animationTimerFired:)
						   userInfo:nil
						   repeats:YES];
	}
}

- (void) stopTimer {
	if (animationTimer) {
		[animationTimer invalidate];
        animationTimer = nil;
	}
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
    NSDictionary *attr = @{NSFontAttributeName: self.font};
    CFDictionaryRef cfAttr = (__bridge CFDictionaryRef)(attr);
    CFAttributedStringRef cfAttrSting = CFAttributedStringCreate(kCFAllocatorDefault, (__bridge CFStringRef)(self.text), cfAttr);
    
    CTLineRef line = CTLineCreateWithAttributedString(cfAttrSting);
    CGContextSetTextMatrix(theContext, CGAffineTransformMake(1.0,  0.0,0.0, -1.0,0.0,  0.0));
    
    CGContextSetTextDrawingMode (theContext, kCGTextClip);
    CGContextSetTextPosition(theContext, (self.bounds.size.width - self.text.length * self.font.pointSize) / 2.0f, (self.bounds.size.height + self.font.pointSize) / 2.0f - 2.0f);
    CTLineDraw(line, theContext);
    CFRelease(line);
    
    CGPoint textEnd = CGContextGetTextPosition(theContext);
    
	///third-party code///
    
	// Get the foreground text color from the UILabel.
	// Note: UIColor color space may be either monochrome or RGB.
	// If monochrome, there are 2 components, including alpha.
	// If RGB, there are 4 components, including alpha.
	CGColorRef textColor = self.textColor.CGColor;
	const CGFloat *components = CGColorGetComponents(textColor);
	size_t numberOfComponents = CGColorGetNumberOfComponents(textColor);
	BOOL isRGB = (numberOfComponents == 4);
	CGFloat red = components[0];
	CGFloat green = isRGB ? components[1] : components[0];
	CGFloat blue = isRGB ? components[2] : components[0];
	CGFloat alpha = isRGB ? components[3] : components[1];
    
	// The gradient has 4 sections, whose relative positions are defined by
	// the "gradientLocations" array:
	// 1) from 0.0 to gradientLocations[0] (dim)
	// 2) from gradientLocations[0] to gradientLocations[1] (increasing brightness)
	// 3) from gradientLocations[1] to gradientLocations[2] (decreasing brightness)
	// 4) from gradientLocations[3] to 1.0 (dim)
	size_t num_locations = 3;
	
	// The gradientComponents array is a 4 x 3 matrix. Each row of the matrix
	// defines the R, G, B, and alpha values to be used by the corresponding
	// element of the gradientLocations array
	CGFloat gradientComponents[12];
	for (int row = 0; row < num_locations; row++) {
		int index = 4 * row;
		gradientComponents[index++] = red;
		gradientComponents[index++] = green;
		gradientComponents[index++] = blue;
		gradientComponents[index] = alpha * gradientDimAlpha;
	}
    
	// If animating, set the center of the gradient to be bright (maximum alpha)
	// Otherwise it stays dim (as set above) leaving the text at uniform
	// dim brightness
	if (animationTimer) {
		gradientComponents[7] = alpha;
	}
    
	// Load RGB Colorspace
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	// Create Gradient
	CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents,
																  gradientLocations, num_locations);
	// Draw the gradient (using label text as the clipping path)
	CGContextDrawLinearGradient (theContext, gradient, self.bounds.origin, textEnd, 0);
	
	// Cleanup
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorspace);
}

- (void) setGradientLocations:(CGFloat) leftEdge {
	// Subtract the gradient width to start the animation with the brightest
	// part (center) of the gradient at left edge of the label text
	leftEdge -= gradientWidth;
	
	//position the bright segment of the gradient, keeping all segments within the range 0..1
	gradientLocations[0] = leftEdge < 0.0 ? 0.0 : (leftEdge > 1.0 ? 1.0 : leftEdge);
	gradientLocations[1] = MIN(leftEdge + gradientWidth, 1.0);
	gradientLocations[2] = MIN(gradientLocations[1] + gradientWidth, 1.0);
	
	// Re-render the label text
	[self.layer setNeedsDisplay];
}


@end

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
    
    WARVLabel *label = [[WARVLabel alloc] initWithFrame:self.bounds];
    label.text = @"滑动删除";
    label.font = [UIFont systemFontOfSize:16.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.animated = YES;
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

@interface WARVChatPanelView ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) WARVSlideView *slideView;
@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIButton *otherBtn;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) CGPoint trackTouchPoint;
@property (nonatomic, assign) CGPoint firstTouchPoint;
@property (nonatomic, strong) UIImageView *garbageImageView;
@property (nonatomic, strong) NSTimer *garbageTimer;
@property (nonatomic, assign) BOOL canCancelAnimation;

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
    self.textField.placeholder = @"说点什么把...";
    [self addSubview:textField];
    self.textField = textField;
    
    UIButton *voice = [UIButton buttonWithType:UIButtonTypeSystem];
    [voice setImage:[UIImage imageNamed:@"ButtonMic7"] forState:UIControlStateNormal];
    [voice setTintColor:[UIColor blueColor]];
    [voice setFrame:CGRectMake(284, 0, 26, 45)];
    [voice addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [voice addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [voice addTarget:self action:@selector(finshedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside];
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
        [self.slideView updateLocation:(curPoint.x - self.trackTouchPoint.x)];
    }
    self.trackTouchPoint = curPoint;
    if ((self.firstTouchPoint.x - self.trackTouchPoint.x ) > 100) {
        [self cancelRecord];
    }
}

- (void)finshedRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldFinishedRecord:)]) {
        [self.delegate chatPanelViewShouldFinishedRecord:self];
    }

    [self endRecord];
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
                    self.recordBtn.alpha = 0.f;
                }completion:^(BOOL finished) {
                    [self dismissGarbage];
                }];
            }];

        }
        }];
}

- (void)dismissGarbage
{
    self.garbageImageView.tag = 101;
    [self startGarbageTimer];
}

- (void)showGarbage
{
    if (self.garbageImageView) {
        self.garbageImageView = nil;
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(3, 30, 31, 36)];
    [self addSubview:imageView];
    self.garbageImageView = imageView;
    self.garbageImageView.tag = 1;
    [self startGarbageTimer];
}

- (void)startGarbageTimer
{
    if (self.garbageTimer) {
        [self.garbageTimer invalidate];
        self.garbageTimer = nil;
    }
    self.garbageTimer = [NSTimer timerWithTimeInterval:kFloatGarbageAnimationTime / kIntGarbageAnimationKeyframeCount target:self selector:@selector(updateGarbage:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.garbageTimer forMode:NSDefaultRunLoopMode];
    [self.garbageTimer fire];
}

- (void)updateGarbage:(NSTimer *)timer
{
    if (self.garbageImageView.tag <= kIntGarbageAnimationKeyframeCount) {
        self.garbageImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"UIButtonBarGarbageOpen%ld",(long)self.garbageImageView.tag]];
        CGRect frame = self.garbageImageView.frame;
        frame.origin.y = 30 - self.garbageImageView.tag * (30 / kIntGarbageAnimationKeyframeCount);
        [self.garbageImageView setFrame:frame];
        self.garbageImageView.tag++;
        if (self.garbageImageView.tag == kIntGarbageAnimationKeyframeCount) {
            [self.garbageTimer invalidate];
            self.garbageTimer = nil;
        }
    }else{
        NSInteger tag = self.garbageImageView.tag - 100;
        if (tag <= kIntGarbageAnimationKeyframeCount) {
            self.garbageImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"UIButtonBarGarbageClose%ld",(long)tag]];
            CGRect frame = self.garbageImageView.frame;
            frame.origin.y =  tag * (30 / kIntGarbageAnimationKeyframeCount);
            [self.garbageImageView setFrame:frame];
            self.garbageImageView.tag++;
            if (tag == kIntGarbageAnimationKeyframeCount) {
                [self.garbageTimer invalidate];
                self.garbageTimer = nil;
                [self endRecord];
            }
        }
    }
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
    self.otherBtn.hidden = NO;
    
    [self.recordBtn.layer removeAllAnimations];
    [self.recordBtn removeFromSuperview];
    self.recordBtn = nil;
    [self.slideView removeFromSuperview];
    self.slideView = nil;
    [self.timeLabel removeFromSuperview];
    self.timeLabel = nil;
    [self.garbageImageView removeFromSuperview];
    self.garbageImageView = nil;
    
    [self.voiceBtn addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [self.voiceBtn addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [self.voiceBtn addTarget:self action:@selector(finshedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside];
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

- (WARVSlideView *)slideView
{
    if (!_slideView) {
        _slideView = [[WARVSlideView alloc] initWithFrame:CGRectMake(90, self.textField.frame.origin.y, 185, self.textField.frame.size.height)];
        [self addSubview:_slideView];
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
