//
//  DYYImageStickerView.h
//  DYYStickerDemo
//
//  Created by 杜远洋 on 2017/11/14.
//  Copyright © 2017年 杜远洋. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DYYSTICKER_BUTTON_NULL,
    DYYSTICKER_BUTTON_DELETE,
    DYYSTICKER_BUTTON_RESIZE,
    DYYSTICKER_BUTTON_CUSTOM,
    DYYSTICKER_BUTTON_MAX,
} DYYSTICKER_BUTTON;

@protocol DYYImageStickerViewDelegate;

@interface DYYImageStickerView : UIView<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL preventPositionOutsideSuperview;
@property (nonatomic, assign) BOOL preventResizing;
@property (nonatomic, assign) BOOL preventDeleting;
@property (nonatomic, assign) BOOL preventCustomButton;
@property (nonatomic, assign) BOOL translucencySticker;
@property (nonatomic, assign) BOOL preventTapping;
@property (nonatomic, assign) BOOL isTransformEnabled;
@property (nonatomic, assign) CGFloat minWidth;
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, copy) NSString *stickerPath;
@property (nonatomic, weak) id <DYYImageStickerViewDelegate> delegate;

- (void)setButton:(DYYSTICKER_BUTTON)type image:(UIImage *)image;
- (void)setbutton:(DYYSTICKER_BUTTON)type hidden:(BOOL)hidden;
- (void)showBorderAndController;
- (void)hideBorderAndController;
@end

@protocol DYYImageStickerViewDelegate <NSObject>
@optional
- (void)stickerViewDidBeginEditing:(DYYImageStickerView *)sticker;
- (void)stickerViewDidEndEditing:(DYYImageStickerView *)sticker;
- (void)stickerViewDidCancelEditing:(DYYImageStickerView *)sticker;
- (void)stickerViewDidClose:(DYYImageStickerView *)sticker;
- (void)stickerViewDidTapCustomButton:(DYYImageStickerView *)sticker;
- (void)stickerViewDidLongPressed:(DYYImageStickerView *)sticker;
@end




