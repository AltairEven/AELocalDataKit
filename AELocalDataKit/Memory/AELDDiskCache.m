//
//  AELDDiskCache.m
//  AELocalDataKit
//
//  Created by Altair on 27/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import "AELDDiskCache.h"

@interface AELDDiskCache ()

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

@property (nonatomic, strong) NSFileManager *fileManager;

- (NSString *)cacheDirectoryPath;

- (NSString *)filePathWithCacheIdentifier:(NSString *)identifier;

- (void)initializeStorage;

- (void)saveCacheObject:(id)object;

- (id)loadCacheObjectWithIdentifier:(NSString *)identifier;

@end

@implementation AELDDiskCache

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *queueName = [NSString stringWithFormat:@"com.altaireven.aeldmemorycache-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        [self initializeStorage];
        self.fileManager = [NSFileManager new];
    }
    return self;
}

#pragma mark Private methods

- (NSString *)cacheDirectoryPath {
    NSString *docment = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    NSString *cachePath = [docment stringByAppendingPathComponent:@"/AELDDiskCache"];
    return cachePath;
}

- (NSString *)filePathWithCacheIdentifier:(NSString *)identifier {
    NSString *filePath = [[self cacheDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", identifier]];
    return filePath;
}

- (void)initializeStorage {
    NSError *error = nil;
    BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:[self cacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:&error];
    if (!result && error) {
        NSLog(@"Create directory failed。%@", error);
    }
}

- (void)saveCacheObject:(id)object {
    @synchronized (object) {
        //防止object被其他线程访问，故使用同步锁
        [NSKeyedArchiver archiveRootObject:object toFile:[self filePathWithCacheIdentifier:[object aeld_CacheIdentifier]]];
    }
}

- (id)loadCacheObjectWithIdentifier:(NSString *)identifier {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePathWithCacheIdentifier:identifier]];
}

#pragma mark Public methods

+ (instancetype)memoryCacheWithName:(NSString *)name {
    AELDDiskCache *cache = [[AELDDiskCache alloc] init];
    cache.cacheName = name;
    return cache;
}

#pragma mark Super methods

- (BOOL)addObject:(id)obj{
    if (![obj aeld_ValidateCacheObject] && ![obj conformsToProtocol:@protocol(NSCoding)]) {
        //非法对象
        return NO;
    }
    dispatch_barrier_async(self.synchronizationQueue, ^{
        [self saveCacheObject:obj];
    });
    return YES;
}

- (id)objectWithCacheIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || [identifier length] == 0) {
        return nil;
    }
    return [self loadCacheObjectWithIdentifier:identifier];
}

- (NSDictionary<NSString *, id> *)allCachedObjects {
    __block NSDictionary *objects = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        NSError *error = nil;
        NSArray *files = [self.fileManager contentsOfDirectoryAtPath:[self cacheDirectoryPath] error:&error];
        NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
        for (NSString *filePath in files) {
            @autoreleasepool {
                NSString *identifier = [[filePath lastPathComponent] stringByDeletingPathExtension];
                id cacheObject = [self loadCacheObjectWithIdentifier:identifier];
                if (cacheObject) {
                    [tempDic setObject:cacheObject forKey:identifier];
                }
            }
        }
        objects = [tempDic copy];
    });
    return objects;
}

- (BOOL)removeObjectWithCacheIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:[NSString class]] || [identifier length] == 0) {
        return NO;
    }
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSString *filePath = [self filePathWithCacheIdentifier:identifier];
        NSError *error =  nil;
        removed = [self.fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Remove cache failed:%@", error);;
        }
    });
    return removed;
}

- (void)removeAllObjects {
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        NSError *error = nil;
        NSArray *files = [self.fileManager contentsOfDirectoryAtPath:[self cacheDirectoryPath] error:&error];
        for (NSString *filePath in files) {
            NSError *err =  nil;
            [self.fileManager removeItemAtPath:filePath error:&error];
            if (err) {
                NSLog(@"Remove cache failed:%@", err);;
            }
        }
    });
}

@end
