#!/bin/sh
# MySQL のスロークエリログをローテートする（ローカル Docker 版）
#
# ログファイルは compose.yml で ./logs/mysql を /var/log/mysql にマウントしているため、
# ホスト側で mv し、ログを開き直す FLUSH LOGS だけコンテナ内の MySQL に送る。
set -eu

cd "$(dirname "$0")"

LOG_DIR=./logs/mysql

# 実行時点の日時を YYYYMMDD-HHMMSS 形式で付与したファイル名にローテートする
mv "$LOG_DIR/mysql-slow.log" "$LOG_DIR/mysql-slow.log.$(date +%Y%m%d-%H%M%S)"
# MySQL にログファイルを開き直させる
docker compose exec mysql mysqladmin -uroot -proot flush-logs
