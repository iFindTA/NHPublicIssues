# The Public Issues
#### the public issues for ios developers

****
##### **证书显示：此证书的签发者无效**
```
1、删除过期的AppleWWDRCA.cer证书（->登录->所有->搜索）；
2、通过https://developer.apple.com/certificationauthority/AppleWWDRCA.cer重新下载并安装（若不行则执行3、4步骤）；
3、右键证书简介，信任里面选择始终信任；
4、重启Xcode(最彻底的重启电脑).
```
~关于数据、程序安全的相关考虑，网上有相关资料，这里仅作筛选整理~
##### **static和被裁的符号表**
```
为了不让攻击者理清自己程序的敏感业务逻辑，于是我们想方设法提高逆向门槛
原理：
如果函数属性为 static ，那么编译时该函数符号就会被解析为local符号。
在发布release程序时（用Xcode打包编译二进制）默认会strip裁掉这些函数符号，无疑给逆向者加大了工作难度
eg：
id createBtn()  
{  
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectZero];  
    [btn setFrame:CGRectMake(200, 100, 100, 100)];  
    [btn setBackgroundColor:[UIColor redColor]];  
    btn.layer.cornerRadius = 7.0f;  
    btn.layer.masksToBounds = YES;  
    return btn;  
}  
  
static id static_createBtn()  
{  
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectZero];  
    [btn setFrame:CGRectMake(50, 100, 100, 100)];  
    [btn setBackgroundColor:[UIColor blueColor]];  
    btn.layer.cornerRadius = 7.0f;  
    btn.layer.masksToBounds = YES;  
    return btn;  
}  
局限：
当然这种方法也有局限性。正如你所知道的，static函数，只在本文件可见。
解决办法：
怎么让别的文件也能调到本文件的static方法呢？
在本文件建造一个结构体，结构体里包含函数指针。把static函数的函数指针都赋在这个结构体里，再把这个结构体抛出去。
这样做的好处是，既隐藏了函数代码也丰富了调用方式。
```

##### **敏感逻辑的保护方案**
```
Objective-C代码容易被hook，暴露信息太赤裸裸，为了安全，改用C来写吧！当然不是全部代码都要C来写，指的是敏感业务逻辑代码。
这里介绍一种低学习成本的，简易的，Objective-C逻辑代码重写为C代码的办法，也许，程序中存在一个类似这样的类：
@interface XXUtil : NSObject  
  
+ (BOOL)isVerified;  
+ (BOOL)isNeedSomething;  
+ (void)resetPassword:(NSString *)password;  
  
@end  
被class-dump出来后，利用Cycript很容易实现攻击，容易被hook，存在很大的安全隐患，想改，但是不想大改程序结构，肿么办呢？
把函数名隐藏在结构体里，以函数指针成员的形式存储。
这样做的好处是，编译后，只留了下地址，去掉了名字和参数表，提高了逆向成本和攻击门槛，改写的程序如下：
//XXUtil.h  
#import <Foundation/Foundation.h>  
  
typedef struct _util {  
    BOOL (*isVerified)(void);  
    BOOL (*isNeedSomething)(void);  
    void (*resetPassword)(NSString *password);  
}XXUtil_t ;  
  
#define XXUtil ([_XXUtil sharedUtil])  
  
@interface _XXUtil : NSObject  
  
+ (XXUtil_t *)sharedUtil;  
@end  
//XXUtil.m  
#import "XXUtil.h"  
  
static BOOL _isVerified(void)  
{  
    //bala bala ...  
    return YES;  
}  
  
static BOOL _isNeedSomething(void)  
{  
    //bala bala ...  
    return YES;  
}  
  
static void _resetPassword(NSString *password)  
{  
    //bala bala ...  
}  
  
static XXUtil_t * util = NULL;  
@implementation _XXUtil  
  
+(XXUtil_t *)sharedUtil  
{  
    static dispatch_once_t onceToken;  
    dispatch_once(&onceToken, ^{  
        util = malloc(sizeof(XXUtil_t));  
        util->isVerified = _isVerified;  
        util->isNeedSomething = _isNeedSomething;  
        util->resetPassword = _resetPassword;  
    });  
    return util;  
}  
  
+ (void)destroy  
{  
    util ? free(util): 0;  
    util = NULL;  
}  
@end  
最后，根据Xcode的报错指引，把以前这样的调用：
[XXUtil isVerified];
对应改成：
XXUtil->isVerified();就可以了。
```
##### **阻止GDB依附**
```
#import <dlfcn.h>  
#import <sys/types.h>  
  
typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);  
#if !defined(PT_DENY_ATTACH)  
#define PT_DENY_ATTACH 31  
#endif  // !defined(PT_DENY_ATTACH)  
  
void disable_gdb() {  
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);  
    ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");  
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);  
    dlclose(handle);  
}  
  
int main(int argc, charchar *argv[])  
{  
#ifndef DEBUG  
    disable_gdb();  
#endif  
    @autoreleasepool {  
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([WQMainPageAppDelegate class]));  
    }  
}  
```
##### **简单的防止系统键盘缓存方法**
```
UITextFiled *textFiled = [[UITextField alloc]initWithFrame:frame];
textFiled.autocorrectionType = UITextAutocorrectionTypeNo
```
##### **Cycript运行时工具的简单使用**
```
安装：
[官方网站](https://cycript.com)
```