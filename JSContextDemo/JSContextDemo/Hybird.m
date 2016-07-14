//
//  Hybird.m
//  NoWait
//
//  Created by liu nian on 5/13/16.
//  Copyright © 2016 Shanghai Puscene Information Technology Co.,Ltd. All rights reserved.
//

#import "Hybird.h"
#import "MainViewController.h"

typedef NS_ENUM(NSInteger, HybirdStatusCode) {
    HybirdStatusCodeSuccess         = 0,    //成功
    HybirdStatusCodeFail            = 101,  //调用失败
    HybirdStatusCodeAPINotSupport   = 102,  //所调用的方法不支持
    HybirdStatusCodeUserCancel      = 103,  //用户取消
    HybirdStatusCodeParamError      = 104,  //参数错误
    HybirdStatusCodeNotAuth         = 105,  //未授权//系统的一些功能未开启或者未授权
};

// shareType
typedef NS_ENUM(NSInteger, HybirdShareType) {
    HybirdShareTypeDefault             = 0, //其他未指定的平台，都适用该分享内容
    HybirdShareTypeWechatFriend        = 1, //微信好友
    HybirdShareTypeWechatCircle        = 2, //微信朋友圈
    
};

@interface Hybird ()<WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) MainViewController *webController;

NSString *makeHybirdServiceHandler(NSString *service,NSString *action,id param,NSString *callback_action);
NSString *makeCallbackHybirdServiceHandler(NSString *service,NSString *action,id param, NSInteger statusCode);
@end
@implementation Hybird
/**
 *  组合请求JSON
 *
 *  @param service         业务类型
 *  @param action          函数名
 *  @param param           参数
 *  @param callback_action 回调函数名
 *
 *  @return JSON字符串
 */
