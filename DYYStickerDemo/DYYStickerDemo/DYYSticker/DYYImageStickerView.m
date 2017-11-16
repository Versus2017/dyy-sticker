//
//  DYYImageStickerView.m
//  DYYStickerDemo
//
//  Created by 杜远洋 on 2017/11/14.
//  Copyright © 2017年 杜远洋. All rights reserved.
//

#import "DYYImageStickerView.h"

#define kSPUserResizableViewGlobalInset 12
#define kSPUserResizableViewDefaultMinWidth 48.0
#define kSPUserResizableViewInteractiveBorderSize 10.0
#define kZDStickerViewControlSize 26
#define kZDPinchGestureCenterChangeMinValue 3
#define kZDPinchGestureCenterChangeMaxValue 100

@interface DYYImageStickerView ()
{
    CGFloat currentWidth;
    CGFloat currentHeight;
    CGFloat lastRotation;
    CGFloat panCenterX;
    CGFloat panCenterY;
    BOOL singleTapMoving;
    BOOL isResizing;
    CGFloat scaleNumber;
}
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIImageView *resizingControl;
@property (nonatomic, strong) UIImageView *deleteControl;
@property (nonatomic, strong) UIImageView *customControl;

@property (nonatomic, assign) BOOL preventLayoutWhileResizing;
@property (nonatomic, assign) CGFloat deltaAngle;
@property (nonatomic, assign) CGPoint prevPoint;
@property (nonatomic, assign) CGAffineTransform startTransform;
@property (nonatomic, assign) CGPoint touchStart;

@end

@implementation DYYImageStickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupDefaultAttributes];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupDefaultAttributes];
    }
    return self;
}

- (void)setupDefaultAttributes {
    self.borderView = [[UIView alloc] initWithFrame:CGRectInset(
                                                                self.bounds,
                                                                kSPUserResizableViewGlobalInset,
                                                                kSPUserResizableViewGlobalInset)];
    [self.borderView setHidden: YES];
    [self addSubview:self.borderView];
    
    self.preventPositionOutsideSuperview = YES;
    self.preventLayoutWhileResizing = YES;
    self.preventResizing = NO;
    self.preventDeleting = NO;
    self.preventCustomButton = YES;
    self.translucencySticker = YES;
    self.preventTapping = YES;
    self.isTransformEnabled = NO;
    self.exclusiveTouch = YES;
    self.userInteractionEnabled = YES;
    
#ifdef DYYSTICKERVIEW_LONGPRESS
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPress:)];
    [self addGestureRecognizer: longPress];
#endif
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    pinch.delegate = self;
    [self addGestureRecognizer:pinch];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    pan.minimumNumberOfTouches = 2;
    pan.delegate = self;
    [self addGestureRecognizer:pan];
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationAction:)];
    rotation.delegate = self;
    [self addGestureRecognizer:rotation];
    
    self.deleteControl = [[UIImageView alloc] initWithFrame:CGRectMake(
                                                                       0,
                                                                       0,
                                                                       kZDStickerViewControlSize,
                                                                       kZDStickerViewControlSize)];
    self.deleteControl.backgroundColor = [UIColor clearColor];
    self.deleteControl.image = nil;
    self.deleteControl.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [self.deleteControl addGestureRecognizer:singleTap];
    [self addSubview:self.deleteControl];
    
    self.resizingControl = [[UIImageView alloc] initWithFrame:CGRectMake(
                                                                         self.frame.size.width - kZDStickerViewControlSize,
                                                                         self.frame.size.height - kZDStickerViewControlSize,
                                                                         kZDStickerViewControlSize,
                                                                         kZDStickerViewControlSize)];
    self.resizingControl.backgroundColor = [UIColor clearColor];
    self.resizingControl.userInteractionEnabled = YES;
    self.resizingControl.exclusiveTouch = YES;
    self.resizingControl.image = nil;
    UIPanGestureRecognizer *panResizeGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(resizeTanslate:)];
    [self.resizingControl addGestureRecognizer:panResizeGesture];
    [self addSubview:self.resizingControl];
    
    self.customControl = [[UIImageView alloc] initWithFrame:CGRectMake(
                                                                       0,
                                                                       self.frame.size.width - kZDStickerViewControlSize,
                                                                       kZDStickerViewControlSize,
                                                                       kZDStickerViewControlSize)];
    self.customControl.backgroundColor = [UIColor clearColor];
    self.customControl.userInteractionEnabled = YES;
    self.customControl.image = nil;
    UITapGestureRecognizer *customTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(customTap:)];
    [self.customControl addGestureRecognizer:customTapGesture];
    [self addSubview:self.customControl];
    
    self.deltaAngle = atan2(
                            self.frame.origin.y + self.frame.size.height - self.center.y,
                            self.frame.origin.x + self.frame.size.width - self.center.x);
    
    currentWidth = self.bounds.size.width;
    currentHeight = self.bounds.size.height;
}


