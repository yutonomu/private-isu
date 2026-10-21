// k6からhttp処理のmoduleをimport
import http from "k6/http";

// k6からcheck関数をimport
import { check } from "k6";

// k6からHTMLをパースする関数をimport
import { parseHTML } from "k6/html";

// url関数をimport
import { url } from "./config.js";

// getAccount 関数を accounts.js から import
import { getAccount } from "./accounts.js";

// ベンチマーカーが実行するシナリオ関数
// ログインしてからコメントを投稿する
export default function () {
  // ランダムに1アカウントを選択
  const account = getAccount();
  // /login に対してアカウント名とパスワードを送信
  const login_res = http.post(url("/login"), {
    account_name: account.account_name,
    password: account.password,
  });

  // レスポンスのステータスコードが200であることを確認
  check(login_res, {
    "is status 200": (r) => r.status === 200,
  });

  // ログインしたユーザーのページ /@アカウント名 をGET
  const res = http.get(url(`/@${account.account_name}`));

  // レスポンスの内容をHTMLとして解釈
  const doc = parseHTML(res.body);

  // フォームのhidden要素からcsrf_token, post_idを抽出
  const token = doc.find('input[name="csrf_token"]').first().attr("value");
  const post_id = doc.find('input[name="post_id"]').first().attr("value");

  // /comment に対して、post_id, csrf_token とともにコメント本文をPOST
  const comment_res = http.post(url("/comment"), {
    post_id: post_id,
    csrf_token: token,
    comment: "Hello k6!",
  });
  check(comment_res, {
    "is status 200": (r) => r.status === 200,
  });
}
