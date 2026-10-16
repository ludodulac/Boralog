// BORALOG Cloudflare staging API — no Supabase, no public data access.
// Set BORALOG_BOOTSTRAP_TOKEN as a Worker secret. Never put it in source control.
// This is an administrative staging-only inspection API, NOT the finished app.
const json=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{"content-type":"application/json; charset=utf-8","cache-control":"no-store"}});
const timingSafe=(a,b)=>{if(typeof a!=="string"||typeof b!=="string"||a.length!==b.length)return false;let diff=0;for(let i=0;i<a.length;i++)diff|=a.charCodeAt(i)^b.charCodeAt(i);return diff===0};
export default {
 async fetch(request,env){
  const url=new URL(request.url);
  if(url.pathname==="/health"&&request.method==="GET")return json({ok:true,service:"boralog-staging",database:!!env.DB});
  if(url.pathname!=="/admin/schema-status")return json({ok:false,error:"Not found"},404);
  if(request.method!=="GET")return json({ok:false,error:"Method not allowed"},405);
  const token=request.headers.get("authorization")?.replace(/^Bearer /,"")??"";
  if(!env.BORALOG_BOOTSTRAP_TOKEN||!timingSafe(token,env.BORALOG_BOOTSTRAP_TOKEN))return json({ok:false,error:"Unauthorized"},401);
  if(!env.DB)return json({ok:false,error:"D1 binding missing"},503);
  try{
   const result=await env.DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name").all();
   return json({ok:true,tables:(result.results??[]).map(r=>r.name)});
  }catch{return json({ok:false,error:"Database unavailable"},503)}
 }
};
