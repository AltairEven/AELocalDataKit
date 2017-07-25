//
//  AELDResponse.h
//  AELocalDataKit
//
//  Created by Altair on 21/06/2017.
//  Copyright © 2017 Altair. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AELDOperationMode;

/**
 数据操作的返回
 */
@interface AELDResponse : NSObject

@property (nonatomic, copy) AELDOperationMode *originalMode;  //原始数据操作模式

@property (nonatomic, strong) NSError *error; //数据操作返回错误信息

@property (nonatomic, copy) NSDictionary *userInfo; //数据操作返回用户信息

/**
 初始化数据操作请求返回的方法
 
 @param originalMode 原始数据操作模式
 @return 类实例
 */
- (instancetype)initWithOriginalMode:(AELDOperationMode *)originalMode;

@end
