//
//  AELDMemoryCache.h
//  AELocalDataKit
//
//  Created by Altair on 23/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface AELDMemoryCache : AELDCache

@property (nonatomic, readonly) NSUInteger currentUsage;    //当前内存占用

@property (nonatomic, assign) NSUInteger cacheBytesLimit;   //内存最大限制

@property (nonatomic, assign) NSUInteger autoClearExpectation;  //自动释放后，预期保留的内存占用

@property (nonatomic, copy) void(^ WillEvictAction)(AELDMemoryCache *cache, id object); //即将释放缓存对象时的回调

/**
 便捷初始化方法

 @param name 缓存名称
 @param action 即将释放缓存对象时的回调
 @return 缓存实例
 */
+ (instancetype)memoryCacheWithName:(NSString *)name willEvictAction:(nullable void(^)(AELDMemoryCache *cache, id object))action;

/**
 *  清除不使用的缓存对象
 */
- (void)clearUnused;

@end

NS_ASSUME_NONNULL_END
