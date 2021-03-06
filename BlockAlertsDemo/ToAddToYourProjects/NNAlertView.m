//
//  NNAlertView.m
//
//

#import "NNAlertView.h"
#import "BlockBackground.h"
#import "BlockUI.h"

@interface NNAlertView (Private)
- (void)hide;
- (void)needsLayout;
- (void)needsLayoutWithAnimation:(BOOL)animate;
@end

@implementation NNAlertView

@synthesize view = _view;
@synthesize backgroundImage = _backgroundImage;
@synthesize vignetteBackground = _vignetteBackground;
@synthesize delegate;

static UIImage *background = nil;
static UIFont *titleFont = nil;
static UIFont *messageFont = nil;
static UIFont *buttonFont = nil;

+ (void)initialize {
    if (self == [NNAlertView class]) {
        background = [UIImage imageNamed:kAlertViewBackground];
        background = [[background stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight] retain];
        titleFont = [kAlertViewTitleFont retain];
        messageFont = [kAlertViewMessageFont retain];
        buttonFont = [kAlertViewButtonFont retain];
    }
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)_delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION {
	if ((self = [super init])) {
		UIWindow *parentView = [BlockBackground sharedInstance];
		CGRect frame = parentView.bounds;
		frame.origin.x = floorf((frame.size.width - background.size.width) * 0.5);
		frame.size.width = background.size.width;
		
		_view = [[UIView alloc] initWithFrame:frame];
		allButtons = [[NSMutableArray alloc] init];
		_height = kAlertViewBorder + 6;
		
		if (title) {
			CGSize size = [title sizeWithFont:titleFont
							constrainedToSize:CGSizeMake(frame.size.width-kAlertViewBorder*2, 1000)
								lineBreakMode:UILineBreakModeWordWrap];
			
			UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewBorder, _height, frame.size.width-kAlertViewBorder*2, size.height)];
			labelView.font = titleFont;
			labelView.numberOfLines = 0;
			labelView.lineBreakMode = UILineBreakModeWordWrap;
			labelView.textColor = kAlertViewTitleTextColor;
			labelView.backgroundColor = [UIColor clearColor];
			labelView.textAlignment = UITextAlignmentCenter;
			labelView.shadowColor = kAlertViewTitleShadowColor;
			labelView.shadowOffset = kAlertViewTitleShadowOffset;
			labelView.text = title;
			[_view addSubview:labelView];
			[labelView release];
			
			_height += size.height + kAlertViewBorder;
		}
		
		if (message) {
			CGSize size = [message sizeWithFont:messageFont
							  constrainedToSize:CGSizeMake(frame.size.width-kAlertViewBorder*2, 1000)
								  lineBreakMode:UILineBreakModeWordWrap];
			
			UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(kAlertViewBorder, _height, frame.size.width-kAlertViewBorder*2, size.height)];
			labelView.font = messageFont;
			labelView.numberOfLines = 0;
			labelView.lineBreakMode = UILineBreakModeWordWrap;
			labelView.textColor = kAlertViewMessageTextColor;
			labelView.backgroundColor = [UIColor clearColor];
			labelView.textAlignment = UITextAlignmentCenter;
			labelView.shadowColor = kAlertViewMessageShadowColor;
			labelView.shadowOffset = kAlertViewMessageShadowOffset;
			labelView.text = message;
			[_view addSubview:labelView];
			[labelView release];
			
			_height += size.height + kAlertViewBorder;
		}
		
		NSMutableArray *buttonTitles = [NSMutableArray array];
		va_list args;
		va_start(args, otherButtonTitles);
		for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString*))
			[buttonTitles addObject:arg];
		va_end(args);
		
		if (cancelButtonTitle)
			[allButtons addObject:[NSArray arrayWithObjects:cancelButtonTitle, @"black", nil]];
		if (destructiveButtonTitle)
			[allButtons addObject:[NSArray arrayWithObjects:destructiveButtonTitle, @"red", nil]];
		for (NSString *title in buttonTitles)
			[allButtons addObject:[NSArray arrayWithObjects:title, @"gray", nil]];
		
		_vignetteBackground = NO;
		self.delegate = _delegate;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(needsLayout)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_backgroundImage release];
    [_view release];
	[allButtons release];
    [super dealloc];
}

