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

@property (nonatomic, readonly) NSUInteger currentUsage;

@property (nonatomic, assign) NSUInteger cacheBytesLimit;

@property (nonatomic, assign) NSUInteger autoClearExpectation;

@property (nonatomic, copy) void(^ EvictAction)(AELDMemoryCache *cache, id object);

+ (instancetype)memoryCacheWithName:(NSString *)name evictAction:(nullable void(^)(AELDMemoryCache *cache, id object))action;

/**
 *  清除不使用的缓存对象
 */
- (void)clearUnused;

@end

NS_ASSUME_NONNULL_END
