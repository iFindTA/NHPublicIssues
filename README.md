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
##### **证书显示：此证书的签发者无效**