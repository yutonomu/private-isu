#!/bin/sh
# query-digester（kazeburo/query-digester）の Docker 版
#
# 指定した秒数だけスロークエリログの出力先を一時ファイルに切り替えて取得し、
# 元の設定に戻してから pt-query-digest で解析する。
# MySQL はコンテナ内で動いているため、ログの出力先は compose.yml で
# ./logs/mysql にマウントしている /var/log/mysql 配下にする。
#
# 使い方: ./query-digester.sh [-duration 秒] [-limit 件数] [-stdout] [-clear-log]
set -eu

cd "$(dirname "$0")"

DURATION=10
LIMIT=40
STDOUT=0
CLEAR_LOG=0
while [ $# -gt 0 ]; do
  case "$1" in
    -duration) DURATION="$2"; shift 2 ;;
    -limit) LIMIT="$2"; shift 2 ;;
    -stdout) STDOUT=1; shift ;;
    -clear-log) CLEAR_LOG=1; shift ;;
    -h|-help|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

command -v pt-query-digest >/dev/null || { echo "could not find pt-query-digest" >&2; exit 1; }

mysql() {
  docker compose exec -T mysql mysql -uroot -proot "$@" 2>&1 | grep -v 'Using a password' || true
}

DATE=$(date +%Y%m%d%H%M%S)
CONTAINER_LOG="/var/log/mysql/slow_query_$DATE.log"   # MySQL から見たパス
HOST_LOG="./logs/mysql/slow_query_$DATE.log"           # ホストから見た同じファイル
DIGEST="./logs/mysql/slow_query_$DATE.digest"

# 現在の設定を控える
read -r CUR_LONG_QUERY_TIME CUR_SLOW_QUERY_LOG_FILE CUR_SLOW_QUERY_LOG <<EOS
$(mysql -N -e 'SELECT @@long_query_time, @@slow_query_log_file, @@slow_query_log')
EOS

restore() {
  mysql -e "SET GLOBAL long_query_time = $CUR_LONG_QUERY_TIME;
            SET GLOBAL slow_query_log_file = '$CUR_SLOW_QUERY_LOG_FILE';
            SET GLOBAL slow_query_log = $CUR_SLOW_QUERY_LOG;"
}

echo "exec mysql to change long_query_time and slow_query_log_file" >&2
echo "save slowlog to $HOST_LOG" >&2
mysql -e "SET GLOBAL slow_query_log_file = '$CONTAINER_LOG';
          SET GLOBAL long_query_time = 0;
          SET GLOBAL slow_query_log = 1;"

# Ctrl+C で中断しても設定を元に戻す
trap 'restore; exit 130' INT TERM

echo "wait $DURATION seconds" >&2
sleep "$DURATION"

restore
trap - INT TERM
echo "finished capturing slowlog." >&2

echo "start query-digest" >&2
if [ "$STDOUT" -eq 1 ]; then
  pt-query-digest --limit "$LIMIT" "$HOST_LOG"
else
  pt-query-digest --limit "$LIMIT" "$HOST_LOG" > "$DIGEST"
fi
echo "finished pt-query-digest." >&2
[ "$STDOUT" -eq 1 ] || echo "digest saved to $DIGEST" >&2
[ "$CLEAR_LOG" -eq 1 ] && rm -f "$HOST_LOG"
exit 0
