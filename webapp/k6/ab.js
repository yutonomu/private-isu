import http from "k6/http";

const BASE_URL = "http://localhost:8080";

export default function () {
  http.get(`${BASE_URL}/`);
}
