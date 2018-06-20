# Cr-iOS-AutoBuild 打造灵活易用的iOS自动打包脚本工具
首先在此感谢飞腾和永胜在初版实现时给予的帮助与指导，以及小清同学提出的后续优化扩展建议。
- - -
随着公司技术团队的日益壮大和产品线项目的日渐繁多，CI 与 DailyBuild 就被提上了日程。
本人最终采取的解决方案是：Jenkins + Shell脚本。Jenkins 负责定时触发和拉代码，脚本负责其他一切功能。脚本投入使用的四个月中，进行了一定的扩展与优化，现开源给有需要的同学们，大家一同成长。

本工程只为展示脚本工具 autobuild.sh ，CRSampleA 和 CRSampleB 只是提供依赖设置的模板样例。脚本说明参见 [AUTOBUILD_README.md](https://github.com/ZhangCrow/Cr-iOS-AutoBuild/blob/master/AUTOBUILD_README.md)。实际使用中须注意 autobuild.sh 中的各种路径，以及 autoBuildInfo.plist 及各种ExportOptions.plist 中的描述文件与证书的正确配置。

不同公司不同项目会有不同需求，所以该脚本只是提供思路与模板，对于我司产品线，当前脚本支持的功能(命令参数)有：

| 参数 | 必传/选传 | 支持选项 | 描述 | 
| :---: | :-----: | :---------: | :---------: | 
| -d | ==必传== | 任意字符串 | 项目根目录文件夹名称 | 
| -e | ==必传== | prod, uat, dev | 项目的接口环境 | 
| -m | ==必传== | appstore, adhoc, dev | 项目的打包方式 | 
| -p | 选传 | - | 是否执行Pod安装，默认不执行 | 
| -i | 选传 | - | 是否执行buildNo.自增(仅appstore模式下生效)，默认不执行 | 
| -f | 选传 | - | 是否执行Fir发布，默认不执行 | 
| -b | 选传 | - | 是否备份出包文件，默认不执行 | 

只需要在出包机器的终端，Jenkins或其他持续集成平台中插入脚本即可。
```
# sh autobuild.sh -d 项目根文件夹名称 -e 接口环境 -m 打包方式 -p(podInstall) -i(buildNo.自增) -b(执行备份) -f(Fir发布)
# 测试包：
$ sh autobuild.sh -d CRSample -e uat -m dev -fb
# 预发布包：
$ sh autobuild.sh -d CRSample -e prod -m adhoc -fb
# 生产包：
$ sh autobuild.sh -d CRSample -e prod -m appstore -pi
```
此外配合项目代码，可实现App内友好的环境版本信息展示，例如：
```
v1.0.1.15_debug_envdev             // 开发　: 开发环境 Debug编译运行
v1.0.1.15_envuat_dev_18031022      // 测试　: 测试环境 Development方式打包
v1.0.1                             // 发布　: 生产环境 AppStore方式打包
```

出于一些历史原因和公司代码托管规定，产品线多个项目代码只能在一个 SVN 仓库的一条分支下，并且项目差异化也无法通过多 Target 进行管理，所以有了如上功能的打包脚本。但总之，只有想不到，没有做不到。对于其他需求或不同的工程项目结构，完全可以修改为单一脚本支持传入项目根文件夹路径而非文件夹名称，多 Target 区分等功能，诸如此类。

第一次出于开源的目的上传代码，望轻拍~

**🎊以上 施工完毕🎉干杯🍻**


