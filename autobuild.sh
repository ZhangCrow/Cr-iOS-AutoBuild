# Author By ZhangKr
# Script Version: 2.3.4
# The Latest Edited Date: 2019/11/07 16:20

# 注意：脚本文件应和项目文件夹在同一目录下/且工程中已配置好autoBuildInfo.plist和ExportOptions文件
# 执行文件Eg: sh autobuild.sh -d HHSample -e uat -m adhoc -f -b
# ⚠️注意：脚本中有一行切换路径的命令“cd ${projDirName}”，该命令执行后请确认所有相对路径的正确性

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 帮助文档 与 使用说明
helpTipD="[-d <dirName>] 目标工程xcworkspace文件所在文件夹名称。
必填项，请输入正确的文件夹名称。\n"
helpTipT="[-t <targetFlag>] 所要读取的autoBuildInfo文件的标签(工程多Targets的场景)。
选填项，若未填，则会尝试读取\"autoBuildInfo.plist\"。\n"
helpTipE="[-e <env>] 选择接口环境。
    prod => 生产环境
    uat  => 测试环境
    dev  => 开发环境
必填项，请输入正确的选项名称。\n"
helpTipM="[-m <method>] 选择打包方式。
    appstore => App Store Deployment
    adhoc    => Ad Hoc Deployment
    dev      => Development Deployment
必填项，请输入正确的选项名称。\n"
helpTipU="[-u] 更新描述文件。
可选项，此选项不需要参数，使用此项即开启功能。\n"
helpTipP="[-p] 执行 \`pod install\`。
可选项，此选项不需要参数，使用此项即开启功能。\n"
helpTipI="[-i] 在选择\"appstore\"打包方式时启用build号自增。
可选项，此选项不需要参数，使用此项即开启功能。\n"
helpTipF="[-f] 出包成功后执行 \`fir publish\`。
可选项，此选项不需要参数，使用此项即开启功能。\n"
helpTipB="[-b] 出包成功后备份.ipa文件。
可选项，此选项不需要参数，使用此项即开启功能。\n"
helpString="
使用方式: \$sh autobuild.sh -d <dirName> -t <targetFlag> -e <env> -m <method> -p -f -b
举个例子: \$sh autobuild.sh -d HHSample -e uat -m adhoc -upfb
 \n${helpTipD} \n${helpTipT} \n${helpTipE} \n${helpTipM} \n${helpTipU} \n${helpTipP} \n${helpTipI} \n${helpTipF} \n${helpTipB}"

# 参数
configurationPrefix="Release"

useGitSvn=false
podInstall=false
updateMobileProvisionEnabled=false
incrementEnabled=false
backupIpaEnabled=false
firEnabled=false

# 提取选项参数
while getopts 'd:t:e:m:upifbh' OPT;
do
    case $OPT in
        d)
        projDirName="$OPTARG";;
        t)
        targetFlag="$OPTARG";;
        e)
        apiEnv="$OPTARG";;
        m)
        method="$OPTARG";;
        u)
        updateMobileProvisionEnabled=true;;
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

# 选项参数判断 —— [-t <targetFlag>]
# 判读用户是否有输入
if [ -n "$targetFlag" ]
then
    projAutoBuildInfo="autoBuildInfo_${targetFlag}.plist"
else
    projAutoBuildInfo="autoBuildInfo.plist"
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
        targetName=$(/usr/libexec/PlistBuddy -c "Print :targetName" "${buildPlist}")
        schemeNamePrefix=$(/usr/libexec/PlistBuddy -c "Print :schemeNamePrefix" "${buildPlist}")
        workspaceName=$(/usr/libexec/PlistBuddy -c "Print :workspaceName" "${buildPlist}")
        bundleID=$(/usr/libexec/PlistBuddy -c "Print :bundleID" "${buildPlist}")
        firToken=$(/usr/libexec/PlistBuddy -c "Print :firToken" "${buildPlist}")
        AppStore_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :AppStore_ExportOptionsPlist" "${buildPlist}")
        AdHoc_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :AdHoc_ExportOptionsPlist" "${buildPlist}")
        Dev_ExportOptionsPlist=$(/usr/libexec/PlistBuddy -c "Print :Dev_ExportOptionsPlist" "${buildPlist}")
    else
        echo "请检查[-d <dirName>]及[-t <targetFlag>]参数是否有效...."
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
        EXPORT_OPTIONS_PLIST=${AdHoc_ExportOptionsPlist}
    elif [ "$method" == "dev" ]
    then
