var{Bun:h}=globalThis[Symbol.for("Bun.lazy")]("primordials"),p=h.readableStreamToArrayBuffer,c=h.readableStreamToText,g=(o)=>h.readableStreamToText(o).then(JSON.parse),i=async(o)=>{return new Buffer(await p(o))},k=h.readableStreamToBlob,q={[Symbol.for("CommonJS")]:0,arrayBuffer:p,text:c,json:g,buffer:i,blob:k};export{c as text,g as json,q as default,i as buffer,k as blob,p as arrayBuffer};
