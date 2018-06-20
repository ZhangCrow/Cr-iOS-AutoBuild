//
//  ViewController.m
//  CRSampleB
//
//  Created by HHT_乌鸦君 on 2018/6/20.
//  Copyright © 2018年 CR. All rights reserved.
//

#import "ViewController.h"

#define kInfoAutoBuildMethodKey     @"CRAutoBuildMethod"
#define kInfoAutoBuildDateKey       @"CRAutoBuildDate"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showSampleAlert];
}

- (void)showSampleAlert {
    NSString *baseUrl = [[self class] apiBaseUrl];
    NSString *buildInfo = [[self class] fullAppNameEnvVersion];
    NSString *msg = [NSString stringWithFormat:@"BaseUrl:\n%@\n\nAboutMe:\n%@", baseUrl, buildInfo];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// 因为是Sample项目且主要是脚本工具，所以并未创建工具类, 常量字符串或宏的头文件。
#pragma mark - 使用场景介绍
/** 在应用工具类中 提供不同接口环境的baseUrl */
+ (NSString *)apiBaseUrl {
#ifdef CR_ENV_DEV
    // 开发环境
    return @"http://cr.dev.net/";
#elif CR_ENV_UAT
    // 测试环境
    return @"http://cr.uat.net/";
#else
    // 生产环境
    return @"http://cr.xxx.cn/";
#endif
}

/** 在应用工具类中 提供应用环境版本等信息 */
+ (NSString *)fullAppNameEnvVersion {
    /* Eg:
     v1.0.1.168_debug_envdev             // 开发　: 开发环境 Debug编译
     v1.0.1.168_envuat_dev_18031022      // 测试　: 测试环境 Development方式打包
     v1.0.1                              // 发布　: 生产环境 AppStore方式打包
     
     App显示名 v版本号.Build号_编译方式_接口环境_打包方式_打包时间
     ${appName} v${appShortVersion}.${appBuildVersion}_${mode}_${env}_${method}_${date}
     */
    NSString *appBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *appShortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *result = [NSString stringWithFormat:@"v%@", appShortVersion];
    BOOL debugMode = NO;
#ifdef DEBUG
    debugMode = YES;
#endif
    NSString *env = nil;
#ifdef CR_ENV_DEV
    env = @"_envdev";
#elif CR_ENV_UAT
    env = @"_envuat";
#else
    env = @"";
#endif
    if (!debugMode && env.length == 0) {
        // Release 生产环境 result: v2.0.1
        return result;
    }
    // result: v2.0.1.168
    result = [NSString stringWithFormat:@"%@.%@", result, appBundleVersion];
    
    if (debugMode) {
        // result: v2.0.1.168_debug
        result = [result stringByAppendingString:@"_debug"];
    }
    // result: v2.0.1.168_debug_envdev
    result = [result stringByAppendingString:env];
    // 以下字段若为非发布自动打包 会执行拼接
    NSString *method = [[[NSBundle mainBundle] infoDictionary] objectForKey:kInfoAutoBuildMethodKey];
    if ([method isKindOfClass:[NSString class]] && method.length > 0) {
        // result: v2.0.1.168_debug_envdev_dev
        result = [NSString stringWithFormat:@"%@_%@", result, method];
    }
    NSString *date = [[[NSBundle mainBundle] infoDictionary] objectForKey:kInfoAutoBuildDateKey];
    if ([date isKindOfClass:[NSString class]] && date.length > 0) {
        // result: v2.0.1.168_debug_envdev_dev_18031022
        result = [NSString stringWithFormat:@"%@_%@", result, date];
    }
    return result;
}

@end