# 开发打包脚本
        methodName="Development"
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

# 检查autoBuildInfo.plist
echo "—————————————— 确认 autoBuildInfo ———————————————
    buildPlist = ${buildPlist}
    projectName = ${projectName}
    targetName = ${targetName}
    schemeNamePrefix = ${schemeNamePrefix}
    workspaceName = ${workspaceName}
    bundleID = ${bundleID}
    firToken = ${firToken}
    AppStore_ExportOptionsPlist = ${AppStore_ExportOptionsPlist}
    AdHoc_ExportOptionsPlist = ${AdHoc_ExportOptionsPlist}
    Dev_ExportOptionsPlist = ${Dev_ExportOptionsPlist}
"

schemeNameIntact="${schemeNamePrefix}${schemeNameSuffix}"
configurationIntact="${configurationPrefix}${configurationSuffix}"

echo "————————————————————— 确认 ——————————————————————"
echo "Scheme         : ${schemeNameIntact}"
echo "Configuration  : ${configurationIntact}"
echo "Deployment     : ${methodName}"
echo ""

if [ -d ".svn" ]
        then
        svn upgrade
fi

# 准备编译与打包
cd ${projDirName}
# 执行这行代码过后，以下路径均是相对项目文件夹的

# 读取版本号
infoPlist="./${workspaceName}/Info.plist"
projVersion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${infoPlist}")
projBuild=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${infoPlist}")

echo "————————————————————— 版本确认 ——————————————————————"
echo "infoPlist         : ${infoPlist}"
echo "projVersion       : ${projVersion}"
echo "projBuild         : ${projBuild}"
echo ""

if [ "$method" == "appstore" ] && [ $incrementEnabled == true ]
then
    # 若为AppStore，build自增
    projBuild=`expr $projBuild + 1`
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${projBuild}" "${infoPlist}"
fi

# 导出.ipa文件命名时拼接时间
autoBuildDate=`date +"%y%m%d%H%M"`
if [ "$method" != "appstore" ]
then
    # App内提示打包时间 / 打包方式
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildDate ${autoBuildDate}" "${infoPlist}"
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildMethod ${method}" "${infoPlist}"
fi
# Build与出包路径
exportName="${schemeNameIntact}_${configurationPrefix}_${methodName}_v${projVersion}_${projBuild}_${autoBuildDate}"
exportDir="../../iOS-Build"
if [ "$method" == "appstore" ]
then
    # AppStore包出包路径
    archiveDir="${exportDir}/AppStore"
    ipaDir="${exportDir}/AppStore"
else
    # 任何测试包出包路径
    archiveDir="${exportDir}/${schemeNamePrefix}"
    ipaDir="${exportDir}/${schemeNamePrefix}"
fi

