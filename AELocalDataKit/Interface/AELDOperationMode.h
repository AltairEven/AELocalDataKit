//
//  AELDOperationMode.h
//  AELocalDataKit
//
//  Created by Altair on 21/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AELDOperationSynchronized,  //同步
    AELDOperationAsynchronized  //异步
}AELDOperationSynchronization;


typedef enum {
    AELDOperationTypeRead           = 1 << 0,       //读
    AELDOperationTypeWrite          = 1 << 1,       //写
    AELDOperationTypeDelete         = 1 << 2,       //删
    AELDOperationTypeAll            = (1 << 3) - 1  //全部
}AELDOperationType;

@interface AELDOperationMode : NSObject

@property (nonatomic, strong, readonly) NSString *name; //数据操作模式名称

@property (nonatomic, assign) AELDOperationSynchronization synchronization; //同步操作或者异步操作，默认为AELDOperationSynchronized

@property (nonatomic, readonly) AELDOperationType operationType; //数据操作类型，建议根据实际数据操作，或者数据插件的定义来赋值

/**
 便捷实例化方法
 
 @param name 模式名称
 @param type 操作类型
 @return 类实例
 */
+ (instancetype)modeWithName:(NSString *)name operationType:(AELDOperationType)type;

@end
