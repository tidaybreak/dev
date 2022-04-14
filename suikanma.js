/*
README：https://github.com/yichahucha/surge/tree/master
 */

const path1 = "serverConfig";
const path2 = "wareBusiness";
const path3 = "basicConfig";
const url = $request.url;
const body = $response.body;

let obj = JSON.parse(body);
$done({ body: "xxx" });
