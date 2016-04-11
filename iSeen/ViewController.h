//
//  ViewController.h
//  iSeen
//
//  Created by Ling Evan on 25/12/15.
//  Copyright © 2015 Evan. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController <NSStreamDelegate>
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

@property UIImage* frame; //video frame capture
@property CGSize reducedFrameSize; //reduced frame size to upload to server

@end

