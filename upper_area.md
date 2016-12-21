tempファイル削除
drop view tempmesh;
delete from lrs_network_lu_83_point01;

作業確認用qgisは，
Z:\面積推定・精度検証\農村集落土地利用確認.qgs
とする．

サンプルとしてはlrs_network_83_lu_099 を使うとする．
まず，単純にディゾルブは，

select st_union (geom) from lrs_network_83_lu_099

になる．重複は，st_Withinを使えばいい．

http://www.finds.jp/docs/pgisman/1.5.1/ST_Within.html

 ST_Within(geometry A, geometry B);

これは，AがBに完全に含まれる場合，Tureを返す．
Tureを返す系の場合，SELECT文を使うとTureのものが選択される．

文書としては，
SELECT gid FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select st_union (geom) from lrs_network_83_lu_099))

の筈なのだが，なぜか一つしか帰ってこない．

よくわからんので，とりあえず，upper_basinというテーブルを作って，dissしたものをぶち込む

まず，テーブルのクリエイト
CREATE TABLE  upper_basin (UID character varying(10),  geom geometry(Polygon,4612),  id serial NOT NULL, CONSTRAINT upper_basin_pkey PRIMARY KEY (id))
CREATE INDEX upper_basin_geom ON upper_basin USING gist (geom)

OK

これにディゾルブしたものをinsert
INSERT INTO upper_basin(uid, geom) values(099, (select st_union (geom) from lrs_network_83_lu_099))
結果，
----
ERROR: Geometry type (MultiPolygon) does not match column type (Polygon)
********** エラー **********

ERROR: Geometry type (MultiPolygon) does not match column type (Polygon)
SQLステート:22023
---
とのエラー．
ここで確認．

lu meshは，Polygon
agrimap2005は，multipolygon
upper_basinはPolygon
st_unionしたものは，multypolygon

作るテーブルをマルチポリゴンにする．修正版
CREATE TABLE  upper_basin (UID character varying(10),  geom geometry(MultiPolygon,4612),  id serial NOT NULL, CONSTRAINT upper_basin_pkey PRIMARY KEY (id))
CREATE INDEX upper_basin_geom ON upper_basin USING gist (geom)
INSERT INTO upper_basin(uid, geom) values(099, (select st_union (geom) from lrs_network_83_lu_099))

格子が残ってた･･･・ST_Bufferをつかってみる．

INSERT INTO upper_basin(uid, geom) values(099, ST_Buffer((select st_union (geom) from lrs_network_83_lu_099), 0.0))

これでも，格子が残る．

INSERT INTO upper_basin(uid, geom) values(099, ST_Buffer((select st_union (geom) from lrs_network_83_lu_099), 0.001))

実際に，0.001にしたら，今度はPolygonになって，あわないという．なので，上の方に帰ってやってみる．

SELECT gid FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, ST_Buffer((select st_union (geom) from lrs_network_83_lu_099), 0.001))

時間がかかる，buffの結果を確認する．
CREATE TABLE  upper_basin_single (UID character varying(10),  geom geometry(Polygon,4612),  id serial NOT NULL, CONSTRAINT upper_basin_single_pkey PRIMARY KEY (id));
CREATE INDEX upper_basin_single_geom ON upper_basin USING gist (geom);
INSERT INTO upper_basin_single(uid, geom) values(099, ST_Buffer((select st_union (geom) from lrs_network_83_lu_099), 0.001));
できあがりとしては，OK
これに，
     SELECT gid FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select (geom) from upper_basin_single where uid = '99')
をかけると，大体，引っ張ってくる．
この方が速度が速いので（というか，一発でやろうとすると，まだ走ってる），
bufferでポリゴンを作る→テーブルにぶち込む→作ったバッファーでinsertを行う
という手順で行うこととする．

つぎに，選択した農村集落界を投入するためのtableを準備する．
元の文を参考とし，

