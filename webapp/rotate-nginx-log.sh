#!/bin/sh
# nginx のアクセスログをローテートする（ローカル Docker 版）
#
# ログファイルは compose.yml で ./logs/nginx を /var/log/nginx にマウントしているため、
# ホスト側で mv し、ログを開き直すシグナルだけコンテナ内の nginx に送る。
set -eu

cd "$(dirname "$0")"

LOG_DIR=./logs/nginx

# 実行時点の日時を YYYYMMDD-HHMMSS 形式で付与したファイル名にローテートする
mv "$LOG_DIR/access.log" "$LOG_DIR/access.log.$(date +%Y%m%d-%H%M%S)"
# nginx にログファイルを開き直すシグナルを送信する
docker compose exec nginx nginx -s reopen
