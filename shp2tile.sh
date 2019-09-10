#!/bin/bash

# フォルダ内のshpファイルについて実行する
for i in *.shp; do 

mkdir ${i:5:1}_${i:7:3}_${i:11:2}

xtile_ul=`echo $((${i:7:3}*32))` # *32はZ7からZ12の場合。Z13だと64になるはず。
ytile_ul=`echo $((${i:11:2}*32))`
xtile_lr=`echo $(($(($((${i:7:3}+1))*32))-1))`
ytile_lr=`echo $(($(($((${i:11:2}+1))*32))-1))`
zoom=12


#出力の確認
echo $xtile_ul $ytile_ul $xtile_lr $ytile_lr $zoom

#ループを回す
#xtileのループ。変数名はX $xtile_ulから$xtile_lrまで、回す
#ytileのループ。変数名はY $ytile_ulから$ytile_lrまで、回す
#注意！タイルX方向は、タイル番号と同じくminとmaxになるが、Yはタイル番号と逆にmaxとminになる

X=$xtile_ul
Y=$ytile_ul

while [ $X -le $xtile_lr ]  #Xタイル分繰り返し
do
    while [ $Y -le $ytile_lr ] #Yタイル分繰り返し
    do
#      echo $X $Y #ループ確認
      
      #以下でタイルナンバーからlon, latへの変換を実施
      xmin=$X
      xmax=$(($X+1))
      ymin=$(($Y+1))
      ymax=$Y
      lon_min=`echo "${xmin} ${zoom}" | awk '{printf("%.9f", $1 / 2.0^$2 * 360.0 - 180)}'`
      lon_max=`echo "${xmax} ${zoom}" | awk '{printf("%.9f", $1 / 2.0^$2 * 360.0 - 180)}'`
      lat_min=`echo "${ymin} ${zoom}" | awk -v PI=3.14159265358979323846 '{ 
            num_tiles = PI - 2.0 * PI * $1 / 2.0^$2;
            printf("%.9f", 180.0 / PI * atan2(0.5 * (exp(num_tiles) - exp(-num_tiles)),1)); }'`
      lat_max=`echo "${ymax} ${zoom}" | awk -v PI=3.14159265358979323846 '{ 
            num_tiles = PI - 2.0 * PI * $1 / 2.0^$2;
            printf("%.9f", 180.0 / PI * atan2(0.5 * (exp(num_tiles) - exp(-num_tiles)),1)); }'`
      
      echo $lon_min  $lat_min $lon_max $lat_max # bbox 確認
      
      #クリップを実行
      ogr2ogr -spat $lon_min  $lat_min $lon_max $lat_max -lco ENCODING=UTF-8 -oo ENCODING=UTF-8 -f "ESRI Shapefile" ./${i:5:1}_${i:7:3}_${i:11:2}/tile${zoom}_${X}_${Y}.shp $i
      
      Y=`echo $(($Y+1))`
    done
  X=`echo $(($X+1))`  
  Y=$ytile_ul
done

# 実行完了
done
