//
//  LPExceptionHandler.m
//  Mach-O UUID
//
//  Created by Jack on 2018/8/1.
//  Copyright © 2018年 emerys. All rights reserved.
//

#import "LPExceptionHandler.h"
#import <UIKit/UIDevice.h>
#import <sys/utsname.h>

// Mach-O UUID
#import <mach-o/ldsyms.h>

// CPU arch
#import <mach-o/arch.h>

// Slide Address
#include <mach-o/dyld.h>

@interface LPExceptionHandler ()

@property (nonatomic,copy) void (^handler)(NSString *);

+ (instancetype)sharedHanlder;

@end

#pragma mark - dSYM UUID

// 获取主执行Image UUID，此UUID要和dSYM文件UUID相同
NSString *mach_oUUID() {
    const uint8_t *command = (const uint8_t *)(&_mh_execute_header + 1);
    for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx) {
        if (((const struct load_command *)command)->cmd == LC_UUID) {
            command += sizeof(struct load_command);
//            return [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
//                    command[0], command[1], command[2], command[3],
//                    command[4], command[5],
//                    command[6], command[7],
//                    command[8], command[9],
//                    command[10], command[11], command[12], command[13], command[14], command[15]];
            
            CFUUIDRef uuidRef = CFUUIDCreateFromUUIDBytes(NULL, *((CFUUIDBytes*)command));
            NSString* uuidStr = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuidRef);
            
            return uuidStr;
            
        } else {
            command += ((const struct load_command *)command)->cmdsize;
        }
    }
    return nil;
}

#pragma mark - CPU Type

const char *byteOrder(enum NXByteOrder BO) {
    switch (BO) {
        case NX_LittleEndian: return ("Little-Endian");
        case NX_BigEndian: return ("Big-Endian");
        case NX_UnknownByteOrder: return "Unknow";
        default: return ("!?!");
    }
}

void testGetAllArch () {
    
    const NXArchInfo *known = NXGetAllArchInfos();
    
    while (known && known->description) {
        printf("known: %s\t%x/%x\t%s\n", known->description,
               known->cputype,
               known->cpusubtype,
               byteOrder(known->byteorder));
        known++;
    }
}

// 获取CPU架构类型
NSString *localCPUType() {
    const NXArchInfo *local = NXGetLocalArchInfo();
    
    
    if (local) {
        printf("Local - %s\t%x/%x\t%s\n", local->description,
               local->cputype,
               local->cpusubtype,
               byteOrder(local->byteorder));
        
        return [NSString stringWithUTF8String:local->description];
    }
    return @"unknown";
}

#pragma mark - Slide Address

//获取基地址
uintptr_t loadAddress() {
    const struct mach_header *exe_header = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            exe_header = header;
            break;
        }
    }
    
    //返回值即为加载地址
    return (uintptr_t)exe_header;
}

// 获取偏移地址
uintptr_t slideAddress() {
    
    uintptr_t vmaddr_slide = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    
    return (uintptr_t)vmaddr_slide;
}

#pragma mark - Binary Image

NSString *binaryImageName() {
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            
            const char *path = _dyld_get_image_name((unsigned)i);
            NSString *imagePath = [NSString stringWithUTF8String:path];
            NSArray *array = [imagePath componentsSeparatedByString:@"/"];
            NSString *imageName = array[array.count - 1];
            return imageName;
            
            break;
        }
    }
    
    return nil;
}

#pragma mark - Caught Exception

void UncaughtExceptionHandler(NSException *exception) {
    
    NSMutableString *exceptionStr = [NSMutableString string];
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *modle = device.model;
    NSString *os = device.systemName;
    NSString *ver = device.systemVersion;
    
    struct utsname systeminfo;
    uname(&systeminfo);
    NSString *deviceString = [NSString stringWithCString:systeminfo.machine encoding:NSUTF8StringEncoding];
    
    [exceptionStr appendFormat:@"Device: %@\n",modle];
    [exceptionStr appendFormat:@"OS: %@ %@\n",os,ver];
    [exceptionStr appendFormat:@"Hardware: %@\n",deviceString];
    
    NSDictionary* infoDict =[[NSBundle mainBundle] infoDictionary];
    NSString* build =[infoDict objectForKey:@"CFBundleVersion"];
    NSString* version =[infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleID = [infoDict objectForKey:@"CFBundleIdentifier"];
    NSString *bundleName = [infoDict objectForKey:@"CFBundleName"];
    
    [exceptionStr appendFormat:@"Bundle Name: %@\n",bundleName];
    [exceptionStr appendFormat:@"build: %@\n",build];
    [exceptionStr appendFormat:@"version: %@\n",version];
    [exceptionStr appendFormat:@"identifier: %@\n",bundleID];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    NSString *dateStr = [formatter stringFromDate:date];
    
    [exceptionStr appendFormat:@"Date/Time: %@\n\n",dateStr];
    
    NSArray *callStack = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    
    [exceptionStr appendFormat:@"%@\n%@\n\n%@\n\n",name,reason,callStack];
    [exceptionStr appendFormat:@"dSYM UUID: %@\n",mach_oUUID()];
    [exceptionStr appendFormat:@"CPU Type: %@\n",localCPUType()];
    [exceptionStr appendFormat:@"Slide Address: 0x%lx\n",slideAddress()];
    [exceptionStr appendFormat:@"Binary Image: %@\n",binaryImageName()];
    [exceptionStr appendFormat:@"Base Address: 0x%lx\n",loadAddress()];
    
    NSLog(@"exception:\n%@",exceptionStr);
    
    if ([LPExceptionHandler sharedHanlder].handler) {
        [LPExceptionHandler sharedHanlder].handler(exceptionStr);
    }
}

#pragma mark - Handler

@implementation LPExceptionHandler

+ (instancetype)sharedHanlder {
    static LPExceptionHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[LPExceptionHandler alloc] init];
    });
    return handler;
}

+ (void)registHandler:(void (^)(NSString *))handler {
    [[LPExceptionHandler sharedHanlder] registExceptionHandler:handler];
}

- (void)registExceptionHandler:(void (^)(NSString *))handler {
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    self.handler = handler;
}

@end