NSString *makeHybirdServiceHandler(NSString *service,NSString *action,id param,NSString *callback_action){
    NSString *jsonString = nil;
    if (!service || !action) {
        return jsonString;
    }
    
    NSMutableDictionary *hybirdDic = @{@"service":service,@"action":action}.mutableCopy;
    if (param) {
        hybirdDic[@"param"] = param;
    }
    if (callback_action) {
        hybirdDic[@"callback_action"] = callback_action;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:hybirdDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if ([jsonData length] > 0 && error == nil){
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

/**
 *  组合回调请求JSON
 *
 *  @param service    业务类型
 *  @param action     回调函数名
 *  @param param      参数
 *  @param statusCode 状态码
 *
 *  @return JSON字符串
 */
NSString *makeCallbackHybirdServiceHandler(NSString *service,NSString *action,id param, NSInteger statusCode){
    NSString *jsonString = nil;
    if (!service || !action) {
        return jsonString;
    }
    
    NSMutableDictionary *hybirdDic = @{@"service":service, @"action":action, @"statusCode":@(statusCode)}.mutableCopy;
    if (param) {
        hybirdDic[@"param"] = param;
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:hybirdDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if ([jsonData length] > 0 && error == nil){
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

+ (NSString*)urlEncode:(NSString*)str {
    //different library use slightly different escaped and unescaped set.
    //below is copied from AFNetworking but still escaped [] as AF leave them for Rails array parameter which we don't use.
    //https://github.com/AFNetworking/AFNetworking/pull/555
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)str, CFSTR("."), CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
    return result;
}
+ (NSString *)URLDecodedString:(NSString*)str{
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)sendCommand:(NSString *)commandJSON completionHandler:(void (^ __nullable)(__nullable id, NSError * __nullable error))completionHandler{
    NSString *js = [NSString stringWithFormat:@"client_callback(\"%@\")",[[self class] urlEncode:commandJSON]];
    [self.webView evaluateJavaScript:js completionHandler:completionHandler];
}

#pragma mark - init
- (instancetype)initWithWebView:(WKWebView *)webView webController:(MainViewController *)webController{
    if (self = [super init]) {
        self.webView = webView;
        self.webController = webController;
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addScriptMessageHandler:self name:@"app"];
        self.webView.configuration.userContentController = userContentController;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"方法名:%@", message.name);
    NSLog(@"参数:%@", message.body);
    if (!message.body) {
        return;
    }
    
    if ([message.name isEqualToString:@"app"]) {
        NSDictionary *body = nil;
        if ([message.body isKindOfClass:[NSDictionary class]]) {
            body = message.body;
        }else if ([message.body isKindOfClass:[NSString class]]){
            NSString *jsonString = [[self class] URLDecodedString:message.body];
            
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
            body = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
        }
        
        if (!body) {
            return;
        }
        
        NSString *service = body[@"service"];
        NSString *action = body[@"action"];
        NSDictionary *param = nil;
        if ([[body allKeys] containsObject:@"param"]) {
            param = body[@"param"];
        }
        NSString *callback_action = nil;
        if ([[body allKeys] containsObject:@"callback_action"]) {
            callback_action = body[@"callback_action"];
        }
        
        NSInteger statusCode = 0;
        if ([[body allKeys] containsObject:@"statusCode"]) {
            statusCode = [body[@"statusCode"] integerValue];
        }
        [self executeReceiveHybirdService:service
                                   action:action
                                    param:param
                          callback_action:callback_action
                               statusCode:statusCode];
    }
    
    
}
- (void)excuteScriptMessage:(WKScriptMessage *)message{
    NSLog(@"方法名:%@", message.name);
    NSLog(@"参数:%@", message.body);
    if (!message.body) {
        return;
    }
    
    if ([message.name isEqualToString:@"app"]) {
        NSDictionary *body = nil;
        if ([message.body isKindOfClass:[NSDictionary class]]) {
            body = message.body;
        }else if ([message.body isKindOfClass:[NSString class]]){
            NSString *jsonString = [[self class] URLDecodedString:message.body];
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
            body = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            
        }
        if (!body) {
            return;
        }
        
        NSString *service = body[@"service"];
        NSString *action = body[@"action"];
        NSDictionary *param = nil;
        if ([[body allKeys] containsObject:@"param"]) {
            param = body[@"param"];
        }
        NSString *callback_action = nil;
        if ([[body allKeys] containsObject:@"callback_action"]) {
            callback_action = body[@"callback_action"];
        }
        
        NSInteger statusCode = 0;
        if ([[body allKeys] containsObject:@"statusCode"]) {
            statusCode = [body[@"statusCode"] integerValue];
        }
        [self executeReceiveHybirdService:service
                                   action:action
                                    param:param
                          callback_action:callback_action
                               statusCode:statusCode];
    }
}
#pragma mark - DO
- (void)doUploadAppInfoAtWebViewDidLoadFinish{
    NSDictionary *dic = @{@"appver":@"1.0",@"deviceid":@"12113123",@"jkversion":@"jkversion",@"token":@"token"};
    NSString *com = makeHybirdServiceHandler(@"app", @"do_uploadAppInfo", dic, nil);
    [self sendCommand:com completionHandler:nil];
}

#pragma mark - CALLBACK
- (void)callbackAction:(NSString *)callback_action afterLoginWithToken:(NSString *)token statusCode:(HybirdStatusCode)statusCode{
    NSMutableDictionary *dic = @{}.mutableCopy;
    if (token) {
        dic[@"token"] = token;
    }
    
    if (!callback_action) {
        callback_action = @"callback_qrcode";
    }
    
    NSString *com = makeCallbackHybirdServiceHandler(@"app", callback_action, dic, statusCode);
    [self sendCommand:com completionHandler:nil];
    
}

- (void)callbackAction:(NSString *)callback_action afterQRCodeWithQRCode:(NSString *)qrcode statusCode:(HybirdStatusCode)statusCode{
    NSMutableDictionary *dic = @{}.mutableCopy;
    if (qrcode) {
        dic[@"qrcode"] = qrcode;
    }
    
    if (!callback_action) {
        callback_action = @"callback_qrcode";
    }
    
    NSString *com = makeCallbackHybirdServiceHandler(@"business", callback_action, dic, statusCode);
    [self sendCommand:com completionHandler:nil];
}

BOOL isStrEqual(NSString *string1,NSString *string2){
    return [string1 isEqualToString:string2];
}

- (void)executeReceiveHybirdService:(NSString *)service
                             action:(NSString *)action
                              param:(id)param
                    callback_action:(NSString *)callback_action
                         statusCode:(NSInteger)statusCode{
    __weak typeof(self) weakSelf = self;
    if (isStrEqual(service, @"app")) {
        //设备业务
        
        if (isStrEqual(action, @"do_login")) {
            //登陆
            //            [self.webController whenAuthValidDoActionBlock:^{
            //                [weakSelf callbackAction:callback_action afterLoginWithToken:[MWDataManager sharedInstance].sessionId statusCode:HybirdStatusCodeSuccess];
            //            }];
            
        }else if (isStrEqual(service, @"share")){
            //分享业务
            
            if (isStrEqual(action, @"do_one_share")) {
                if ([param isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *paramDic = (NSDictionary *)param;
                    
                }
                
                
            }else if (isStrEqual(action, @"callback_custom_share")){
                
            }
            
        }else if (isStrEqual(service, @"business")){
            //基础业务
        }
    }
}

@end

