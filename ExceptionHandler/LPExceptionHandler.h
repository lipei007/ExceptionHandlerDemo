//
//  LPExceptionHandler.h
//  Mach-O UUID
//
//  Created by Jack on 2018/8/1.
//  Copyright © 2018年 United Software Applications. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief 收集Crash信息，分析参考https://github.com/answer-huang/dSYMTools
 */
@interface LPExceptionHandler : NSObject

+ (instancetype)sharedHanlder;

+ (void)registHandler:(void (^)(NSString *exceptionStr)) handler;

- (void)registExceptionHandler:(void (^)(NSString *exceptionStr)) handler;

@end
