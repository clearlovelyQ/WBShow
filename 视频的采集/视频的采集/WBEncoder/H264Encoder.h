//
//  H264Encoder.h
//  视频的采集
//
//  Created by mac on 17/4/8.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface H264Encoder : NSObject

/** 准备编码*/
- (void)prepareEncodeWithWidth:(int)width height:(int)height;
/** 进行编码*/
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer;

@end
