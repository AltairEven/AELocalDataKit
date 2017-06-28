//
//  AELDDiskCache.h
//  AELocalDataKit
//
//  Created by Altair on 27/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import <AELocalDataKit/AELocalDataKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AELDDiskCache<__covariant ObjectType> : AELDCache

@property (nonatomic, readonly) NSUInteger currentDiskUsage;    //当前磁盘占用

/**
 便捷初始化方法
 
 @param name 缓存名称
 @return 缓存实例
 */
+ (instancetype)memoryCacheWithName:(NSString *)name;

/**
 加入磁盘缓存

 @param obj 缓存对象，需要遵循NSCoding协议
 @return 缓存成功或者失败
 */
- (BOOL)addObject:(ObjectType<NSCoding>)obj;

@end

NS_ASSUME_NONNULL_END
