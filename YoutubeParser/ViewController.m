//
//  ViewController.m
//  YoutubeParser
//
//  Created by Simon Andersson on 9/22/12.
//  Copyright (c) 2012 Hiddencode.me. All rights reserved.
//

#import "ViewController.h"
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

@implementation ViewController

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
            CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGImageAlphaNone);
            CFRelease(colorSpace);
            noiseImageRef = CGBitmapContextCreateImage(bitmapContext);
            CFRelease(bitmapContext);
            free(rgba);
        });
        
        CGContextSaveGState(context);
        CGContextSetAlpha(context, 0.5);
        CGContextSetBlendMode(context, kCGBlendModeScreen);
        
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
            CGFloat scaleFactor = [[UIScreen mainScreen] scale];
            CGContextScaleCTM(context, 1/scaleFactor, 1/scaleFactor);
        }
        
        CGRect imageRect = (CGRect){CGPointZero, CGImageGetWidth(noiseImageRef), CGImageGetHeight(noiseImageRef)};
        CGContextDrawTiledImage(context, imageRect, noiseImageRef);
        CGContextRestoreGState(context);
    }];
    
    [self.view insertSubview:grainView atIndex:0];
}

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
@end
