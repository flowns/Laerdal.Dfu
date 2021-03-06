#!/bin/bash

usage(){
    echo "usage: ./build.sh [-c|--clean-output] [-v|--verbose] [-o|--output path]"
    echo "parameters:"
    echo "  -c | --clean-output                     Cleans the output before building"
    echo "  -v | --verbose                          Enable verbose build details from msbuild and gradle tasks"
    echo "  --use-carthage                          Use cocoa pods binary via carthage"
    echo "  -s | --sharpie                          Regenerates objective sharpie autogenerated files, useful to spot API changes"
    echo "  -o | --output [path]                    Output path"
    echo "  -h | --help                             Prints this message"
}

while [ "$1" != "" ]; do
    case $1 in
        -o | --output )         shift
                                output_path=$1
                                ;;
        -c | --clean-output )   clean_output=1
                                ;;
        --use-carthage )        use_carthage=1
                                ;;
        -s | --sharpie )        sharpie=1
                                ;;
        -v | --verbose )        verbose=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     echo
                                echo "### Wrong parameter: $1 ###"
                                echo
                                usage
                                exit 1
    esac
    shift
done

echo
echo "### INFORMATION ###"
echo

# Static configuration
nuget_project_folder="Laerdal.Xamarin.Dfu"
nuget_project_name="Laerdal.Xamarin.Dfu"
nuget_output_folder="$nuget_project_name.Output"
nuget_source_folder="$nuget_project_name.Source"
nuget_csproj_path="$nuget_project_folder/$nuget_project_name.csproj"
nuget_jars_folder="$nuget_project_folder/Droid/Jars"
nuget_frameworks_folder="$nuget_project_folder/iOS/Frameworks"
nuget_sharpie_folder="$nuget_project_folder/iOS/ObjcBinding/Sharpie_Generated"

# Generates variables
echo "nuget_project_folder = $nuget_project_folder"
echo "nuget_jars_folder = $nuget_jars_folder"
echo "nuget_frameworks_folder = $nuget_frameworks_folder"
echo "nuget_output_folder = $nuget_output_folder"
echo "nuget_project_name = $nuget_project_name"
echo "nuget_csproj_path = $nuget_csproj_path"
echo "nuget_sharpie_folder = $nuget_sharpie_folder"

if [ "$clean_output" = "1" ]; then
    echo
    echo "### CLEAN OUTPUT ###"
    echo
    rm -rf $nuget_output_folder
    echo "Deleted : $nuget_output_folder"
fi

pushd $nuget_source_folder
. ./download.android.sh
if [ "$use_carthage" = "1" ]; then
    . ./download.ios.carthage.sh
else 
    . ./download.ios.sh
fi
popd

echo ""
echo "### COPY NATIVE FILES ###"
echo ""

echo "Copying $nuget_source_folder/$dfu_release_aar to $nuget_jars_folder/dfu-release.aar"
if [ ! -f "$nuget_source_folder/$dfu_release_aar" ]; then
    echo "Failed : $nuget_source_folder/$dfu_release_aar does not exist"
    exit 1
fi
rm -rf $nuget_jars_folder/dfu-release.aar
mkdir -p $nuget_jars_folder
cp $nuget_source_folder/$dfu_release_aar $nuget_jars_folder/dfu-release.aar

echo "Copying $nuget_source_folder/$iOSDFULibrary_fat_framework to $nuget_frameworks_folder/iOSDFULibrary.framework"
if [ ! -d "$nuget_source_folder/$iOSDFULibrary_fat_framework" ]; then
    echo "Failed : $nuget_source_folder/$iOSDFULibrary_fat_framework does not exist"
    exit 1
fi
rm -rf $nuget_frameworks_folder/iOSDFULibrary.framework
mkdir -p $nuget_frameworks_folder/iOSDFULibrary.framework
cp -a $nuget_source_folder/$iOSDFULibrary_fat_framework/. $nuget_frameworks_folder/iOSDFULibrary.framework

echo "Copying $nuget_source_folder/$ZIPFoundation_fat_framework to $nuget_frameworks_folder/ZIPFoundation.framework"
if [ ! -d "$nuget_source_folder/$ZIPFoundation_fat_framework" ]; then
    echo "Failed : $nuget_source_folder/$ZIPFoundation_fat_framework does not exist"
    exit 1
fi
rm -rf $nuget_frameworks_folder/ZIPFoundation.framework
mkdir -p $nuget_frameworks_folder/ZIPFoundation.framework
cp -a $nuget_source_folder/$ZIPFoundation_fat_framework/. $nuget_frameworks_folder/ZIPFoundation.framework

echo "Copying $nuget_source_folder/$iOSDFULibrary_fat_framework_dsym to $nuget_frameworks_folder/iOSDFULibrary.framework.dSYM"
if [ ! -d "$nuget_source_folder/$iOSDFULibrary_fat_framework_dsym" ]; then
    echo "Failed : $nuget_source_folder/$iOSDFULibrary_fat_framework_dsym does not exist"
    exit 1
fi
rm -rf $nuget_frameworks_folder/iOSDFULibrary.framework.dSYM
mkdir -p $nuget_frameworks_folder/iOSDFULibrary.framework.dSYM
cp -a $nuget_source_folder/$iOSDFULibrary_fat_framework_dsym/. $nuget_frameworks_folder/iOSDFULibrary.framework.dSYM

echo "Copying $nuget_source_folder/$ZIPFoundation_fat_framework_dsym to $nuget_frameworks_folder/ZIPFoundation.framework.dSYM"
if [ ! -d "$nuget_source_folder/$ZIPFoundation_fat_framework_dsym" ]; then
    echo "Failed : $nuget_source_folder/$ZIPFoundation_fat_framework_dsym does not exist"
    exit 1
fi
rm -rf $nuget_frameworks_folder/ZIPFoundation.framework.dSYM
mkdir -p $nuget_frameworks_folder/ZIPFoundation.framework.dSYM
cp -a $nuget_source_folder/$ZIPFoundation_fat_framework_dsym/. $nuget_frameworks_folder/ZIPFoundation.framework.dSYM

if [ "$sharpie" = "1" ]; then
    echo
    echo "### SHARPIE ###"
    echo

    sharpie_version=$(sharpie -v)
    echo "sharpie_version = $sharpie_version"

    sharpie bind -sdk iphoneos -o $nuget_sharpie_folder -f $nuget_frameworks_folder/iOSDFULibrary.framework
fi

echo ""
echo "### MSBUILD ###"
echo ""

msbuild_parameters=""
if [ ! "$verbose" = "1" ]; then
    msbuild_parameters="${msbuild_parameters} -nologo -verbosity:quiet"
fi
msbuild_parameters="${msbuild_parameters} -t:Rebuild"
msbuild_parameters="${msbuild_parameters} -restore:True"
msbuild_parameters="${msbuild_parameters} -p:Configuration=Release"
echo "msbuild_parameters = $msbuild_parameters"
echo ""

rm -rf $nuget_project_folder/bin
rm -rf $nuget_project_folder/obj
msbuild $nuget_csproj_path $msbuild_parameters

if [ ! -z "$output_path" ]; then

    echo
    echo "### COPY FILES TO OUTPUT ###"
    echo

    mkdir -p $output_path
    cp -a $nuget_output_folder/. $output_path

    echo "Copied into $output_path"
fi