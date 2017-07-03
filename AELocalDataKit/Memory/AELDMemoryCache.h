//
//  AELDMemoryCache.h
//  AELocalDataKit
//
//  Created by Altair on 23/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDCache.h"

NS_ASSUME_NONNULL_BEGIN

/**
 内存缓存
 */
@interface AELDMemoryCache : AELDCache

@property (nonatomic, readonly) NSUInteger currentUsage;    //当前内存占用

@property (nonatomic, assign) NSUInteger cacheBytesLimit;   //内存最大限制

@property (nonatomic, assign) NSUInteger autoClearExpectation;  //自动释放后，预期保留的内存占用

@property (nonatomic, copy) void(^__nullable WillEvictAction)(AELDMemoryCache *cache, id object); //即将释放缓存对象时的回调

@property (nonatomic, copy) void(^__nullable CacheFullAlert)(AELDMemoryCache *cache); //缓存已满警告，只有在非自动清理时才可能被调用

/**
 便捷初始化方法，并默认设置了“自动清理”

 @param name 缓存名称
 @param action 即将释放缓存对象时的回调
 @return 缓存实例
 */
+ (instancetype)memoryCacheWithName:(NSString *)name willEvictAction:(nullable void(^)(AELDMemoryCache *cache, id object))action;

/**
 *  清除不使用的缓存对象，如果设置了自动清理，则该方法每隔2秒钟会清理一次。
 */
- (void)autoClearCacheSpace;

@end

NS_ASSUME_NONNULL_END
