
## strace

システムコール発行の可視化ができる

```bash
strace -o hello.log ./hello

```

## sar

システムコールを処理している時間の割合を表示

```bash
sar -P 0 1 1
```

## taskset

```bash
taskset -c <論理CPU番号> <コマンド>

taskset -c 0 ./task.py &

```
