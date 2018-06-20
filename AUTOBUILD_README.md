# CrProjs_Autobuild.sh Direction 
## iOS产品线-多项目自定义-自动编译打包脚本使用说明

> The Latest Edited Date: 2018/06/20 15:00
>
> 本说明旨在为当前目录下autobuild.sh脚本的日常使用与维护尽可能的提供指导与帮助。
> 如需维护或新增项目支持，建议通读本文档和脚本文件，特别是【(二)脚本解析】章节。
> 如需在新项目中使用该脚本，务必详细参阅【(二)脚本讲解】-【配置依赖】章节。
> 如需在当前项目组直接使用该脚本，请直接参阅【(一)使用说明】-【参数组合】章节，根据具体需求复制粘贴即可。

[TOC]

### (一) 使用说明
#### 帮助提示
```shell
usage: sh autobuild.sh -d <dirName> -e <env> -m <method> -p -f -b
example: sh autobuild.sh -d CRSample -e uat -m adhoc -pfb

[-d <dirName>] This's the folder name for the target project.
Required option. Please enter the correct folder name.

[-e <env>] This's the option to select the interface environment.
    prod    => Prod API Env
    uat     => UAT API Env
    dev     => Dev API Env
Required option. Please enter the correct option.

[-m <method>] This's the option to select the deployment method option.
    appstore    => App Store Deployment
    adhoc       => Ad Hoc Deployment
    dev         => Development Deployment
Required option. Please enter the correct option.

[-p] This's the switch to control whether or not to run `pod install`.
Optional option. This option does't require parameters.

[-i] This's the switch to control whether or not to increment build number with "appstore" mode.
Optional option. This option does't require parameters.

[-f] This's the switch to control whether or not to run `fir publish`.
Optional option. This option does't require parameters.

[-b] This's the switch to control whether or not to backup the .ipa file.
Optional option. This option does't require parameters.
```

#### 参数说明
本节【帮助提示】中提到了运行脚本的参数，其中

| 参数 | 必传/选传 | 支持选项 | 描述 | 
| :---: | :-----: | :---------: | :---------: | 
| -d | ==必传== | 任意字符串 | 项目根目录文件夹名称 | 
| -e | ==必传== | prod, uat, dev | 项目的接口环境 | 
| -m | ==必传== | appstore, adhoc, dev | 项目的打包方式 | 
| -p | 选传 | - | 是否执行Pod安装，默认不执行 | 
| -i | 选传 | - | 是否执行buildNo.自增(仅appstore模式下生效)，默认不执行 | 
| -f | 选传 | - | 是否执行Fir发布，默认不执行 | 
| -b | 选传 | - | 是否备份出包文件，默认不执行 | 

#### 参数组合
脚本的[-d]、[-e]、[-m]不同传参组合可以编译出不同的ipa文件，但限于对配置的依赖及团队的某些需求，当前仅支持特定的组合才能顺利的完成编译并出包。具体依赖及如何修改参见【脚本解析】章节。
**特定要求对应的参数组合：**
```shell
# 测试包：
$ sh autobuild.sh -d CRSample -e uat -m dev -f
# 预发布包：
$ sh autobuild.sh -d CRSample -e prod -m adhoc -f
# 生产包：
$ sh autobuild.sh -d CRSample -e prod -m appstore -p
```
(PS: 由于非生产接口服务端不触发生产环境的极光推送，以及出于生产环境推送安全考虑，测试环境测试包不能以AdHoc的形式而只能以Development的形式打包。)

#### 注意事项
若在Jenkins项目中使用该脚本，只需在项目配置-构建-Execute shell中该脚本的执行命令即可。
若在本地使用命令行执行脚本，需先前往脚本所在路径。
不论在Jenkins中或在本地使用该脚本，须保证设备已安装CocoaPods；如需使用[-f]，须保证设备已安装fir-cli。
以上工具的安装参见【(二)脚本讲解】-【配置依赖】。
由于脚本中实现了AppStore打包时build号自增并提交到svn远端仓库，所以设备必须支持svn命令或git-svn命令。

### (二) 脚本讲解

#### 配置依赖
##### 工具依赖
svn/git-svn, CocoaPods, fir-cli
设备必须支持svn命令或git-svn命令。
CocoaPods的安装不再赘述，fir-cli是fir提供的命令行客户端。其文档与安装方式如下：
[fir-cli GitHub](https://github.com/FIRHQ/fir-cli)
**安装fir-cli**
fir-cli 使用 Ruby 构建, 无需编译, 只要安装相应 gem 即可.
```shell
$ ruby -v # > 1.9.3
$ gem install fir-cli
```

##### 文件依赖
###### autoBuildInfo.plist
为了支持一个脚本文件进行多项目的自动编译与打包的功能，每个工程的详细参数由其目录下的plist文件提供。
其文件名应为：autoBuildInfo.plist
其位置应在工程根目录下。
其提供的信息包括且不限于：Target名称，Scheme名称，workspace名称，bundleID，证书名称，描述文件名称，ExportOptionsPlist路径……
注意：
1). 脚本对该文件有直接依赖，如需修改该文件的命名或路径，脚本代码及所有工程的该文件均须修改。
2). 所有ExportOptionsPlist路径Key对应的Value指的是相对工程根目录的路径。

