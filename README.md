# WebViewDemo
UIWebView,JavaScriptCore,WKWebView 关于HTML的JS交互
DEMO中的见解见:[iOS中的HTML交互简说](http://iliunian.cn/14684585476236.html)



# iOS中的HTML交互简说

跟原生开发相比，H5的开发相对来一个成熟的框架和团队来讲在开发速度和开发效率上有着比原生很大的优势，至少不用等待审核。那么问题来了，H5与本地原生代码势必要有交互的，比如本地上传一些信息，H5打开本地的页面，打开本地进行微信等第三方分享等，今天就简单讲一下iOS中本地UIWebView,WKWebView与H5的交互。

##UIWebView的交互

###stringByEvaluatingJavaScriptFromString的使用
UIWebView在2.0时代就有的类，一直到现在（目前9.x）都可以使用的WEB容器，它的方法很简单，在iOS7.0之前JS交互的方法只有一个`stringByEvaluatingJavaScriptFromString`:

```
- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
```

使用stringByEvaluatingJavaScriptFromString方法，需要等UIWebView中的页面加载完成之后去调用.

以下是简单的使用场景：

1、获取当前页面的url。

```
- (void)webViewDidFinishLoad:(UIWebView *)webView {      
	NSString *currentURL = [webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];  
} 
```
2、获取页面title：

```
- (void)webViewDidFinishLoad:(UIWebView *)webView {       
		NSString *currentURL = [webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];     
NSString *title = [webview stringByEvaluatingJavaScriptFromString:@"document.title"];  
} 
```
3、修改界面元素的值。

```
NSString *js_result = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('q')[0].value='iOS';"]; 
```
4、表单提交：

```
NSString *js_result2 = [webView stringByEvaluatingJavaScriptFromString:@"document.forms[0].submit(); "]; 
```
这样就实现了在google搜索关键字：“iOS”的功能。
5、插入js代码
上面的功能我们可以封装到一个js函数中，将这个函数插入到页面上执行，代码如下：

```	[webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"     
	"script.type = 'text/javascript';"            
	"script.text = \"function myFunction() { "            
	"var field = document.getElementsByName('q')[0];"             
	"field.value='iOS';"            
	"document.forms[0].submit();"   
	"}\";"     
	"document.getElementsByTagName('head')[0].appendChild(script);"];    
	
	[webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];   
```
看上面的代码：

a、首先通过js创建一个script的标签，type为'text/javascript'。
b、然后在这个标签中插入一段字符串，这段字符串就是一个函数：myFunction，这个函数实现google自动搜索关键字的功能。
c、然后使用stringByEvaluatingJavaScriptFromString执行myFunction函数。

6、直接调用JS函数

上面的函数调用是本地注入到H5中，然后本地调用的，那么如果H5中就有原生的JS函数:`myFunction();`，那么我们就可以直接执行:

```
[webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];  
```


###JavaScriptCore框架的使用

我们会发现`stringByEvaluatingJavaScriptFromString`的方法调用太笨拙,在iOS7.0中苹果公司增加了JS利器`JavaScriptCore`框架,框架让Objective-C和JavaScript代码直接的交互变得更加的简单方便。该框架其实只是基于webkit中以C/C++实现的JavaScriptCore的一个包装。其本身是可以单独作为一个开发库来使用，框架中有完整的数据计算逻辑，今天只讲H5与本地交互，所以不作涉及，有兴趣可以参考:[iOS7新JavaScriptCore框架入门介绍](http://blog.iderzheng.com/introduction-to-ios7-javascriptcore-framework/)。

JavaScriptCore提供了很多灵活的本地OC与JS的交互方式，通过`JSContext`和`JSValue`来完成的，JSContext是一个WebView中js代码运行环境，所有的JS交互都要通过`- (JSValue *)evaluateScript:(NSString *)script;`方法就可以执行一段JavaScript脚本。

JSValue则可以说是JavaScript和Object-C之间互换的桥梁，它提供了多种方法可以方便地把JavaScript数据类型转换成Objective-C.

具体如何交互我们先来看一段H5代码:

```
<!DOCTYPE html>
<html>
    <head>
        <title>测试iOS与JS之前的互调</title>
        <style type="text/css">
            * {
                font-size: 40px;
            }
        </style>
        <script type="text/javascript">
            function showAppAlertMsg(message){
                alert(message);
            }
        </script>
    </head>
    <body>
        <div style="margin-top: 100px">
            <h1>Test how to use objective-c call js</h1>
            <input type="button" value="Call ObjC system camera" onclick="callSystemCamera()">
                <input type="button" value="Call ObjC system alert" onclick="showAlertMsg('js title', 'js message')">
        </div>
        
        <div>
            <input type="button" value="Call ObjC func with JSON " onclick="callWithDict({'name': 'testname', 'age': 10, 'height': 170})">
                <input type="button" value="Call ObjC func with JSON and ObjC call js func to pass args." onclick="jsCallObjcAndObjcCallJsWithDict({'name': 'testname', 'age': 10, 'height': 170})">
        </div>
        
        <div>
            <span id="jsParamFuncSpan" style="color: red; font-size: 50px;"></span>
        </div>
    </body>
</html>
```

我们可以看出其中H5实现的JS代码如下:

```
<script type="text/javascript">
	function showAppAlertMsg(message){
		alert(message);
	}
</script>
```
函数`showAppAlertMsg`是H5实现可以由我们本地主动调用的。那么相对应的H5主动调用的方法是:

```
<input type="button" value="Call ObjC system camera" onclick="callSystemCamera()">
```
其中`callSystemCamera()`是H5调用的函数，我们可以看到在HTML代码中是找不到这个函数的实现的，因为这个函数是需要我们本地去实现。

接下来我们就讲一下我们本地如何调用由H5实现的函数`showAppAlertMsg`,本地如何实现能够右H5端调用的方法:

1.在页面加载完成之后获取JS运行环境JSContext

```
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	JSContext *jsContext = [webView 	valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
}
```
2.利用`evaluateScript`声明函数并传递参数执行代码

```
    JSValue *jsValue = [jsContext evaluateScript:@"showAppAlertMsg"];
    [jsValue callWithArguments:@[@"这是app本地交互文案"]];
```

第一行代码是声明一个函数`showAppAlertMsg`，第二行是传递参数并执行代码`callWithArguments`.

以上是主动调用H5实现的函数，也可以称之为传递数据给H5。

本地实现能够让H5调用的函数:

```
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
```

一目了然，通过Block传递参数和方法。


上面是利用JavaScriptCore的最基本的方法实现JS调用，还有另外一种方案利用`JSExport协议`进行交互.其实可以理解为通过JSExport协议实现一种把本地的实例绑定为H5中的一个对象，通过这个对象调用本地实例方法的一种交互设计。
该设计在H5端与上面的是不一样的：

```
   <input type="button" value="Call ObjC system camera" onclick="OCModel.callSystemCamera()">
   <input type="button" value="Call ObjC system alert" onclick="OCModel.showAlertMsg('js title', 'js message')">
```
我们会发现 与之前的H5代码相比 多了一个 `OCModel`,这个在JS中可以理解为一个对象，点击按钮之后调用对象OCModel中的函数OCModel.callSystemCamera,那么该对象如何由本地绑定呢。

1.首先声明一个JSExport协议,该协议需要声明刚才H5中的函数:

```
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JavaScriptObjectiveCDelegate <JSExport>

// JS调用此方法来调用OC的系统相册方法
- (void)callSystemCamera;
// 在JS中调用时，函数名应该为showAlertMsg(arg1, arg2)
// 这里是只两个参数的。
- (void)showAlert:(NSString *)title msg:(NSString *)msg;
// 通过JSON传过来
- (void)callWithDict:(NSDictionary *)params;
// JS调用Oc，然后在OC中通过调用JS方法来传值给JS。
- (void)jsCallObjcAndObjcCallJsWithDict:(NSDictionary *)params;

@end
```


2.新建一个类，该类实现上面的协议

```
@interface NLJsObjCModel : NSObject <JavaScriptObjectiveCDelegate>
@property (nonatomic, weak) JSContext *jsContext;
@property (nonatomic, weak) UIWebView *webView;
@end
```

实现文件:

```
#import "NLJsObjCModel.h"

@implementation NLJsObjCModel

- (void)callWithDict:(NSDictionary *)params {
    NSLog(@"Js调用了OC的方法，参数为：%@", params);
}

// Js调用了callSystemCamera
- (void)callSystemCamera {
    NSLog(@"JS调用了OC的方法，调起系统相册");
    
    // JS调用后OC后，又通过OC调用JS，但是这个是没有传参数的
    JSValue *jsFunc = self.jsContext[@"jsFunc"];
    [jsFunc callWithArguments:nil];
}

- (void)jsCallObjcAndObjcCallJsWithDict:(NSDictionary *)params {
    NSLog(@"jsCallObjcAndObjcCallJsWithDict was called, params is %@", params);
    
    // 调用JS的方法
    JSValue *jsParamFunc = self.jsContext[@"jsParamFunc"];
    [jsParamFunc callWithArguments:@[@{@"age": @10, @"name": @"lili", @"height": @158}]];
}

- (void)showAlert:(NSString *)title msg:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [a show];
    });
}
@end
```

3.将NLJsObjCModel实例对象绑定到JS中:

```
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
}
```

到此结束，H5按钮点击之后就可以通过JSExport协议传递跟本地对象，本地对象就能收到相应。


###WKWebView的交互使用

...未完待续

