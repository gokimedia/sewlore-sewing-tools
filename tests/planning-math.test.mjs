import test from 'node:test';
import assert from 'node:assert/strict';
import {buttonSpacing,rectangularLayout} from '../resources/planning-math.js';
test('button centres obey endpoints, equal intervals and unit scaling',()=>{
 const r=buttonSpacing(60,3,3,7);assert.deepEqual(r.positions,[3,12,21,30,39,48,57]);
 for(const factor of [0.1,25.4,10]){const s=buttonSpacing(60*factor,3*factor,3*factor,7);for(let i=0;i<s.positions.length;i++)assert.ok(Math.abs(s.positions[i]-r.positions[i]*factor)<1e-9);}
 assert.throws(()=>buttonSpacing(60,30,30,2));assert.throws(()=>buttonSpacing(60,3,3,1));assert.throws(()=>buttonSpacing(Infinity,3,3,7));
});
test('rectangular grids include every gap and stay inside the usable edges',()=>{
 for(const rotate of [false,true])for(const gap of [0,0.5,2]){
 const r=rectangularLayout(140,100,20,30,2,gap,rotate);
 assert.ok(r.across*r.pieceWidth+Math.max(0,r.across-1)*gap<=r.usableWidth+1e-9);
 assert.ok(r.rows*r.pieceLength+Math.max(0,r.rows-1)*gap<=r.usableLength+1e-9);
 assert.equal(r.count,r.across*r.rows);
 if(rotate)assert.ok(r.count>=r.originalCount);
 }
 assert.equal(rectangularLayout(140,100,20,30,2,0,true).count,18);
 assert.equal(rectangularLayout(62,42,20,30,1,0,true).count,4);
 assert.equal(rectangularLayout(10,10,20,30,0,0,false).count,0);
 assert.equal(rectangularLayout(30,10,10,10,0,0,false).count,3);
 assert.equal(rectangularLayout(32,10,10,10,0,1,false).count,3);
 assert.throws(()=>rectangularLayout(10,10,2,2,5,0,false));
});
