# pdal の使い方関係

## copc の作り方
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

できあがり。
