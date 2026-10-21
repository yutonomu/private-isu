// http処理のmoduleをimport
import http from "k6/http";

// HTMLをパースする関数をimport
import { parseHTML } from "k6/html";

// リクエスト対象URLを生成する関数をimport
import { url } from "./config.js";

// getAccount 関数を accounts.js から import
import { getAccount } from "./accounts.js";

// ファイルをバイナリとして開く
const testImage = open("testimage.jpg", "b");

// k6が実行する関数
// ログインして画像を投稿するシナリオ
export default function () {
  // ランダムに1アカウントを選択
  const account = getAccount();
  // /login に対して送信
  const res = http.post(url("/login"), {
    account_name: account.account_name,
    password: account.password,
  });
  const doc = parseHTML(res.body);
  const token = doc.find('input[name="csrf_token"]').first().attr("value");
  http.post(url("/"), {
    // http.fileでファイルアップロードを行う
    file: http.file(testImage, "testimage.jpg", "image/jpeg"),
    body: "Posted by k6",
    csrf_token: token,
  });
}
