# Mapillary upload 作業メモ

## Macの場合
- conda activate mapillary
- 作業フォルダに移動
- mapillary_tools process_and_upload ./

## GPX ファイルから、画像の位置情報を付与する
### mac環境でGPXデータをZ1に与える場合
- `exiftool -geotag ./combined.gpx ./*.JPG` でできる
- `mapillary_tools process_and_upload ./*.JPG　--skip_process_errors` でアップロード


### mac環境でGPXデータをGoProMaxに与える場合
- 基本は`exiftool -geotag ./combined.gpx ./*.JPG`でOK
   - ただし、小笠原の最初のシークエンスの場合、なぜか、時間がずれていた
   - `exiftool -geotag combined.gpx '-geosync=-264' ./*.JPG `で、時差を修正
- exiftool -geotag combined.gpx '-geosync=-264' ./*.JPG 

## Winの場合

### 位置座標付きファイルを単純にアップロードする場合

- mapirally_tools_win64.exe と upload.bat をアップロードしたい画像があるフォルダに入れて、upload.bat を実行すれば OK
- 注意事項として、サブフォルダ、その他ファイル等があると、それらもまとめてアップロード用の設定ファイルを作る
  - なので、必要な画像だけ temporary にフォルダを作って、アップするのがいいだろう。

### GPX ファイルから、画像の位置情報を付与する

- 以下のページを参考
  - https://exiftool.org/geotag.html
  - https://haru-kichi.hatenadiary.org/entry/20101104/p1

1. 作業用のフォルダに画像をコピー
2. `exiftool -geotag hogehoge.gpx "-geotime<${createdate}+09:00" .\` で、gpx に基づき位置情報を更新
3. 「位置座標付きファイルを単純にアップロードする場合」に順次、ファイルをアップロード

4. 必要ではないが、データの確認方法。
    1. 以下の手順で、画像の EXIF からCSVを生成  
    ```
    exiftool -csv -GPSLongitude -GPSLatitude -GPSAltitude -n *.JPG >exif.csv
    ```
    2. 以下のコマンドを実施し、点を作成。 -oo AUTODETECT_TYPE=YES でデータ型を指定（高さを数値にする）。なお、csvtファイルを作っておいてもデータ型は指定できる。
    ```
    ogr2ogr -oo AUTODETECT_TYPE=YES -dialect SQLite -sql "SELECT *, MakePoint(CAST(GPSLongitude AS float),CAST(GPSLatitude AS float)) FROM exif" -a_srs EPSG:4612 point.geojson exif.csv
    ```
    3. 以下のコマンドを実施し、線分を作成
   ```
   ogr2ogr -oo AUTODETECT_TYPE=YES -dialect SQLite -sql "SELECT *, MakeLine(MakePoint(CAST(GPSLongitude AS float),CAST(GPSLatitude AS float))) FROM exif" -a_srs EPSG:4612 line.geojson exif.csv
   ```

### 位置座標付きファイルから、位置情報を抜き出して、ラインファイルを作る場合

1. Windwos でやる場合、exiftool を同じフォルダにコピー
2. `exiftool -csv -GPSLongitude -GPSLatitude -n *.JPG >exif.csv` で、csv ファイルに位置情報を書き出し
3. csv を QGIS で開いて、正しく出力されているか、確認
   1. Visual Studio の GeoFile Viewer でも OK
4. 以下のコマンドを実施し、線分を作成
   ```
   ogr2ogr -dialect SQLite -sql "SELECT *, MakeLine(MakePoint(CAST(GPSLongitude AS float),CAST(GPSLatitude AS float))) FROM exif" -a_srs EPSG:4612 line.geojson exif.csv
   ```
   