CREATE TABLE agri_upper
(
  gid numeric(10,0),
  key character varying(10),
  uid character varying(10),
  b14_c1 numeric(10,0),
  b14_c2 numeric(10,0),
  b14_c3 numeric(10,0),
  b14_c4 numeric(10,0),
  b14_c5 numeric(10,0),
  b14_c6 numeric(10,0),
  b14_c7 numeric(10,0),
  b14_c8 numeric(10,0),
  geom geometry(MultiPolygon,4612),
  id serial NOT NULL,
  CONSTRAINT agri_upper_pkey PRIMARY KEY (gid)
);
CREATE INDEX agri_upper_geom_gist
  ON agri_upper
  USING gist
  (geom);

で，いく．
次に，
SELECT gid FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select (geom) from upper_basin_single where uid = '99')
を改変して，

INSERT INTO agri_upper select gid, key, 099, b14_c1, b14_c2, b14_c3, b14_c4, b14_c5, b14_c6, b14_c7, b14_c8, geom FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select (geom) from upper_basin_single where uid = '99'))

でいく（っつか，いっちゃっった．こんなに簡単でいいのですか！？）
面積を集計する．
SELECT sum(b14_c4) from agri_upper where uid='99'
これについては，正しいものを後で確認．集計結果を投入する表を作る．この表には，後ほど，meshデータを検索した結果も一緒に入れるので，列としては，
uid, 農村集落界の水田面積，水稲作付面積，meshデータからカウントした田面積とする．geomの無いテーブルとなる．
CREATE TABLE agri_upper_area
(
  uid character varying(10),
  count_b14_c4 numeric(10,0),
  count_b14_c5 numeric(10,0),
  count_mesh numeric(10,0),
  gid serial NOT NULL,
  CONSTRAINT agri_upper_area_pkey PRIMARY KEY (gid)
);

まず，SELECT文を考える．
gidは，自動で振られるのがいいなぁ，ということで，最後に持ってく必要があるか．
uidはディゾルブしたtableからひっぱる．固定入力でもOK（というか，ポイント指定する必要があるので，固定でOK）

途中まで作成した分
select 99, (select sum(b14_c4) from agri_upper where uid = '99'), (select sum(b14_c5) from agri_upper where uid='99'), (select count(lu) from lrs_network_83_lu_099 where lu='0100');
uid, c4_sum, C5_sum, mesh_0100_sum
99;230613;214685;5632
まだ，overlayをかけていない．

select 99, (select sum(b14_c4) from agri_upper where uid = '99'), (select sum(b14_c5) from agri_upper where uid='99'), (select count(lu) from lrs_network_83_lu_099 where lu='0100' and ST_Intersects((select ST_Union (geom) from agri_upper where uid = '99'), lrs_network_83_lu_099.geom));

上記のsqlで、選択はしてくれる。テーブルへの投入は、
INSERT INTO agri_upper_area select 99, (select sum(b14_c4) from agri_upper where uid = '99'), (select sum(b14_c5) from agri_upper where uid='99'), (select count(lu) from lrs_network_83_lu_099 where lu='0100' and ST_Intersects((select ST_Union (geom) from agri_upper where uid = '99'), lrs_network_83_lu_099.geom));
で、とりまとめ完了。

一応，うまくいってるが，面積の値がアレな感じ．

実際の作業の場合に，使うスクリプトは以下の行にまとめる．
1.　上流域ポリゴンを挿入するためのテーブル作成これは，一度でいい．
CREATE TABLE  upper_basin (UID character varying(10),  geom geometry(Polygon,4612),  id serial NOT NULL, CONSTRAINT upper_basin_pkey PRIMARY KEY (id))
CREATE INDEX upper_basin_geom ON upper_basin USING gist (geom)

2.　選択した農村集落データを投入するためのtableを作成．これは，1回作ればOK
CREATE TABLE agri_upper
(
  gid numeric(10,0),
  key character varying(10),
  uid character varying(10),
  b14_c1 numeric(10,0),
  b14_c2 numeric(10,0),
  b14_c3 numeric(10,0),
  b14_c4 numeric(10,0),
  b14_c5 numeric(10,0),
  b14_c6 numeric(10,0),
  b14_c7 numeric(10,0),
  b14_c8 numeric(10,0),
  geom geometry(MultiPolygon,4612),
  id serial NOT NULL,
  CONSTRAINT agri_upper_pkey PRIMARY KEY (id)
);
CREATE INDEX agri_upper_geom_gist
  ON agri_upper
  USING gist
  (geom);

