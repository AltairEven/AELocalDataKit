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
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount", count, OBJC_ASSOCIATION_ASSIGN);
}

- (void)clearAeld_MemoryCache_HitCount {
    NSNumber *count = [NSNumber numberWithInteger:0];
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_HitCount", count, OBJC_ASSOCIATION_ASSIGN);
}

- (void)setAeld_MemoryCache_LastUseDate:(NSDate * _Nullable)aeld_LastUseDate {
    objc_setAssociatedObject(self, @"AELocalDataKit_CacheObject_LastUseDate", aeld_LastUseDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface AELDMemoryCache ()

@property (nonatomic, strong) NSMutableDictionary *cachePool;

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

@property (nonatomic, strong) dispatch_source_t autoClearTimer;

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
    if (currentUsage >= self.cacheBytesLimit && self.CacheFullAlert) {
        __weak typeof(self) weakSelf = self;
        weakSelf.CacheFullAlert(weakSelf);
    }
}

- (void)startAutoClear {
    if (!self.autoClearTimer) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.autoClearTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        dispatch_source_set_timer(self.autoClearTimer, DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.autoClearTimer, ^{
            [weakSelf autoClearCacheSpace];
        });
        dispatch_resume(self.autoClearTimer);
    }
}

- (void)stopAutoClear {
    if (self.autoClearTimer) {
        if (!dispatch_source_testcancel(self.autoClearTimer)) {
            //尚未取消，先关闭定时器
            dispatch_source_cancel(self.autoClearTimer);
        }
        self.autoClearTimer = nil;
    }
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
//    [cache setAutoClear:YES];
    return cache;
}

#pragma mark Super methods

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [self stopAutoClear];
}

- (void)setAutoClear:(BOOL)autoClear {
    [super setAutoClear:autoClear];
    if (autoClear) {
        [self startAutoClear];
    } else {
        [self stopAutoClear];
    }
}

- (void)autoClearCacheSpace {
    [super autoClearCacheSpace];
    if ([self.cachePool count] == 0) {
        return;
    }
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSDate *currentDate = [NSDate date];
        //先清理过期的
        [self.cachePool enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSDate *expireDate = [obj aeld_ExpireDate];
            if (expireDate && [currentDate timeIntervalSinceDate:expireDate] > 0) {
                [self reallyRemoveCacheObject:obj];
            }
        }];
        //还需要继续清理
        if (self.currentUsage > self.cacheBytesLimit) {
            //按照权重降序排列
            NSArray *allKeys = [self.cachePool keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSNumber *clearWeight1 = [NSNumber numberWithInteger:[obj1 aeld_AutoClearWeightAtDate:currentDate]];
                NSNumber *clearWeight2 = [NSNumber numberWithInteger:[obj2 aeld_AutoClearWeightAtDate:currentDate]];
                NSComparisonResult result = [clearWeight1 compare:clearWeight2];
                return result == NSOrderedAscending;
            }];
            //这个地方需要先按照策略排序，再for循环清理
            NSUInteger bytesToClear = self.currentUsage - self.autoClearExpectation;
            NSUInteger clearedBytes = 0;
            for (NSString *key in allKeys) {
                id cachedObj = [self.cachePool objectForKey:key];
                [self reallyRemoveCacheObject:cachedObj];
                clearedBytes += [cachedObj aeld_TotalBytes];
                if (clearedBytes >= bytesToClear) {
                    break;
                }
            }
        }
    });
}

- (BOOL)setObject:(id)obj forKey:(NSString *)key {
    [obj setAeld_MemoryCache_CacheKey:key];
    if (![obj aeld_ValidateCacheObject]) {
        //非法对象
        return NO;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.synchronizationQueue, ^{
        if (!weakSelf.autoClear && weakSelf.currentUsage >= weakSelf.cacheBytesLimit) {
            //非自动清理，并且已经装满
            if (weakSelf.CacheFullAlert) {
                weakSelf.CacheFullAlert(weakSelf);
            }
        } else {
            [self.cachePool setObject:obj forKey:key];
            [obj setAeld_MemoryCache_LastUseDate:[NSDate date]];
            self.currentUsage += [obj aeld_TotalBytes];
        }
    });

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
