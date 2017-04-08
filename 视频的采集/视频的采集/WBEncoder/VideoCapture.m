//
//  VideoCapture.m
//  视频的采集
//
//  Created by mac on 17/4/8.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "VideoCapture.h"
// 导入AVFoundation框架
#import <AVFoundation/AVFoundation.h>

@interface VideoCapture()<AVCaptureVideoDataOutputSampleBufferDelegate>

/** 视频session*/
@property (nonatomic , weak) AVCaptureSession *session;

/** 预览图层*/
@property (nonatomic , weak) AVCaptureVideoPreviewLayer *preLayer;

@end

@implementation VideoCapture

- (void)startCapturing:(UIView *)preView{

    // 1. 创建session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];

    [session startRunning];
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    self.session = session;
  
    
    // 2. 设置视频的输入，添加到session中
       // 2.1 先获取摄像头
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
       // 2.2 创建AVCaptureDeviceInput
    NSError *error;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (!error) {
    
    [session addInput:input];
        
    }else{
    
        NSLog(@"不支持模拟器");
        
    }

    // 3. 设置视频的输出
    AVCaptureVideoDataOutput *outPut = [[AVCaptureVideoDataOutput alloc] init];
      // 3.1 通过delegate来监听输出的数据
    [outPut setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
      // 3.2 允许丢帧
    [outPut setAlwaysDiscardsLateVideoFrames:YES];
    [session addOutput:outPut];
    // 3.3 视频输出的方向,必须在[session addOutput:outPut]之后
    AVCaptureConnection *connection = [outPut connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
        
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
    }else{
        
        NSLog(@"不支持设置方向");
    }
    
    // 4. 添加预览的图层
    AVCaptureVideoPreviewLayer *preLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    preLayer.frame = preView.bounds;
    [preView.layer insertSublayer:preLayer atIndex:0];
    self.preLayer = preLayer;
    

}
- (void)stopCapturing{
 
    [self.preLayer removeFromSuperlayer];
    [self.session stopRunning];
    
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
/** 采集到视频画面会调用*/
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    NSLog(@"采集到视频画面");
    
}
/** 出现丢帧会调用*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

}
@end
