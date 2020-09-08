# GDAL Tips 

## GDAL三大コマンド
個人的に外すことの出来ないGDALの三つのコマンド。gdalwarpと、gdal_translateと、gdaladdo。

  ```gdalwarp -of GTiff -s_srs "EPSG:2451" -t_srs "EPSG:3100" sakura_mosaic.img sakura_mosaic_utm54.tif```

  ```gdal_translate -of GTiff -co "TILED=YES" -co "TWF=YES" rapid_sub.img rapid_tiled_sub.tif```

  ```gdaladdo -r average rapid_sub_addo.tiff 2 4 8 16 32```


## GDAL_CACHEMAX
gdalでキャッシュのサイズを指定する方法。
基本は、

  ```--config GDAL_CACHEMAX (size)```

で指定すればOK。例えばgdal_translateの場合、

  ```gdal_translate --config GDAL_CACHEMAX 64 in.tif out.tif```

となる。

## 複数の画像を一気にマージして、vrtを作る

```gdalbuildvrt -a_srs EPSG:2450 out_2450.vrt *.jpg```

## gdalbuildvrtを使って、モノクロ画像から、RGB画像を作る。

まず、

  ```gdalbuildvrt -separate truecolor.vrt band3.tif band2.tif band1.tif```

で、バーチャルレイヤーを作成。その上で、

  ```gdal_translate truecolor.vrt truecolor.tif```

で実際のレイヤを作ってあげる。これでOK。

複数のファイルを一つのファイルにまとめる場合、

  ```gdalbuildvrt -a_srs EPSG:2454 merge.vrt *.tif```

となる。

## Float32の画像を、Int16に変換する。サンプルとして3バンドの画像を作って試す。

  ```gdalbuildvrt -separate merge.vrt Float32_1.tif Float32_2.tif Float32_3.tif```
  
  ```gdal_translate merge.vrt Float32_3band.tif```
  
  ```gdal_calc -A Float32_3band.tif --outfile=Float32_3band_1000.tif --allBands=A --calc="A*1000"```
  
  ```gdal_translate Float32_3band_1000.tif Int16.tif -ot Int16```

## Convert MODIS HDF File
まず、 modis_hdf2erdas_ll_wgs84.sh http://www.grassbook.org/neteler/useful/modis_hdf2erdas_ll_wgs84.sh を使うと、MODIS HDFファイルをERDAS IMGファイルに変換できる。Thanks, Markus!

ただし、幾何補正をかけたあとにマージするとMODIS画像間にギャップができてしまう。よって手順としては、

  - hdfからバンドごとのimgファイルを作成する
  - このimgファイルをマージする
  - マージしたimgファイルを幾何補正する

といった手順でいく。

### imgファイルの抽出

まず、hdfからimgの抽出。下記のスクリプト名は**modis_hdf2img_grid.sh**。ただし、このスクリプトは処理対象のファイルを指定して実行するので、実行するスクリプトは二つ下の**hdf2img.sh**となる。

