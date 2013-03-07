=============
 easyjubatus
=============

easyjubatus は Jubatus (http://jubat.us) を、プログラムを書くことなく、定型フォーマットのデータ形式を与えることで実験できるようにしたプログラムです。


動作条件
========

Ruby 1.9 での動作を確認しています。
以下の Ruby ライブラリが必要です。
gemを利用して事前にインストールしてください。

- thor


実行方法
========

以下のサブコマンドがあります。

``train``
  ラベル付きデータセットを利用して学習を行います。
``eval``
  ラベル付きデータセットを利用して予測と評価を行います。
``save``
  現在のモデルを保存します。
``load``
  以前に保存したモデルを読み込みます。

以下は共通のコマンドラインオプションです。

-h HOST, --host=HOST  Jubatusが起動しているマシンのホスト名を指定します。("127.0.0.1")
-p PORT, --port=PORT  Jubatusが利用しているポート番号を指定します。(9199)
-n NAME, --name=NAME  Jubatusのクラスタ名を指定します。()

train
-----

::

   $ easyjubatus.rb train [options] FILE_NAME

``FILE_NAME`` で指定されたラベル付きデータセットを利用して学習を行います。
ラベル付きデータセットのフォーマットは、Bazilフォーマットです。


eval
----

::

   $ easyjubatus.rb eval [options] FILE_NAME

``FILE_NAME`` で指定されたラベル付きデータセットを利用して評価を行います。
実行が終わると、予測ラベルと正解のラベルを比較し、正解率を表示します。
ラベル付きデータセットのフォーマットは、Bazilフォーマットです。


save
----

::

   $ easyjubatus.rb save [options] MODEL_NAME

現在のJubatusの状態を ``MODEL_NAME`` に保存します。
保存にはJubatusのsaveメソッドが利用されます。
``MODEL_NAME`` をloadすると、元の状態に戻すことができます。


load
----

::

   $ easyjubatus.rb load [options] MODEL_NAME

saveで保存されたモデルを読み込み、元の状態に復元します。
``MODEL_NAME`` はsaveのときに指定した名前を指定してください。


ライセンス
==========

このプログラムはMITライセンスのもと配布されています。

:author: Yuya Unno
:license: MIT

