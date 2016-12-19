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
##### **真机测试报错：The identity used to sign the executable is no longer valid.**
Please verify that your device’s clock is properly set, and that your signing certificate is not expired.
```
1、restart Xcode if not working then continue；
2、Go to Accounts in Xcode (in preferences), Details for developer account then clicking the refresh icon at lower left；
3、if there were not refresh icon then delete the team provisioning profile who was dulplicate or delete all team provisioning profile and download them for new.
```

##### **ld: library not found for -lPods**
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```
project navigation->framework-delete lib-Pods.a(if its color is red)
```

##### **library not found for -lPods-AFNetworking**
```
1.Go to project setting -> build setting -> other linker flag, and remove all flags that have -lpod or frameworks or related to pods. Don't remove the required flags (e.g. -ObjC, -licucore, -libxml2)
2.Add a flag $(inherited) at the top.
3.Clean the project and compile.
```

##### **lPods某一类库 报Undefined symbols for architecture armv7:**
```
＊原因：很有可能你在开发时选中的编译版本为arm64或其他非armv7平台
＊解决：在project navigation界面选中pod project，build setting里的Valid Architectures 增加你要的版本 then clean&&build即可
```

##### **Xcode编译时注意strip**
```
build setting->strip->
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

##### **Cycript运行时工具的简单使用**
```
安装：
[官方网站](https://cycript.org/)下载完之后是framework，可以使用在仅使用在自己的应用里，在非越狱设备上可以hook自己的应用进程有相应的[介绍](http://lldong.github.io/2014/03/03/embed-cycript-into-your-app-for-debugging.html),不再赘述
[文件下载](http://www.cycript.org/debs/)后的越狱[安装方式](http://blog.csdn.net/sakulafly/article/details/29633627)：
1- 使用cydia安装openSSH确保可以登录到越狱设备,使用SFTP上传下载好的cycript_0.9.501_iphoneos-arm.deb和libffi_1-3.0.10-5_iphoneos-arm.deb安装包到iOS设备上
2- sftp root@IP输入后会要求输入password（默认alpine），链接成功后执行：
sftp> put cycript_0.9.501_iphoneos-arm.deb完成后，同样方式上传另一个文件，ctrl＋d结束。
3- 使用dpkg -i 安装：
ssh root@IP登录，查看是否上传成功，执行：
ls
dpkg -i cycript_0.9.501_iphoneos-arm.deb
同样安装另一个文件 
结束安装
4- 运行cycript 如果出现cy＃符号说明成功：
cycrypt
ctrl＋D结束

用法：
cycript的用法上主要是注入你关注的那个应用的线程，然后就可以获得app，获得window，慢慢去获得viewController，逐步逐步拨开UI的面纱，这个在学习经典应用的UI时真的是无上的利器！
1- 打开设备（越狱）运行相关app，以GSLC为例
2- 打开终端SSH登录设备，执行：
iPhone5s:/ root# ps aux | grep GSLC
得到如下：
mobile     479   0.6  4.3   590776  44956   ??  Ss    5:14PM   0:09.58 /var/mobile/Applications/8723004E-9E54-4B37-856D-86292780E958/GSLC.app/GSLC  
root       497   0.0  0.0   329252    176 s000  R+    5:21PM   0:00.00 grep GSLC 
其中479即为进程号，接着：
cycript -p 479 
如果出现cy# 说明依附成功，可依据相关语法追踪、控制了。
UIApp是默认命令，变量赋值可采取KVC方式
Tips:如果报错（MS:Error: _krncall(task_for_pid(self, pid, &task)) =5）挂钩进程名字即可成功
```

```
function printsMethod(m){
	var count = new new Type("I");
    var methods = class_copyMethodList(objc_getClass(m),count);
    var methodsArr = [];
    for(var i = 0;i < *count;i++){
    	var method = methods[i];
 methodsArr.push({selector:method_getName(method),imp:method_getImplementation(method)});
    }
    free(methods);
    free(count);
	return methodsArr;
}
```

##### **Class-dump-z相关**
```
[安装](http://itony.me/200.html)：
class-dump大概有三个版本（它们之间的区别和详细介绍在此），我们[直接下载class-dump-z 0.2a](https://code.google.com/archive/p/networkpx/wikis/class_dump_z.wiki)，解压后将mac_x86目录中的class-dump-z程序文件拷贝至/usr/local/bin目录。这样就算安装完成啦。
使用：以GSLC为例
使用iFunBox进入到程序GSLC.app文件内,可以看到有个相同名字的文件，这个就是编译之后的主程序，拷贝到桌面，打开终端，进入桌面，执行：
class-dump-z GSLC
可以看到输出了一大推信息，不过都是加密的，所以需要解密，会使用到工具Clutch。
Clutch的安装：
首先越狱机器已经准备好了，使用Cydia搜索并安装Clutch（注：现在Cydia已经下载不到了，需要我们自己下载程序后通过sftp上传到设备，[Clutch下载地址](https://github.com/KJCracks/Clutch/releases)）
1- 打开设备Cydia下载终端Terminal和iFile
2- ssh到设备 sftp上传Clutch文件，ifile打到usr/bin/clutch这个文件修改权限，把用户、组、全局权限的前三项全打钩
3- 打开 MobileTerminal 输入“su”，此时提示要输入密码(默认“alpine”)
4- 按照Clutch git上的指引，输入 Clutch -i,可看到行交替颜色的程序出现，假如GSLC序号为3，还有bundleid:com.xxx.xxx
5- 执行：Clutch -d com.xxx.xxx即可生成解密的ipa文件，根据路径找到它并拷贝到桌面
6- 再次执行 class-dump-z GSLC 就可以看到你想要的！

至此你已经可以查看到你想看的App的头文件声明了！
```
##### **简单的防止系统键盘缓存方法**
```
UITextFiled *textFiled = [[UITextField alloc]initWithFrame:frame];
textFiled.autocorrectionType = UITextAutocorrectionTypeNo
```

##### **应用进入后台的时候应该清除剪贴板**
```ObjectiveC
- (void)applicationDidEnterBackground:(UIApplication *)application
{
// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
[UIPasteboard generalPasteboard].items = nil;
}
```

##### **JSPatch、ReactNative使用注意点**
```
由于JS具有很高的执行权限，所以要注意验证签名，防止恶意加载
```

##### **图片格式的选择**
```
真对上行下行中图片资源文件较多的情况可以采取webp格式去传输。
```

##### **Python Flask全局安装（非virtualenv）**
```
shell环境下pip管理安装，执行shell：
sudo easy_install pip
安装好之后再安装Flask，执行shell：
sudo pip install flask
即可
```

##### **Development Commands**
```
1，homebrew 用于管理其他安装包
2，cocoaPods 
3，curl 模拟网络请求
4，cycript class-dump-z
5，ideviceinstaller／usb／plist／mobiledevice
6，rar（homebrew）
7，shenzhen ipa command
8，pip management Python‘s packages
9，snoop-it 追踪方法调用（阻止依附）
10，Jenkins CI（homebrew）
```

##### **Development Kit Sets**
```
1,Xcode
2,Android Studio
3,Google:Chrome,PostMan,WireShark,Thunder [ShadowSocks](https://portal.shadowsocks.com/clientarea.php)
4,GitHub Desktop,SourceTree,Sublime Text,Haroopad/MacDown
5,Xmind,Axure RP,Sketch Gif Brewery
6,Window Offices
```

##### **开发中可公用的类或方法**
```
1，设置页面可以模版提取
2，搜索页面可以模版提取
3，登录、注册、找回登录（交易密码）页面可以模版提取
```

```ObjectiveC
	[self.navigationController.navigationBar setHidden:YES];//--doesn't remove pop gesture

	[self.navigationController setNavigationBarHidden:YES];//-- disables pop gesture
```

##### **同一布局页面从不通Navigation push高度不一致**
```
注意不通UINavigationBar的translucent属性是否设置一致
```

##### **检测IDFA**
```
	grep -r advertisingIdentifier .
```

##### **CocoaPods Issues**
```
1,rm ~/Library/Caches/CocoaPods/search_index.json
```

###### **Dev Tips**
```
1,sqlite insert failed:
	a>,field declared to non-null but insert value was nil!
2,zh_hans white placeholder :\u3000
3,[NSThread sleepForTimeInterval:]; whatever u should must be careful to use it!cause of it will block all tread include the main thread! if neccesory to use, just follow down:
dispatch_queue_t queue = dispatch_queue_create(“com.thread.queue”, NULL);
dispatch_async(queue, ^{
	[NSThread sleepForTimeInterval:];
	//TODO: something
});
```