#pragma mark Class Methods
- (void)show {
    BOOL isSecondButton = NO;
    NSUInteger index = 0;
    for (NSUInteger i = 0; i < [allButtons count]; i++) {
        NSArray *buttonInfo = [allButtons objectAtIndex:i];
        NSString *title = [buttonInfo objectAtIndex:0];
        NSString *color = [buttonInfo objectAtIndex:1];

        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button.png", color]];
        image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
        
        CGFloat maxHalfWidth = floorf((_view.bounds.size.width-kAlertViewBorder*3)*0.5);
        CGFloat width = _view.bounds.size.width-kAlertViewBorder*2;
        CGFloat xOffset = kAlertViewBorder;
        if (isSecondButton) {
            width = maxHalfWidth;
            xOffset = width + kAlertViewBorder * 2;
            isSecondButton = NO;
        }
        else if (i + 1 < [allButtons count]) {
            // In this case there's another button.
            // Let's check if they fit on the same line.
            CGSize size = [title sizeWithFont:buttonFont 
                                  minFontSize:10 
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width-kAlertViewBorder*2 
                                lineBreakMode:UILineBreakModeClip];
            
            if (size.width < maxHalfWidth - kAlertViewBorder)
            {
                // It might fit. Check the next Button
                NSArray *block2 = [allButtons objectAtIndex:i+1];
                NSString *title2 = [block2 objectAtIndex:1];
                size = [title2 sizeWithFont:buttonFont 
                                minFontSize:10 
                             actualFontSize:nil
                                   forWidth:_view.bounds.size.width-kAlertViewBorder*2 
                              lineBreakMode:UILineBreakModeClip];
                
                if (size.width < maxHalfWidth - kAlertViewBorder)
                {
                    // They'll fit!
                    isSecondButton = YES;  // For the next iteration
                    width = maxHalfWidth;
                }
            }
        }
        else if ([allButtons count] == 1)
        {
            // In this case this is the ony button. We'll size according to the text
            CGSize size = [title sizeWithFont:buttonFont 
                                  minFontSize:10 
                               actualFontSize:nil
                                     forWidth:_view.bounds.size.width-kAlertViewBorder*2 
                                lineBreakMode:UILineBreakModeClip];

            size.width = MAX(size.width, 80);
            if (size.width + 2 * kAlertViewBorder < width)
            {
                width = size.width + 2 * kAlertViewBorder;
                xOffset = floorf((_view.bounds.size.width - width) * 0.5);
            }
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(xOffset, _height, width, kAlertButtonHeight);
        button.titleLabel.font = buttonFont;
        button.titleLabel.minimumFontSize = 10;
        button.titleLabel.textAlignment = UITextAlignmentCenter;
        button.titleLabel.shadowOffset = kAlertViewButtonShadowOffset;
        button.backgroundColor = [UIColor clearColor];
        button.tag = i;
        
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button setTitleColor:kAlertViewButtonTextColor forState:UIControlStateNormal];
        [button setTitleShadowColor:kAlertViewButtonShadowColor forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal];
        button.accessibilityLabel = title;
        
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [_view addSubview:button];
        
        if (!isSecondButton)
            _height += kAlertButtonHeight + kAlertViewBorder;
        
        index++;
    }
    
    _height += 10;  // Margin for the shadow
    
    if (_height < background.size.height)
    {
        CGFloat offset = background.size.height - _height;
        _height = background.size.height;
        CGRect frame;
        for (NSUInteger i = 0; i < [allButtons count]; i++)
        {
            UIButton *btn = (UIButton *)[_view viewWithTag:i+1];
            frame = btn.frame;
            frame.origin.y += offset;
            btn.frame = frame;
        }
    }

    CGRect frame = _view.frame;
    frame.origin.y = - _height;
    frame.size.height = _height;
    _view.frame = frame;
    
    UIImageView *modalBackground = [[UIImageView alloc] initWithFrame:_view.bounds];
    modalBackground.image = background;
    modalBackground.contentMode = UIViewContentModeScaleToFill;
    [_view insertSubview:modalBackground atIndex:0];
    [modalBackground release];
    
    if (_backgroundImage)
    {
        [BlockBackground sharedInstance].backgroundImage = _backgroundImage;
        [_backgroundImage release];
        _backgroundImage = nil;
    }
    [BlockBackground sharedInstance].vignetteBackground = _vignetteBackground;
    [[BlockBackground sharedInstance] addToMainWindow:_view];

    __block CGPoint center = _view.center;
    center.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5);
	_view.center = center;
	[BlockBackground sharedInstance].alpha = 1.0f;
    
	// Show with bounce animation
	[self needsLayoutWithAnimation:NO];
	CGAffineTransform transform = _view.transform;
	_view.transform = CGAffineTransformScale(transform, 0.5, 0.5);
	[UIView animateWithDuration:0.1
					 animations:^{
						 _view.transform = CGAffineTransformScale(transform, 1.1, 1.1);
					 }
					 completion:^(BOOL finished) {
						 [UIView animateWithDuration:0.1
										  animations:
						  ^{
							  _view.transform = CGAffineTransformScale(transform, 0.9, 0.9);
						  }
										  completion:^(BOOL finished)
						 {
							 [UIView animateWithDuration:0.1
											  animations:
							  ^{
								  _view.transform = CGAffineTransformScale(transform, 1.0, 1.0);
							  }
											  completion:^(BOOL finished) {}];
						 }];
					 }];
    
    [self retain];
}

- (void)hide {
	[UIView animateWithDuration:0.1
						  delay:0.0f
						options:0
					 animations:^{
						 [[BlockBackground sharedInstance] reduceAlphaIfEmpty];
					 }
					 completion:^(BOOL finished) {
						 [[BlockBackground sharedInstance] removeView:_view];
						 [_view release]; _view = nil;
						 [self autorelease];
					 }];
}

- (void)moveUpwards {
    __block CGPoint center = _view.center;
    center.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5) - 100;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3f];
	_view.center = center;
	[UIView commitAnimations];
}

- (void)moveToDefaultPosition {
    __block CGPoint center = _view.center;
    center.y = floorf([BlockBackground sharedInstance].bounds.size.height * 0.5) - 100;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3f];
	_view.center = center;
	[UIView commitAnimations];
}

- (void)buttonClicked:(id)sender {
	[delegate nnAlertView:self didDismissWithButtonIndex:[sender tag]];
	[self hide];
}

- (void)needsLayout {
	[self needsLayoutWithAnimation:YES];
}

- (void)needsLayoutWithAnimation:(BOOL)animate {
	float angle = 0.0f;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (orientation == UIInterfaceOrientationLandscapeLeft)
		angle = 270.0f;
	else if (orientation == UIInterfaceOrientationLandscapeRight)
		angle = 90.0f;
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
		angle = 180.0f;
	else
		angle = 0.0f;
	
	if (animate) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3f];
	}
	_view.transform = CGAffineTransformMakeRotation((angle * M_PI) / 180.0);
	if (animate)
		[UIView commitAnimations];
}

@end
