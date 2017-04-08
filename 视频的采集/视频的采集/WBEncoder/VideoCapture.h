//
//  VideoCapture.h
//  视频的采集
//
//  Created by mac on 17/4/8.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCapture : NSObject

/** 
  开始采集视频
  @preView ：预览的图层
*/
- (void)startCapturing:(UIView *)preView;

/** 停止采集视频*/
- (void)stopCapturing;


@end
