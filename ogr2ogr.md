# ogr2ogr tipx

## ファイル一括変換
### shp を geojsonへ
for %i in (*.shp) do ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:4326 -f geoJSON %~ni.geojson %i

### gejson を shpへ
for %i in (*.geojson) do ogr2ogr -f "ESRI Shapefile" "%~ni.shp" %i

### csvをgeojsonに変換
for %N in (*.csv) do ogr2ogr -f "GeoJSON"  -oo X_POSSIBLE_NAMES=longitude  -oo Y_POSSIBLE_NAMES=latitude %N.geojson %N

### csvをFlatGeobuf形式に変換
FOR %F IN (*.csv) do ogr2ogr -f "FlatGeobuf" "%~nF.fgb" "%F" -s_srs EPSG:4326 -t_srs EPSG:4326 -oo X_POSSIBLE_NAMES="経度" -oo Y_POSSIBLE_NAMES="緯度" -append

### csvファイルの文字コードを変更する
FOR %F IN (*.csv) do iconv -f CP932 -t UTF-8 "%F" > "%F_UTF-8.csv"

### fgbの属性値に基づき点データを生成する
ogr2ogr -f "FlatGeobuf" point.fgb 08564_Tone_With_Daihyoten.fgb -dialect sqlite -sql "SELECT 地番, 所在, 代表点経度, 代表点緯度, MakePoint(代表点経度, 代表点緯度, 4612) AS geometry FROM '08564_Tone_With_Daihyoten'" -a_srs EPSG:4612

## ファイルマージ
### 複数のshpを一つのshpへ
for %i in (*.shp) do ogr2ogr -f "ESRI Shapefile" -append ..\merge.shp %i

### geojsonを一つのgpkgレイヤにマージ
ogrmerge -f GPKG -single -o merged_single.gpkg *.geojson

### geojsonを一つのFlatGeobufレイヤにマージ
ogrmerge -f FlatGeobuf -single -o merged_single.fgb *.json

### 別々のgpkgレイヤにマージ
ogrmerge -f GPKG -o merged.gpkg *.geojson

## ファイルディゾルブ
- ogr2ogr -t_srs "EPSG:3100" -f "ESRI Shapefile" diss.shp(あてファイル) vg.shp（もとファイル） -dialect sqlite -sql "SELECT ST_Buffer(ST_Collect(ST_SnapToGrid(Geometry, 0.00001)),0), landuse (融合するフィールド名） from vg (入力ファイルの頭） GROUP BY landuse" -lco ENCODING=932 (SJIS指定） --config GDAL_CACHEMAX 1024
- --config GDAL_CACHEMAX 1024　は効いて無さそう。
- 最後の GROUP BYを除いても、走ることは走る。ただし、時間がかなり余分にかかる。

- ogr2ogr output.shp aaaa.shp -dialect sqlite -sql "SELECT ST_Union(geometry),A40_001, A40_002, A40_003 FROM aaaa GROUP BY A40_003" 
 -lco ENCODING=UTF-8（もしくはCP932） オプションをつけたら全角文字カラムでも認識してくれました〜。

https://qiita.com/nishi_bayashi/items/4520ac228e845779af64#comment-0f4a840480999cc969dc
