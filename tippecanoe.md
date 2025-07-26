# tippecanoe のtips

## tile-join をつかって、レイヤを抽出する

hfu 氏の以下のサイトを参考  
https://qiita.com/hfu/items/144bb4384226e7c30000

- レイヤの抽出

```
$ tile-join --layer=buildings -f -o out.mbtiles a.mbtiles
$ tile-join -l buildings -f -o out.mbtiles a.mbtiles
```

- zoom levelの刈込

```
$ tile-join -z 6 -Z 4 -f -o out.mbtiles a.mbtiles
$ tile-join --maximum-zoom=6 --minimum-zoom=4 -f -o out.mbtiles a.mbtiles
```

この辺を組み合わせれば、特定のレベルの、特定の地物だけ抽出できそう。  
なお、建物は、Z16が最大。
