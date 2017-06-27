//
//  AELDCache.h
//  AELocalDataKit
//
//  Created by Altair on 23/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AELDCacheObjectTypeUnknown,
    AELDCacheObjectTypeNSString,
    AELDCacheObjectTypeNSData,
    AELDCacheObjectTypeUIImage,
    AELDCacheObjectTypeOther
}AELDCacheObjectType;

NS_ASSUME_NONNULL_BEGIN

/**
 对NSObject的缓存扩展
 */
@interface NSObject (AELDCacheObject)

@property (nonatomic, copy) NSString *aeld_CacheIdentifier;    //缓存对象的id，用作缓存key

@property (nonatomic, readonly) AELDCacheObjectType aeld_MimeType;  //缓存对象的类型

@property (nonatomic, assign) NSUInteger aeld_TotalBytes;   //缓存对象的内存占用大小，如果缓存对象是UIImage || NSString || NSData，会默认自动填入一个系统计算出来的值（如果需要也可以自行赋值，以用户赋值为准）；否则需要自行赋值。如果这个值为0，将无法存入缓存。

@property (nonatomic, readonly) NSInteger aeld_HitCount;  //使用次数，不会被清零，除非对象被移出缓存

@property (nonatomic, strong, readonly) NSDate *aeld_LastUseDate; //上一次使用时间，不会被置为nil，除非对象被移出缓存

/**
 判断是否是合法的缓存对象

 @return 是否合法
 */
- (BOOL)aeld_ValidateCacheObject;

/**
 被自动清理的权重，权重越高，则越会被清理

 @return 自动清理权重
 */
- (NSInteger)aeld_AutoClearWeight;

@end

/**
 Cache基类，需继承后使用
 */
@interface AELDCache <__covariant ObjectType> : NSObject

@property (nonatomic, copy) NSString *cacheName;    //Cache名称，可用作区分不同Cache

- (BOOL)addObject:(ObjectType)obj;
- (ObjectType)objectWithCacheIdentifier:(NSString *)identifier;
- (NSDictionary<NSString *, ObjectType> *)allCachedObjects;
- (BOOL)removeObjectWithCacheIdentifier:(NSString *)identifier;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
