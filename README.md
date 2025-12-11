# logs_archiver

### remover.sh

input arguments:

```
bash remover.sh /path/to/your/dir 'filter_mask*' 3 3
  ^       ^             ^               ^        ^ ^
  1       2             3               4        5 6
```

1 - interpreter
2 - script name (arg ``$0``)
3 - path to directory (arg ``$1``)
4 - mask for search (arg ``$2``)
5 - leave files (arg ``$3``)
6 - leave archives (arg ``$4``)
