# Author By ZhangKr
# Script Version: 2.1.0
# The Latest Edited Date: 2018/06/20 15:00

# 注意：脚本文件应和项目文件夹在同一目录下/且工程中已配置好autoBuildInfo.plist和ExportOptions文件
# 执行文件Eg: sh autobuild.sh -d CRSample -e uat -m adhoc -pfb
# ⚠️注意：脚本中有一行切换路径的命令“cd ${projDirName}”，该命令执行后请确认所有相对路径的正确性

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 帮助文档 与 使用说明
helpTipD="[-d <dirName>] This's the folder name for the target project.
Required option. Please enter the correct folder name.\n"
helpTipE="[-e <env>] This's the option to select the interface environment.
    prod    => Prod API Env
    uat     => UAT API Env
    dev     => Dev API Env
Required option. Please enter the correct option.\n"
helpTipM="[-m <method>] This's the option to select the deployment method option.
    appstore    => App Store Deployment
    adhoc       => Ad Hoc Deployment
    dev         => Development Deployment
Required option. Please enter the correct option.\n"
helpTipP="[-p] This's the switch to control whether or not to run \`pod install\`.
Optional option. This option does't require parameters.\n"
helpTipI="[-i] This's the switch to control whether or not to increment build number with \"appstore\" mode.
Optional option. This option does't require parameters.\n"
helpTipF="[-f] This's the switch to control whether or not to run \`fir publish\`.
Optional option. This option does't require parameters.\n"
helpTipB="[-b] This's the switch to control whether or not to backup the .ipa file.
Optional option. This option does't require parameters.\n"
helpString="
usage: sh autobuild.sh -d <dirName> -e <env> -m <method> -p -f -b
example: sh autobuild.sh -d CRSample -e uat -m adhoc -pfb \n${helpTipD}\n${helpTipE}\n${helpTipM}\n${helpTipP}\n${helpTipI}\n${helpTipF}\n${helpTipB}"

# 参数
configurationPrefix="Release"
projAutoBuildInfo="autoBuildInfo.plist"

podInstall=false
incrementEnabled=false
backupIpaEnabled=false
firEnabled=false
nullValue=""

# 提取选项参数
while getopts 'd:e:m:pifbh' OPT;
do
    case $OPT in
        d)
        projDirName="$OPTARG";;
        e)
        apiEnv="$OPTARG";;
        m)
        method="$OPTARG";;
        p)
        podInstall=true;;
        i)
        incrementEnabled=true;;
        f)
        firEnabled=true;;
        b)
		backupIpaEnabled=true;;
		h)
		showHelp=true;;
        ?)
        echo "`basename $0`: Unrecognized commands. See 'sh `basename $0` -help'."
        exit 1;;
    esac
done

if [ $showHelp ]
then
	echo "$helpString"
	exit 0
fi

# 选项参数判断 —— [-d <dirName>]
# 判读用户是否有输入
if [ -n "$projDirName" ]
then
    if [ -d "./${projDirName}" ] && [ -f "./${projDirName}/${projAutoBuildInfo}" ]
    then
    	# 提取项目参数及配置
        buildPlist=./${projDirName}/${projAutoBuildInfo}
        projectName=$(/usr/libexec/PlistBuddy -c "Print :projectName" "${buildPlist}")
        schemeNamePrefix=$(/usr/libexec/PlistBuddy -c "Print :schemeNamePrefix" "${buildPlist}")
        workspaceName=$(/usr/libexec/PlistBuddy -c "Print :workspaceName" "${buildPlist}")
        bundleID=$(/usr/libexec/PlistBuddy -c "Print :bundleID" "${buildPlist}")
        firToken=$(/usr/libexec/PlistBuddy -c "Print :firToken" "${buildPlist}")
        AppStore_CodeSignIdentity=$(/usr/libexec/PlistBuddy -c "Print :AppStore_CodeSignIdentity" "${buildPlist}")
        AppStore_ProvisioningProfileName=$(/usr/libexec/PlistBuddy -c "Print :AppStore_ProvisioningProfileName" "${buildPlist}")
        AppStore_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :AppStore_ExportOptionsPlist" "${buildPlist}")
        AdHoc_CodeSignIdentity=$(/usr/libexec/PlistBuddy -c "Print :AdHoc_CodeSignIdentity" "${buildPlist}")
        AdHoc_ProvisioningProfileName=$(/usr/libexec/PlistBuddy -c "Print :AdHoc_ProvisioningProfileName" "${buildPlist}")
        AdHoc_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :AdHoc_ExportOptionsPlist" "${buildPlist}")
        Dev_CodeSignIdentity=$(/usr/libexec/PlistBuddy -c "Print :Dev_CodeSignIdentity" "${buildPlist}")
        Dev_ProvisioningProfileName=$(/usr/libexec/PlistBuddy -c "Print :Dev_ProvisioningProfileName" "${buildPlist}")
        Dev_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :Dev_ExportOptionsPlist" "${buildPlist}")
    else
        echo "[-d <dirName>]参数无效...."
        echo "请检查项目文件夹名称以及文件夹中是否存在${projAutoBuildInfo}文件...."
        echo "$helpTipD"
        exit 1
    fi