スクリプトは上記のマーカスのものを改変して以下のとおり。

    #!/bin/bash
   
    # 2005, Markus Neteler
    # warp MODIS HDF to Erdas/Img - LatLong/WGS84
    # modified Nobusuke Iwasaki, 2011
    
    PROG="$0"
    
    if [ $# -lt 1 -o "$1" = "-h" -o "$1" = "--help" -o "$1" = "-help" ] ; then
     echo "Script to warp all layers of MODIS HDF to GeoTiff/tif - UTM41/WGS84"
     echo "Usage:"
     echo "      $PROG M[OD|MYD]blabla.hdf"
     exit 1
    fi
    
    FILE=$1
    FILE_HEAD="${FILE%.*.*.*}"
    
    HDFlayerNAMES="`gdalinfo $FILE | grep SUBDATASET_ | grep _NAME | cut -d'=' -f2`"
    
    #aarg! NDVI/EVI MOD13 contains spaces:
    HDFlayerNAMES_NOSPACES="`gdalinfo $FILE | grep SUBDATASET_ | grep _NAME | cut -d'=' -f2 | tr -s ' ' '|'`"
    
    #MODIS does not use the "Normal Sphere (r=6370997)"!!!
    # MODIS sphere, radius of 6371007.181
    # http://edcdaac.usgs.gov/landdaac/tools/mrtswath/info/ReleaseNotes.pdf
    #
    # WGS 84
    # <4326> +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs  <>
    
    # cs2cs -le
    SPHERE="+ellps=sphere"
    
    #loop over all layers:
    for i in ${HDFlayerNAMES_NOSPACES} ; do
          #transform back:
          INPUT="`echo ${i} | tr -s '|' ' '`"
          NEWNAME="`echo ${i} | cut -d':' -f4,5 | tr ':' '_' | tr -s '|' '_'`"
    #        BAND="`echo ${i} | cut -d':' -f5 | tr ':' '_' | tr -s '|' '_'`"
          BAND="`echo ${i} | cut -c 110- | tr ':' '_' | tr -s '|' '_'`"
          echo "${BAND}"        
          gdal_translate -of HFA \
                         -co COMPRESS=YES \
             "${INPUT}" ./img/$FILE_HEAD.$BAND.img
    done


また、このスクリプトを実行するために、*.hdfファイルを一ヶ所にまとめる。ここではHDFフォルダにした。んで、ここにあるファイルすべてについて変換する。スクリプト名は**hdf2img.sh**。内容は以下のとおり。

    #!/bin/bash
    
    # Convert MODIS hdf to GeoTiff WGS84 UTM41 in the current folder
    
    # make the array of hdf file list
    LIST=(`ls *.hdf | tr '\n' ' '| sed 's/,$//g'`)
    
    for hdf_list in ${LIST[@]};do
      echo `sh ./modis_hdf2img_grid.sh ${hdf_list}`
    done

### imgファイルのマージとgdalwarp 

次の手順は、おなじくMarkusのスクリプトを参考にして、以下のとおり。スクリプト名は**grid_merge.sh**。なお、対象とするプロダクトによって、BANDとPRODUCTの部分を変える必要がある。あと、DOYは全体を対象とするのか、そうじゃないのかによって。変えたり変えなかったり。

    #!/bin/bash
    
    DOY=2010041
    BAND=(b01 b02 b03 b04 b05 b06 b07 day_of_year qc_500m raz state_500m szen vzen) # add layer names
    # BAND=(b01) for test
    PRODUCT=MOD09A1 # set name of MODIS Product
    SPHERE="+ellps=sphere"
    
    while [ $DOY -le 2010049 ] # set date
    # while [ $DOY -le 2010001 ] # for test
     do
       for i in ${BAND[@]} ; do
       
       LIST=(`ls ./img/"$PRODUCT".A"$DOY".*."$i".img | tr '\n' ' '| sed 's/,$//g'`)
       # echo ${LIST[*]}
       gdal_merge.py -o merge.tmp.img -of HFA -co COMPRESS=YES ${LIST[*]}
       # gdal_merge.py -o merge.A"$DOY"."$i"tmp.img -of HFA -co COMPRESS=YES ${LIST[*]} for test
       gdalwarp -of HFA -t_srs "+proj=latlong $SPHERE" merge.tmp.img -r near -dstnodata 0 warp.tmp.img
       gdal_translate -of HFA -a_srs "EPSG:4326" -co COMPRESS=YES -projwin 46.4 55.5 87.4 35.1 warp.tmp.img latlon.tmp.img
       gdalwarp -r near -dstnodata 0 -of HFA -co COMPRESS=YES -s_srs "EPSG:4326" -t_srs "EPSG:32641" latlon.tmp.img ./UTM41/"$PRODUCT".A"$DOY"."$i".img
       rm -f ./merge.tmp.img
       rm -f ./warp.tmp.*
       rm -f ./latlon.tmp.*
     done
     eval DOY=`expr "$DOY" + 8` # calc ODY
    done

ここで、latlonに変換したあとに、UTM41に変換するのだが、その際全域を変換しようとすると、エラーが出る。なので、latlon.tmp.imgを作る際に、**-projwin 46.4 55.5 87.4 35.1** で出力先のウインドサイズを指定してあげて、サブセットを作るようにした。なおこうすると、最終的な出力サイズも小さくなる（2GBが500MB）ので、そういった意味でもお得（お得?)。

