# PostGIS メモ
## 空間index作製

```
CREATE INDEX lumesh_all_spatial_gix
    ON public.lumesh_all USING gist
    (geom)
    TABLESPACE pg_default;
```

以下は、暫時変えること  
lumesh_all_spatial_gix:インデックス名  
public.lumesh_all:テーブル名  
gist: indexの作り方。

## 集計

```
SELECT city code, lu, count (lu) FROM tumesh all GROUP BY city code, lu ORDER BY city code ASC, lu ASC:
```

## 空間検索、（まだ、作成中）

```
　　　　
```
