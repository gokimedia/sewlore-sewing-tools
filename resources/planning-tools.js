import {buttonSpacing,rectangularLayout} from './planning-math.js';
const form=document.querySelector('#calculator'), result=document.querySelector('#result'), svg=document.querySelector('#diagram');
const num=id=>Number(document.querySelector('#'+id).value), fmt=x=>new Intl.NumberFormat('en',{maximumFractionDigits:4}).format(x);
function text(tag,value,cls){const e=document.createElement(tag);e.textContent=value;if(cls)e.className=cls;result.append(e);}
function shape(tag,attrs){const e=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const [k,v] of Object.entries(attrs))e.setAttribute(k,v);svg.append(e);return e;}
function run(){result.replaceChildren();svg.replaceChildren();try{
  if(document.querySelector('#count')){
    const L=num('length'), r=buttonSpacing(L,num('first'),num('last'),num('count')),unit=document.querySelector('#unit').value;
    text('p',fmt(r.spacing)+' '+unit+' between centres','metric');text('p','Positions from the top: '+r.positions.map(fmt).join(', ')+' '+unit+'.','positions');
    shape('line',{x1:30,y1:62,x2:510,y2:62,stroke:'#71827d','stroke-width':2});
    for(const p of r.positions){const x=30+480*p/L;shape('circle',{cx:x,cy:62,r:5,fill:'#8b3d2e'});if(r.positions.length<=15){const t=shape('text',{x,y:91,'text-anchor':'middle','font-size':12,fill:'#273a40'});t.textContent=fmt(p);}}
    svg.setAttribute('aria-label','Button centre positions from the top: '+r.positions.map(fmt).join(', ')+' '+unit);
  }else{
    const W=num('width'),L=num('length'),m=num('margin'),g=num('gap'),r=rectangularLayout(W,L,num('piece-width'),num('piece-length'),m,g,document.querySelector('#rotate').checked);
    text('p',fmt(r.count)+' rectangular pieces','metric');text('p',`${r.across} across × ${r.rows} rows. ${r.rotated?'The turned grid fits more pieces.':'The original orientation is selected.'}`);text('p',`Original grid: ${r.originalCount}. ${r.rotatedCount===null?'Rotation is disabled.':'Turned grid: '+r.rotatedCount+'.'} Usable fabric: ${fmt(r.usableWidth)} × ${fmt(r.usableLength)} cm.`);
    const s=Math.min(480/W,320/L);shape('rect',{x:30,y:28,width:W*s,height:L*s,fill:'#e2d7bd',stroke:'#71827d'});shape('rect',{x:30+m*s,y:28+m*s,width:r.usableWidth*s,height:r.usableLength*s,fill:'#f9f7f1',stroke:'#8b3d2e','stroke-dasharray':'5 4'});
    const shown=Math.min(r.count,100);for(let i=0;i<shown;i++){let col=i%r.across,row=Math.floor(i/r.across);shape('rect',{x:30+(m+col*(r.pieceWidth+g))*s,y:28+(m+row*(r.pieceLength+g))*s,width:r.pieceWidth*s,height:r.pieceLength*s,fill:'#becec3',stroke:'#536e62','stroke-width':.8});}
    if(r.count>100)text('p','The diagram shows the first 100 pieces; the count includes the full grid.');if(r.count===0)text('p','Neither permitted uniform grid fits a complete piece.');
    svg.setAttribute('aria-label',`${r.across} columns and ${r.rows} rows of rectangular pieces within the fabric margins. ${shown} of ${r.count} pieces drawn.`);
  }
}catch(e){text('p',e.message,'error');}}
form.addEventListener('submit',e=>{e.preventDefault();if(form.reportValidity())run();});form.addEventListener('input',()=>{result.replaceChildren();svg.replaceChildren();text('p','Inputs changed. Calculate again to update the result.');});run();
