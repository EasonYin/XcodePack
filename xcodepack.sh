#使用方法

if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

#工程绝对路径
project_path=$(cd `dirname $0`; pwd)

#工程名 将XXX替换成自己的工程名
project_name=XXX

#scheme名 将XXX替换成自己的sheme名
scheme_name=XXX

#打包模式 Debug/Release
development_mode=Debug

#build文件夹路径
build_path=${project_path}/build

#plist文件所在路径
exportOptionsPlistPath=${project_path}/ExportOptions_adhoc.plist

# 工程中Target对应的配置plist文件名称, Xcode默认的配置文件为Info.plist
info_plist_name="Info"

# 获取项目名称
project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
# 获取版本号,内部版本号,bundleID
info_plist_path="$project_name/$info_plist_name.plist"
display_name=`/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" $info_plist_path`
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $info_plist_path`
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $info_plist_path`
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $info_plist_path`

echo '==========================================='
echo '///-----------'
echo '/// 项目信息'
echo '///-----------'
echo 'display_name: '$display_name
echo 'bundle_version: '$bundle_version
echo 'bundle_build_version: '$bundle_build_version
echo 'bundle_identifier: '$bundle_identifier
echo '==========================================='
echo "Place enter the number you want to export ?  
1:App-store 
2:Ad-hoc 
3:Enterprise
4:Development "
echo '==========================================='

##
read number
while([ $number != 1 ] && [ $number != 2 ] && [ $number != 3 ] && [ $number != 4 ])
do
echo "Error! Should enter 1/2/3/4"
echo "Place enter the number you want to export ?  
1:App-store 
2:Ad-hoc 
3:Enterprise
4:Development "
echo '==========================================='

read number
done

echo '==========================================='
echo 'You select number: '$number
echo '==========================================='

# if ([ $number == 3 ] && [ bundle_identifier == '$(PRODUCT_BUNDLE_IDENTIFIER)' ]);then
# development_mode=Com
# exportOptionsPlistPath=${project_path}/ExportOptions_com.plist
# else
# echo 'Enterprise bundle_identifier Error!'
# exit 0
# fi


if [ $number == 1 ];then
development_mode=Release
exportOptionsPlistPath=${project_path}/ExportOptions_release.plist
elif [ $number == 2 ];then
development_mode=Debug
exportOptionsPlistPath=${project_path}/ExportOptions_adhoc.plist
elif [ $number == 3 ];then
development_mode=Com
exportOptionsPlistPath=${project_path}/ExportOptions_com.plist
else
development_mode=Dev
exportOptionsPlistPath=${project_path}/ExportOptions_dev.plist
fi

#导出.ipa文件所在路径
exportIpaPath=${project_path}/IPADir/${development_mode}

#pod install
echo '///-----------'
echo '/// 正在更新工程'
echo '///-----------'
pod install

echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit

echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive \
-workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${exportIpaPath}/${project_name}.xcarchive  \
-sdk iphoneos build DWARF_DSYM_FOLDER_PATH=${exportIpaPath} \
-quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild \
-exportArchive \
-archivePath ${exportIpaPath}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

# echo '///-------------'
# echo '/// 开始发布ipa包 '
# echo '///-------------'

# if [ $number == 1 ];then

# #验证并上传到App Store
# # 将-u 后面的XXX替换成自己的AppleID的账号，-p后面的XXX替换成自己的密码
# altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
# "$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u XXX -p XXX -t ios --output-format xml
# "$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  XXX -p XXX -t ios --output-format xml
# else

# #上传到Fir
# # 将XXX替换成自己的Fir平台的token
# fir login -T XXX
# fir publish $exportIpaPath/$scheme_name.ipa

# fi

exit 0
