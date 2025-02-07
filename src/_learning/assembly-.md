# Processor Registers Overview

Processor Registersは大きく分けて３つのグループがあります。

1. General Registers（汎用レジスタ）
2. Control Registers（制御レジスタ）
3. Segment Registers（セグメントレジスタ）

## General Registers

General Registersないでさはさらに３つのグループがあります

1. Data Registers
2. Pointer Registers
3. Index Registers

### Data Registers

以下の4つのデータレジスタは算術、論理、およびその他の操作に使用されます：

| 32-bit Register | 16-bit Register | 8-bit Register (Lower/Upper) |
|-----------------|-----------------|-----------------------------|
| EAX             | AX              | AH, AL                      |
| EBX             | BX              | BH, BL                      |
| ECX             | CX              | CH, CL                      |
| EDX             | DX              | DH, DL                      |

用途：

- AX: accumulator register（算術操作や入出力）
- BX: base register（インデックス付きアドレッシング）
- CX: count register（ループカウント用）
- DX: data register（大規模な演算でAXと共に使用）

### Pointer Registers

以下の3種類のポインタレジスタがあります：

| 32-bit Register | 16-bit Register |
|-----------------|-----------------|
| EIP             | IP              |
| ESP             | SP              |
| EBP             | BP              |

用途：

- Instruction Pointer (IP): 16-bit IPは次の命令アドレスを格納（CS(Code Segment):IPで完全アドレス）。
- Stack Pointer (SP): SPはスタック内の現在位置をSS(Stack Segment):SPで示す。
  - スタック はプログラムの一時的なデータ保存に使用されるメモリ領域
- Base Pointer (BP): BPはサブルーチンのパラメータ位置を参照し、特殊アドレッシングに対応。

### Index Registers

以下の2種類のインデックスレジスタがあります：

| 32-bit Register | 16-bit Register | 用途                          |
|-----------------|-----------------|-----------------------------|
| ESI             | SI              | 文字列操作のソースインデックス |
| EDI             | DI              | 文字列操作のデスティネーションインデックス |

用途：

- Source Index (SI): データの出発地点（ソース） を指します
- Destination Index (DI): データの到着地点（デスティネーション） を指します

## Control Registers