3.　集計した結果を投入するテーブルを作成する．
CREATE TABLE agri_upper_area
(
  uid character varying(10),
  count_b14_c4 numeric(10,0),
  count_b14_c5 numeric(10,0),
  count_mesh numeric(10,0),
  gid serial NOT NULL,
  CONSTRAINT agri_upper_area_pkey PRIMARY KEY (gid)
);

4.　対象となる流量観測地点の上流域ポリゴンを選択し，バッファーを作成．できたものをupper_basin_singleに投入する．
INSERT INTO upper_basin_single(uid, geom) values(099, ST_Buffer((select st_union (geom) from lrs_network_83_lu_099), 0.001));

5.　上記のバッファーに完全に含まれる農村集落を抽出し，agri_upper_selectに投入する
INSERT INTO agri_upper select gid, key, 099, b14_c1, b14_c2, b14_c3, b14_c4, b14_c5, b14_c6, b14_c7, b14_c8, geom FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select (geom) from upper_basin_single where uid = '99'))

6.　上記の農村集落と重複するメッシュを抽出し，集計した結果をagri_upper_areaに投入する．一列目が流量観測地点id, 二列目が経営耕地の田面積，四列目が経営耕地稲を作った面積
INSERT INTO agri_upper_area select 99, (select sum(b14_c4) from agri_upper where uid = '99'), (select sum(b14_c5) from agri_upper where uid='99'), (select count(lu) from lrs_network_83_lu_099 where lu='0100' and ST_Intersects((select ST_Union (geom) from agri_upper where uid = '99'), lrs_network_83_lu_099.geom));

101の実行文は，以下の通り
INSERT INTO upper_basin_single(uid, geom) values(101, ST_Buffer((select st_union (geom) from lrs_network_83_lu_101), 0.001));
INSERT INTO agri_upper select gid, key, 101, b14_c1, b14_c2, b14_c3, b14_c4, b14_c5, b14_c6, b14_c7, b14_c8, geom FROM agrimap2005 WHERE ST_Within (agrimap2005.geom, (select (geom) from upper_basin_single where uid = '101'));
INSERT INTO agri_upper_area select 101, (select sum(b14_c4) from agri_upper where uid = '101'), (select sum(b14_c5) from agri_upper where uid='101'), (select count(lu) from lrs_network_83_lu_101 where lu='0100' and ST_Intersects((select ST_Union (geom) from agri_upper where uid = '101'), lrs_network_83_lu_101.geom));

途中まで作った集計sqlを
Z:\面積推定・精度検証\上流土地利用集計sql.txt
として保存．
102にコピーしたら，いきなり失敗ｗ←なぜか飛び地があったので，これを修正．
一行ずつ実行

INSERT INTO upper_basin_single(uid, geom) values(102, ST_Buffer((select st_union (geom) from lrs_network_83_lu_102), 0.001));

だめ．まだ，MultiPolygon.
実施に，並列して走らせたせいもあるが，約50分　なかなかきつい．

ERROR:  Geometry type (MultiPolygon) does not match column type (Polygon)
********** エラー **********

ERROR: Geometry type (MultiPolygon) does not match column type (Polygon)
SQLステート:22023

104で試したが，エラー．ここより上流にあるということか．
109もエラー
114
上手くいかないのは，multiのupper_basinにいれて，セレクトする．

実行完了

ちなみに、マルチになってしまうのは
"125"
"124"
"115"
"112"
"111"
"110"
"109"
"108"
"107"
"106"
"105"
"104"
"103"
"102"
なので、ここを修正してみる。ここで入るかどうか頑張ると後を引くので、ここまででOKということにする．

psqlでsqlを実行する方法

psql -h localhost -d lrs_network -U postgres -w -f test.txt

で，ファイルを指定して実行出来る．
とりあえず，128で試してみる．OK
コマンド用sqlのエクセル編集は，
Z:\面積推定・精度検証H27流量観測地点上流土地利用集計用sql.xlsx
→Z:\GIS_DATA\upper_83\upper_basin_landuse_sql.xlsx
とする．
ここから，126と127を抜き出してテキストに貼り付けて実行