else
    echo "未输入[-d <dirName>]参数...."
    echo "$helpTipD"
    exit 1
fi

# 选项参数判断 —— [-e <env>]
# 判读用户是否有输入
if [ -n "$apiEnv" ]
then
    if [ "$apiEnv" == "prod" ]
    then
# 生产环境
        schemeNameSuffix="_Prod"
        configurationSuffix="_Prod"
    elif [ "$apiEnv" == "uat" ]
    then
# 测试环境
        schemeNameSuffix="_UAT"
        configurationSuffix="_UAT"
    elif [ "$apiEnv" == "dev" ]
    then
# 开发调试环境
        schemeNameSuffix="_Dev"
        configurationSuffix="_Dev"
    else
        echo "[-e <env>]参数无效...."
        echo "$helpTipE"
        exit 1
    fi
else
    echo "未输入[-e <env>]参数...."
    echo "$helpTipE"
    exit 1
fi

# 选项参数判断 —— [-m <method>]
# 判读用户是否有输入
if [ -n "$method" ]
then
    if [ "$method" == "appstore" ]
    then
        if [ "$apiEnv" == "prod" ]
        then
# AppStore脚本
            methodName="AppStore"
            configurationSuffix=""
            CODE_SIGN_IDENTITY=${AppStore_CodeSignIdentity}
            PROVISIONING_PROFILE_NAME=${AppStore_ProvisioningProfileName}
            EXPORT_OPTIONS_PLIST=${AppStore_ExportOptionsPlist}
            # appStore的打包方式没有备份和Fir发布的必要
            backupIpaEnabled=false
            firEnabled=false
        else
            echo "选择[-m appstore]时, 必须符合[-e prod]...."
            echo "$helpString"
            exit 1
        fi
    elif [ "$method" == "adhoc" ]
    then
# AdHoc脚本
        methodName="AdHoc"
        CODE_SIGN_IDENTITY=${AdHoc_CodeSignIdentity}
        PROVISIONING_PROFILE_NAME=${AdHoc_ProvisioningProfileName}
        EXPORT_OPTIONS_PLIST=${AdHoc_ExportOptionsPlist}
    elif [ "$method" == "dev" ]
    then
# 开发打包脚本
        methodName="Development"
        CODE_SIGN_IDENTITY=${Dev_CodeSignIdentity}
        PROVISIONING_PROFILE_NAME=${Dev_ProvisioningProfileName}
        EXPORT_OPTIONS_PLIST=${Dev_ExportOptionsPlist}
    else
        echo "[-m <method>]参数无效...."
        echo "$helpTipM"
        exit 1
    fi
else
    echo "未输入[-m <method>]参数...."
    echo "$helpTipM"
    exit 1
fi

# # 检查autoBuildInfo.plist
# echo "Get the build info from the plist.
#     projectName = ${projectName}
#     schemeNamePrefix = ${schemeNamePrefix}
#     workspaceName = ${workspaceName}
#     bundleID = ${bundleID}
#     firToken = ${firToken}
#     AppStore_CodeSignIdentity = ${AppStore_CodeSignIdentity}
#     AppStore_ProvisioningProfileName = ${AppStore_ProvisioningProfileName}
#     AppStore_ExportOptionsPlist = ${AppStore_ExportOptionsPlist}
#     AdHoc_CodeSignIdentity = ${AdHoc_CodeSignIdentity}
#     AdHoc_ProvisioningProfileName = ${AdHoc_ProvisioningProfileName}
#     AdHoc_ExportOptionsPlist = ${AdHoc_ExportOptionsPlist}
#     Dev_CodeSignIdentity = ${Dev_CodeSignIdentity}
#     Dev_ProvisioningProfileName = ${Dev_ProvisioningProfileName}
#     Dev_ExportOptionsPlist = ${Dev_ExportOptionsPlist}
# "

schemeNameIntact="${schemeNamePrefix}${schemeNameSuffix}"
configurationIntact="${configurationPrefix}${configurationSuffix}"

echo "————————————————————— 确认 ——————————————————————"
echo "Scheme         : ${schemeNameIntact}"
echo "Configuration  : ${configurationIntact}"
echo "Deployment     : ${methodName}"
echo ""
# echo "—————————————————————————————————————————————————"

# # if used SVN
# if [ -d ".svn" ]
#         then
#         svn upgrade
# fi

