import http from 'k6/http';

export default function () {
  for (let i = 0; i < 10; i++) {
    let res = http.post(
      'http://localhost:3001/api/v1/auth/login',
      JSON.stringify({email: "loadtest.admin@jeeb.com", password: "password"}),
      {headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}}
    );
    console.log('Req ' + i + ': Status ' + res.status + ' Body ' + res.body.substring(0, 80));
  }
}
