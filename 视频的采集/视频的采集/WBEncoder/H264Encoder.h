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

/** 准备编码相关信息*/
- (void)prepareEncodeWithWidth:(int)width height:(int)height;
/** 对采集的数据进行编码*/
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer;
/** 结束编码*/
- (void)endEncoder;

@end
