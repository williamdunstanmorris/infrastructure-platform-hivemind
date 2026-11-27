import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s',  target: 200 },    // warm-up
    { duration: '1m', target: 5000 },   // spike
    { duration: '2m',  target: 8000 },   // hold: HPA should react
    { duration: '1m', target: 500 },    // slow decline: watch scale-in
    { duration: '30s',  target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const r = http.get('https://hivemind.subcloudlabs.com/?name=load');
  check(r, { 'status 200': (res) => res.status === 200 });
  sleep(0.5);   // each virtual user does ~2 req/s, so 300 users is roughly 600 req/s
}