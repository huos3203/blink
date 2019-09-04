### 安装pgyer插件
```
fastlane add_plugin pgyer
```
### 定制自己的lane swift版本:
```swift
//MARK: 发布到蒲公英平台
    //https://www.pgyer.com/doc/view/fastlane
    
    /// 发布到蒲公英平台
    /// - Parameter api_key: api_key 设置默认值
    /// - Parameter user_key: user_key 设置默认值
    /// - Parameter desc: 每次发布的描述信息
    func uploadPgyer(api_key: String? = "318c51ed714a80fxxxxxxx",
                user_key: String? = "5d4309fb86e31axxxxxxxx",
                    desc: String? = "update by fastlane") {
      let command = RubyCommand(commandID: "",
                                methodName: "pgyer",
                                className: nil,
                                args: [ RubyCommand.Argument(name: "api_key", value: api_key),
                                        RubyCommand.Argument(name: "user_key", value: user_key),
                                        RubyCommand.Argument(name: "update_description", value: desc)
                                      ]
                    )
      _ = runner.executeCommand(command)
    }
```
### 实现真机安装和上传至蒲公英平台
编译问题:https://github.com/blinksh/blink/issues/792#issue-488991461
解决办法: 从blink项目配置中移除`curl_ios_static.xcodeproj`的依赖,然后执行以下lane
```swift
    func personalLane() {
        desc("使用个人账号,实现真机运行")
        gym(scheme:"Blink",
                configuration: "Debug",
                 exportMethod: "development",
                 exportXcargs: "-allowProvisioningUpdates",
                 sdk: "iphoneos13.0")
        installOnDevice(deviceId: ipad, ipa: "Blink.ipa")
        uploadPgyer()
    }
```
### 蒲公英问题
使用personal teams证书,上传ipa包, 在pgyer证书页面显示两个设备可以安装.
但是,
1. 当其中一个手机扫描二维码下载安装之后,启动图标为灰色,点击启动图标无反应.
2. 另一个是ipad,在safari上点击“点击安装”提示不支持,iPad端安装.