# 编译与打包
cd ${projDirName}
# 执行这行代码过后，以下路径均是相对项目文件夹的

# 读取版本号
infoPlist=./${workspaceName}/Info.plist
projVersion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${infoPlist}")
projBuild=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${infoPlist}")
if [ "$method" == "appstore" ] && [ $incrementEnabled == true ]
then
    # 若为AppStore，build自增
    projBuild=`expr $projBuild + 1`
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${projBuild}" "${infoPlist}"
    commitLog="[AutoBuild] Build number increment by script. [${schemeNamePrefix}] Build: ${projBuild}"
    # if used Git
    if [ -d "../.git" ]
        then
        git add ${infoPlist}
        git commit -m "${commitLog}"
        git push origin production
    fi
    # # if used SVN
    # if [ -d "../.svn" ]
    #     then
    #     svn commit -m "${commitLog}" ${infoPlist}
    # elif [ -d "../.git" ]
    #     then
    #     git add ${infoPlist}
    #     git commit -m "${commitLog}"
    #     git svn dcommit --rmdir
    # fi
    echo "___${commitLog}"
fi

# 导出.ipa文件命名时拼接时间
autoBuildDate=`date +"%y%m%d%H"`
if [ "$method" != "appstore" ]
then
    # App内提示打包时间 / 打包方式
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildDate ${autoBuildDate}" "${infoPlist}"
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildMethod ${method}" "${infoPlist}"
else
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildDate ${nullValue}" "${infoPlist}"
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildMethod ${nullValue}" "${infoPlist}"
fi
# Build与出包路径
exportName="${schemeNameIntact}_${configurationPrefix}_${methodName}_v${projVersion}_${projBuild}_${autoBuildDate}"
exportDir="../../iOS-Build"
if [ "$method" == "appstore" ]
then
    # AppStore包出包路径
    archivePath="${exportDir}/AppStore"
    ipaPath="${exportDir}/AppStore"
else
    # 任何测试包出包路径
    archivePath="${exportDir}/${schemeNamePrefix}"
    ipaPath="${exportDir}/${schemeNamePrefix}"
fi

# 执行pod install
if [ $podInstall == true ]
then
    echo "——————————————— running <pod install> ————————————————"
    pod install
fi

xcodebuild clean -workspace ${workspaceName}.xcworkspace \
                 -scheme ${schemeNameIntact} \
                 -configuration ${configurationIntact} \

xcodebuild archive -workspace ${workspaceName}.xcworkspace \
                   -scheme ${schemeNameIntact} \
                   -configuration ${configurationIntact} \
                   -archivePath ${archivePath}/${exportName}.xcarchive archive build \
                   CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
                   PROVISIONING_PROFILE="${ROVISIONING_PROFILE_NAME}" \
                   PRODUCT_BUNDLE_IDENTIFIER="${bundleID}"

# 还原Info.plist
if [ "$method" != "appstore" ]
then
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildDate ${nullValue}" "${infoPlist}"
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildMethod ${nullValue}" "${infoPlist}"
fi

if [ ! -e "${archivePath}/${exportName}.xcarchive" ]
then
    echo "Current Path: $(pwd)"
    echo "Not found the archive file: ${archivePath}/${exportName}.xcarchive"
    exit 1
fi

xcodebuild -exportArchive -archivePath ${archivePath}/${exportName}.xcarchive \
                          -exportOptionsPlist ${EXPORT_OPTIONS_PLIST} \
                          -exportPath ${ipaPath}/${exportName}
if [ ! -e "${ipaPath}/${exportName}/${schemeNameIntact}.ipa" ]
then
    echo "Current Path: $(pwd)"
    echo "Not found dir: ${ipaPath}/${exportName}/${schemeNameIntact}.ipa"
    exit 1
fi

# 拷贝ipa文件到固定目录，以供自动化测试
if [ $backupIpaEnabled == true ]
then
	echo "——————————————— 正在备份.ipa文件 ————————————————"
	backupPath="${exportDir}/Latest/${schemeNamePrefix}"
	rm -rf "${backupPath}"
	mkdir -p "${backupPath}"
	cp -R -f -p "${ipaPath}/${exportName}/${schemeNameIntact}.ipa" \
			"${backupPath}/${schemeNamePrefix}.ipa"
fi

# 上传至fir
if [ $firEnabled == true ]
then
    firChangeLog="${exportName} \n\nUploaded by cr plugin"
    export LANG=en_US
    export LC_ALL=en_US;
    echo "——————————————— 正在上传到fir.im ————————————————"
    fir login ${firToken}
    fir publish ${ipaPath}/${exportName}/${schemeNameIntact}.ipa --changelog=${firChangeLog}
fi
