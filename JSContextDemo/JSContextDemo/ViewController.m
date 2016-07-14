//
//  ViewController.m
//  JSContextDemo
//
//  Created by liu nian on 4/15/16.
//  Copyright © 2016 Copyright © 2015年 http://iliunian.cn. All rights reserved.
//

#import "ViewController.h"
#import "NLJsObjCModel.h"
#import <WebKit/WebKit.h>

@interface ViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) JSContext *jsContext;

@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    
    self.title = @"JSContext 对象绑定";
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
    // 通过模型调用方法，这种方式更好些。
    NLJsObjCModel *model  = [[NLJsObjCModel alloc] init];
    self.jsContext[@"OCModel"] = model;
    model.jsContext = self.jsContext;
    model.webView = self.webView;
    
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
    
    // 也可以通过下标的方式获取到方法
    JSValue *reFuc = self.jsContext[@"reFuc"];
    JSValue *value = [reFuc callWithArguments:@[@"20"]];
    
    NSLog(@"%@", reFuc.toNumber);
    NSLog(@"%@", value.toNumber);
}

- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.scalesPageToFit = YES;
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Example" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:request];
        _webView.delegate = self;
    }
    
    return _webView;
}


@end
