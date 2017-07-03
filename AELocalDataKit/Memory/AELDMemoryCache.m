//
//  AELDMemoryCache.m
//  AELocalDataKit
//
//  Created by Altair on 23/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDMemoryCache.h"
#import <UIKit/UIKit.h>


@interface NSObject (AELDCacheObject_MemoryCache)

- (void)setAeld_MemoryCache_CacheKey:(NSString *)aeld_CacheKey;

- (void)addAeld_MemoryCache_HitCount;

- (void)clearAeld_MemoryCache_HitCount;

- (void)setAeld_MemoryCache_LastUseDate:( NSDate * _Nullable)aeld_LastUseDate;

@end

@implementation NSObject (AELDCacheObject_MemoryCache)

- (void)setAeld_MemoryCache_CacheKey:(NSString *)aeld_CacheKey {
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_CacheKey", aeld_CacheKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)addAeld_MemoryCache_HitCount {
    NSNumber *count = [NSNumber numberWithInteger:self.aeld_HitCount + 1];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount", count, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)clearAeld_MemoryCache_HitCount {
    NSNumber *count = [NSNumber numberWithInteger:0];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount", count, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAeld_MemoryCache_LastUseDate:(NSDate * _Nullable)aeld_LastUseDate {
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_LastUseDate", aeld_LastUseDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface AELDMemoryCache ()

@property (nonatomic, strong) NSMutableDictionary *cachePool;

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

@end

@implementation AELDMemoryCache

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachePool = [[NSMutableDictionary alloc] init];
        NSString *queueName = [NSString stringWithFormat:@"com.altaireven.aeldmemorycache-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    return self;
}

#pragma mark Private methods

- (void)setCurrentUsage:(NSUInteger)currentUsage {
    [self willChangeValueForKey:@"currentUsage"];
    _currentUsage = currentUsage;
    [self didChangeValueForKey:@"currentUsage"];
}

- (BOOL)reallyRemoveCacheObject:(id)object {
    if (!object || [[object aeld_CacheKey] length] == 0) {
        return NO;
    }
    __weak typeof(self) weakSelf = self;
    //通知即将移除的回调函数
    if (weakSelf.WillEvictAction) {
        weakSelf.WillEvictAction(weakSelf, object);
    }
    //移除缓存对象
    [self.cachePool removeObjectForKey:[object aeld_CacheKey]];
    //将对象相关属性置空
    [object clearAeld_MemoryCache_HitCount];
    [object setAeld_MemoryCache_LastUseDate:nil];
    //重新计算当前缓存消耗
    self.currentUsage -= [object aeld_TotalBytes];
    
    return YES;
}

#pragma mark Public methods

+ (instancetype)memoryCacheWithName:(NSString *)name willEvictAction:(nullable void (^)(AELDMemoryCache * _Nonnull, id _Nonnull))action {
    AELDMemoryCache *cache = [[AELDMemoryCache alloc] init];
    cache.cacheName = name;
    cache.WillEvictAction = action;
    return cache;
}

- (void)clearUnused {
    if ([self.cachePool count] == 0) {
        return;
    }
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSArray *totalCaches = [self.cachePool allValues];
        //先清理过期的
        for (id cachedObj in totalCaches) {
            NSDate *currentDate = [NSDate date];
            NSDate *expireDate = [cachedObj aeld_ExpireDate];
            if (expireDate && [currentDate timeIntervalSinceDate:expireDate] > 0) {
                [self reallyRemoveCacheObject:cachedObj];
            }
        }
        //还需要继续清理
        if (self.currentUsage > self.cacheBytesLimit) {
            //按照权重降序排列
            NSArray *allCaches = [self.cachePool allValues];
            allCaches = [allCaches sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSNumber *clearWeight1 = [NSNumber numberWithInteger:[obj1 aeld_AutoClearWeight]];
                NSNumber *clearWeight2 = [NSNumber numberWithInteger:[obj2 aeld_AutoClearWeight]];
                NSComparisonResult result = [clearWeight1 compare:clearWeight2];
                return result == NSOrderedAscending;
            }];
            //这个地方需要先按照策略排序，再for循环清理
            NSUInteger bytesToClear = self.currentUsage - self.autoClearExpectation;
            NSUInteger clearedBytes = 0;
            for (id cachedObj in allCaches) {
                [self reallyRemoveCacheObject:cachedObj];
                clearedBytes += [cachedObj aeld_TotalBytes];
                if (clearedBytes >= bytesToClear) {
                    break;
                }
            }
        }
    });
}

#pragma mark Super methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (BOOL)setObject:(id)obj forKey:(NSString *)key {
    [obj setAeld_MemoryCache_CacheKey:key];
    if (![obj aeld_ValidateCacheObject]) {
        //非法对象
        return NO;
    }
    dispatch_barrier_async(self.synchronizationQueue, ^{
        //先存入
        [self.cachePool setObject:obj forKey:key];
        [obj setAeld_MemoryCache_LastUseDate:[NSDate date]];
        self.currentUsage += [obj aeld_TotalBytes];
    });
    
    //再清理
    [self clearUnused];
    return YES;
}

- (id)objectForKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || [key length] == 0) {
        return nil;
    }
    __block id object = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        object = [self.cachePool objectForKey:key];
        [object addAeld_MemoryCache_HitCount];
        [object setAeld_MemoryCache_LastUseDate:[NSDate date]];
    });
    return object;
}

- (NSDictionary<NSString *, id> *)allCachedObjects {
    __block NSDictionary *objects = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        //此处没有增加hitCount，也没有设置lastUseDate，主要是为了防止自动清理权重被打乱
        objects = [self.cachePool copy];
    });
    return objects;
}

- (BOOL)removeObjectForKey:(NSString *)key {
    if (![key isKindOfClass:[NSString class]] || [key length] == 0) {
        return NO;
    }
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        id object = [self.cachePool objectForKey:key];
        if (object) {
            removed = [self reallyRemoveCacheObject:object];
        }
    });
    return removed;
}

- (void)removeAllObjects {
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSArray *allCacheObjects = [self.cachePool allValues];
        for (id object in allCacheObjects) {
            [self reallyRemoveCacheObject:object];
        }
    });
}

@end
