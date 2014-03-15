//
//  ViewController.m
//  YoutubeParser
//
//  Created by Simon Andersson on 9/22/12.
//  Copyright (c) 2012 Hiddencode.me. All rights reserved.
//

#import "ViewController.h"
#import "HCYoutubeParser.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

typedef void(^DrawRectBlock)(CGRect rect);

@interface HCView : UIView {
@private
    DrawRectBlock block;
}

- (void)setDrawRectBlock:(DrawRectBlock)b;

@end

@interface UIView (DrawRect)
+ (UIView *)viewWithFrame:(CGRect)frame drawRect:(DrawRectBlock)block;
@end

@implementation HCView

- (void)setDrawRectBlock:(DrawRectBlock)b {
    block = [b copy];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (block)
        block(rect);
}

@end

@implementation UIView (DrawRect)

+ (UIView *)viewWithFrame:(CGRect)frame drawRect:(DrawRectBlock)block {
    HCView *view = [[HCView alloc] initWithFrame:frame];
    [view setDrawRectBlock:block];
    return view;
}

@end

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController {
    NSURL *_urlToLoad;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *grainView = [UIView viewWithFrame:self.view.bounds drawRect:^(CGRect rect) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [[UIColor colorWithHue:0.000 saturation:0.000 brightness:0.773 alpha:1] setFill];
        CGContextFillRect(context, rect);
        
        static CGImageRef noiseImageRef = nil;
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            NSUInteger width = 128, height = width;
            NSUInteger size = width*height;
            char *rgba = (char *)malloc(size); srand(115);
            for(NSUInteger i=0; i < size; ++i){rgba[i] = rand()%256;}
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
            CGContextRef bitmapContext =
            CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGBitmapByteOrderDefault);
            CFRelease(colorSpace);
            noiseImageRef = CGBitmapContextCreateImage(bitmapContext);
            CFRelease(bitmapContext);
            free(rgba);
        });
        
        CGContextSaveGState(context);
        CGContextSetAlpha(context, 0.5);
        CGContextSetBlendMode(context, kCGBlendModeScreen);
        
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            CGFloat scaleFactor = [[UIScreen mainScreen] scale];
            CGContextScaleCTM(context, 1/scaleFactor, 1/scaleFactor);
        }
        
        CGRect imageRect = (CGRect){CGPointZero, CGImageGetWidth(noiseImageRef), CGImageGetHeight(noiseImageRef)};
        CGContextDrawTiledImage(context, imageRect, noiseImageRef);
        CGContextRestoreGState(context);
    }];
    
    [self.view insertSubview:grainView atIndex:0];
    
    [_submitButton addTarget:self action:@selector(submitYouTubeURL:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    _playButton.layer.shadowColor = [UIColor blackColor].CGColor;
    _playButton.layer.shadowOffset = CGSizeMake(0, 0);
    _playButton.layer.shadowOpacity = 0.7;
    _playButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:_playButton.bounds].CGPath;
    _playButton.layer.shadowRadius = 2;
}

#pragma mark - Actions

- (void)playVideo:(id)sender {
    if (_urlToLoad) {
        
        MPMoviePlayerViewController *mp = [[MPMoviePlayerViewController alloc] initWithContentURL:_urlToLoad];
        [self presentViewController:mp animated:YES completion:NULL];
        
    }
}

- (void)submitYouTubeURL:(id)sender {
    
    if ([_urlTextField canResignFirstResponder]) {
        [_urlTextField resignFirstResponder];
    }
    _urlToLoad = nil;
    [_playButton setImage:nil forState:UIControlStateNormal];
    
    NSURL *url = [NSURL URLWithString:_urlTextField.text];
    _activityIndicator.hidden = NO;
    [HCYoutubeParser thumbnailForYoutubeURL:url thumbnailSize:YouTubeThumbnailDefaultHighQuality completeBlock:^(UIImage *image, NSError *error) {
        
        if (!error) {
            [_playButton setBackgroundImage:image forState:UIControlStateNormal];
            
            [HCYoutubeParser h264videosWithYoutubeURL:url completeBlock:^(NSDictionary *videoDictionary, NSError *error) {
                
                _playButton.hidden = NO;
                _activityIndicator.hidden = YES;
                
                NSDictionary *qualities = videoDictionary;
                
                NSString *URLString = nil;
                if ([qualities objectForKey:@"small"] != nil) {
                    URLString = [qualities objectForKey:@"small"];
                }
                else if ([qualities objectForKey:@"live"] != nil) {
                    URLString = [qualities objectForKey:@"live"];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't find youtube video" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
                    return;
                }
                _urlToLoad = [NSURL URLWithString:URLString];
                
                [_playButton setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
            }];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSubmitButton:nil];
    [self setUrlTextField:nil];
    [self setActivityIndicator:nil];
    [self setPlayButton:nil];
    
    [super viewDidUnload];
}

#pragma mark - UITextFieldDelegate Implementation

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField canResignFirstResponder]) {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
