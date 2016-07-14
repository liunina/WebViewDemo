//
//  DefaultViewController.m
//  JSContextDemo
//
//  Created by liu nian on 7/13/16.
//  Copyright © 2016 Copyright © 2015年 http://iliunian.cn. All rights reserved.
//

#import "DefaultViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "NLJsObjCModel.h"

@interface DefaultViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) JSContext *jsContext;

@end

@implementation DefaultViewController
-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    
    self.title = @"JSContext普通交互";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAction:)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doAction:(id)sender{
    JSValue *jsValue = [self.jsContext evaluateScript:@"showAppAlertMsg"];
    [jsValue callWithArguments:@[@"这是app本地交互文案"]];
}
#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
    
    // 也可以通过下标的方式获取到方法
    self.jsContext[@"callSystemCamera"] = ^(){
        NSLog(@"callSystemCamera");
        
    };
    
    self.jsContext[@"showAlertMsg"] = ^(NSString *title, NSString *message){
        NSLog(@"callSystemCamera");
        
    };
    
    self.jsContext[@"callWithDict"] = ^(id jsonDic){
        NSLog(@"callWithDict%@",jsonDic);
        
    };
}

- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:request];
        _webView.scalesPageToFit = YES;
        _webView.delegate = self;
    }
    
    return _webView;
}
@end
