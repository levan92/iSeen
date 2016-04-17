//
//  ViewController.m
//  iSeen
//
//  Created by Ling Evan on 25/12/15.
//  Copyright © 2015 Evan. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "VideoSource.h"

@interface ViewController () <VideoSourceDelegate>

@property (nonatomic, strong) VideoSource * videoSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    self.reducedFrameSize = {533.33/2.0, 300.0/2.0}; //new reduced resolution of frame to upload (in pts)
    
    [super viewDidLoad];
    
    // Configure Video Source
    self.videoSource = [[VideoSource alloc] init];
    self.videoSource.delegate = self;
    
    [self initSocketConn];
    
    [self.videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
    
    float refreshRate = 0.5;
    
    [NSTimer scheduledTimerWithTimeInterval:refreshRate
                                     target:self
                                   selector:@selector(uploadPhoto:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) frameReady:(VideoFrame)frame {
    __weak typeof(self) _weakSelf = self;
    dispatch_sync( dispatch_get_main_queue(), ^{
        // Construct CGContextRef from VideoFrame
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(frame.data,
                                                        frame.width,
                                                        frame.height,
                                                        8,
                                                        frame.stride,
                                                        colorSpace,
                                                        kCGBitmapByteOrder32Little |
                                                        kCGImageAlphaPremultipliedFirst);
        
        // Construct CGImageRef from CGContextRef
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        // Construct UIImage from CGImageRef
        self.frame = [UIImage imageWithCGImage:newImage];
        CGImageRelease(newImage);
        [[_weakSelf backgroundImageView] setImage:self.frame];
        self.frame = [self imageWithImage:self.frame scaledToSize: self.reducedFrameSize];
    });
}

-(void) uploadPhoto: (NSTimer*) timer {
    //NSLog(@"Uploading current video frame...");
    NSData *imageData = UIImageJPEGRepresentation(self.frame, 0.005); //compressing image
    //TCP
    [imageData bytes];
    [outputStream write:(const uint8_t *)[imageData bytes] maxLength:[imageData length]];
}

-(void) addLabels : (NSString*) labelsString{
    //NSLog(@"Labelling...");
    //retrieve info from path
    NSArray* labels = [labelsString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",\n"]];
    NSUInteger numOfLabels  = ([labels count]-1)/3;
    
    for (UIView *subview in [self.view subviews]) {
        if (subview != self.backgroundImageView) {
            [subview removeFromSuperview];
        }
    }
    
    //computing scaling factor to take into account difference in resolution between video frame and device screen
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float frameImageWidth = self.reducedFrameSize.width;
    float scalingFactorForWidth = screenWidth / frameImageWidth;
    
    float screenHeight = [[UIScreen mainScreen] bounds].size.height;
    float frameImageHeight = self.reducedFrameSize.height;
    float scalingFactorForHeight = screenHeight / frameImageHeight;
    
    //loops through num of labels and adds an overlay for each label.
    for (int i = 0; i<numOfLabels; i++) {
        int objX = [(NSNumber*)[labels objectAtIndex:3*i] intValue]*scalingFactorForWidth/2;
        int objY = [(NSNumber*)[labels objectAtIndex:3*i+1] intValue]*scalingFactorForHeight/2;
        NSString *objName = [labels objectAtIndex:3*i +2];
        float labelWidth = 100;
        float labelHeight = 50;
        UILabel *someLabel = [[UILabel alloc]initWithFrame:CGRectMake(objX - labelWidth/2, objY - labelHeight/2, labelWidth, labelHeight)];
        someLabel.numberOfLines = 0;
        someLabel.backgroundColor = [UIColor clearColor];
        someLabel.textAlignment = NSTextAlignmentCenter;
        someLabel.text = objName;
        //diff colour for diff objects
        if  ([objName  isEqualToString: @"Sky\r"]){
            someLabel.textColor = [UIColor colorWithRed:0.0f green:128.0f/255.0f blue:1.0f alpha:1.0f];
        }
        else if ([objName isEqualToString:@"HighVeg\r"] || [objName isEqualToString:@"LowVeg\r"])
            someLabel.textColor= [UIColor colorWithRed:51.0/255.0f green:1.0f blue:51.0/255.0f alpha:1.0f];
        else if ([objName isEqualToString:@"Building\r"])
            someLabel.textColor= [UIColor brownColor];
        else if ([objName isEqualToString:@"Road\r"])
            someLabel.textColor= [UIColor blackColor];
        else if ([objName isEqualToString:@"Pavement\r"])
            someLabel.textColor= [UIColor magentaColor];
        else if ([objName isEqualToString:@"Kerb\r"])
            someLabel.textColor= [UIColor colorWithRed:1.0f green:94.0/255.0f blue:197.0/255.0f alpha:1.0f];
        else if ([objName isEqualToString:@"YellowLine\r"])
            someLabel.textColor= [UIColor orangeColor];
        else if ([objName isEqualToString:@"WhiteLine\r"])
            someLabel.textColor= [UIColor colorWithRed:110.0/255.0f green:80.0/255.0f blue:80.0/255.0f alpha:1.0f];
        else if ([objName isEqualToString:@"TreeTrunk\r"])
            someLabel.textColor= [UIColor colorWithRed:139.0/255.0f green:69.0f/255.0f blue:19.0/255.0f alpha:1.0f];
        else
            someLabel.textColor = [UIColor redColor];
        [self.view addSubview:someLabel];
    }
    //NSLog(@"%lu labels labelled.",(unsigned long)numOfLabels);
}

//resizes UIImage to prepare for frame upload
-(UIImage *) imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)initSocketConn {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"52.76.218.133", 9000,
                                       &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
    
    NSLog(@"Socket connection opened");
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                uint8_t buffer[2048];
                NSInteger len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (output != nil) {
                            [self addLabels:output];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        default:
            break;
    }
}


@end
