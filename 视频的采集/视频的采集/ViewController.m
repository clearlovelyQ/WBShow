//
//  ViewController.m
//  视频的采集
//
//  Created by mac on 17/4/8.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "VideoCapture.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic , strong) VideoCapture *videoCapture;

@end

@implementation ViewController

#pragma mark - lazy

-(VideoCapture *)videoCapture{

    if (!_videoCapture) {
        _videoCapture = [[VideoCapture alloc] init];
    }
    
    return _videoCapture;

}

- (void)viewDidLoad {
    [super viewDidLoad];
   


}
// 开始采集
- (IBAction)startCapture:(id)sender {
    
    [self.videoCapture startCapturing:self.view];
  
    
}
// 结束采集
- (IBAction)stopCapture:(id)sender {
    
    [self.videoCapture stopCapturing];
}

@end
