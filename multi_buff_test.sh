#!/bin/bash

# GRASSでマルチバッファーを作るためのスクリプト

export PAHT=$PATH:/C/OSGeo4W/apps/grass/grass-7.0.4/scripts
export PATHEXT=$PATHEXT;.py

i=1
j=100
while [ $i -le 2 ]
 do
 v.extract --overwrite InvPoint_dragonfly  output=point_select where="cat="$i""
 while [ $j -le 200 ]
  do
   v.buffer --overwrite input=point_select output=point_select_buff type=point distance="$j"
   # バッファーの形状が荒い。コマンドの追加を検討
   v.type --overwrite input=point_select output=point_select_cent from_type=point to_type=centroid
   v.patch --overwrite input=point_select_cent,point_select_buff output=point_select_patch
   db.copy from_table=point_select_cent to_table=point_select_patch
   v.db.connect map=point_select_patch table=point_select_patch
   v.overlay --overwrite ainput=point_select_patch binput=landuse_diss output=veg_overlay_point"$i"_d"$j" operator=and
   # v.db.addcolumn map=veg_overlay_point"$i" columns="area DOUBLE PRECISION" bashだとpathが切れてないので，以下でで対応
   /C/OSGeo4W/apps/grass/grass-7.0.4/scripts/v.db.addcolumn.py map=veg_overlay_point"$i"_d"$j" columns="area DOUBLE PRECISION"
   v.to.db map=veg_overlay_point"$i"_d"$j" option=area units=meters columns=area
   v.out.ogr input=veg_overlay_point"$i"_d"$j" type=area output=/C/GIS_DATA olayer=point"$i"_buffer_"$j" lco="ENCODING=UTF-8"
  # exportはshpじゃなくてもOK.また，SQLのgroupbyで，まとめテキストにはき出せばいいんじゃないか？
  eval j=`expr "$j" + 100`
done
 eval i=`expr "$i" + 1`
done
