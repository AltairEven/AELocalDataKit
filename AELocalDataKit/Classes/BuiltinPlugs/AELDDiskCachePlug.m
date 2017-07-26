//
//  AELDDiskCachePlug.m
//  Pods
//
//  Created by Altair on 26/07/2017.
//
//

#import "AELDDiskCachePlug.h"
#import "AELDDiskCache.h"

@interface AELDDiskCachePlug ()

@property (nonatomic, strong) AELDDiskCache *diskCache;

@end

@implementation AELDDiskCachePlug

- (instancetype)init {
    self = [super init];
    if (self) {
        self.diskCache = [AELDDiskCache diskCacheWithName:NSStringFromClass([self class])];
    }
    return self;
}

#pragma mark AELocalDataPlugProtocal

- (AELDPlugMode *)plugMode {
    return [AELDPlugMode modeWithName:NSStringFromClass([self class]) supportOperationType:AELDOperationTypeRead|AELDOperationTypeWrite|AELDOperationTypeDelete];
}

- (BOOL)startOperation:(AELDOperationMode *)mode forKey:(NSString * _Nullable)key value:(id _Nullable)value response:(nonnull void (^)(AELDResponse * _Nonnull))response {
    if (!mode) {
        return NO;
    }
    id obj = nil;
    NSError *error = nil;
    switch (mode.operationType) {
        case AELDOperationTypeRead:
        {
            obj = [self.diskCache objectForKey:key];
            if (!obj) {
                error = [NSError errorWithDomain:@"AELDMemoryCachePlug" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"找不到对象"}];
            }
        }
            break;
        case AELDOperationTypeWrite:
        {
            if (![self.diskCache setObject:value forKey:key]) {
                error = [NSError errorWithDomain:@"AELDMemoryCachePlug" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"缓存失败"}];
            }
        }
            break;
        case AELDOperationTypeDelete:
        {
            if (![self.diskCache removeObjectForKey:key]) {
                error = [NSError errorWithDomain:@"AELDMemoryCachePlug" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"删除缓存失败"}];
            }
        }
            break;
        case AELDOperationTypeClear:
        {
            [self.diskCache removeAllObjects];
        }
            break;
        default:
            break;
    }
    
    AELDResponse *resp = [[AELDResponse alloc] initWithOriginalMode:mode responseData:obj userInfo:nil error:error];
    if (response) {
        response(resp);
    }
    
    return YES;
}

- (BOOL)stopOperation {
    return YES;
}

@end