ファイル一括変換

for %i in (*.shp) do ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:4326 -f geoJSON .\geojson\rapid%~ni.geojson %i

for %i in (*.geojson) do ogr2ogr -f "ESRI Shapefile" "%~ni.shp" %i

ファイルディゾルブ
ogr2ogr -t_srs "EPSG:3100" -f "ESRI Shapefile" diss.shp(あてファイル) vg.shp（もとファイル） -dialect sqlite -sql "SELECT ST_Buffer(ST_Collect(ST_SnapToGrid(Geometry, 0.00001)),0), landuse (融合するフィールド名） from vg (入力ファイルの頭） GROUP BY landuse" -lco ENCODING=932 (SJIS指定） --config GDAL_CACHEMAX 1024

--config GDAL_CACHEMAX 1024　は効いて無さそう。

最後の GROUP BYを除いても、走ることは走る。ただし、時間がかなり余分にかかる。