# 执行MobileProvision更新
if [ $updateMobileProvisionEnabled == true ]
then
    provisionDir="./MobileProvision"
    echo "——————————————— 更新 <MobileProvision> ————————————————"
    echo "Current Path: $(pwd)"
    if [ -d ${provisionDir} ]
    then
        for file in ${provisionDir}/*
        do
            if test -f ${file}
            then
                open ${file}
                echo "Open file:    ${file}"
            fi
        done
    else
        echo "Not found the dir: ${provisionDir}"
    fi
fi

# 执行pod install
if [ $podInstall == true ]
then
    echo "——————————————— 执行 <pod install> ————————————————"
    pod install
fi

archivePath="${archiveDir}/${exportName}.xcarchive"

echo "——————————————— 确认 xcodebuild  ————————————————
xcodebuild clean -workspace ${workspaceName}.xcworkspace
                 -scheme ${schemeNameIntact}
                 -configuration ${configurationIntact}\n
xcodebuild archive -workspace ${workspaceName}.xcworkspace
                   -scheme ${schemeNameIntact}
                   -configuration ${configurationIntact}
                   -archivePath ${archivePath}"
echo ""

xcodebuild clean -workspace ${workspaceName}.xcworkspace \
                 -scheme ${schemeNameIntact} \
                 -configuration ${configurationIntact} \

xcodebuild archive -workspace ${workspaceName}.xcworkspace \
                   -scheme ${schemeNameIntact} \
                   -configuration ${configurationIntact} \
                   -archivePath ${archivePath} \

# 还原Info.plist
if [ "$method" != "appstore" ]
then
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildDate ${nullValue}" "${infoPlist}"
    /usr/libexec/PlistBuddy -c "Set :CRAutoBuildMethod ${nullValue}" "${infoPlist}"
fi

if [ ! -e "${archivePath}" ]
then
    echo "Current Path: $(pwd)"
    echo "Not found the archive file: ${archivePath}"
    exit 1
fi

echo "——————————————— 确认 xcodebuild  ————————————————
xcodebuild -exportArchive -archivePath ${archivePath} 
                          -exportOptionsPlist ${EXPORT_OPTIONS_PLIST} 
                          -exportPath ${ipaDir}/${exportName}"
echo ""

xcodebuild -exportArchive -archivePath ${archivePath} \
                          -exportOptionsPlist ${EXPORT_OPTIONS_PLIST} \
                          -exportPath ${ipaDir}/${exportName} \

ipaPath="${ipaDir}/${exportName}/${schemeNameIntact}.ipa"

if [ ! -e "${ipaPath}" ]
then
    echo "Current Path: $(pwd)"
    echo "Not found the file: ${ipaPath}"
    exit 1
else
    # 出包成功才判断是否要提交改动
    if [ "$method" == "appstore" ] && [ $incrementEnabled == true ]
    then
        # 若为AppStore，build自增 的提交
        commitLog="autobuild: [${schemeNamePrefix}] BuildNum: ${projBuild}"
        if [ -d "../.svn" ]
            then
            svn commit -m "${commitLog}" ${infoPlist}
        elif [ -d "../.git" ]
            then
            git add ${infoPlist}
            git commit -m "${commitLog}"
            git checkout .
            if [ $useGitSvn == true ]
                then
                git svn dcommit --rmdir
            else
                branchName=$(git symbolic-ref --short -q HEAD)
                echo "current loacl branch name: ${branchName}"
                git fetch origin ${branchName}
                git rebase origin/${branchName}
                git push origin ${branchName}
            fi
        fi
        echo "___${commitLog}"
    fi
    echo "包文件路径: ${ipaPath}"
fi

# 拷贝ipa文件到固定目录，以供自动化测试
if [ $backupIpaEnabled == true ]
then
    echo "——————————————— 备份 .ipa 文件 ————————————————"
    backupPath="${exportDir}/Latest/${schemeNamePrefix}"
    rm -rf "${backupPath}"
    mkdir -p "${backupPath}"
    cp -R -f -p "${ipaPath}" \
            "${backupPath}/${schemeNamePrefix}.ipa"
fi

# 自动上传至iTunesConnect
if [ "$method" == "appstore" ]
then
    echo "——————————————— 上传到 iTunes Connect ————————————————"
    appleID="your-apple-id@gmail.com"
    applePassword="xxxx-xxxx-xxxx-xxxx"
    # 验证信息
    xcrun altool --validate-app -f "${ipaPath}" -t iOS -u "${appleID}" -p "${applePassword}" --output-format xml
    #上传iTunesConnect
    xcrun altool --upload-app -f "${ipaPath}" -u "${appleID}" -p "${applePassword}" --output-format xml
fi

# 上传至fir 若不需要上传 删除以下代码即可
if [ $firEnabled == true ]
then
    firChangeLog="${exportName} \n\nUploaded by hht plugin"
    echo "——————————————— 上传到 fir.im ————————————————"
    fir login ${firToken}
    fir publish ${ipaPath} --changelog=${firChangeLog}
fi
