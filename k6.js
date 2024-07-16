import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 600 },
    { duration: "20m", target: 600 },
  ],
};

export default function () {
  const res = http.get("https://nilsherzig.com");
  check(res, { "status was 200": (r) => r.status == 200 });
  sleep(1);
}
