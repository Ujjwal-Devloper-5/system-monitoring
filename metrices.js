const baseurl="http://localhost:9100/metrics";

async function getMetrics(){
    const response=await fetch(baseurl);
    const data=await response.text();
    console.log(data);
}
getMetrics();