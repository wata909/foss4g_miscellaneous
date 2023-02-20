# pdal の使い方関係

## copc の作り方
- metashapeで、平面直角座標系、XYZ形式で、エクスポート
- CloudCompareで読み込み、laz形式で保存
- 以下のコマンドでcopcに変換
  - 環境はOSGeo4W
  - 以下の内容のJSONファイルを作成。ファイル名は、`pipeline.json`。ファイル名は適宜変更
```json
[
    "kawaba_20230211_pc.laz",
    {
        "type":"writers.copc",
        "filename":"kawaba_20230211_copc.laz"
    }
]
```
  - コマンドを実行
```sh
pdal pipeline --stdin < pipeline.json
```