#ifdef DYYSTICKERVIEW_LONGPRESS
- (void)longpress: (UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(stickerViewDidLongPressed:)]) {
            [self.delegate stickerViewDidLongPressed:self];
        }
    }
}
#endif

- (void)singleTap: (UIPanGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(stickerViewDidClose:)]) {
        [self.delegate stickerViewDidClose:self];
    }
    // what does this mean?
    if (self.preventDeleting == NO) {
        UIView *close = [recognizer view];
        [close.superview removeFromSuperview];
    }
}

- (void)customTap: (UIPanGestureRecognizer *)recognizer {
    if (self.preventCustomButton == NO) {
        if ([self.delegate respondsToSelector:@selector(stickerViewDidTapCustomButton:)]) {
            [self.delegate stickerViewDidTapCustomButton:self];
        }
    }
}

- (void)resizeTranslate: (UIPanGestureRecognizer *)recognizer
{
    if (singleTapMoving) {
        return;
    }
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        isResizing = YES;
        [self enableTransluceny:YES];
        self.prevPoint = [recognizer locationInView:self];
    } else if ([recognizer state] == UIGestureRecognizerStateChanged) {
        isResizing = YES;
        [self enableTransluceny:YES];
        CGPoint currentPoint = [recognizer locationOfTouch:0 inView:self];
        
        // preventing from the picture being shrinked too far by resizing
        if (self.bounds.size.width <= self.minWidth || self.bounds.size.height <= self.minHeight) {
            if (self.bounds.size.width == self.minWidth && self.bounds.size.height == self.minHeight) {
                return;
            }
            self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.minWidth + 1, self.minHeight + 1);
            self.resizingControl.frame = CGRectMake(
                                                    self.bounds.size.width - kZDStickerViewControlSize,
                                                    self.bounds.size.height - kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize);
            self.deleteControl.frame = CGRectMake(
                                                  0,
                                                  0,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
            self.customControl.frame = CGRectMake(
                                                  0, 
                                                  self.bounds.size.width - kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
            self.prevPoint = [recognizer locationInView:self];
        } else if ((currentPoint.x - _prevPoint.x > 0) && (self.bounds.size.width >= self.maxWidth || self.bounds.size.height >= self.maxHeight)) {
            if (self.bounds.size.width == self.maxWidth && self.bounds.size.height == self.maxHeight) {
                return;
            }
            self.bounds = CGRectMake(
                                     self.bounds.origin.x,
                                     self.bounds.origin.y,
                                     self.maxWidth,
                                     self.maxHeight);
            self.resizingControl.frame = CGRectMake(
                                                    self.bounds.size.width - kZDStickerViewControlSize,
                                                    self.bounds.size.height - kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize);
            self.deleteControl.frame = CGRectMake(
                                                  0,
                                                  0,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
            self.customControl.frame = CGRectMake(
                                                  0,
                                                  self.bounds.size.width - kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
        } else {
            CGPoint point = [recognizer locationInView:self];
            float wChange = 0.0, hChange = 0.0;
            wChange = point.x - self.prevPoint.x;
            float wRatioChange = (wChange/(float)self.bounds.size.width);
            hChange = wRatioChange * self.bounds.size.height;
            if (ABS(wChange) > 50.0f || ABS(hChange) > 50.0f) {
                self.prevPoint = [recognizer locationOfTouch:0 inView:self];
                return;
            }
            
            CGFloat scale = self.bounds.size.width/self.bounds.size.height;
            CGFloat height = (self.bounds.size.width + wChange * 2)/scale;
            self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width + (wChange * 2), height);
            self.resizingControl.frame = CGRectMake(
                                                    self.bounds.size.width - kZDStickerViewControlSize,
                                                    self.bounds.size.height - kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize,
                                                    kZDStickerViewControlSize);
            self.deleteControl.frame = CGRectMake(
                                                  0,
                                                  0,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
            self.customControl.frame = CGRectMake(
                                                  0,
                                                  self.bounds.size.width - kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize,
                                                  kZDStickerViewControlSize);
            self.prevPoint = [recognizer locationOfTouch:0 inView:self];
        }
        // Rotation
        float angle = atan2(
                            [recognizer locationInView:self.superview].y - self.center.y,
                            [recognizer locationInView:self.superview].x - self.center.x);
        float angleDiff = self.deltaAngle - angle;
        if (self.preventResizing == NO) {
            self.transform = CGAffineTransformMakeRotation(-angleDiff);
        }
        
        self.borderView.frame = CGRectInset(
                                            self.bounds,
                                            kSPUserResizableViewGlobalInset,
                                            kSPUserResizableViewGlobalInset);
        [self.borderView setNeedsDisplay];
        
        [self setNeedsDisplay];
    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
        isResizing = NO;
        currentWidth = self.bounds.size.width;
        currentHeight = self.bounds.size.height;
        [self enableTransluceny:NO];
        self.prevPoint = [recognizer locationInView:self];
        [self setNeedsDisplay];
    } else {
        isResizing = YES;
    }
}

- (void)enableTransluceny: (BOOL)state
{
    if (self.translucencySticker == YES) {
        self.alpha = state ? 0.65 : 1.0;
    }
}

- (void)setContentView:(UIView *)contentView {
    [self.contentView removeFromSuperview];
    self.contentView.frame = CGRectZero;
    _contentView = contentView;
    _contentView.userInteractionEnabled = NO;
    
    self.contentView.frame = CGRectInset(
                                         self.bounds,
                                         kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2,
                                         kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2);
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.contentView];
    
    for (UIView *subview in [self.contentView subviews]) {
        [subview setFrame:CGRectMake(
                                     0,
                                     0,
                                     self.contentView.frame.size.width,
                                     self.contentView.frame.size.height)];
        subview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    [self bringSubviewToFront:self.borderView];
    [self bringSubviewToFront:self.resizingControl];
    [self bringSubviewToFront:self.deleteControl];
    [self bringSubviewToFront:self.customControl];
}


- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.minWidth = self.bounds.size.width * 0.75;
    self.minHeight = self.bounds.size.height * 0.75;
    self.maxWidth = self.bounds.size.width * 5;
    self.maxHeight = self.bounds.size.height * 5;
    
    if (frame.size.width > frame.size.height) {
        scaleNumber = frame.size.height / frame.size.width;
    } else {
        scaleNumber = frame.size.width / frame.size.height;
    }
    
    self.contentView.frame = CGRectInset(
                                         self.bounds,
                                         kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2,
                                         kSPUserResizableViewGlobalInset + kSPUserResizableViewInteractiveBorderSize/2);
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    for (UIView *subview in [self.contentView subviews]) {
        [subview setFrame:CGRectMake(
                                     0,
                                     0,
                                     self.contentView.frame.size.width,
                                     self.contentView.frame.size.height)];
        subview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    self.borderView.frame = CGRectInset(
                                        self.bounds,
                                        kSPUserResizableViewGlobalInset,
                                        kSPUserResizableViewGlobalInset);
    self.resizingControl.frame = CGRectMake(
                                            self.bounds.size.width - kZDStickerViewControlSize,
                                            self.bounds.size.height,
                                            kZDStickerViewControlSize,
                                            kZDStickerViewControlSize);
    self.deleteControl.frame = CGRectMake(
                                          0,
                                          0,
                                          kZDStickerViewControlSize,
                                          kZDStickerViewControlSize);
    self.customControl.frame = CGRectMake(
                                          0,
                                          self.bounds.size.width - kZDStickerViewControlSize,
                                          kZDStickerViewControlSize,
                                          kZDStickerViewControlSize);
    [self.borderView setNeedsDisplay];
}

- (void)panAction: (UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer translationInView:self.superview];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        panCenterX = self.center.x;
        panCenterY = self.center.y;
    } else {
        self.center = CGPointMake(
                                  panCenterX + location.x,
                                  panCenterY + location.y);
    }
}

- (void)rotationAction: (UIRotationGestureRecognizer *)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        lastRotation = 0;
        return;
    }
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        CGAffineTransform currentTransform = self.transform;
        CGFloat rotation = 0.0 - (lastRotation - recognizer.rotation);
        CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform, rotation);
        self.transform = newTransform;
        lastRotation = recognizer.rotation;
    }
}

- (void)pinchAction:(UIPinchGestureRecognizer *)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        [self enableTransluceny:YES];
        [self setNeedsDisplay];
    } else if ([recognizer.state == UIGestureRecognizerStateChanged]) {
        [self enableTransluceny:YES];
        // preventing from the picture being shrinked too far by resizing
        if (self.bounds.size.width < self.minWidth ||
            self.bounds.size.height <= self.minHeight ||
            (currentWidth * recognizer.scale < self.minWidth) ||
            (currentHeight * recognizer.scale < self.minHeight))
            if (self.bounds.size.width == self.minWidth && sef.bounds.size.height == self.minHeight) {
                return;
            }
        
    }
}















@end
