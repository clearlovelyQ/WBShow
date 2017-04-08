//
//  H264Encoder.m
//  视频的采集
//
//  Created by mac on 17/4/8.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "H264Encoder.h"
// 硬编码的库
#import <VideoToolbox/VideoToolbox.h>

@interface H264Encoder()

@property (nonatomic , assign) VTCompressionSessionRef compressionSession;

@property (nonatomic , assign) int frameIndex;

/** 写入文件的对象*/
@property (nonatomic , strong) NSFileHandle *fileHandle;

@end

@implementation H264Encoder

/** 准备编码*/
- (void)prepareEncodeWithWidth:(int)width height:(int)height{
    
    // 写入文件的路径
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"wb.H264"];
   //在使用NSFileHandle的时候，必须要先创建路径，否则filehandle = nil
   [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    
    // 默认是第0帧
    self.frameIndex = 0;
    
    // 1. 创建VTCompressionSessionRef
    // 参数1：CFAllocatorRef用于CF框架下分配内存
    // 参数2，3：编码视频的宽高
    // 参数4：编码的标准 h264
    // 参数5.6.7：传递NULL
    // 参数8：编码成功之后回调用的函数
    // 参数9：传递self，可以传递到回调函数里面
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressionOutputCallback, (__bridge void * _Nullable)(self), &_compressionSession);
    
    // 2. 设置属性
    // 2.1 设置实时输出
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, (__bridge CFTypeRef _Nonnull)(@YES));
    // 2.2 设置帧率.24-->1s 24帧
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@24));
    // 2.3 设置比特率,参考视频输出的标准
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@1500000)); // bit 位
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)(@[@(15000000/8),@1])); // byte 字节流
    // 2.4 设置GOP大小,最大连个关键帧的间隔.1s一个组
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
   
    // 3. 准备编码
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);

}
/** 进行编码*/
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer{
 
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 开始对一帧进行编码
    // 参数一：compressionSession
    // 参数二：将CMSampleBufferRef转化为CVImageBufferRef
    // 参数三：PTS presentationTimeStamp/ DTS h264编码的时候,GOP里编码前后的顺序不一样
    // 参数四 ：kCMTimeInvalid
    // 参数五六：编码回调的函数 里面的 参数
    CMTime pts = CMTimeMake(self.frameIndex, 24);
    VTCompressionSessionEncodeFrame(self.compressionSession, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
    
//    NSLog(@"开始编码一帧数据");
    
}
#pragma mark - 获取编码后的数据
void didCompressionOutputCallback(
                                  void * CM_NULLABLE outputCallbackRefCon,
                                  void * CM_NULLABLE sourceFrameRefCon,
                                  OSStatus status,
                                  VTEncodeInfoFlags infoFlags,
                                  CM_NULLABLE CMSampleBufferRef sampleBuffer ){
    
    //    NSLog(@"编码出一帧");
    
    H264Encoder *encoder = (__bridge H264Encoder *)(outputCallbackRefCon);
    
    //1. 判断该帧否是关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    //包含这个key，就是普通帧
    BOOL isKeyFrame = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    //2. 如果是关键帧，获取SPS/PPS ，并写入文件
    if(isKeyFrame){
        // 2.1 从CMSampleBufferRef获取CMSampleBufferRef
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        //2.2 获取SPS信息
        // size_t parameterSetIndex sps = 0 ,pps = 1
        const uint8_t *spsOutPointer;
        size_t spsOutSize , spsOutCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsOutPointer, &spsOutSize, &spsOutCount, NULL);
        
        //2.3 获取PPS信息
        const uint8_t *ppsOutPointer;
        size_t ppsOutSize , ppsOutCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsOutPointer, &ppsOutSize, &ppsOutCount, NULL);
        
        //2.4 将SPS和PPS转化为NSData
        NSData *spsData = [[NSData alloc] initWithBytes:spsOutPointer length:spsOutSize];
        NSData *ppsData = [[NSData alloc] initWithBytes:ppsOutPointer length:ppsOutSize];
        
        //2.5 写入文件
        [encoder writeData:spsData];
        [encoder writeData:ppsData];
    
    }
    
    //3. 获取编码之后的数据，写入文件
    //3.1 获取CMBlockBufferRef
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //3.2 从blockBuffer中获取起始位置的内存地址,获取起始地址，和长度，在一个个写入
    size_t totalLength = 0;
    char *dataPointer;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totalLength, &dataPointer);
    
    //3.3 从起始位置开水一个一个写入NSLU单元-- > h264切片，不一定是写入一个可能是多个
    static const int h264HeaderLength = 4; // 根据头部的长度到内存中copy地址
    size_t bufferOffset = 0;
    while (bufferOffset < totalLength - h264HeaderLength) {
        //3.4 内存地址copy,从起始位置拷贝h264HeaderLength长度的地址，计算NSLULength
        int NALULength = 0;
        memcpy(&NALULength
               , dataPointer+bufferOffset, h264HeaderLength);
        
        //h264获取的是大端模式,iOS模式是小端模式
      NALULength =  CFSwapInt32BigToHost(NALULength);
        //3.5 从dataPointer中获取NSData
        NSData *data = [NSData dataWithBytes:dataPointer+bufferOffset+h264HeaderLength length:NALULength];
        [encoder writeData:data];
        
        bufferOffset += NALULength + h264HeaderLength;
    }
}

/** 写入文件*/
- (void)writeData:(NSData *)data{

    //先写入startCoder
    const char bytes[] = "\x00\x00\x00\x01";
    NSData *headerData = [NSData dataWithBytes:bytes length:sizeof(bytes) - 1];
    [self.fileHandle writeData:headerData];
    [self.fileHandle writeData:data];
    
}
/** 结束编码*/
- (void)endEncoder{

    VTCompressionSessionInvalidate(self.compressionSession);
    CFRelease(self.compressionSession);

}
@end
