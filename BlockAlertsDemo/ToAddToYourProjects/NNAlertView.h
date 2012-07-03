//
//  NNAlertView.h
//
//

#import <UIKit/UIKit.h>

@protocol NNAlertViewDelegate;
@interface NNAlertView : NSObject {
@protected
    UIView *_view;
	NSMutableArray *allButtons;
    CGFloat _height;
}
@property(nonatomic,assign) id <NNAlertViewDelegate> delegate;
@property (nonatomic, retain) UIImage *backgroundImage;
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readwrite) BOOL vignetteBackground;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)_delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
- (void)show;
- (void)moveUpwards;
- (void)moveToDefaultPosition;
@end

@protocol NNAlertViewDelegate
@optional
- (void)nnAlertView:(NNAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end