###### ExportOptions
脚本通过xcodebuild执行打包工程的过程中，需要一份ExportOptionsPlist文件，不同的打包方式自然需要不同的ExportOptionsPlist。为此我们需要一个文件夹来存放这些ExportOptionsPlist文件。
其文件夹命名应为：ExportOptions
其位置应在工程根目录下。
其路径下至少应配置如下三个文件：
	ExportOptions_AdHoc.plist
	ExportOptions_AppStore.plist
	ExportOptions_Dev.plist
对于不同打包方式应使用哪个ExportOptionsPlist文件，请在上文提到的autoBuildInfo.plist中进行配置。
注意：
1). 脚本并不对该文件夹有直接依赖。但该文件夹的命名或位置，及其中的plist文件名如需修改，须同时更改autoBuildInfo.plist中的配置。

##### 工程依赖
###### Scheme & Configuration
为了使脚本支持一个项目可进行不同接口环境的自动编译与打包的功能，在项目中需要自定义配置Scheme与Configuration。
通过Scheme和Configuration命名后缀的不同以区分不同的接口环境、描述文件和证书。
所有Scheme命名保持相同的前缀，如：CRSample，并将前缀存储在autoBuildInfo.plist中。
后缀支持“_Prod”，“_UAT”，“_Dev”，以区分接口环境。
所有Configuration命名保持相同的前缀，如：Release，并将前缀存储在autoBuildInfo.plist中。
暂不支持Debug前缀。
后缀支持“_Prod”，“_UAT”，“”，以区分接口环境和打包方式(最后一个为空字符串即生产环境AppStore打包)。
不同的Configuration配置的证书与描述文件要与autoBuildInfo.plist和ExportOptionsPlist中的配置对应。

###### info.plist
工程的info.plist中需要添加两个Key，以在编译后的App内显示编译信息（编译时间，打包方式）。
两个Key分别为"CRAutoBuildDate"和"CRAutoBuildMethod"。
此外，还须注意info.plist的路径必须统一为，若有修改请统一并修改脚本:
```
[工程根目录]/[项目目录]/Info.plist
```

#### 执行流程
> 本节简介该脚本的执行流程。
> 首先提取输入的命令和参数。
> 然后判断[-d <dirName>]中proj的有效性及目录下的projAutoBuildInfo文件是否存在。
> 从projAutoBuildInfo文件中提取配置信息。
> 判断[-e <env>]的有效性，并拼接完整的schemeName和configurationName。
> 判断[-m <method>]的有效性，并匹配对应的methodName、证书、描述文件和ExportOptionsPlist文件。
> 前往工程根目录下（此处特别注意，后续的相对路径参数或命令均相对于此）。
> 从工程Info.plist中读出版本号和构建号。
> 如果需要自增且为AppStore打包方式，build号自增，并提交改动。
> 在工程Info.plist中写入编译打包的备注信息。
> 拼接编译与打包的路径和文件名。
> 如果需要pod操作，将执行`pod install`
> `xcodebuild clean`
> `xcodebuild archive`
> 置空上述步骤在工程Info.plist中写入的字段。
> `xcodebuild -exportArchive`
> 如果需要备份，将ipa文件以固定名称覆盖拷贝到固定路径。
> 如果需要fir发布，将ipa文件发布到fir平台。

### (三) 更新日志
> **v2.1.0**
> 原`[-p]`命令改为`[-d]`。
> 新增`[-p]`命令，以灵活控制是否执行`pod install`命令。
> 新增`[-i]`命令，以灵活控制正式包是否执行build号自增。

> **v2.0.2**
> 若为AppStore打包方式，build号自增，并提交改动。

> **v2.0.1**
> 优化命令非法提示。
> 新增`[-b]`命令，以支持打包成功后备份到特定路径以供自动化测试。
> 新增`[-h]`命令，以查看帮助文档，并优化帮助文档内容。
> xcodebuild 执行失败时增加提示并结束脚本。

> **v2.0.0**
> 多项目支持，不同项目的打包将工程根目录文件夹名称以参数的形式传递给脚本即可。
> 修改参数命令形式，以`$ sh autobuild.sh -p CRSample -e uat -m adhoc -f`替换原先的`$ sh autobuild.sh 1 2`传参形式。
> 新增`[-f]`命令，以灵活控制是否通过fir进行发布。
> 移除【debug】编译方式。
> 新增帮助文档，在命令非法时会自动提示。
> 接入`pod install`。

> **v1.0.0**
> 项目的自动编译打包。
> 通过传入不同的Number参数，以支持不同的接口环境，打包方式。
> 自动通过fir进行发布。

