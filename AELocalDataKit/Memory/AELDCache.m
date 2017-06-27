//
//  AELDCache.m
//  AELocalDataKit
//
//  Created by Altair on 23/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDCache.h"
#import <UIKit/UIKit.h>


@implementation NSObject (AELDCacheObject)

#pragma mark NSObject-Properties

- (void)setAeld_CacheIdentifier:(NSString *)aeld_CacheIdentifier {
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_CacheIdentifier", aeld_CacheIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)aeld_CacheIdentifier {
    return objc_getAssociatedObject(self, @"AELocalDataKit_CacheObject_CacheIdentifier");
}

- (void)setAeld_MimeType:(AELDCacheObjectType)aeld_MimeType {
    NSNumber *type = [NSNumber numberWithInteger:aeld_MimeType];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_MimeType", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AELDCacheObjectType)aeld_MimeType {
    NSNumber *type = objc_getAssociatedObject(self, @"AELocalDataKit_CacheObject_MimeType");
    return (AELDCacheObjectType)[type integerValue];
}

- (void)setAeld_TotalBytes:(NSUInteger)aeld_TotalBytes {
    NSNumber *totalBytes = [NSNumber numberWithInteger:aeld_TotalBytes];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_TotalBytes", totalBytes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)aeld_TotalBytes {
    NSNumber *totalBytes = objc_getAssociatedObject(self, @"AELocalDataKit_CacheObject_TotalBytes");
    return [totalBytes unsignedIntegerValue];
}

- (void)setAeld_HitCount:(NSInteger)aeld_HitCount {
    NSNumber *count = [NSNumber numberWithInteger:aeld_HitCount];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount", count, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)aeld_HitCount {
    NSNumber *count = objc_getAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount");
    return [count integerValue];
}

- (void)setAeld_LastUseDate:(NSDate *)aeld_LastUseDate {
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_LastUseDate", aeld_LastUseDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)aeld_LastUseDate {
    return objc_getAssociatedObject(self, @"AELocalDataKit_CacheObject_LastUseDate");
}

#pragma mark NSObject - Public methods

- (BOOL)aeld_ValidateCacheObject {
    if ([self.aeld_CacheIdentifier length] == 0) {
        return NO;
    }
    //设置缓存对象类型和默认内存占用大小
    NSUInteger defaultTotalBytes = 0;
    if ([self isKindOfClass:[NSString class]]) {
        [self setAeld_MimeType:AELDCacheObjectTypeNSString];
        
        defaultTotalBytes = strlen([(NSString *)self UTF8String]);
    } else if ([self isKindOfClass:[NSData class]]) {
        [self setAeld_MimeType:AELDCacheObjectTypeNSData];
        
        defaultTotalBytes = [(NSData *)self length];
    } else if ([self isKindOfClass:[UIImage class]]) {
        [self setAeld_MimeType:AELDCacheObjectTypeUIImage];
        
        __weak UIImage *weakSelf = (UIImage *)self;
        CGSize imageSize = CGSizeMake(weakSelf.size.width * weakSelf.scale, weakSelf.size.height * weakSelf.scale);
        CGFloat bytesPerPixel = 4.0;
        CGFloat bytesPerSize = imageSize.width * imageSize.height;
        defaultTotalBytes = (UInt64)bytesPerPixel * (UInt64)bytesPerSize;
    } else {
        [self setAeld_MimeType:AELDCacheObjectTypeOther];
    }
    if (self.aeld_TotalBytes > 0) {
        //说明已经人为设置过大小，无需再重新计算
        return YES;
    } else {
        //否则赋值默认计算的占用值
        self.aeld_TotalBytes = defaultTotalBytes;
    }
    if (self.aeld_TotalBytes == 0 || self.aeld_TotalBytes == NSUIntegerMax) {
        //如果内存占用大小，仍然不合法，则返回非法
        return NO;
    }
    return YES;
}

- (NSInteger)aeld_AutoClearWeight {
    NSInteger weight = 10000;
    //采用“使用次数”和“上次使用时间”的双重计算方案，使用次数越少，上次使用时间越远，则权重越大，越会被清理
    weight -= self.aeld_HitCount; //每个hitCount减少一个权重
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.aeld_LastUseDate];
    weight +=  interval;// / 60; //每过1分钟，增加一个权重
    return weight;
}

@end

@implementation AELDCache

- (BOOL)addObject:(id)obj {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

- (id)objectWithCacheIdentifier:(NSString *)identifier {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSDictionary<NSString *, id> *)allCachedObjects {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (BOOL)removeObjectWithCacheIdentifier:(NSString *)identifier {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

- (void)removeAllObjects {
    [self doesNotRecognizeSelector:_cmd];
}

@end
