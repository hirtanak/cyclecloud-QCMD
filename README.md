# Azure CycleCloud template for Quantum Chemistry and Molecular Dynamics (QCMD)

## Prerequisites

1. Install CycleCloud CLI

## Applications

### Cluster Application
1. QuantumESPRESOO 6.5
1. ESM RISM QuantumESPRESOO (9th May 2020 Update: Missing the original link)
1. LAMMPS 7Aug2019, 3Mar2020, 29Oct2020, 29Sep2021
1. GROMACS 2020, 2019
1. GAMESS US (Need to get source file set up project.ini and locates in blobs directory)
1. NAMD 2.14b1 (Need to get source file set up project.ini and locates in blobs directory)

### Windows VM Application
1. Paraview 5.7.0
1. VMD 1.9.3 (Need to get source file set up project.ini and locates in blobs directory)

### Support Functions
1. OSS PBS Pro job scheduler environment
1. NFS Server 1TB in master node
1. Fixed Global IP
1. Support VM: H16r, H16r_Promo, HC44rs, HB60rs, HB120rs_v2 
1. Windows NFS client and mount (WIP)

## How to install 

1. tar zxvf cyclecloud-QCMD<version>.tar.gz
1. cd cyclecloud-QCMD<version>
1. run "cyclecloud project upload azure-storage" for uploading template to CycleCloud
1. "cyclecloud import_template -f templates/pbs_extended_nfs_qcmd.txt" for register this template to your CycleCloud

## How to run QCMD

1. Create Execute Node manually
1. Check Node IP Address
1. Create hosts file for your nodes
1. qsub ~/qerub.sh

## Known Issues
1. This tempate support only single administrator. So you have to use same user between superuser(initial Azure CycleCloud User) and deployment user of this template

# Azure CycleCloud用テンプレート:QCMD with OSS PBS Pro

[Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) はMicrosoft Azure上で簡単にCAE/HPC/Deep Learning用のクラスタ環境を構築できるソリューションです。

![Azure CycleCloudの構築・テンプレート構成](https://raw.githubusercontent.com/hirtanak/osspbsdefault/master/AzureCycleCloud-OSSPBSDefault.png "Azure CycleCloudの構築・テンプレート構成")

Azure CyceCloudのインストールに関しては、[こちら](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) のドキュメントを参照してください。

第一原理、量子化学、分子動力学アプリケーション用のテンプレートになっています。
以下の構成、特徴を持っています。

## Cluster アプリケーション
1. QuantumESPRESOO 6.5
1. ESM RISM QuantumESPRESOO (2020/5/9 Update: オリジナルのリンクがないため動作しない)
1. LAMMPS 7Aug2019, 3Mar2020
1. GROMACS 2020, 2019
1. GAMESS US (無料ですが、ライセンス制のため自身でファイル取得とproject.ini, blobsディレクトリへの設置が必要です)
1. NAMD 2.14b1 (無料ですが、ライセンス制のため自身でファイル取得とproject.ini, blobsディレクトリへの設置が必要です)

## Windows VM アプリケーション
1. Paraview 5.7.0
1. VMD 1.9.3 (無料ですが、ライセンス制のため自身でファイル取得とproject.ini, blobsディレクトリへの設置が必要です)

## その他の機能
1. OSS PBS ProジョブスケジューラをMasterノードにインストール、計算ノード(Execノード)にも自動設定
1. H16r, H16r_Promo, HC44rs, HB60rs, HB120rs_v2を想定したテンプレート、イメージ
	 - OpenLogic CentOS 7.6 HPC を利用 
1. Masterノードに512GB * 2 のNFSストレージサーバを搭載
	 - Executeノード（計算ノード）からNFSをマウント
1. MasterノードのIPアドレスを固定設定
	 - 一旦停止後、再度起動した場合にアクセスする先のIPアドレスが変更されない

![OSS PBS Default テンプレート構成](https://raw.githubusercontent.com/hirtanak/osspbsdefault/master/OSSPBSDefaultDiagram.png "OSS PBS Default テンプレート構成")

## QCMDテンプレートインストール方法

前提条件: テンプレートを利用するためには、Azure CycleCloud CLIのインストールと設定が必要です。詳しくは、 [こちら](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli) の文書からインストールと展開されたAzure CycleCloudサーバのFQDNの設定が必要です。

1. テンプレート本体をダウンロード
1. 展開、ディレクトリ移動
1. cyclecloudコマンドラインからテンプレートインストール 
   - tar zxvf cyclecloud-QCMD<version>.tar.gz
   - cd cyclecloud-QCMD<version>
   - cyclecloud project upload azure-storage
   - cyclecloud import_template -f templates/pbs_extended_nfs_quantumespresso.txt
1. 削除したい場合、 cyclecloud delete_template QCMD コマンドで削除可能

***
Copyright Hiroshi Tanaka, hirtanak@gmail.com, @hirtanak All rights reserved.
Use of this source code is governed by MIT license that can be found in the LICENSE file.

