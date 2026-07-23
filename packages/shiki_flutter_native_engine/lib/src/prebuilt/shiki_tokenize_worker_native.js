(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.mk(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)A.c(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.ht(b)
return new s(c,this)}:function(){if(s===null)s=A.ht(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.ht(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
hy(a,b,c,d){return{i:a,p:b,e:c,x:d}},
hu(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.hv==null){A.m1()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.e(A.ie("Return interceptor for "+A.n(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.eQ
if(o==null)o=$.eQ=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.m6(a)
if(p!=null)return p
if(typeof a=="function")return B.L
s=Object.getPrototypeOf(a)
if(s==null)return B.m
if(s===Object.prototype)return B.m
if(typeof q=="function"){o=$.eQ
if(o==null)o=$.eQ=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.i,enumerable:false,writable:true,configurable:true})
return B.i}return B.i},
jX(a,b){if(a<0||a>4294967295)throw A.e(A.ar(a,0,4294967295,"length",null))
return J.jZ(new Array(a),b)},
jY(a,b){if(a<0)throw A.e(A.bb("Length must be a non-negative integer: "+a,null))
return A.c(new Array(a),b.h("j<0>"))},
hT(a,b){if(a<0)throw A.e(A.bb("Length must be a non-negative integer: "+a,null))
return A.c(new Array(a),b.h("j<0>"))},
jZ(a,b){var s=A.c(a,b.h("j<0>"))
s.$flags=1
return s},
k_(a,b){var s=t.e8
return J.jC(s.a(a),s.a(b))},
hU(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
k0(a,b){var s,r
for(s=a.length;b<s;){r=a.charCodeAt(b)
if(r!==32&&r!==13&&!J.hU(r))break;++b}return b},
k1(a,b){var s,r,q
for(s=a.length;b>0;b=r){r=b-1
if(!(r<s))return A.a(a,r)
q=a.charCodeAt(r)
if(q!==32&&q!==13&&!J.hU(q))break}return b},
b8(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.bG.prototype
return J.cH.prototype}if(typeof a=="string")return J.aD.prototype
if(a==null)return J.bH.prototype
if(typeof a=="boolean")return J.cG.prototype
if(Array.isArray(a))return J.j.prototype
if(typeof a!="object"){if(typeof a=="function")return J.al.prototype
if(typeof a=="symbol")return J.bL.prototype
if(typeof a=="bigint")return J.bJ.prototype
return a}if(a instanceof A.k)return a
return J.hu(a)},
aK(a){if(typeof a=="string")return J.aD.prototype
if(a==null)return a
if(Array.isArray(a))return J.j.prototype
if(typeof a!="object"){if(typeof a=="function")return J.al.prototype
if(typeof a=="symbol")return J.bL.prototype
if(typeof a=="bigint")return J.bJ.prototype
return a}if(a instanceof A.k)return a
return J.hu(a)},
dF(a){if(a==null)return a
if(Array.isArray(a))return J.j.prototype
if(typeof a!="object"){if(typeof a=="function")return J.al.prototype
if(typeof a=="symbol")return J.bL.prototype
if(typeof a=="bigint")return J.bJ.prototype
return a}if(a instanceof A.k)return a
return J.hu(a)},
lU(a){if(typeof a=="number")return J.be.prototype
if(typeof a=="string")return J.aD.prototype
if(a==null)return a
if(!(a instanceof A.k))return J.aY.prototype
return a},
lV(a){if(typeof a=="string")return J.aD.prototype
if(a==null)return a
if(!(a instanceof A.k))return J.aY.prototype
return a},
bx(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.b8(a).W(a,b)},
jz(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.m4(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.aK(a).i(a,b)},
jA(a,b){return J.dF(a).j(a,b)},
jB(a,b){return J.lV(a).ac(a,b)},
ct(a,b){return J.dF(a).ad(a,b)},
jC(a,b){return J.lU(a).av(a,b)},
hJ(a,b){return J.dF(a).F(a,b)},
ae(a){return J.b8(a).gD(a)},
jD(a){return J.aK(a).gu(a)},
jE(a){return J.aK(a).gN(a)},
af(a){return J.dF(a).gt(a)},
ay(a){return J.aK(a).gm(a)},
jF(a){return J.b8(a).gC(a)},
dG(a,b,c){return J.dF(a).aK(a,b,c)},
a_(a){return J.b8(a).k(a)},
cE:function cE(){},
cG:function cG(){},
bH:function bH(){},
bK:function bK(){},
aE:function aE(){},
cW:function cW(){},
aY:function aY(){},
al:function al(){},
bJ:function bJ(){},
bL:function bL(){},
j:function j(a){this.$ti=a},
cF:function cF(){},
dV:function dV(a){this.$ti=a},
aN:function aN(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
be:function be(){},
bG:function bG(){},
cH:function cH(){},
aD:function aD(){}},A={h2:function h2(){},
hQ(a,b,c){if(t.U.b(a))return new A.c6(a,b.h("@<0>").q(c).h("c6<1,2>"))
return new A.aQ(a,b.h("@<0>").q(c).h("aQ<1,2>"))},
k2(a){return new A.an("Field '"+a+"' has been assigned during initialization.")},
k4(a){return new A.an("Field '"+a+"' has not been initialized.")},
h4(a){return new A.an("Local '"+a+"' has not been initialized.")},
k3(a){return new A.an("Field '"+a+"' has already been initialized.")},
aH(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
hb(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
hs(a,b,c){return a},
hw(a){var s,r
for(s=$.Z.length,r=0;r<s;++r)if(a===$.Z[r])return!0
return!1},
k6(a,b,c,d){if(t.U.b(a))return new A.bC(a,b,c.h("@<0>").q(d).h("bC<1,2>"))
return new A.aV(a,b,c.h("@<0>").q(d).h("aV<1,2>"))},
h0(){return new A.c0("No element")},
aI:function aI(){},
bz:function bz(a,b){this.a=a
this.$ti=b},
aQ:function aQ(a,b){this.a=a
this.$ti=b},
c6:function c6(a,b){this.a=a
this.$ti=b},
c5:function c5(){},
ag:function ag(a,b){this.a=a
this.$ti=b},
aR:function aR(a,b){this.a=a
this.$ti=b},
dL:function dL(a,b){this.a=a
this.b=b},
an:function an(a){this.a=a},
el:function el(){},
i:function i(){},
B:function B(){},
V:function V(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aV:function aV(a,b,c){this.a=a
this.b=b
this.$ti=c},
bC:function bC(a,b,c){this.a=a
this.b=b
this.$ti=c},
bO:function bO(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
X:function X(a,b,c){this.a=a
this.b=b
this.$ti=c},
P:function P(){},
av:function av(a,b){this.a=a
this.$ti=b},
co:function co(){},
jb(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
m4(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.aU.b(a)},
n(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.a_(a)
return s},
cX(a){var s,r=$.i3
if(r==null)r=$.i3=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
h6(a,b){var s,r,q,p,o,n=null,m=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(m==null)return n
if(3>=m.length)return A.a(m,3)
s=m[3]
if(b==null){if(s!=null)return parseInt(a,10)
if(m[2]!=null)return parseInt(a,16)
return n}if(b<2||b>36)throw A.e(A.ar(b,2,36,"radix",n))
if(b===10&&s!=null)return parseInt(a,10)
if(b<10||s==null){r=b<=10?47+b:86+b
q=m[1]
for(p=q.length,o=0;o<p;++o)if((q.charCodeAt(o)|32)>r)return n}return parseInt(a,b)},
cY(a){var s,r,q,p
if(a instanceof A.k)return A.Q(A.b9(a),null)
s=J.b8(a)
if(s===B.J||s===B.M||t.ak.b(a)){r=B.j(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.Q(A.b9(a),null)},
i4(a){var s,r,q
if(a==null||typeof a=="number"||A.fe(a))return J.a_(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.aB)return a.k(0)
if(a instanceof A.b1)return a.bc(!0)
s=$.ju()
for(r=0;r<1;++r){q=s[r].cH(a)
if(q!=null)return q}return"Instance of '"+A.cY(a)+"'"},
L(a){var s
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.d.a_(s,10)|55296)>>>0,s&1023|56320)}}throw A.e(A.ar(a,0,1114111,null,null))},
kd(a){var s=a.$thrownJsError
if(s==null)return null
return A.aL(s)},
i5(a,b){var s
if(a.$thrownJsError==null){s=new Error()
A.A(a,s)
a.$thrownJsError=s
s.stack=b.k(0)}},
m_(a){throw A.e(A.lI(a))},
a(a,b){if(a==null)J.ay(a)
throw A.e(A.fw(a,b))},
fw(a,b){var s,r="index"
if(!A.iG(b))return new A.aa(!0,b,r,null)
s=A.u(J.ay(a))
if(b<0||b>=s)return A.fZ(b,s,a,r)
return A.ea(b,r)},
lI(a){return new A.aa(!0,a,null,null)},
e(a){return A.A(a,new Error())},
A(a,b){var s
if(a==null)a=new A.aw()
b.dartException=a
s=A.mm
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
mm(){return J.a_(this.dartException)},
O(a,b){throw A.A(a,b==null?new Error():b)},
cs(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.O(A.l1(a,b,c),s)},
l1(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.j.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new A.c3("'"+s+"': Cannot "+o+" "+l+k+n)},
y(a){throw A.e(A.aj(a))},
ax(a){var s,r,q,p,o,n
a=A.j5(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.c([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.ev(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
ew(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
id(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
h3(a,b){var s=b==null,r=s?null:b.method
return new A.cI(a,r,s?null:b.receiver)},
a9(a){var s
if(a==null)return new A.e4(a)
if(a instanceof A.bD){s=a.a
return A.aM(a,s==null?A.b3(s):s)}if(typeof a!=="object")return a
if("dartException" in a)return A.aM(a,a.dartException)
return A.lG(a)},
aM(a,b){if(t.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
lG(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.d.a_(r,16)&8191)===10)switch(q){case 438:return A.aM(a,A.h3(A.n(s)+" (Error "+q+")",null))
case 445:case 5007:A.n(s)
return A.aM(a,new A.bV())}}if(a instanceof TypeError){p=$.jf()
o=$.jg()
n=$.jh()
m=$.ji()
l=$.jl()
k=$.jm()
j=$.jk()
$.jj()
i=$.jo()
h=$.jn()
g=p.J(s)
if(g!=null)return A.aM(a,A.h3(A.v(s),g))
else{g=o.J(s)
if(g!=null){g.method="call"
return A.aM(a,A.h3(A.v(s),g))}else if(n.J(s)!=null||m.J(s)!=null||l.J(s)!=null||k.J(s)!=null||j.J(s)!=null||m.J(s)!=null||i.J(s)!=null||h.J(s)!=null){A.v(s)
return A.aM(a,new A.bV())}}return A.aM(a,new A.de(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.c_()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.aM(a,new A.aa(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.c_()
return a},
aL(a){var s
if(a instanceof A.bD)return a.b
if(a==null)return new A.ci(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.ci(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
j1(a){if(a==null)return J.ae(a)
if(typeof a=="object")return A.cX(a)
return J.ae(a)},
lT(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.l(0,a[s],a[r])}return b},
lc(a,b,c,d,e,f){t.Z.a(a)
switch(A.u(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.e(new A.eE("Unsupported number of arguments for wrapped closure"))},
b6(a,b){var s
if(a==null)return null
s=a.$identity
if(!!s)return s
s=A.lO(a,b)
a.$identity=s
return s},
lO(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.lc)},
jM(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.d3().constructor.prototype):Object.create(new A.bc(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.hR(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.jI(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.hR(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
jI(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.e("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.jG)}throw A.e("Error in functionType of tearoff")},
jJ(a,b,c,d){var s=A.hP
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
hR(a,b,c,d){if(c)return A.jL(a,b,d)
return A.jJ(b.length,d,a,b)},
jK(a,b,c,d){var s=A.hP,r=A.jH
switch(b?-1:a){case 0:throw A.e(new A.d1("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
jL(a,b,c){var s,r
if($.hN==null)$.hN=A.hM("interceptor")
if($.hO==null)$.hO=A.hM("receiver")
s=b.length
r=A.jK(s,c,a,b)
return r},
ht(a){return A.jM(a)},
jG(a,b){return A.cm(v.typeUniverse,A.b9(a.a),b)},
hP(a){return a.a},
jH(a){return a.b},
hM(a){var s,r,q,p=new A.bc("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.e(A.bb("Field name "+a+" not found.",null))},
iX(a){return v.getIsolateTag(a)},
mp(a,b){var s=$.x
if(s===B.c)return a
return s.ci(a,b)},
n2(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
m6(a){var s,r,q,p,o,n=A.v($.iY.$1(a)),m=$.fx[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.fC[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=A.C($.iQ.$2(a,n))
if(q!=null){m=$.fx[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.fC[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.fF(s)
$.fx[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.fC[n]=s
return s}if(p==="-"){o=A.fF(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.j3(a,s)
if(p==="*")throw A.e(A.ie(n))
if(v.leafTags[n]===true){o=A.fF(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.j3(a,s)},
j3(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.hy(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
fF(a){return J.hy(a,!1,null,!!a.$iU)},
m8(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.fF(s)
else return J.hy(s,c,null,null)},
m1(){if(!0===$.hv)return
$.hv=!0
A.m2()},
m2(){var s,r,q,p,o,n,m,l
$.fx=Object.create(null)
$.fC=Object.create(null)
A.m0()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.j4.$1(o)
if(n!=null){m=A.m8(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
m0(){var s,r,q,p,o,n,m=B.n()
m=A.bv(B.o,A.bv(B.p,A.bv(B.k,A.bv(B.k,A.bv(B.q,A.bv(B.r,A.bv(B.t(B.j),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.iY=new A.fz(p)
$.iQ=new A.fA(o)
$.j4=new A.fB(n)},
bv(a,b){return a(b)||b},
lR(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
hV(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,s+r+q+p+f)
if(o instanceof RegExp)return o
throw A.e(A.fY("Illegal RegExp pattern ("+String(o)+")",a))},
mf(a,b,c){var s=a.indexOf(b,c)
return s>=0},
iV(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
j5(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
hB(a,b,c){var s
if(typeof b=="string")return A.mh(a,b,c)
if(b instanceof A.bI){s=b.gb8()
s.lastIndex=0
return a.replace(s,A.iV(c))}return A.mg(a,b,c)},
mg(a,b,c){var s,r,q,p
for(s=J.jB(b,a),s=s.gt(s),r=0,q="";s.n();){p=s.gp()
q=q+a.substring(r,p.gaT())+c
r=p.gaD()}s=q+a.substring(r)
return s.charCodeAt(0)==0?s:s},
mh(a,b,c){var s,r,q
if(b===""){if(a==="")return c
s=a.length
for(r=c,q=0;q<s;++q)r=r+a[q]+c
return r.charCodeAt(0)==0?r:r}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.j5(b),"g"),A.iV(c))},
iP(a){return a},
hA(a,b,c,d){var s,r,q,p,o,n,m
for(s=b.ac(0,a),s=new A.bo(s.a,s.b,s.c),r=t.d,q=0,p="";s.n();){o=s.d
if(o==null)o=r.a(o)
n=o.b
m=n.index
p=p+A.n(A.iP(B.b.A(a,q,m)))+A.n(c.$1(o))
q=m+n[0].length}s=p+A.n(A.iP(B.b.O(a,q)))
return s.charCodeAt(0)==0?s:s},
b2:function b2(a,b){this.a=a
this.b=b},
bA:function bA(){},
bB:function bB(a,b,c){this.a=a
this.b=b
this.$ti=c},
c7:function c7(a,b){this.a=a
this.$ti=b},
c8:function c8(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bY:function bY(){},
ev:function ev(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bV:function bV(){},
cI:function cI(a,b,c){this.a=a
this.b=b
this.c=c},
de:function de(a){this.a=a},
e4:function e4(a){this.a=a},
bD:function bD(a,b){this.a=a
this.b=b},
ci:function ci(a){this.a=a
this.b=null},
aB:function aB(){},
cw:function cw(){},
cx:function cx(){},
d7:function d7(){},
d3:function d3(){},
bc:function bc(a,b){this.a=a
this.b=b},
d1:function d1(a){this.a=a},
am:function am(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
dW:function dW(a){this.a=a},
e_:function e_(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
ao:function ao(a,b){this.a=a
this.$ti=b},
aU:function aU(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
a4:function a4(a,b){this.a=a
this.$ti=b},
bN:function bN(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
fz:function fz(a){this.a=a},
fA:function fA(a){this.a=a},
fB:function fB(a){this.a=a},
b1:function b1(){},
bq:function bq(){},
bI:function bI(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
cb:function cb(a){this.b=a},
dg:function dg(a,b,c){this.a=a
this.b=b
this.c=c},
bo:function bo(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
d4:function d4(a,b){this.a=a
this.c=b},
dy:function dy(a,b,c){this.a=a
this.b=b
this.c=c},
dz:function dz(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
mk(a){throw A.A(A.k2(a),new Error())},
q(){throw A.A(A.k4(""),new Error())},
j9(){throw A.A(A.k3(""),new Error())},
he(){var s=new A.eD()
return s.b=s},
eD:function eD(){this.b=null},
k7(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
b4(a,b,c){if(a>>>0!==a||a>=c)throw A.e(A.fw(b,a))},
bg:function bg(){},
bf:function bf(){},
bT:function bT(){},
cM:function cM(){},
bi:function bi(){},
bR:function bR(){},
bS:function bS(){},
cN:function cN(){},
cO:function cO(){},
cP:function cP(){},
bh:function bh(){},
cQ:function cQ(){},
cR:function cR(){},
cS:function cS(){},
bU:function bU(){},
cT:function cT(){},
cd:function cd(){},
ce:function ce(){},
cf:function cf(){},
cg:function cg(){},
h7(a,b){var s=b.c
return s==null?b.c=A.ck(a,"a1",[b.x]):s},
ia(a){var s=a.w
if(s===6||s===7)return A.ia(a.x)
return s===11||s===12},
kh(a){return a.as},
dE(a){return A.f3(v.typeUniverse,a,!1)},
b5(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.b5(a1,s,a3,a4)
if(r===s)return a2
return A.is(a1,r,!0)
case 7:s=a2.x
r=A.b5(a1,s,a3,a4)
if(r===s)return a2
return A.ir(a1,r,!0)
case 8:q=a2.y
p=A.bu(a1,q,a3,a4)
if(p===q)return a2
return A.ck(a1,a2.x,p)
case 9:o=a2.x
n=A.b5(a1,o,a3,a4)
m=a2.y
l=A.bu(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.hh(a1,n,l)
case 10:k=a2.x
j=a2.y
i=A.bu(a1,j,a3,a4)
if(i===j)return a2
return A.it(a1,k,i)
case 11:h=a2.x
g=A.b5(a1,h,a3,a4)
f=a2.y
e=A.lD(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.iq(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=A.bu(a1,d,a3,a4)
o=a2.x
n=A.b5(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.hi(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.e(A.cv("Attempted to substitute unexpected RTI kind "+a0))}},
bu(a,b,c,d){var s,r,q,p,o=b.length,n=A.f4(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.b5(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
lE(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.f4(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.b5(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
lD(a,b,c,d){var s,r=b.a,q=A.bu(a,r,c,d),p=b.b,o=A.bu(a,p,c,d),n=b.c,m=A.lE(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.dq()
s.a=q
s.b=o
s.c=m
return s},
c(a,b){a[v.arrayRti]=b
return a},
iS(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.lY(s)
return a.$S()}return null},
m3(a,b){var s
if(A.ia(b))if(a instanceof A.aB){s=A.iS(a)
if(s!=null)return s}return A.b9(a)},
b9(a){if(a instanceof A.k)return A.p(a)
if(Array.isArray(a))return A.G(a)
return A.hn(J.b8(a))},
G(a){var s=a[v.arrayRti],r=t.q
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
p(a){var s=a.$ti
return s!=null?s:A.hn(a)},
hn(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.l8(a,s)},
l8(a,b){var s=a instanceof A.aB?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.kP(v.typeUniverse,s.name)
b.$ccache=r
return r},
lY(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.f3(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
lX(a){return A.b7(A.p(a))},
hq(a){var s
if(a instanceof A.b1)return A.lS(a.$r,a.b5())
s=a instanceof A.aB?A.iS(a):null
if(s!=null)return s
if(t.ci.b(a))return J.jF(a).a
if(Array.isArray(a))return A.G(a)
return A.b9(a)},
b7(a){var s=a.r
return s==null?a.r=new A.f2(a):s},
lS(a,b){var s,r,q=b,p=q.length
if(p===0)return t.bQ
if(0>=p)return A.a(q,0)
s=A.cm(v.typeUniverse,A.hq(q[0]),"@<0>")
for(r=1;r<p;++r){if(!(r<q.length))return A.a(q,r)
s=A.iu(v.typeUniverse,s,A.hq(q[r]))}return A.cm(v.typeUniverse,s,a)},
a8(a){return A.b7(A.f3(v.typeUniverse,a,!1))},
l7(a){var s=this
s.b=A.lB(s)
return s.b(a)},
lB(a){var s,r,q,p,o
if(a===t.K)return A.li
if(A.ba(a))return A.lm
s=a.w
if(s===6)return A.l5
if(s===1)return A.iI
if(s===7)return A.ld
r=A.lA(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(A.ba)){a.f="$i"+q
if(q==="h")return A.lg
if(a===t.m)return A.lf
return A.ll}}else if(s===10){p=A.lR(a.x,a.y)
o=p==null?A.iI:p
return o==null?A.b3(o):o}return A.l3},
lA(a){if(a.w===8){if(a===t.S)return A.iG
if(a===t.V||a===t.o)return A.lh
if(a===t.N)return A.lk
if(a===t.y)return A.fe}return null},
l6(a){var s=this,r=A.l2
if(A.ba(s))r=A.kV
else if(s===t.K)r=A.b3
else if(A.bw(s)){r=A.l4
if(s===t.h6)r=A.hj
else if(s===t.dk)r=A.C
else if(s===t.fQ)r=A.iy
else if(s===t.cg)r=A.iA
else if(s===t.cD)r=A.kT
else if(s===t.an)r=A.kU}else if(s===t.S)r=A.u
else if(s===t.N)r=A.v
else if(s===t.y)r=A.ix
else if(s===t.o)r=A.iz
else if(s===t.V)r=A.kS
else if(s===t.m)r=A.H
s.a=r
return s.a(a)},
l3(a){var s=this
if(a==null)return A.bw(s)
return A.j0(v.typeUniverse,A.m3(a,s),s)},
l5(a){if(a==null)return!0
return this.x.b(a)},
ll(a){var s,r=this
if(a==null)return A.bw(r)
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.b8(a)[s]},
lg(a){var s,r=this
if(a==null)return A.bw(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.b8(a)[s]},
lf(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.k)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
iH(a){if(typeof a=="object"){if(a instanceof A.k)return t.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
l2(a){var s=this
if(a==null){if(A.bw(s))return a}else if(s.b(a))return a
throw A.A(A.iC(a,s),new Error())},
l4(a){var s=this
if(a==null||s.b(a))return a
throw A.A(A.iC(a,s),new Error())},
iC(a,b){return new A.br("TypeError: "+A.ii(a,A.Q(b,null)))},
lN(a,b,c,d){if(A.j0(v.typeUniverse,a,b))return a
throw A.A(A.kH("The type argument '"+A.Q(a,null)+"' is not a subtype of the type variable bound '"+A.Q(b,null)+"' of type variable '"+c+"' in '"+d+"'."),new Error())},
ii(a,b){return A.cC(a)+": type '"+A.Q(A.hq(a),null)+"' is not a subtype of type '"+b+"'"},
kH(a){return new A.br("TypeError: "+a)},
a3(a,b){return new A.br("TypeError: "+A.ii(a,b))},
ld(a){var s=this
return s.x.b(a)||A.h7(v.typeUniverse,s).b(a)},
li(a){return a!=null},
b3(a){if(a!=null)return a
throw A.A(A.a3(a,"Object"),new Error())},
lm(a){return!0},
kV(a){return a},
iI(a){return!1},
fe(a){return!0===a||!1===a},
ix(a){if(!0===a)return!0
if(!1===a)return!1
throw A.A(A.a3(a,"bool"),new Error())},
iy(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.A(A.a3(a,"bool?"),new Error())},
kS(a){if(typeof a=="number")return a
throw A.A(A.a3(a,"double"),new Error())},
kT(a){if(typeof a=="number")return a
if(a==null)return a
throw A.A(A.a3(a,"double?"),new Error())},
iG(a){return typeof a=="number"&&Math.floor(a)===a},
u(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.A(A.a3(a,"int"),new Error())},
hj(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.A(A.a3(a,"int?"),new Error())},
lh(a){return typeof a=="number"},
iz(a){if(typeof a=="number")return a
throw A.A(A.a3(a,"num"),new Error())},
iA(a){if(typeof a=="number")return a
if(a==null)return a
throw A.A(A.a3(a,"num?"),new Error())},
lk(a){return typeof a=="string"},
v(a){if(typeof a=="string")return a
throw A.A(A.a3(a,"String"),new Error())},
C(a){if(typeof a=="string")return a
if(a==null)return a
throw A.A(A.a3(a,"String?"),new Error())},
H(a){if(A.iH(a))return a
throw A.A(A.a3(a,"JSObject"),new Error())},
kU(a){if(a==null)return a
if(A.iH(a))return a
throw A.A(A.a3(a,"JSObject?"),new Error())},
iN(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.Q(a[q],b)
return s},
lu(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.iN(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.Q(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
iD(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){s=a5.length
if(a4==null)a4=A.c([],t.s)
else a2=a4.length
r=a4.length
for(q=s;q>0;--q)B.a.j(a4,"T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a1){m=a4.length
l=m-1-q
if(!(l>=0))return A.a(a4,l)
o=o+n+a4[l]
k=a5[q]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===p))o+=" extends "+A.Q(k,a4)}o+=">"}else o=""
p=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=A.Q(p,a4)
for(a="",a0="",q=0;q<g;++q,a0=a1)a+=a0+A.Q(h[q],a4)
if(e>0){a+=a0+"["
for(a0="",q=0;q<e;++q,a0=a1)a+=a0+A.Q(f[q],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",q=0;q<c;q+=3,a0=a1){a+=a0
if(d[q+1])a+="required "
a+=A.Q(d[q+2],a4)+" "+d[q]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return o+"("+a+") => "+b},
Q(a,b){var s,r,q,p,o,n,m,l=a.w
if(l===5)return"erased"
if(l===2)return"dynamic"
if(l===3)return"void"
if(l===1)return"Never"
if(l===4)return"any"
if(l===6){s=a.x
r=A.Q(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(l===7)return"FutureOr<"+A.Q(a.x,b)+">"
if(l===8){p=A.lF(a.x)
o=a.y
return o.length>0?p+("<"+A.iN(o,b)+">"):p}if(l===10)return A.lu(a,b)
if(l===11)return A.iD(a,b,null)
if(l===12)return A.iD(a.x,b,a.y)
if(l===13){n=a.x
m=b.length
n=m-1-n
if(!(n>=0&&n<m))return A.a(b,n)
return b[n]}return"?"},
lF(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
kQ(a,b){var s=a.tR[b]
while(typeof s=="string")s=a.tR[s]
return s},
kP(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.f3(a,b,!1)
else if(typeof m=="number"){s=m
r=A.cl(a,5,"#")
q=A.f4(s)
for(p=0;p<s;++p)q[p]=r
o=A.ck(a,b,q)
n[b]=o
return o}else return m},
kO(a,b){return A.iv(a.tR,b)},
kN(a,b){return A.iv(a.eT,b)},
f3(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.io(A.il(a,null,b,!1))
r.set(b,s)
return s},
cm(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.io(A.il(a,b,c,!0))
q.set(c,r)
return r},
iu(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.hh(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
aJ(a,b){b.a=A.l6
b.b=A.l7
return b},
cl(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.a7(null,null)
s.w=b
s.as=c
r=A.aJ(a,s)
a.eC.set(c,r)
return r},
is(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.kL(a,b,r,c)
a.eC.set(r,s)
return s},
kL(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!A.ba(b))if(!(b===t.b||b===t.T))if(s!==6)r=s===7&&A.bw(b.x)
if(r)return b
else if(s===1)return t.b}q=new A.a7(null,null)
q.w=6
q.x=b
q.as=c
return A.aJ(a,q)},
ir(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.kJ(a,b,r,c)
a.eC.set(r,s)
return s},
kJ(a,b,c,d){var s,r
if(d){s=b.w
if(A.ba(b)||b===t.K)return b
else if(s===1)return A.ck(a,"a1",[b])
else if(b===t.b||b===t.T)return t.eH}r=new A.a7(null,null)
r.w=7
r.x=b
r.as=c
return A.aJ(a,r)},
kM(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.a7(null,null)
s.w=13
s.x=b
s.as=q
r=A.aJ(a,s)
a.eC.set(q,r)
return r},
cj(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
kI(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
ck(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.cj(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.a7(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.aJ(a,r)
a.eC.set(p,q)
return q},
hh(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.cj(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.a7(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=A.aJ(a,o)
a.eC.set(q,n)
return n},
it(a,b,c){var s,r,q="+"+(b+"("+A.cj(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.a7(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=A.aJ(a,s)
a.eC.set(q,r)
return r},
iq(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.cj(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.cj(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.kI(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.a7(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=A.aJ(a,p)
a.eC.set(r,o)
return o},
hi(a,b,c,d){var s,r=b.as+("<"+A.cj(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.kK(a,b,c,r,d)
a.eC.set(r,s)
return s},
kK(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.f4(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.b5(a,b,r,0)
m=A.bu(a,c,r,0)
return A.hi(a,n,m,c!==m)}}l=new A.a7(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return A.aJ(a,l)},
il(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
io(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.kA(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.im(a,r,l,k,!1)
else if(q===46)r=A.im(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.b0(a.u,a.e,k.pop()))
break
case 94:k.push(A.kM(a.u,k.pop()))
break
case 35:k.push(A.cl(a.u,5,"#"))
break
case 64:k.push(A.cl(a.u,2,"@"))
break
case 126:k.push(A.cl(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.kC(a,k)
break
case 38:A.kB(a,k)
break
case 63:p=a.u
k.push(A.is(p,A.b0(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.ir(p,A.b0(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.kz(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.ip(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.kE(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.b0(a.u,a.e,m)},
kA(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
im(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=A.kQ(s,o.x)[p]
if(n==null)A.O('No "'+p+'" in "'+A.kh(o)+'"')
d.push(A.cm(s,o,n))}else d.push(p)
return m},
kC(a,b){var s,r=a.u,q=A.ik(a,b),p=b.pop()
if(typeof p=="string")b.push(A.ck(r,p,q))
else{s=A.b0(r,a.e,p)
switch(s.w){case 11:b.push(A.hi(r,s,q,a.n))
break
default:b.push(A.hh(r,s,q))
break}}},
kz(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.ik(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.b0(p,a.e,o)
q=new A.dq()
q.a=s
q.b=n
q.c=m
b.push(A.iq(p,r,q))
return
case-4:b.push(A.it(p,b.pop(),s))
return
default:throw A.e(A.cv("Unexpected state under `()`: "+A.n(o)))}},
kB(a,b){var s=b.pop()
if(0===s){b.push(A.cl(a.u,1,"0&"))
return}if(1===s){b.push(A.cl(a.u,4,"1&"))
return}throw A.e(A.cv("Unexpected extended operation "+A.n(s)))},
ik(a,b){var s=b.splice(a.p)
A.ip(a.u,a.e,s)
a.p=b.pop()
return s},
b0(a,b,c){if(typeof c=="string")return A.ck(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.kD(a,b,c)}else return c},
ip(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.b0(a,b,c[s])},
kE(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.b0(a,b,c[s])},
kD(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw A.e(A.cv("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.e(A.cv("Bad index "+c+" for "+b.k(0)))},
j0(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.D(a,b,null,c,null)
r.set(c,s)}return s},
D(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(A.ba(d))return!0
s=b.w
if(s===4)return!0
if(A.ba(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(A.D(a,c[b.x],c,d,e))return!0
q=d.w
p=t.b
if(b===p||b===t.T){if(q===7)return A.D(a,b,c,d.x,e)
return d===p||d===t.T||q===6}if(d===t.K){if(s===7)return A.D(a,b.x,c,d,e)
return s!==6}if(s===7){if(!A.D(a,b.x,c,d,e))return!1
return A.D(a,A.h7(a,b),c,d,e)}if(s===6)return A.D(a,p,c,d,e)&&A.D(a,b.x,c,d,e)
if(q===7){if(A.D(a,b,c,d.x,e))return!0
return A.D(a,b,c,A.h7(a,d),e)}if(q===6)return A.D(a,b,c,p,e)||A.D(a,b,c,d.x,e)
if(r)return!1
p=s!==11
if((!p||s===12)&&d===t.Z)return!0
o=s===10
if(o&&d===t.gT)return!0
if(q===12){if(b===t.W)return!0
if(s!==12)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.D(a,j,c,i,e)||!A.D(a,i,e,j,c))return!1}return A.iF(a,b.x,c,d.x,e)}if(q===11){if(b===t.W)return!0
if(p)return!1
return A.iF(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return A.le(a,b,c,d,e)}if(o&&q===10)return A.lj(a,b,c,d,e)
return!1},
iF(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.D(a3,a4.x,a5,a6.x,a7))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.D(a3,p[h],a7,g,a5))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.D(a3,p[o+h],a7,g,a5))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.D(a3,k[h],a7,g,a5))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.D(a3,e[a+2],a7,g,a5))return!1
break}}while(b<d){if(f[b+1])return!1
b+=3}return!0},
le(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
while(n!==m){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.cm(a,b,r[o])
return A.iw(a,p,null,c,d.y,e)}return A.iw(a,b.y,null,c,d.y,e)},
iw(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!A.D(a,b[s],d,e[s],f))return!1
return!0},
lj(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.D(a,r[s],c,q[s],e))return!1
return!0},
bw(a){var s=a.w,r=!0
if(!(a===t.b||a===t.T))if(!A.ba(a))if(s!==6)r=s===7&&A.bw(a.x)
return r},
ba(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
iv(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
f4(a){return a>0?new Array(a):v.typeUniverse.sEA},
a7:function a7(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
dq:function dq(){this.c=this.b=this.a=null},
f2:function f2(a){this.a=a},
dl:function dl(){},
br:function br(a){this.a=a},
kt(){var s,r,q
if(self.scheduleImmediate!=null)return A.lJ()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(A.b6(new A.eA(s),1)).observe(r,{childList:true})
return new A.ez(s,r,q)}else if(self.setImmediate!=null)return A.lK()
return A.lL()},
ku(a){self.scheduleImmediate(A.b6(new A.eB(t.M.a(a)),0))},
kv(a){self.setImmediate(A.b6(new A.eC(t.M.a(a)),0))},
kw(a){t.M.a(a)
A.kG(0,a)},
kG(a,b){var s=new A.f_()
s.bP(a,b)
return s},
hp(a){return new A.dh(new A.F($.x,a.h("F<0>")),a.h("dh<0>"))},
hm(a,b){a.$2(0,null)
b.b=!0
return b.a},
bs(a,b){A.kW(a,b)},
hl(a,b){b.aw(a)},
hk(a,b){b.az(A.a9(a),A.aL(a))},
kW(a,b){var s,r,q=new A.f6(b),p=new A.f7(b)
if(a instanceof A.F)a.bb(q,p,t.z)
else{s=t.z
if(a instanceof A.F)a.bx(q,p,s)
else{r=new A.F($.x,t._)
r.a=8
r.c=a
r.bb(q,p,s)}}},
hr(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.x.bu(new A.fm(s),t.H,t.S,t.z)},
fV(a){var s
if(t.C.b(a)){s=a.gY()
if(s!=null)return s}return B.f},
l9(a,b){if($.x===B.c)return null
return null},
la(a,b){if($.x!==B.c)A.l9(a,b)
if(b==null)if(t.C.b(a)){b=a.gY()
if(b==null){A.i5(a,B.f)
b=B.f}}else b=B.f
else if(t.C.b(a))A.i5(a,b)
return new A.a0(a,b)},
hf(a,b,c){var s,r,q,p,o={},n=o.a=a
for(s=t._;r=n.a,(r&4)!==0;n=a){a=s.a(n.c)
o.a=a}if(n===b){s=A.kl()
b.aj(new A.a0(new A.aa(!0,n,null,"Cannot complete a future with itself"),s))
return}q=b.a&1
s=n.a=r|q
if((s&24)===0){p=t.F.a(b.c)
b.a=b.a&1|4
b.c=n
n.ba(p)
return}if(!c)if(b.c==null)n=(s&16)===0||q!==0
else n=!1
else n=!0
if(n){p=b.a9()
b.a6(o.a)
A.bp(b,p)
return}b.a^=2
A.dD(null,null,b.b,t.M.a(new A.eJ(o,b)))},
bp(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d={},c=d.a=a
for(s=t.n,r=t.F;;){q={}
p=c.a
o=(p&16)===0
n=!o
if(b==null){if(n&&(p&1)===0){m=s.a(c.c)
A.fi(m.a,m.b)}return}q.a=b
l=b.a
for(c=b;l!=null;c=l,l=k){c.a=null
A.bp(d.a,c)
q.a=l
k=l.a}p=d.a
j=p.c
q.b=n
q.c=j
if(o){i=c.c
i=(i&1)!==0||(i&15)===8}else i=!0
if(i){h=c.b.b
if(n){p=p.b===h
p=!(p||p)}else p=!1
if(p){s.a(j)
A.fi(j.a,j.b)
return}g=$.x
if(g!==h)$.x=h
else g=null
c=c.c
if((c&15)===8)new A.eN(q,d,n).$0()
else if(o){if((c&1)!==0)new A.eM(q,j).$0()}else if((c&2)!==0)new A.eL(d,q).$0()
if(g!=null)$.x=g
c=q.c
if(c instanceof A.F){p=q.a.$ti
p=p.h("a1<2>").b(c)||!p.y[1].b(c)}else p=!1
if(p){f=q.a.b
if((c.a&24)!==0){e=r.a(f.c)
f.c=null
b=f.ab(e)
f.a=c.a&30|f.a&1
f.c=c.c
d.a=c
continue}else A.hf(c,f,!0)
return}}f=q.a.b
e=r.a(f.c)
f.c=null
b=f.ab(e)
c=q.b
p=q.c
if(!c){f.$ti.c.a(p)
f.a=8
f.c=p}else{s.a(p)
f.a=f.a&1|16
f.c=p}d.a=f
c=f}},
lv(a,b){var s
if(t.Q.b(a))return b.bu(a,t.z,t.K,t.l)
s=t.v
if(s.b(a))return s.a(a)
throw A.e(A.fU(a,"onError",u.c))},
lr(){var s,r
for(s=$.bt;s!=null;s=$.bt){$.cq=null
r=s.b
$.bt=r
if(r==null)$.cp=null
s.a.$0()}},
lC(){$.ho=!0
try{A.lr()}finally{$.cq=null
$.ho=!1
if($.bt!=null)$.hC().$1(A.iR())}},
iO(a){var s=new A.di(a),r=$.cp
if(r==null){$.bt=$.cp=s
if(!$.ho)$.hC().$1(A.iR())}else $.cp=r.b=s},
lx(a){var s,r,q,p=$.bt
if(p==null){A.iO(a)
$.cq=$.cp
return}s=new A.di(a)
r=$.cq
if(r==null){s.b=p
$.bt=$.cq=s}else{q=r.b
s.b=q
$.cq=r.b=s
if(q==null)$.cp=s}},
my(a,b){A.hs(a,"stream",t.K)
return new A.dx(b.h("dx<0>"))},
fi(a,b){A.lx(new A.fj(a,b))},
iL(a,b,c,d,e){var s,r=$.x
if(r===c)return d.$0()
$.x=c
s=r
try{r=d.$0()
return r}finally{$.x=s}},
iM(a,b,c,d,e,f,g){var s,r=$.x
if(r===c)return d.$1(e)
$.x=c
s=r
try{r=d.$1(e)
return r}finally{$.x=s}},
lw(a,b,c,d,e,f,g,h,i){var s,r=$.x
if(r===c)return d.$2(e,f)
$.x=c
s=r
try{r=d.$2(e,f)
return r}finally{$.x=s}},
dD(a,b,c,d){t.M.a(d)
if(B.c!==c){d=c.cg(d)
d=d}A.iO(d)},
eA:function eA(a){this.a=a},
ez:function ez(a,b,c){this.a=a
this.b=b
this.c=c},
eB:function eB(a){this.a=a},
eC:function eC(a){this.a=a},
f_:function f_(){},
f0:function f0(a,b){this.a=a
this.b=b},
dh:function dh(a,b){this.a=a
this.b=!1
this.$ti=b},
f6:function f6(a){this.a=a},
f7:function f7(a){this.a=a},
fm:function fm(a){this.a=a},
a0:function a0(a,b){this.a=a
this.b=b},
dj:function dj(){},
c4:function c4(a,b){this.a=a
this.$ti=b},
aZ:function aZ(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
F:function F(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
eG:function eG(a,b){this.a=a
this.b=b},
eK:function eK(a,b){this.a=a
this.b=b},
eJ:function eJ(a,b){this.a=a
this.b=b},
eI:function eI(a,b){this.a=a
this.b=b},
eH:function eH(a,b){this.a=a
this.b=b},
eN:function eN(a,b,c){this.a=a
this.b=b
this.c=c},
eO:function eO(a,b){this.a=a
this.b=b},
eP:function eP(a){this.a=a},
eM:function eM(a,b){this.a=a
this.b=b},
eL:function eL(a,b){this.a=a
this.b=b},
di:function di(a){this.a=a
this.b=null},
dx:function dx(a){this.$ti=a},
cn:function cn(){},
dw:function dw(){},
eW:function eW(a,b){this.a=a
this.b=b},
eX:function eX(a,b,c){this.a=a
this.b=b
this.c=c},
fj:function fj(a,b){this.a=a
this.b=b},
hY(a,b){return new A.am(a.h("@<0>").q(b).h("am<1,2>"))},
cL(a,b,c){return b.h("@<0>").q(c).h("hX<1,2>").a(A.lT(a,new A.am(b.h("@<0>").q(c).h("am<1,2>"))))},
t(a,b){return new A.am(a.h("@<0>").q(b).h("am<1,2>"))},
e0(a){return new A.c9(a.h("c9<0>"))},
hg(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
hZ(a,b,c){var s=A.hY(b,c)
s.a0(0,a)
return s},
h5(a){var s,r
if(A.hw(a))return"{...}"
s=new A.bn("")
try{r={}
B.a.j($.Z,a)
s.a+="{"
r.a=!0
a.B(0,new A.e1(r,s))
s.a+="}"}finally{if(0>=$.Z.length)return A.a($.Z,-1)
$.Z.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
c9:function c9(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
dt:function dt(a){this.a=a
this.c=this.b=null},
ca:function ca(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
l:function l(){},
J:function J(){},
e1:function e1(a,b){this.a=a
this.b=b},
bm:function bm(){},
ch:function ch(){},
lt(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.a9(r)
q=A.fY(String(s),null)
throw A.e(q)}q=A.fd(p)
return q},
fd(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.dr(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.fd(a[s])
return a},
hW(a,b,c){return new A.bM(a,b)},
l0(a){return a.cE()},
kx(a,b){return new A.eR(a,[],A.lP())},
ky(a,b,c){var s,r=new A.bn(""),q=A.kx(r,b)
q.ae(a)
s=r.a
return s.charCodeAt(0)==0?s:s},
dr:function dr(a,b){this.a=a
this.b=b
this.c=null},
ds:function ds(a){this.a=a},
cy:function cy(){},
cB:function cB(){},
bM:function bM(a,b){this.a=a
this.b=b},
cK:function cK(a,b){this.a=a
this.b=b},
cJ:function cJ(){},
dY:function dY(a){this.b=a},
dX:function dX(a){this.a=a},
eS:function eS(){},
eT:function eT(a,b){this.a=a
this.b=b},
eR:function eR(a,b,c){this.c=a
this.a=b
this.b=c},
hS(a,b){var s=$.jp()
s=s==null?null:new s(A.b6(A.mp(a,b),1))
return new A.dp(s,b.h("dp<0>"))},
j_(a,b){var s=A.h6(a,b)
if(s!=null)return s
throw A.e(A.fY(a,null))},
jO(a,b){a=A.A(a,new Error())
if(a==null)a=A.b3(a)
a.stack=b.k(0)
throw a},
i_(a,b,c,d){var s,r=J.jX(a,d)
if(a!==0&&b!=null)for(s=0;s<a;++s)r[s]=b
return r},
i0(a,b,c){var s,r,q=A.c([],c.h("j<0>"))
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.y)(a),++r)B.a.j(q,c.a(a[r]))
if(b)return q
q.$flags=1
return q},
W(a,b){var s,r
if(Array.isArray(a))return A.c(a.slice(0),b.h("j<0>"))
s=A.c([],b.h("j<0>"))
for(r=J.af(a);r.n();)B.a.j(s,r.gp())
return s},
k5(a,b,c){var s,r=J.jY(a,c)
for(s=0;s<a;++s)B.a.l(r,s,b.$1(s))
return r},
Y(a,b,c){return new A.bI(a,A.hV(a,c,b,!1,!1,""))},
ib(a,b,c){var s=J.af(b)
if(!s.n())return a
if(c.length===0){do a+=A.n(s.gp())
while(s.n())}else{a+=A.n(s.gp())
while(s.n())a=a+c+A.n(s.gp())}return a},
kl(){return A.aL(new Error())},
jN(a,b,c){var s,r
for(s=0;s<9;++s){r=a[s]
if(r.b===b)return r}throw A.e(A.fU(b,"name","No enum value with that name"))},
cC(a){if(typeof a=="number"||A.fe(a)||a==null)return J.a_(a)
if(typeof a=="string")return JSON.stringify(a)
return A.i4(a)},
jP(a,b){A.hs(a,"error",t.K)
A.hs(b,"stackTrace",t.l)
A.jO(a,b)},
cv(a){return new A.cu(a)},
bb(a,b){return new A.aa(!1,null,b,a)},
fU(a,b,c){return new A.aa(!0,a,b,c)},
ea(a,b){return new A.bW(null,null,!0,a,b,"Value not in range")},
ar(a,b,c,d,e){return new A.bW(b,c,!0,a,d,"Invalid value")},
ke(a,b,c){if(0>a||a>c)throw A.e(A.ar(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.e(A.ar(b,a,c,"end",null))
return b}return c},
i6(a,b){if(a<0)throw A.e(A.ar(a,0,null,b,null))
return a},
fZ(a,b,c,d){return new A.cD(b,!0,a,d,"Index out of range")},
ig(a){return new A.c3(a)},
ie(a){return new A.dd(a)},
M(a){return new A.c0(a)},
aj(a){return new A.cA(a)},
fY(a,b){return new A.dQ(a,b)},
jW(a,b,c){var s,r
if(A.hw(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.c([],t.s)
B.a.j($.Z,a)
try{A.ln(a,s)}finally{if(0>=$.Z.length)return A.a($.Z,-1)
$.Z.pop()}r=A.ib(b,t.hf.a(s),", ")+c
return r.charCodeAt(0)==0?r:r},
h1(a,b,c){var s,r
if(A.hw(a))return b+"..."+c
s=new A.bn(b)
B.a.j($.Z,a)
try{r=s
r.a=A.ib(r.a,a,", ")}finally{if(0>=$.Z.length)return A.a($.Z,-1)
$.Z.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
ln(a,b){var s,r,q,p,o,n,m,l=a.gt(a),k=0,j=0
for(;;){if(!(k<80||j<3))break
if(!l.n())return
s=A.n(l.gp())
B.a.j(b,s)
k+=s.length+2;++j}if(!l.n()){if(j<=5)return
if(0>=b.length)return A.a(b,-1)
r=b.pop()
if(0>=b.length)return A.a(b,-1)
q=b.pop()}else{p=l.gp();++j
if(!l.n()){if(j<=4){B.a.j(b,A.n(p))
return}r=A.n(p)
if(0>=b.length)return A.a(b,-1)
q=b.pop()
k+=r.length+2}else{o=l.gp();++j
for(;l.n();p=o,o=n){n=l.gp();++j
if(j>100){for(;;){if(!(k>75&&j>3))break
if(0>=b.length)return A.a(b,-1)
k-=b.pop().length+2;--j}B.a.j(b,"...")
return}}q=A.n(p)
r=A.n(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
for(;;){if(!(k>80&&b.length>3))break
if(0>=b.length)return A.a(b,-1)
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)B.a.j(b,m)
B.a.j(b,q)
B.a.j(b,r)},
i1(a,b,c,d,e){return new A.aR(a,b.h("@<0>").q(c).q(d).q(e).h("aR<1,2,3,4>"))},
k8(a,b,c,d){var s
if(B.h===c){s=B.d.gD(a)
b=J.ae(b)
return A.hb(A.aH(A.aH($.fT(),s),b))}if(B.h===d){s=B.d.gD(a)
b=J.ae(b)
c=J.ae(c)
return A.hb(A.aH(A.aH(A.aH($.fT(),s),b),c))}s=B.d.gD(a)
b=J.ae(b)
c=J.ae(c)
d=J.ae(d)
d=A.hb(A.aH(A.aH(A.aH(A.aH($.fT(),s),b),c),d))
return d},
dp:function dp(a,b){this.a=a
this.$ti=b},
dk:function dk(){},
r:function r(){},
cu:function cu(a){this.a=a},
aw:function aw(){},
aa:function aa(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
bW:function bW(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
cD:function cD(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
c3:function c3(a){this.a=a},
dd:function dd(a){this.a=a},
c0:function c0(a){this.a=a},
cA:function cA(a){this.a=a},
cV:function cV(){},
c_:function c_(){},
eE:function eE(a){this.a=a},
dQ:function dQ(a,b){this.a=a
this.b=b},
f:function f(){},
a5:function a5(a,b,c){this.a=a
this.b=b
this.$ti=c},
K:function K(){},
k:function k(){},
dA:function dA(){},
bn:function bn(a){this.a=a},
e3:function e3(a){this.a=a},
iE(a){var s
if(typeof a=="function")throw A.e(A.bb("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(A.kX,a)
s[$.fS()]=a
return s},
kX(a,b,c){t.Z.a(a)
if(A.u(c)>=1)return a.$1(b)
return a.$0()},
kY(a,b,c,d,e,f){t.Z.a(a)
A.u(f)
if(f>=4)return a.$4(b,c,d,e)
if(f===3)return a.$3(b,c,d)
if(f===2)return a.$2(b,c)
if(f===1)return a.$1(b)
return a.$0()},
lW(a,b,c){return c.a(a[b])},
fI(a,b){var s=new A.F($.x,b.h("F<0>")),r=new A.c4(s,b.h("c4<0>"))
a.then(A.b6(new A.fJ(r,b),1),A.b6(new A.fK(r),1))
return s},
fJ:function fJ(a,b){this.a=a
this.b=b},
fK:function fK(a){this.a=a},
cr(a,b){var s=0,r=A.hp(t.H),q,p=2,o=[],n,m,l,k,j,i,h
var $async$cr=A.hr(function(c,d){if(c===1){o.push(d)
s=p}for(;;)switch(s){case 0:if($.a6!=null){s=1
break}p=4
s=7
return A.bs(A.aW("oniguruma_native.wasm"),$async$cr)
case 7:p=2
s=6
break
case 4:p=3
i=o.pop()
n=A.a9(i)
m="https://github.com/BirjuVachhani/oniguruma-dart/releases/download/1.0.1+2/oniguruma_native.wasm"
p=9
s=12
return A.bs(A.aW(m),$async$cr)
case 12:p=3
s=11
break
case 9:p=8
h=o.pop()
l=A.a9(h)
j=A.M("Could not load 'oniguruma_native.wasm'. Tried the local copy (run `dart run oniguruma_native:setup` to create it in web/) and the release fallback '"+A.n(m)+"'. Check your network/CSP, or pass loadWasm(bytes: ...) / loadWasm(url: ...) with your own module. Local error: "+A.n(n)+"; release error: "+A.n(l))
throw A.e(j)
s=11
break
case 8:s=3
break
case 11:s=6
break
case 3:s=2
break
case 6:case 1:return A.hl(q,r)
case 2:return A.hk(o.at(-1),r)}})
return A.hm($async$cr,r)},
i2(a){var s,r=A.iT(a),q=new A.bk(r),p=$.a6
if(p==null)p=A.O(A.M(u.h))
q.c=r.b
r=r.a
s=q.d=r.length
if(s===0)s=1
s=A.u(p.a.malloc(s))
q.e=s
p.bz(s,r)
return q},
bk:function bk(a){var _=this
_.b=a
_.e=_.d=_.c=$},
bj:function bj(a,b,c){var _=this
_.a=$
_.b=a
_.c=b
_.d=c},
cU:function cU(a,b){this.a=a
this.b=b},
e6:function e6(a,b){this.a=a
this.b=b},
iT(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=a.length
for(s=0,r=!0,q=0;q<b;++q){p=a.charCodeAt(q)
if(p<128){++s
continue}if(p<2048)s+=2
else{o=!1
if(p>=55296&&p<=56319){n=q+1
if(n<b){o=a.charCodeAt(n)
o=o>=56320&&o<=57343}}if(o){s+=4;++q}else s+=3}r=!1}if(r){m=new Uint8Array(b)
for(q=0;q<b;++q)m[q]=a.charCodeAt(q)
return new A.df(m,b,!0,null,null)}m=new Uint8Array(s)
o=s+1
l=new Int32Array(o)
n=b+1
k=new Int32Array(n)
for(j=0,i=0;i<b;){p=a.charCodeAt(i)
if(p<128){if(!(j<o))return A.a(l,j)
l[j]=i
h=j+1
if(!(j<s))return A.a(m,j)
m[j]=p
k[i]=j;++i
j=h}else if(p<2048){if(!(j<o))return A.a(l,j)
l[j]=i
h=j+1
if(!(j<s))return A.a(m,j)
m[j]=p>>>6|192
if(!(h<o))return A.a(l,h)
l[h]=i
g=h+1
if(!(h<s))return A.a(m,h)
m[h]=p&63|128
k[i]=j;++i
j=g}else{f=!1
if(p>=55296&&p<=56319){e=i+1
if(e<b){f=a.charCodeAt(e)
f=f>=56320&&f<=57343}}d=i+1
h=j+1
g=h+1
if(f){if(!(d<b))return A.a(a,d)
c=65536+(p-55296<<10>>>0)+(a.charCodeAt(d)-56320)
if(!(j<o))return A.a(l,j)
l[j]=i
f=B.d.a_(c,18)
if(!(j<s))return A.a(m,j)
m[j]=(f|240)>>>0
if(!(h<o))return A.a(l,h)
l[h]=i
f=B.d.a_(c,12)
if(!(h<s))return A.a(m,h)
m[h]=f&63|128
if(!(g<o))return A.a(l,g)
l[g]=i
h=g+1
f=B.d.a_(c,6)
if(!(g<s))return A.a(m,g)
m[g]=f&63|128
if(!(h<o))return A.a(l,h)
l[h]=i
g=h+1
if(!(h<s))return A.a(m,h)
m[h]=c&63|128
k[i]=j
k[d]=j
i+=2
j=g}else{if(!(j<o))return A.a(l,j)
l[j]=i
if(!(j<s))return A.a(m,j)
m[j]=p>>>12|224
if(!(h<o))return A.a(l,h)
l[h]=i
if(!(h<s))return A.a(m,h)
m[h]=p>>>6&63|128
if(!(g<o))return A.a(l,g)
l[g]=i
h=g+1
if(!(g<s))return A.a(m,g)
m[g]=p&63|128
k[i]=j
i=d
j=h}}}if(!(j<o))return A.a(l,j)
l[j]=i
if(!(i<n))return A.a(k,i)
k[i]=j
return new A.df(m,b,!1,l,k)},
df:function df(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
iB(){var s,r,q,p=A.iE(new A.f8()),o=new A.f9()
if(typeof o=="function")A.O(A.bb("Attempting to rewrap a JS function.",null))
s=function(a,b){return function(c,d,e,f){return a(b,c,d,e,f,arguments.length)}}(A.kY,o)
s[$.fS()]=o
r={}
r.fd_close=p
r.fd_seek=s
r.fd_write=s
q={}
q.wasi_snapshot_preview1=r
return q},
aW(a){return A.kc(a)},
kc(a){var s=0,r=A.hp(t.H),q,p=2,o=[],n,m,l,k,j,i,h,g
var $async$aW=A.hr(function(b,c){if(b===1){o.push(c)
s=p}for(;;)switch(s){case 0:if($.a6!=null){s=1
break}n=null
p=4
k=v.G
s=7
return A.bs(A.fI(A.H(k.WebAssembly.instantiateStreaming(A.H(k.fetch(a)),A.iB())),t.m),$async$aW)
case 7:n=c
p=2
s=6
break
case 4:p=3
g=o.pop()
k=v.G
i=t.m
s=8
return A.bs(A.fI(A.H(k.fetch(a)),i),$async$aW)
case 8:h=c
m=h
if(!A.ix(m.ok))throw A.e(A.M("fetch "+a+" failed with HTTP "+A.n(A.lW(m,"status",t.S))))
s=9
return A.bs(A.fI(A.H(m.arrayBuffer()),t.i),$async$aW)
case 9:l=c
s=10
return A.bs(A.fI(A.H(k.WebAssembly.instantiate(A.k7(l,0,null),A.iB())),i),$async$aW)
case 10:n=c
s=6
break
case 3:s=2
break
case 6:A.kb(n)
case 1:return A.hl(q,r)
case 2:return A.hk(o.at(-1),r)}})
return A.hm($async$aW,r)},
kb(a){var s=A.H(A.H(a.instance).exports),r=t.e0.a(s._initialize)
if(r!=null)r.call()
$.a6=new A.e8(s)},
f8:function f8(){},
f9:function f9(){},
e8:function e8(a){this.a=a},
iW(a,b){var s,r,q
if(b==null)b=A.e0(t.N)
s=A.c([],t.k)
r=a.b
if(b.j(0,r))for(q=J.af(a.e.$0());q.n();)B.a.j(s,A.iW(q.gp(),b))
return new A.ab(a.a,r,a.c,a.d,a.f,a.r,s)},
hz(a){t.D.a(a)
return new A.ah(a.a,a.b,a.c,a.d,new A.fL(a),a.e,a.f)},
ab:function ab(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
fL:function fL(a){this.a=a},
ex:function ex(a,b,c){this.b=a
this.c=b
this.d=c},
hx(a){var s=a.a,r=a.$ti.h("4?"),q=A.v(r.a(s.i(0,"id"))),p=A.v(r.a(s.i(0,"scopeName"))),o=A.v(r.a(s.i(0,"displayName"))),n=A.v(r.a(s.i(0,"json"))),m=t.j,l=J.ct(m.a(r.a(s.i(0,"aliases"))),t.N),k=t.g.a(r.a(s.i(0,"categories")))
if(k==null)k=null
else{k=J.dG(k,new A.fD(),t.e)
k=A.W(k,k.$ti.h("B.E"))}if(k==null)k=B.Q
s=J.dG(m.a(r.a(s.i(0,"embedded"))),new A.fE(),t.D)
s=A.W(s,s.$ti.h("B.E"))
return new A.ab(q,p,o,n,l,k,s)},
mj(a){var s,r
t.aN.a(a)
s=A.cL(["c",a.a,"o",a.b],t.N,t.z)
r=a.c
if(r!=null)s.l(0,"fg",r)
r=a.e
if(r!==0)s.l(0,"fs",r)
r=a.f
if(r!=null)s.l(0,"s",r)
return s},
mn(a){var s=A.G(a),r=s.h("X<1,h<E<d,@>>>")
s=A.W(new A.X(a,s.h("h<E<d,@>>(1)").a(new A.fQ()),r),r.h("B.E"))
return s},
mo(a){var s,r=a.a,q=a.$ti.h("4?"),p=t.j,o=J.dG(p.a(q.a(r.i(0,"langs"))),new A.fR(),t.D)
o=A.W(o,o.$ti.h("B.E"))
s=t.N
return new A.ex(o,J.ct(p.a(q.a(r.i(0,"rawLangJsons"))),s),J.ct(p.a(q.a(r.i(0,"themeJsons"))),s))},
fD:function fD(){},
fE:function fE(){},
fQ:function fQ(){},
fR:function fR(){},
hd:function hd(a){this.c=a},
fg(a){return A.H(v.G.self).postMessage(B.e.aC(a,null))},
me(a,b){var s={}
s.a=null
A.H(v.G.self).onmessage=A.iE(new A.fO(new A.fP(s,b,a)))},
fP:function fP(a,b,c){this.a=a
this.b=b
this.c=c},
fO:function fO(a){this.a=a},
ah:function ah(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
N:function N(a,b){this.a=a
this.b=b},
md(a,b,c){var s=t.N
s=A.t(s,s)
s.a0(0,b)
if(c!=null)c.B(0,new A.fN(s,a))
return s},
lH(a,b){var s
if(a.length===0)return a
s=b.i(0,a.toLowerCase())
return s==null?a:s},
j6(a){var s,r,q,p,o=a.length
if(o===0)return A.c([B.V],t.B)
s=A.c([],t.B)
for(r=0,q=0;q<o;++q)if(a.charCodeAt(q)===10){if(q>r){p=q-1
if(!(p>=0))return A.a(a,p)
p=a.charCodeAt(p)===13}else p=!1
B.a.j(s,new A.b2(B.b.A(a,r,p?q-1:q),r))
r=q+1}B.a.j(s,new A.b2(B.b.O(a,r),r))
return s},
fN:function fN(a,b){this.a=a
this.b=b},
fM:function fM(a){this.a=a},
ha(a){return new A.em(a)},
em:function em(a){this.a=a},
eu:function eu(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
dv:function dv(a,b,c){this.a=a
this.b=b
this.c=c},
en:function en(a,b,c,d,e,f,g,h,i,j,k){var _=this
_.b=a
_.c=b
_.d=c
_.e=d
_.f=e
_.r=f
_.w=g
_.x=null
_.z=h
_.Q=i
_.as=j
_.ax=_.at=0
_.ch=k},
kn(a){var s,r,q,p,o,n,m,l,k,j,i,h="settings",g=a.i(0,h)
if(g==null)g=a.i(0,"tokenColors")
t.g.a(g)
s=A.c([],t.G)
if(g!=null)for(g=J.af(g),r=t.f;g.n();){q=g.gp()
if(r.b(q)){p=q.i(0,h)
o=r.b(p)?p:B.S
B.a.j(s,new A.aF(A.C(q.i(0,"name")),q.i(0,"scope"),new A.c2(A.C(o.i(0,"fontStyle")),A.C(o.i(0,"foreground")),A.C(o.i(0,"background")))))}}g=t.N
n=A.t(g,g)
m=a.i(0,"colors")
r=t.f
if(r.b(m))m.B(0,new A.eq(n))
l=A.t(g,g)
k=a.i(0,"colorReplacements")
if(r.b(k))k.B(0,new A.er(l))
g=A.C(a.i(0,"name"))
if(g==null)g="default"
r=A.C(a.i(0,"type"))
if(r==null)r="dark"
j=A.C(a.i(0,"fg"))
i=A.C(a.i(0,"bg"))
return new A.d8(g,r,s,j,i,l,n)},
ma(a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=null,a0={},a1=t.N
a2.sck(A.hZ(a2.f,a1,a1))
s=A.W(a2.c,t.fN)
r=a2.e
q=a2.d
p=r==null
if(p||q==null){n=s.length
m=0
for(;;){if(!(m<n)){o=a
break}l=s[m]
if(l.a==null&&l.b==null){o=l
break}++m}if(q==null)q=o==null?a:o.c.b
if(p)r=o==null?a:o.c.c
if(q==null)q=a2.r.i(0,"editor.foreground")
if(r==null)r=a2.r.i(0,"editor.background")
if(q==null)q=a2.b==="light"?"#333333":"#bbbbbb"
if(r==null)r=a2.b==="light"?"#fffffe":"#1e1e1e"
a2.d=q
a2.e=r}if(!(s.length!==0&&B.a.gbk(s).b==null&&B.a.gbk(s).a==null))B.a.bn(s,0,new A.aF(a,a,new A.c2(a,a2.d,a2.e)))
m=a0.a=0
k=new A.fH(a0,A.t(a1,a1))
j=A.c([],t.G)
for(a1=s.length;m<s.length;s.length===a1||(0,A.y)(s),++m){i=s[m]
p=i.c
h=p.b
g=p.c
f=h!=null&&!B.b.ah(h,"#")
e=g!=null&&!B.b.ah(g,"#")
if(!f&&!e){B.a.j(j,i)
continue}if(f){d=k.$1(h)
a2.f.l(0,d,h)
c=d}else c=h
if(e){d=k.$1(g)
a2.f.l(0,d,g)
b=d}else b=g
B.a.j(j,new A.aF(i.a,i.b,new A.c2(p.a,c,b)))}a2.sbG(j)
return a2},
d8:function d8(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
eq:function eq(a){this.a=a},
er:function er(a){this.a=a},
fH:function fH(a,b){this.a=a
this.b=b},
S:function S(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.e=d
_.f=e},
kF(a){var s=new A.eY()
s.bO(a)
return s},
az:function az(a,b){this.a=a
this.b=b},
dH:function dH(a,b){this.a=a
this.b=b
this.c=$},
dI:function dI(a){this.a=a},
eY:function eY(){this.b=this.a=null},
eZ:function eZ(){},
l_(a,b,c,d,e){var s,r,q,p,o=A.lQ(b,A.lZ(),t.a),n=A.aX(c,d,e.a)
for(s=o.length,r=t.ah,q=0;q<o.length;o.length===s||(0,A.y)(o),++q){p=o[q]
B.a.j(a,new A.ak(r.a(p.a),p.b,n))}},
m9(a,b){var s={},r=t.a
r.a(a)
r.a(b)
if(J.ay(b)<a.length)return!1
s.a=0
return B.a.bj(a,new A.fG(s,b))},
lz(a,b){var s,r=a.length
if(r===0)return!1
if(a===b)return!0
s=b.length
return r>s&&B.b.A(a,0,s)===b&&a[s]==="."},
iZ(a,b){var s,r,q=null
a=a.G()
s=a.a.a
s.l(0,"$self",new A.ad(q,q,a.b,q,q,q,q,q,q,q,q,q,a.c,q,q))
r=b==null?s.i(0,"$self"):b
if(r==null)s.aL(0,"$base")
else s.l(0,"$base",r)
return a},
hK(a,b,c){var s,r,q
if(c!=null){s=c.a
r=c.b
q=c.c}else{s=-1
r=0
q=0}return A.fW(a,b.a,b.b,null,s,r,q)},
hL(a,b,c){var s,r=c.x
r===$&&A.q()
s=new A.bZ(a.b,b)
return new A.by(s,A.hK(a.c,r.aQ(b),c.f.d.R(s)))},
eo(a,b,c,d,e,f,g,h){return new A.c1(a,b,c,d,a!=null?a.e+1:1,e,f,g,h)},
da:function da(a,b,c){this.a=a
this.b=b
this.c=c},
et:function et(a){this.a=a},
ak:function ak(a,b,c){this.b=a
this.c=b
this.d=c},
fG:function fG(a,b){this.a=a
this.b=b},
bE:function bE(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=-1
_.c=0
_.d=b
_.e=c
_.f=d
_.r=$
_.w=null
_.x=$
_.y=e
_.z=f
_.Q=g},
dT:function dT(a){this.a=a},
dR:function dR(a,b,c){this.a=a
this.b=b
this.c=c},
dS:function dS(){},
f1:function f1(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
by:function by(a,b){this.b=a
this.c=b},
c1:function c1(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
dZ:function dZ(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=0
_.e=d
_.f=e},
mb(a){var s,r=null
if(a==="$base")return new A.aT(B.F,r,r)
else if(a==="$self")return new A.aT(B.G,r,r)
s=B.b.aF(a,"#")
if(s===-1)return new A.aT(B.I,a,r)
else if(s===0)return new A.aT(B.H,r,B.b.O(a,1))
else return new A.aT(B.l,B.b.A(a,0,s),B.b.O(a,s+1))},
aC:function aC(a,b){this.a=a
this.b=b},
aT:function aT(a,b,c){this.a=a
this.b=b
this.c=c},
lQ(a,b,c){var s,r,q,p,o,n,m,l,k={},j=A.c([],c.h("j<bQ<0>>")),i=A.ls(a)
k.a=i.$0()
s=A.he()
r=A.he()
q=A.he()
s.saE(new A.ft(k,i,s,q,b,c))
r.saE(new A.fu(s,c))
q.saE(new A.fv(k,r,i,c))
for(p=c.h("bQ<0>");o=k.a,o!=null;){n=o.length
if(n===2){if(1>=n)return A.a(o,1)
m=o[1]===":"}else m=!1
l=0
if(m){if(0>=n)return A.a(o,0)
switch(o[0]){case"R":l=1
break
case"L":l=-1
break
default:break}k.a=i.$0()}o=r.b
if(o===r)A.O(A.h4(""))
B.a.j(j,new A.bQ(o.$0(),l,p))
if(k.a!==",")break
k.a=i.$0()}return j},
ls(a){var s=$.jx().ac(0,a)
return new A.ff(new A.bo(s.a,s.b,s.c))},
bQ:function bQ(a,b,c){this.a=a
this.b=b
this.$ti=c},
ft:function ft(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
fr:function fr(a,b){this.a=a
this.b=b},
fs:function fs(a,b,c){this.a=a
this.b=b
this.c=c},
fu:function fu(a,b){this.a=a
this.b=b},
fq:function fq(a,b){this.a=a
this.b=b},
fo:function fo(a,b){this.a=a
this.b=b},
fv:function fv(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fp:function fp(a,b){this.a=a
this.b=b},
fn:function fn(a,b){this.a=a
this.b=b},
ff:function ff(a){this.a=a},
ef(a){var s="repository",r=a.a,q=a.$ti.h("4?"),p=A.C(q.a(r.i(0,"include"))),o=A.C(q.a(r.i(0,"name"))),n=A.C(q.a(r.i(0,"contentName"))),m=A.C(q.a(r.i(0,"match"))),l=A.fa(q.a(r.i(0,"captures"))),k=A.C(q.a(r.i(0,"begin"))),j=A.fa(q.a(r.i(0,"beginCaptures"))),i=A.C(q.a(r.i(0,"end"))),h=A.fa(q.a(r.i(0,"endCaptures"))),g=A.C(q.a(r.i(0,"while"))),f=A.fa(q.a(r.i(0,"whileCaptures"))),e=A.iJ(q.a(r.i(0,"patterns"))),d=q.a(r.i(0,s))==null?null:A.i8(t.P.a(q.a(r.i(0,s))))
return new A.ad(null,p,o,n,m,l,k,j,i,h,g,f,e,d,A.kR(q.a(r.i(0,"applyEndPatternLast"))))},
fa(a){var s
if(!t.f.b(a))return null
s=A.t(t.N,t.Y)
a.B(0,new A.fb(s))
return s},
iJ(a){var s,r,q,p,o,n
if(!t.j.b(a))return null
s=A.c([],t.h)
for(r=J.af(a),q=t.f,p=t.N,o=t.z;r.n();){n=r.gp()
if(q.b(n))s.push(A.ef(n.E(0,p,o)))}return s},
fc(a){var s,r,q
if(a==null)return null
s=A.t(t.N,t.Y)
for(r=new A.a4(a,A.p(a).h("a4<1,2>")).gt(0);r.n();){q=r.d
s.l(0,q.a,q.b.G())}return s},
kR(a){if(A.fe(a))return a
return null},
ed(a){return new A.ec(a==null?A.t(t.N,t.Y):a)},
i8(a){var s=A.t(t.N,t.Y)
a.B(0,new A.ee(s))
return A.ed(s)},
i7(a,b,c,d,e,f,g,h){return new A.bl(g,h,f,d,c,e,a,b)},
kf(a){var s,r,q,p,o,n,m,l,k,j="repository",i={}
i.a=null
s=a.a
r=a.$ti.h("4?")
q=r.a(s.i(0,"injections"))
if(t.f.b(q)){i.a=A.t(t.N,t.Y)
q.B(0,new A.eb(i))}p=A.v(r.a(s.i(0,"scopeName")))
o=A.iJ(r.a(s.i(0,"patterns")))
if(o==null)o=A.c([],t.h)
n=r.a(s.i(0,j))==null?A.ed(null):A.i8(t.P.a(r.a(s.i(0,j))))
i=i.a
m=A.C(r.a(s.i(0,"injectionSelector")))
l=A.C(r.a(s.i(0,"name")))
k=t.g.a(r.a(s.i(0,"fileTypes")))
k=k==null?null:J.ct(k,t.N)
return A.i7(k,A.C(r.a(s.i(0,"firstLineMatch"))),m,i,l,o,n,p)},
ad:function ad(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o},
fb:function fb(a){this.a=a},
ec:function ec(a){this.a=a},
ee:function ee(a){this.a=a},
bl:function bl(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
eb:function eb(a){this.a=a},
d6:function d6(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
as(a,b){var s=new A.d_(b)
s.bN(a,b)
return s},
kj(a,b,c,d){return a.bv(new A.ej(b,c,d),t.ds)},
aX(a,b,c){var s
if(a.a==null)b.bv(new A.ek(a,b,c),t.r)
s=a.a
s.toString
return s},
d0(a,b,c){var s,r,q,p,o=A.c([],t.ac)
if(a!=null){for(s=new A.aU(a,a.r,a.e,A.p(a).h("aU<1>")),r=0;s.n();){q=A.h6(s.d,null)
if(q!=null&&q>r)r=q}for(p=0;p<=r;++p)B.a.j(o,null)
a.B(0,new A.ei(b,c,o))}return o},
h8(a,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=A.c([],t.t),b=a==null
if(!b)for(s=a.length,r=a1.a,q=a0.d,p=0;p<a.length;a.length===s||(0,A.y)(a),++p){o=a[p]
n=o.b
if(n!=null){m=A.mb(n)
l=m.a
k=-1
switch(l.a){case 0:case 1:j=r.i(0,n)
k=j!=null?A.aX(j,a0,a1):-1
break
case 2:n=m.c
n.toString
i=r.i(0,n)
k=i!=null?A.aX(i,a0,a1):-1
break
case 3:case 4:n=m.b
n.toString
h=l===B.l?m.c:null
g=a0.aR(n,a1)
if(g!=null){n=g.a
l=n.a
if(h!=null){f=l.i(0,h)
k=f!=null?A.aX(f,a0,n):-1}else{l=l.i(0,"$self")
l.toString
k=A.aX(l,a0,n)}}break}}else k=A.aX(o,a0,a1)
if(k!==-1){if(k>=0&&k<q.length){if(!(k>=0&&k<q.length))return A.a(q,k)
e=q[k]}else e=null
if(e instanceof A.bF)d=e.r&&e.f.length===0
else if(e instanceof A.aO)d=e.Q&&e.as.length===0
else if(e instanceof A.aP)d=e.z&&e.Q.length===0
else d=!1
if(d)continue
B.a.j(c,k)}}b=b?null:a.length
if(b==null)b=0
return new A.dO(c,b!==c.length)},
a2:function a2(){},
dO:function dO(a,b){this.a=a
this.b=b},
aA:function aA(a,b,c,d,e){var _=this
_.f=a
_.b=b
_.c=c
_.d=d
_.e=e},
bP:function bP(a,b,c,d,e,f){var _=this
_.f=a
_.r=b
_.w=null
_.b=c
_.c=d
_.d=e
_.e=f},
e2:function e2(a,b){this.a=a
this.b=b},
bF:function bF(a,b,c,d,e,f){var _=this
_.f=a
_.r=b
_.w=null
_.b=c
_.c=d
_.d=e
_.e=f},
dU:function dU(a,b){this.a=a
this.b=b},
aO:function aO(a,b,c,d,e,f,g,h,i,j,k,l){var _=this
_.f=a
_.r=b
_.w=c
_.x=d
_.y=e
_.z=f
_.Q=g
_.as=h
_.at=null
_.b=i
_.c=j
_.d=k
_.e=l},
aP:function aP(a,b,c,d,e,f,g,h,i,j,k){var _=this
_.f=a
_.r=b
_.w=c
_.x=d
_.y=e
_.z=f
_.Q=g
_.at=_.as=null
_.b=h
_.c=i
_.d=j
_.e=k},
dJ:function dJ(a,b){this.a=a
this.b=b},
dK:function dK(a){this.a=a},
ey:function ey(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
d_:function d_(a){var _=this
_.a=$
_.b=a
_.d=_.c=$
_.e=null},
eg:function eg(a){this.a=a},
b_:function b_(){var _=this
_.d=_.c=_.b=_.a=null},
at:function at(a,b){var _=this
_.a=a
_.b=!1
_.c=null
_.d=b},
dP:function dP(a,b){this.a=a
this.b=b},
cz:function cz(a,b,c){this.a=a
this.b=b
this.c=c},
ej:function ej(a,b,c){this.a=a
this.b=b
this.c=c},
ek:function ek(a,b,c){this.a=a
this.b=b
this.c=c},
ei:function ei(a,b,c){this.a=a
this.b=b
this.c=c},
ly(a,b){var s,r,q,p,o,n,m,l=b.length
if(l===0)return!0
for(s=l-1,r=0;r<l;++r){q=b[r]
p=q===">"
if(p){if(r===s)return!1;++r
if(!(r<l))return A.a(b,r)
q=b[r]}for(o=q.length;n=a==null,!n;){m=a.b
if(q!==m)m=B.b.ah(m,q)&&m.length>o&&m[o]==="."
else m=!0
if(m)break
if(p)return!1
a=a.a}if(n)return!1
a=a.a}return!0},
j2(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=a5.b,a4=A.c([],t.gw)
for(s=t.s,r=t.j,q=t.N,p=0;p<a3.length;++p){o=a3[p]
n=o.b
if(typeof n=="string"){m=$.jt()
l=A.hB(n,m,"")
m=$.jy()
k=A.c(A.hB(l,m,"").split(","),s)}else k=r.b(n)?J.ct(n,q):A.c([""],s)
m=o.c
j=m.a
if(typeof j=="string")for(i=j.split(" "),h=i.length,g=0,f=0;f<h;++f)switch(i[f]){case"italic":g|=1
break
case"bold":g|=2
break
case"underline":g|=4
break
case"strikethrough":g|=8
break}else g=-1
e=m.b
if(typeof e=="string"){i=$.hG()
h=!0
if(!i.b.test(e)){i=$.hH()
if(!i.b.test(e)){i=$.hE()
if(!i.b.test(e)){i=$.hF()
i=i.b.test(e)}else i=h}else i=h}else i=h}else i=!1
d=i?e:null
c=m.c
if(typeof c=="string"){m=$.hG()
i=!0
if(!m.b.test(c)){m=$.hH()
if(!m.b.test(c)){m=$.hE()
if(!m.b.test(c)){m=$.hF()
m=m.b.test(c)}else m=i}else m=i}else m=i}else m=!1
b=m?c:null
for(m=J.aK(k),a=0;a<m.gm(k);++a){a0=A.c(B.b.cG(m.i(k,a)).split(" "),s)
a1=B.a.gH(a0)
i=a0.length
if(i>1){a2=B.a.bI(a0,0,i-1)
i=A.G(a2).h("av<1>")
a2=A.W(new A.av(a2,i),i.h("B.E"))}else a2=null
B.a.j(a4,new A.aq(a1,a2,p,g,d,b))}}return a4},
hc(a,b,c,d,e){return new A.R(a,b==null?B.R:b,c,d,e)},
ko(a){var s,r,q,p,o,n,m,l=A.c([],t.w)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.y)(a),++r){q=a[r]
p=q.a
o=q.c
n=q.d
m=q.e
l.push(new A.R(p,q.b,o,n,m))}return l},
ic(a,b){return new A.d9(a,b,A.t(t.N,t.go))},
kp(a,b){var s,r,q,p,o,n,m,l=t.cu
l.a(a)
l.a(b)
l=a.a
s=b.a
if(l!==s)return s-l
for(l=b.b,s=l.length,r=a.b,q=r.length,p=0,o=0;;){if(p<q&&r[p]===">")++p
if(o<s&&l[o]===">")++o
if(p>=q||o>=s)break
if(!(o<s))return A.a(l,o)
n=l[o]
if(!(p<q))return A.a(r,p)
m=n.length-r[p].length
if(m!==0)return m;++p;++o}return s-q},
iK(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f
B.a.a5(a,new A.fh())
s=0
r="#000000"
q="#ffffff"
for(;;){p=a.length
if(p!==0){if(0>=p)return A.a(a,0)
p=a[0].a===""}else p=!1
if(!p)break
o=B.a.cv(a,0)
n=o.d
if(n!==-1)s=n
m=o.e
if(m!=null)r=m
l=o.f
if(l!=null)q=l}p=t.S
k=t.N
j=new A.dM(A.t(p,k),A.t(k,p))
j.bK(b)
p=j.a3(r)
k=j.a3(q)
i=A.ic(A.hc(0,null,-1,0,0),A.c([],t.w))
for(h=a.length,g=0;g<a.length;a.length===h||(0,A.y)(a),++g){f=a[g]
i.bo(0,0,f.a,f.b,f.d,j.a3(f.e),j.a3(f.f))}return new A.ep(j,new A.d5(s,p,k),i)},
aF:function aF(a,b,c){this.a=a
this.b=b
this.c=c},
c2:function c2(a,b,c){this.a=a
this.b=b
this.c=c},
cZ:function cZ(a){this.b=a},
d5:function d5(a,b,c){this.a=a
this.b=b
this.c=c},
bZ:function bZ(a,b){this.a=a
this.b=b},
aq:function aq(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
dM:function dM(a,b){var _=this
_.a=!1
_.b=0
_.c=a
_.d=b},
dN:function dN(){},
R:function R(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
d9:function d9(a,b,c){this.a=a
this.b=b
this.c=c},
ep:function ep(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=$},
es:function es(a){this.a=a},
fh:function fh(){},
ja(a5,a6,a7,a8,a9,b0,b1,b2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=a6.a,a4=a3.length
if(b1){s=A.kZ(a5,a6,a7,a8,a9,b0)
r=s.a
q=s.b
p=s.d
o=s.c}else{p=a7
q=a8
r=a9
o=-1}n=Date.now()
for(m=t.dm,l=a5.d,k=b2!==0,j=t.u,i=t.eb;;){if(k)if(Date.now()-n>b2)return new A.db(r,!0)
h=A.lq(a5,a6,p,q,r,o)
if(h==null){b0.v(r.x,a4)
break}g=h.a
f=h.b
e=g.length
if(e!==0){if(0>=e)return A.a(g,0)
d=g[0].b>q}else d=!1
c=l.length
b=r.x
if(f===-1){a=r.b
if(!(a>=0&&a<c))return A.a(l,a)
a=l[a]
a.toString
i.a(a)
if(0>=e)return A.a(g,0)
b0.v(b,g[0].a)
b=r.w
b.toString
r=r.aN(b)
A.dC(a5,a6,p,r,b0,a.y,g)
if(0>=g.length)return A.a(g,0)
a=r.x
b0.v(a,g[0].b)
b=r.a
b.toString
o=r.d
if(!d&&r.c===q){b0.v(a,a4)
break}r=b}else{if(!(f>=0&&f<c))return A.a(l,f)
c=l[f]
c.toString
if(0>=e)return A.a(g,0)
b0.v(b,g[0].a)
a0=b.V(c.a4(a3,g),a5)
if(0>=g.length)return A.a(g,0)
b=g[0]
a1=new A.c1(r,f,q,o,r.e+1,b.b===a4,null,a0,a0)
if(c instanceof A.aO){A.dC(a5,a6,p,a1,b0,c.r,g)
if(0>=g.length)return A.a(g,0)
b0.v(a0,g[0].b)
if(0>=g.length)return A.a(g,0)
o=g[0].b
a1=a1.aN(a0.V(c.af(a3,g),a5))
if(c.x)a1=a1.by(c.w.bw(a3,j.a(g)))
if(!d&&r.bm(a1)){r=a1.a
b0.v(r.x,a4)
break}r=a1}else if(c instanceof A.aP){A.dC(a5,a6,p,a1,b0,c.r,g)
if(0>=g.length)return A.a(g,0)
b0.v(a0,g[0].b)
if(0>=g.length)return A.a(g,0)
o=g[0].b
a1=a1.aN(a0.V(c.af(a3,g),a5))
if(c.y)a1=a1.by(c.x.bw(a3,j.a(g)))
if(!d&&r.bm(a1)){r=a1.a
b0.v(r.x,a4)
break}r=a1}else{A.dC(a5,a6,p,a1,b0,m.a(c).r,g)
if(0>=g.length)return A.a(g,0)
b0.v(a0,g[0].b)
if(!d){a1=r.a
r=a1==null?r:a1
b0.v(r.x,a4)
break}}}if(0>=g.length)return A.a(g,0)
a2=g[0].b
if(a2>q){q=a2
p=!1}}return new A.db(r,!1)},
kZ(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i,h=e.f?0:-1,g=A.c([],t.fj)
for(s=a.d,r=e;r!=null;r=r.a){q=r.b
if(!(q>=0&&q<s.length))return A.a(s,q)
q=s[q]
q.toString
if(q instanceof A.aP)B.a.j(g,new A.dB(r,q))}o=g.length-1
n=c
m=d
for(;;){if(!(o>=0)){p=e
break}if(!(o<g.length))return A.a(g,o)
l=g[o]
s=l.b
q=l.a
k=s.c3(a,q.r).a1(a,n,m===h).M(b,m)
if(k!=null){if(k.a!==-2){s=q.a
s.toString
p=s
break}j=k.b
i=j.length
if(i!==0){if(0>=i)return A.a(j,0)
i=q.x
f.v(i,j[0].a)
A.dC(a,b,n,q,f,s.w,j)
if(0>=j.length)return A.a(j,0)
f.v(i,j[0].b)
if(0>=j.length)return A.a(j,0)
h=j[0].b
if(h>m){m=h
n=!1}}}else{s=q.a
s.toString
p=s
break}--o}return new A.f5(p,m,h,n)},
lq(a,b,c,d,e,f){var s,r,q,p,o,n=A.lp(a,b,c,d,e,f),m=a.aS()
if(m.length===0)return n
s=A.lo(m,a,b,c,d,e,f)
if(s==null)return n
if(n==null)return new A.cc(s.b,s.c)
r=n.a
if(0>=r.length)return A.a(r,0)
q=r[0].a
r=s.b
if(0>=r.length)return A.a(r,0)
p=r[0].a
if(p>=q)o=s.a&&p===q
else o=!0
if(o)return new A.cc(r,s.c)
return n},
lp(a,b,c,d,e,f){var s,r=e.b,q=a.d
if(!(r>=0&&r<q.length))return A.a(q,r)
s=q[r].T(a,e.r,c,d===f).M(b,d)
if(s!=null)return new A.cc(s.b,s.a)
return null},
lo(a,b,c,d,e,a0,a1){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=a0.x.b.X()
for(s=a.length,r=b.d,q=e===a1,p=9007199254740991,o=null,n=-1,m=0,l=0;l<a.length;a.length===s||(0,A.y)(a),++l){k=a[l]
if(!k.b.$1(f))continue
j=k.d
if(!(j<r.length))return A.a(r,j)
i=r[j].T(b,null,d,q).M(c,e)
if(i==null)continue
h=i.b
if(0>=h.length)return A.a(h,0)
g=h[0].a
if(g>=p)continue
n=i.a
m=k.c
if(g===e){o=h
break}o=h
p=g}if(o!=null)return new A.eU(m===-1,o,n)
return null},
dC(a0,a1,a2,a3,a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a5.length
if(a===0)return
s=a1.a
r=a6.length
a=a<r?a:r
q=A.c([],t.dg)
if(0>=a6.length)return A.a(a6,0)
p=a6[0].b
for(o=a3.x,n=a0.Q,m=a3.e+1,l=0;l<a;++l){if(!(l<a5.length))return A.a(a5,l)
k=a5[l]
if(k==null)continue
if(!(l<a6.length))return A.a(a6,l)
j=a6[l]
if(j.c===0)continue
i=j.a
if(i>p)break
for(;;){if(!(q.length!==0&&B.a.gH(q).b<=i))break
a4.v(B.a.gH(q).a,B.a.gH(q).b)
if(0>=q.length)return A.a(q,-1)
q.pop()}if(q.length!==0)a4.v(B.a.gH(q).a,i)
else a4.v(o,i)
h=k.f
if(h!==0){g=o.V(k.a4(s,a6),a0)
f=g.V(k.af(s,a6),a0)
e=n.bi(B.b.A(s,0,j.b))
d=a2&&i===0
A.ja(a0,e,d,i,new A.c1(a3,h,i,-1,m,!1,null,g,f),a4,!1,0)
continue}c=k.a4(s,a6)
if(c!=null){if(q.length!==0)b=B.a.gH(q).a
else{o.toString
b=o}B.a.j(q,new A.du(b.V(c,a0),j.b))}}while(q.length!==0){a4.v(B.a.gH(q).a,B.a.gH(q).b)
if(0>=q.length)return A.a(q,-1)
q.pop()}},
db:function db(a,b){this.a=a
this.b=b},
f5:function f5(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dB:function dB(a,b){this.a=a
this.b=b},
cc:function cc(a,b){this.a=a
this.b=b},
eU:function eU(a,b,c){this.a=a
this.b=b
this.c=c},
du:function du(a,b){this.a=a
this.b=b},
j8(a,b){if(a===b)return 0
return B.b.av(a,b)<0?-1:1},
j7(a,b){var s,r,q,p,o=a==null
if(o&&b==null)return 0
if(o)return-1
if(b==null)return 1
s=a.length
r=b.length
if(s===r){for(q=0;q<s;++q){o=a[q]
if(!(q<r))return A.a(b,q)
p=A.j8(o,b[q])
if(p!==0)return p}return 0}return s-r},
iU(a){return A.hA(a,$.jr(),t.A.a(t.I.a(new A.fy())),null)},
au(a){var s
if(a==null)return!1
s=$.hD()
return s.b.test(a)},
i9(a,b,c){return A.hA(a,$.hD(),t.A.a(t.I.a(new A.eh(c,b))),null)},
fy:function fy(){},
bd:function bd(a,b,c){this.a=a
this.b=b
this.$ti=c},
eh:function eh(a,b){this.a=a
this.b=b},
ap:function ap(a,b,c){this.a=a
this.b=b
this.c=c},
e5:function e5(a,b){this.a=a
this.b=b},
e7:function e7(){},
ij(a){return new A.e5(a.a,A.k5(a.b.length,new A.eF(a),t.gR))},
fl:function fl(){},
fk:function fk(){},
d2:function d2(){},
dm:function dm(a,b){this.b=a
this.a=b},
dn:function dn(a){this.a=a},
eF:function eF(a){this.a=a},
ml(a){return a},
fW(a,b,c,d,e,f,g){var s,r,q,p=a&255,o=a>>>8&3,n=d===!0?1:0
if(d==null)n=(a&1024)!==0?1:0
s=a>>>11&7
r=a>>>15&511
q=a>>>24&255
if(b!==0)p=b
if(c!==8)o=c
if(e!==-1)s=e
if(f!==0)r=f
if(g!==0)q=g
return(p<<0|o<<8|n<<10|s<<11|r<<15|q<<24)>>>0},
m7(){return A.me(B.v,A.lM())}},B={}
var w=[A,J,B]
var $={}
A.h2.prototype={}
J.cE.prototype={
W(a,b){return a===b},
gD(a){return A.cX(a)},
k(a){return"Instance of '"+A.cY(a)+"'"},
gC(a){return A.b7(A.hn(this))}}
J.cG.prototype={
k(a){return String(a)},
gD(a){return a?519018:218159},
gC(a){return A.b7(t.y)},
$io:1,
$iw:1}
J.bH.prototype={
W(a,b){return null==b},
k(a){return"null"},
gD(a){return 0},
$io:1}
J.bK.prototype={$iz:1}
J.aE.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.cW.prototype={}
J.aY.prototype={}
J.al.prototype={
k(a){var s=a[$.jd()]
if(s==null)s=a[$.fS()]
if(s==null)return this.bJ(a)
return"JavaScript function for "+J.a_(s)},
$iaS:1}
J.bJ.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.bL.prototype={
gD(a){return 0},
k(a){return String(a)}}
J.j.prototype={
ad(a,b){return new A.ag(a,A.G(a).h("@<1>").q(b).h("ag<1,2>"))},
j(a,b){A.G(a).c.a(b)
a.$flags&1&&A.cs(a,29)
a.push(b)},
cv(a,b){var s
a.$flags&1&&A.cs(a,"removeAt",1)
s=a.length
if(b>=s)throw A.e(A.ea(b,null))
return a.splice(b,1)[0]},
bn(a,b,c){var s
A.G(a).c.a(c)
a.$flags&1&&A.cs(a,"insert",2)
s=a.length
if(b>s)throw A.e(A.ea(b,null))
a.splice(b,0,c)},
a0(a,b){var s
A.G(a).h("f<1>").a(b)
a.$flags&1&&A.cs(a,"addAll",2)
if(Array.isArray(b)){this.bR(a,b)
return}for(s=J.af(b);s.n();)a.push(s.gp())},
bR(a,b){var s,r
t.q.a(b)
s=b.length
if(s===0)return
if(a===b)throw A.e(A.aj(a))
for(r=0;r<s;++r)a.push(b[r])},
aK(a,b,c){var s=A.G(a)
return new A.X(a,s.q(c).h("1(2)").a(b),s.h("@<1>").q(c).h("X<1,2>"))},
I(a,b){var s,r=A.i_(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)this.l(r,s,A.n(a[s]))
return r.join(b)},
F(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
bI(a,b,c){var s=a.length
if(b>s)throw A.e(A.ar(b,0,s,"start",null))
if(c<b||c>s)throw A.e(A.ar(c,b,s,"end",null))
if(b===c)return A.c([],A.G(a))
return A.c(a.slice(b,c),A.G(a))},
gbk(a){if(a.length>0)return a[0]
throw A.e(A.h0())},
gH(a){var s=a.length
if(s>0)return a[s-1]
throw A.e(A.h0())},
cf(a,b){var s,r
A.G(a).h("w(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(b.$1(a[r]))return!0
if(a.length!==s)throw A.e(A.aj(a))}return!1},
bj(a,b){var s,r
A.G(a).h("w(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(!b.$1(a[r]))return!1
if(a.length!==s)throw A.e(A.aj(a))}return!0},
a5(a,b){var s,r,q,p,o,n=A.G(a)
n.h("b(1,1)?").a(b)
a.$flags&2&&A.cs(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.lb()
if(s===2){r=a[0]
q=a[1]
n=b.$2(r,q)
if(typeof n!=="number")return n.cM()
if(n>0){a[0]=q
a[1]=r}return}p=0
if(n.c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(A.b6(b,2))
if(p>0)this.c7(a,p)},
bH(a){return this.a5(a,null)},
c7(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
gu(a){return a.length===0},
gN(a){return a.length!==0},
k(a){return A.h1(a,"[","]")},
gt(a){return new J.aN(a,a.length,A.G(a).h("aN<1>"))},
gD(a){return A.cX(a)},
gm(a){return a.length},
i(a,b){if(!(b>=0&&b<a.length))throw A.e(A.fw(a,b))
return a[b]},
l(a,b,c){A.G(a).c.a(c)
a.$flags&2&&A.cs(a)
if(!(b>=0&&b<a.length))throw A.e(A.fw(a,b))
a[b]=c},
$ii:1,
$if:1,
$ih:1}
J.cF.prototype={
cH(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+A.cY(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.dV.prototype={}
J.aN.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s,r=this,q=r.a,p=q.length
if(r.b!==p){q=A.y(q)
throw A.e(q)}s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0},
$iI:1}
J.be.prototype={
av(a,b){var s
A.iz(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gaH(b)
if(this.gaH(a)===s)return 0
if(this.gaH(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gaH(a){return a===0?1/a<0:a<0},
cF(a,b){var s,r,q,p,o
if(b<2||b>36)throw A.e(A.ar(b,2,36,"radix",null))
s=a.toString(b)
r=s.length
q=r-1
if(!(q>=0))return A.a(s,q)
if(s.charCodeAt(q)!==41)return s
p=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(p==null)A.O(A.ig("Unexpected toString result: "+s))
r=p.length
if(1>=r)return A.a(p,1)
s=p[1]
if(3>=r)return A.a(p,3)
o=+p[3]
r=p[2]
if(r!=null){s+=r
o-=r.length}return s+B.b.S("0",o)},
k(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gD(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
a_(a,b){var s
if(a>0)s=this.ca(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
ca(a,b){return b>31?0:a>>>b},
gC(a){return A.b7(t.o)},
$iai:1,
$im:1,
$iT:1}
J.bG.prototype={
gC(a){return A.b7(t.S)},
$io:1,
$ib:1}
J.cH.prototype={
gC(a){return A.b7(t.V)},
$io:1}
J.aD.prototype={
ac(a,b){return new A.dy(b,a,0)},
ah(a,b){var s=b.length
if(s>a.length)return!1
return b===a.substring(0,s)},
A(a,b,c){return a.substring(b,A.ke(b,c,a.length))},
O(a,b){return this.A(a,b,null)},
cG(a){var s,r,q,p=a.trim(),o=p.length
if(o===0)return p
if(0>=o)return A.a(p,0)
if(p.charCodeAt(0)===133){s=J.k0(p,1)
if(s===o)return""}else s=0
r=o-1
if(!(r>=0))return A.a(p,r)
q=p.charCodeAt(r)===133?J.k1(p,r):o
if(s===0&&q===o)return p
return p.substring(s,q)},
S(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.e(B.u)
for(s=a,r="";;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
ct(a,b,c){var s=b-a.length
if(s<=0)return a
return this.S(c,s)+a},
aF(a,b){var s=a.indexOf(b,0)
return s},
aA(a,b){return A.mf(a,b,0)},
av(a,b){var s
A.v(b)
if(a===b)s=0
else s=a<b?-1:1
return s},
k(a){return a},
gD(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gC(a){return A.b7(t.N)},
gm(a){return a.length},
$io:1,
$iai:1,
$ie9:1,
$id:1}
A.aI.prototype={
gt(a){return new A.bz(J.af(this.gP()),A.p(this).h("bz<1,2>"))},
gm(a){return J.ay(this.gP())},
gu(a){return J.jD(this.gP())},
gN(a){return J.jE(this.gP())},
F(a,b){return A.p(this).y[1].a(J.hJ(this.gP(),b))},
k(a){return J.a_(this.gP())}}
A.bz.prototype={
n(){return this.a.n()},
gp(){return this.$ti.y[1].a(this.a.gp())},
$iI:1}
A.aQ.prototype={
gP(){return this.a}}
A.c6.prototype={$ii:1}
A.c5.prototype={
i(a,b){return this.$ti.y[1].a(J.jz(this.a,b))},
$ii:1,
$ih:1}
A.ag.prototype={
ad(a,b){return new A.ag(this.a,this.$ti.h("@<1>").q(b).h("ag<1,2>"))},
gP(){return this.a}}
A.aR.prototype={
E(a,b,c){return new A.aR(this.a,this.$ti.h("@<1,2>").q(b).q(c).h("aR<1,2,3,4>"))},
i(a,b){return this.$ti.h("4?").a(this.a.i(0,b))},
B(a,b){this.a.B(0,new A.dL(this,this.$ti.h("~(3,4)").a(b)))},
gK(){var s=this.$ti
return A.hQ(this.a.gK(),s.c,s.y[2])},
gm(a){var s=this.a
return s.gm(s)},
gu(a){var s=this.a
return s.gu(s)}}
A.dL.prototype={
$2(a,b){var s=this.a.$ti
s.c.a(a)
s.y[1].a(b)
this.b.$2(s.y[2].a(a),s.y[3].a(b))},
$S(){return this.a.$ti.h("~(1,2)")}}
A.an.prototype={
k(a){return"LateInitializationError: "+this.a}}
A.el.prototype={}
A.i.prototype={}
A.B.prototype={
gt(a){var s=this
return new A.V(s,s.gm(s),A.p(s).h("V<B.E>"))},
gu(a){return this.gm(this)===0}}
A.V.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s,r=this,q=r.a,p=J.aK(q),o=p.gm(q)
if(r.b!==o)throw A.e(A.aj(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.F(q,s);++r.c
return!0},
$iI:1}
A.aV.prototype={
gt(a){var s=this.a
return new A.bO(s.gt(s),this.b,A.p(this).h("bO<1,2>"))},
gm(a){var s=this.a
return s.gm(s)},
gu(a){var s=this.a
return s.gu(s)},
F(a,b){var s=this.a
return this.b.$1(s.F(s,b))}}
A.bC.prototype={$ii:1}
A.bO.prototype={
n(){var s=this,r=s.b
if(r.n()){s.a=s.c.$1(r.gp())
return!0}s.a=null
return!1},
gp(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
$iI:1}
A.X.prototype={
gm(a){return J.ay(this.a)},
F(a,b){return this.b.$1(J.hJ(this.a,b))}}
A.P.prototype={}
A.av.prototype={
gm(a){return J.ay(this.a)},
F(a,b){var s=this.a,r=J.aK(s)
return r.F(s,r.gm(s)-1-b)}}
A.co.prototype={}
A.b2.prototype={$r:"+content,offset(1,2)",$s:2}
A.bA.prototype={
E(a,b,c){var s=A.p(this)
return A.i1(this,s.c,s.y[1],b,c)},
gu(a){return this.gm(this)===0},
k(a){return A.h5(this)},
$iE:1}
A.bB.prototype={
gm(a){return this.b.length},
gb6(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
a2(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
i(a,b){if(!this.a2(b))return null
return this.b[this.a[b]]},
B(a,b){var s,r,q,p
this.$ti.h("~(1,2)").a(b)
s=this.gb6()
r=this.b
for(q=s.length,p=0;p<q;++p)b.$2(s[p],r[p])},
gK(){return new A.c7(this.gb6(),this.$ti.h("c7<1>"))}}
A.c7.prototype={
gm(a){return this.a.length},
gu(a){return 0===this.a.length},
gN(a){return 0!==this.a.length},
gt(a){var s=this.a
return new A.c8(s,s.length,this.$ti.h("c8<1>"))}}
A.c8.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s=this,r=s.c
if(r>=s.b){s.d=null
return!1}s.d=s.a[r]
s.c=r+1
return!0},
$iI:1}
A.bY.prototype={}
A.ev.prototype={
J(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.bV.prototype={
k(a){return"Null check operator used on a null value"}}
A.cI.prototype={
k(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.de.prototype={
k(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.e4.prototype={
k(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.bD.prototype={}
A.ci.prototype={
k(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$iaG:1}
A.aB.prototype={
k(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.jb(r==null?"unknown":r)+"'"},
$iaS:1,
gcL(){return this},
$C:"$1",
$R:1,
$D:null}
A.cw.prototype={$C:"$0",$R:0}
A.cx.prototype={$C:"$2",$R:2}
A.d7.prototype={}
A.d3.prototype={
k(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.jb(s)+"'"}}
A.bc.prototype={
W(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.bc))return!1
return this.$_target===b.$_target&&this.a===b.a},
gD(a){return(A.j1(this.a)^A.cX(this.$_target))>>>0},
k(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.cY(this.a)+"'")}}
A.d1.prototype={
k(a){return"RuntimeError: "+this.a}}
A.am.prototype={
gm(a){return this.a},
gu(a){return this.a===0},
gK(){return new A.ao(this,A.p(this).h("ao<1>"))},
a2(a){var s=this.b
if(s==null)return!1
return s[a]!=null},
a0(a,b){A.p(this).h("E<1,2>").a(b).B(0,new A.dW(this))},
i(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.cp(b)},
cp(a){var s,r,q=this.d
if(q==null)return null
s=q[this.bp(a)]
r=this.bq(s,a)
if(r<0)return null
return s[r].b},
l(a,b,c){var s,r,q=this,p=A.p(q)
p.c.a(b)
p.y[1].a(c)
if(typeof b=="string"){s=q.b
q.aU(s==null?q.b=q.ar():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.aU(r==null?q.c=q.ar():r,b,c)}else q.cq(b,c)},
cq(a,b){var s,r,q,p,o=this,n=A.p(o)
n.c.a(a)
n.y[1].a(b)
s=o.d
if(s==null)s=o.d=o.ar()
r=o.bp(a)
q=s[r]
if(q==null)s[r]=[o.au(a,b)]
else{p=o.bq(q,a)
if(p>=0)q[p].b=b
else q.push(o.au(a,b))}},
aL(a,b){var s=this.c6(this.b,b)
return s},
B(a,b){var s,r,q=this
A.p(q).h("~(1,2)").a(b)
s=q.e
r=q.r
while(s!=null){b.$2(s.a,s.b)
if(r!==q.r)throw A.e(A.aj(q))
s=s.c}},
aU(a,b,c){var s,r=A.p(this)
r.c.a(b)
r.y[1].a(c)
s=a[b]
if(s==null)a[b]=this.au(b,c)
else s.b=c},
c6(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.cd(s)
delete a[b]
return s.b},
b7(){this.r=this.r+1&1073741823},
au(a,b){var s=this,r=A.p(s),q=new A.e_(r.c.a(a),r.y[1].a(b))
if(s.e==null)s.e=s.f=q
else{r=s.f
r.toString
q.d=r
s.f=r.c=q}++s.a
s.b7()
return q},
cd(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.b7()},
bp(a){return J.ae(a)&1073741823},
bq(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.bx(a[r].a,b))return r
return-1},
k(a){return A.h5(this)},
ar(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
$ihX:1}
A.dW.prototype={
$2(a,b){var s=this.a,r=A.p(s)
s.l(0,r.c.a(a),r.y[1].a(b))},
$S(){return A.p(this.a).h("~(1,2)")}}
A.e_.prototype={}
A.ao.prototype={
gm(a){return this.a.a},
gu(a){return this.a.a===0},
gt(a){var s=this.a
return new A.aU(s,s.r,s.e,this.$ti.h("aU<1>"))}}
A.aU.prototype={
gp(){return this.d},
n(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.e(A.aj(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}},
$iI:1}
A.a4.prototype={
gm(a){return this.a.a},
gu(a){return this.a.a===0},
gt(a){var s=this.a
return new A.bN(s,s.r,s.e,this.$ti.h("bN<1,2>"))}}
A.bN.prototype={
gp(){var s=this.d
s.toString
return s},
n(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.e(A.aj(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=new A.a5(s.a,s.b,r.$ti.h("a5<1,2>"))
r.c=s.c
return!0}},
$iI:1}
A.fz.prototype={
$1(a){return this.a(a)},
$S:12}
A.fA.prototype={
$2(a,b){return this.a(a,b)},
$S:31}
A.fB.prototype={
$1(a){return this.a(A.v(a))},
$S:27}
A.b1.prototype={
k(a){return this.bc(!1)},
bc(a){var s,r,q,p,o,n=this.c0(),m=this.b5(),l=(a?"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
if(!(q<m.length))return A.a(m,q)
o=m[q]
l=a?l+A.i4(o):l+A.n(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
c0(){var s,r=this.$s
while($.eV.length<=r)B.a.j($.eV,null)
s=$.eV[r]
if(s==null){s=this.bW()
B.a.l($.eV,r,s)}return s},
bW(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.K,j=J.hT(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
B.a.l(j,q,r[s])}}j=A.i0(j,!1,k)
j.$flags=3
return j}}
A.bq.prototype={
b5(){return[this.a,this.b]},
W(a,b){if(b==null)return!1
return b instanceof A.bq&&this.$s===b.$s&&J.bx(this.a,b.a)&&J.bx(this.b,b.b)},
gD(a){return A.k8(this.$s,this.a,this.b,B.h)}}
A.bI.prototype={
k(a){return"RegExp/"+this.a+"/"+this.b.flags},
gb8(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.hV(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"g")},
bl(a){var s=this.b.exec(a)
if(s==null)return null
return new A.cb(s)},
ce(a,b,c){if(c<0||c>b.length)throw A.e(A.ar(c,0,b.length,null,null))
return new A.dg(this,b,c)},
ac(a,b){return this.ce(0,b,0)},
c_(a,b){var s,r=this.gb8()
if(r==null)r=A.b3(r)
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.cb(s)},
$ie9:1,
$ikg:1}
A.cb.prototype={
gaT(){return this.b.index},
gaD(){var s=this.b
return s.index+s[0].length},
i(a,b){var s=this.b
if(!(b<s.length))return A.a(s,b)
return s[b]},
$iac:1,
$ibX:1}
A.dg.prototype={
gt(a){return new A.bo(this.a,this.b,this.c)}}
A.bo.prototype={
gp(){var s=this.d
return s==null?t.d.a(s):s},
n(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return!1
s=m.c
r=l.length
if(s<=r){q=m.a
p=q.c_(l,s)
if(p!=null){m.d=p
o=p.gaD()
if(p.b.index===o){s=!1
if(q.b.unicode){q=m.c
n=q+1
if(n<r){if(!(q>=0&&q<r))return A.a(l,q)
q=l.charCodeAt(q)
if(q>=55296&&q<=56319){if(!(n>=0))return A.a(l,n)
s=l.charCodeAt(n)
s=s>=56320&&s<=57343}}}o=(s?o+1:o)+1}m.c=o
return!0}}m.b=m.d=null
return!1},
$iI:1}
A.d4.prototype={
gaD(){return this.a+this.c.length},
i(a,b){if(b!==0)throw A.e(A.ea(b,null))
return this.c},
$iac:1,
gaT(){return this.a}}
A.dy.prototype={
gt(a){return new A.dz(this.a,this.b,this.c)}}
A.dz.prototype={
n(){var s,r,q=this,p=q.c,o=q.b,n=o.length,m=q.a,l=m.length
if(p+n>l){q.d=null
return!1}s=m.indexOf(o,p)
if(s<0){q.c=l+1
q.d=null
return!1}r=s+n
q.d=new A.d4(s,o)
q.c=r===q.c?r+1:r
return!0},
gp(){var s=this.d
s.toString
return s},
$iI:1}
A.eD.prototype={
a8(){var s=this.b
if(s===this)throw A.e(new A.an("Local '' has not been initialized."))
return s},
saE(a){if(this.b!==this)throw A.e(new A.an("Local '' has already been initialized."))
this.b=a}}
A.bg.prototype={
gC(a){return B.W},
$io:1}
A.bf.prototype={$ibf:1}
A.bT.prototype={}
A.cM.prototype={
gC(a){return B.X},
$io:1}
A.bi.prototype={
gm(a){return a.length},
$iU:1}
A.bR.prototype={
i(a,b){A.b4(b,a,a.length)
return a[b]},
$ii:1,
$if:1,
$ih:1}
A.bS.prototype={$ii:1,$if:1,$ih:1}
A.cN.prototype={
gC(a){return B.Y},
$io:1}
A.cO.prototype={
gC(a){return B.Z},
$io:1}
A.cP.prototype={
gC(a){return B.a_},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1}
A.bh.prototype={
gC(a){return B.a0},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1,
$ibh:1,
$ih_:1}
A.cQ.prototype={
gC(a){return B.a1},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1}
A.cR.prototype={
gC(a){return B.a3},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1}
A.cS.prototype={
gC(a){return B.a4},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1}
A.bU.prototype={
gC(a){return B.a5},
gm(a){return a.length},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1}
A.cT.prototype={
gC(a){return B.a6},
gm(a){return a.length},
i(a,b){A.b4(b,a,a.length)
return a[b]},
$io:1,
$idc:1}
A.cd.prototype={}
A.ce.prototype={}
A.cf.prototype={}
A.cg.prototype={}
A.a7.prototype={
h(a){return A.cm(v.typeUniverse,this,a)},
q(a){return A.iu(v.typeUniverse,this,a)}}
A.dq.prototype={}
A.f2.prototype={
k(a){return A.Q(this.a,null)}}
A.dl.prototype={
k(a){return this.a}}
A.br.prototype={$iaw:1}
A.eA.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:9}
A.ez.prototype={
$1(a){var s,r
this.a.a=t.M.a(a)
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:41}
A.eB.prototype={
$0(){this.a.$0()},
$S:6}
A.eC.prototype={
$0(){this.a.$0()},
$S:6}
A.f_.prototype={
bP(a,b){if(self.setTimeout!=null)self.setTimeout(A.b6(new A.f0(this,b),0),a)
else throw A.e(A.ig("`setTimeout()` not found."))}}
A.f0.prototype={
$0(){this.b.$0()},
$S:0}
A.dh.prototype={
aw(a){var s,r=this,q=r.$ti
q.h("1/?").a(a)
if(a==null)a=q.c.a(a)
if(!r.b)r.a.aV(a)
else{s=r.a
if(q.h("a1<1>").b(a))s.aZ(a)
else s.b3(a)}},
az(a,b){var s=this.a
if(this.b)s.am(new A.a0(a,b))
else s.aj(new A.a0(a,b))}}
A.f6.prototype={
$1(a){return this.a.$2(0,a)},
$S:3}
A.f7.prototype={
$2(a,b){this.a.$2(1,new A.bD(a,t.l.a(b)))},
$S:23}
A.fm.prototype={
$2(a,b){this.a(A.u(a),b)},
$S:21}
A.a0.prototype={
k(a){return A.n(this.a)},
$ir:1,
gY(){return this.b}}
A.dj.prototype={
az(a,b){var s=this.a
if((s.a&30)!==0)throw A.e(A.M("Future already completed"))
s.aj(A.la(a,b))},
bg(a){return this.az(a,null)}}
A.c4.prototype={
aw(a){var s,r=this.$ti
r.h("1/?").a(a)
s=this.a
if((s.a&30)!==0)throw A.e(A.M("Future already completed"))
s.aV(r.h("1/").a(a))}}
A.aZ.prototype={
cs(a){if((this.c&15)!==6)return!0
return this.b.b.aM(t.al.a(this.d),a.a,t.y,t.K)},
co(a){var s,r=this,q=r.e,p=null,o=t.z,n=t.K,m=a.a,l=r.b.b
if(t.Q.b(q))p=l.cB(q,m,a.b,o,n,t.l)
else p=l.aM(t.v.a(q),m,o,n)
try{o=r.$ti.h("2/").a(p)
return o}catch(s){if(t.eK.b(A.a9(s))){if((r.c&1)!==0)throw A.e(A.bb("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.e(A.bb("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.F.prototype={
bx(a,b,c){var s,r,q=this.$ti
q.q(c).h("1/(2)").a(a)
s=$.x
if(s===B.c){if(!t.Q.b(b)&&!t.v.b(b))throw A.e(A.fU(b,"onError",u.c))}else{c.h("@<0/>").q(q.c).h("1(2)").a(a)
b=A.lv(b,s)}r=new A.F(s,c.h("F<0>"))
this.ai(new A.aZ(r,3,a,b,q.h("@<1>").q(c).h("aZ<1,2>")))
return r},
bb(a,b,c){var s,r=this.$ti
r.q(c).h("1/(2)").a(a)
s=new A.F($.x,c.h("F<0>"))
this.ai(new A.aZ(s,19,a,b,r.h("@<1>").q(c).h("aZ<1,2>")))
return s},
c9(a){this.a=this.a&1|16
this.c=a},
a6(a){this.a=a.a&30|this.a&1
this.c=a.c},
ai(a){var s,r=this,q=r.a
if(q<=3){a.a=t.F.a(r.c)
r.c=a}else{if((q&4)!==0){s=t._.a(r.c)
if((s.a&24)===0){s.ai(a)
return}r.a6(s)}A.dD(null,null,r.b,t.M.a(new A.eG(r,a)))}},
ba(a){var s,r,q,p,o,n,m=this,l={}
l.a=a
if(a==null)return
s=m.a
if(s<=3){r=t.F.a(m.c)
m.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){n=t._.a(m.c)
if((n.a&24)===0){n.ba(a)
return}m.a6(n)}l.a=m.ab(a)
A.dD(null,null,m.b,t.M.a(new A.eK(l,m)))}},
a9(){var s=t.F.a(this.c)
this.c=null
return this.ab(s)},
ab(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
b3(a){var s,r=this
r.$ti.c.a(a)
s=r.a9()
r.a=8
r.c=a
A.bp(r,s)},
bV(a){var s,r,q=this
if((a.a&16)!==0){s=q.b===a.b
s=!(s||s)}else s=!1
if(s)return
r=q.a9()
q.a6(a)
A.bp(q,r)},
am(a){var s=this.a9()
this.c9(a)
A.bp(this,s)},
aV(a){var s=this.$ti
s.h("1/").a(a)
if(s.h("a1<1>").b(a)){this.aZ(a)
return}this.bS(a)},
bS(a){var s=this
s.$ti.c.a(a)
s.a^=2
A.dD(null,null,s.b,t.M.a(new A.eI(s,a)))},
aZ(a){A.hf(this.$ti.h("a1<1>").a(a),this,!1)
return},
aj(a){this.a^=2
A.dD(null,null,this.b,t.M.a(new A.eH(this,a)))},
$ia1:1}
A.eG.prototype={
$0(){A.bp(this.a,this.b)},
$S:0}
A.eK.prototype={
$0(){A.bp(this.b,this.a.a)},
$S:0}
A.eJ.prototype={
$0(){A.hf(this.a.a,this.b,!0)},
$S:0}
A.eI.prototype={
$0(){this.a.b3(this.b)},
$S:0}
A.eH.prototype={
$0(){this.a.am(this.b)},
$S:0}
A.eN.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
j=q.b.b.cA(t.fO.a(q.d),t.z)}catch(p){s=A.a9(p)
r=A.aL(p)
if(k.c&&t.n.a(k.b.a.c).a===s){q=k.a
q.c=t.n.a(k.b.a.c)}else{q=s
o=r
if(o==null)o=A.fV(q)
n=k.a
n.c=new A.a0(q,o)
q=n}q.b=!0
return}if(j instanceof A.F&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=t.n.a(j.c)
q.b=!0}return}if(j instanceof A.F){m=k.b.a
l=new A.F(m.b,m.$ti)
j.bx(new A.eO(l,m),new A.eP(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:0}
A.eO.prototype={
$1(a){this.a.bV(this.b)},
$S:9}
A.eP.prototype={
$2(a,b){A.b3(a)
t.l.a(b)
this.a.am(new A.a0(a,b))},
$S:20}
A.eM.prototype={
$0(){var s,r,q,p,o,n,m,l
try{q=this.a
p=q.a
o=p.$ti
n=o.c
m=n.a(this.b)
q.c=p.b.b.aM(o.h("2/(1)").a(p.d),m,o.h("2/"),n)}catch(l){s=A.a9(l)
r=A.aL(l)
q=s
p=r
if(p==null)p=A.fV(q)
o=this.a
o.c=new A.a0(q,p)
o.b=!0}},
$S:0}
A.eL.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=t.n.a(l.a.a.c)
p=l.b
if(p.a.cs(s)&&p.a.e!=null){p.c=p.a.co(s)
p.b=!1}}catch(o){r=A.a9(o)
q=A.aL(o)
p=t.n.a(l.a.a.c)
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.fV(p)
m=l.b
m.c=new A.a0(p,n)
p=m}p.b=!0}},
$S:0}
A.di.prototype={}
A.dx.prototype={}
A.cn.prototype={$iih:1}
A.dw.prototype={
cC(a){var s,r,q
t.M.a(a)
try{if(B.c===$.x){a.$0()
return}A.iL(null,null,this,a,t.H)}catch(q){s=A.a9(q)
r=A.aL(q)
A.fi(A.b3(s),t.l.a(r))}},
cD(a,b,c){var s,r,q
c.h("~(0)").a(a)
c.a(b)
try{if(B.c===$.x){a.$1(b)
return}A.iM(null,null,this,a,b,t.H,c)}catch(q){s=A.a9(q)
r=A.aL(q)
A.fi(A.b3(s),t.l.a(r))}},
cg(a){return new A.eW(this,t.M.a(a))},
ci(a,b){return new A.eX(this,b.h("~(0)").a(a),b)},
cA(a,b){b.h("0()").a(a)
if($.x===B.c)return a.$0()
return A.iL(null,null,this,a,b)},
aM(a,b,c,d){c.h("@<0>").q(d).h("1(2)").a(a)
d.a(b)
if($.x===B.c)return a.$1(b)
return A.iM(null,null,this,a,b,c,d)},
cB(a,b,c,d,e,f){d.h("@<0>").q(e).q(f).h("1(2,3)").a(a)
e.a(b)
f.a(c)
if($.x===B.c)return a.$2(b,c)
return A.lw(null,null,this,a,b,c,d,e,f)},
bu(a,b,c,d){return b.h("@<0>").q(c).q(d).h("1(2,3)").a(a)}}
A.eW.prototype={
$0(){return this.a.cC(this.b)},
$S:0}
A.eX.prototype={
$1(a){var s=this.c
return this.a.cD(this.b,s.a(a),s)},
$S(){return this.c.h("~(0)")}}
A.fj.prototype={
$0(){A.jP(this.a,this.b)},
$S:0}
A.c9.prototype={
gt(a){var s=this,r=new A.ca(s,s.r,A.p(s).h("ca<1>"))
r.c=s.e
return r},
gm(a){return this.a},
gu(a){return this.a===0},
gN(a){return this.a!==0},
aA(a,b){var s,r
if(typeof b=="string"&&b!=="__proto__"){s=this.b
if(s==null)return!1
return t.L.a(s[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
if(r==null)return!1
return t.L.a(r[b])!=null}else return this.bX(b)},
bX(a){var s=this.d
if(s==null)return!1
return this.aq(s[this.an(a)],a)>=0},
j(a,b){var s,r,q=this
A.p(q).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.b_(s==null?q.b=A.hg():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.b_(r==null?q.c=A.hg():r,b)}else return q.bQ(b)},
bQ(a){var s,r,q,p=this
A.p(p).c.a(a)
s=p.d
if(s==null)s=p.d=A.hg()
r=p.an(a)
q=s[r]
if(q==null)s[r]=[p.al(a)]
else{if(p.aq(q,a)>=0)return!1
q.push(p.al(a))}return!0},
aL(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.b1(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.b1(s.c,b)
else return s.c5(b)},
c5(a){var s,r,q,p,o=this,n=o.d
if(n==null)return!1
s=o.an(a)
r=n[s]
q=o.aq(r,a)
if(q<0)return!1
p=r.splice(q,1)[0]
if(0===r.length)delete n[s]
o.b2(p)
return!0},
b_(a,b){A.p(this).c.a(b)
if(t.L.a(a[b])!=null)return!1
a[b]=this.al(b)
return!0},
b1(a,b){var s
if(a==null)return!1
s=t.L.a(a[b])
if(s==null)return!1
this.b2(s)
delete a[b]
return!0},
b0(){this.r=this.r+1&1073741823},
al(a){var s,r=this,q=new A.dt(A.p(r).c.a(a))
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.c=s
r.f=s.b=q}++r.a
r.b0()
return q},
b2(a){var s=this,r=a.c,q=a.b
if(r==null)s.e=q
else r.b=q
if(q==null)s.f=r
else q.c=r;--s.a
s.b0()},
an(a){return J.ae(a)&1073741823},
aq(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.bx(a[r].a,b))return r
return-1}}
A.dt.prototype={}
A.ca.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
n(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw A.e(A.aj(q))
else if(r==null){s.d=null
return!1}else{s.d=s.$ti.h("1?").a(r.a)
s.c=r.b
return!0}},
$iI:1}
A.l.prototype={
gt(a){return new A.V(a,this.gm(a),A.b9(a).h("V<l.E>"))},
F(a,b){return this.i(a,b)},
gu(a){return this.gm(a)===0},
gN(a){return!this.gu(a)},
aK(a,b,c){var s=A.b9(a)
return new A.X(a,s.q(c).h("1(l.E)").a(b),s.h("@<l.E>").q(c).h("X<1,2>"))},
ad(a,b){return new A.ag(a,A.b9(a).h("@<l.E>").q(b).h("ag<1,2>"))},
k(a){return A.h1(a,"[","]")}}
A.J.prototype={
E(a,b,c){var s=A.p(this)
return A.i1(this,s.h("J.K"),s.h("J.V"),b,c)},
B(a,b){var s,r,q,p=A.p(this)
p.h("~(J.K,J.V)").a(b)
for(s=this.gK(),s=s.gt(s),p=p.h("J.V");s.n();){r=s.gp()
q=this.i(0,r)
b.$2(r,q==null?p.a(q):q)}},
gm(a){var s=this.gK()
return s.gm(s)},
gu(a){var s=this.gK()
return s.gu(s)},
k(a){return A.h5(this)},
$iE:1}
A.e1.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.n(a)
r.a=(r.a+=s)+": "
s=A.n(b)
r.a+=s},
$S:11}
A.bm.prototype={
gu(a){return this.gm(this)===0},
gN(a){return this.gm(this)!==0},
k(a){return A.h1(this,"{","}")},
F(a,b){var s,r
A.i6(b,"index")
s=this.gt(this)
for(r=b;s.n();){if(r===0)return s.gp();--r}throw A.e(A.fZ(b,b-r,this,"index"))},
$ii:1,
$if:1,
$ih9:1}
A.ch.prototype={}
A.dr.prototype={
i(a,b){var s,r=this.b
if(r==null)return this.c.i(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.c4(b):s}},
gm(a){return this.b==null?this.c.a:this.a7().length},
gu(a){return this.gm(0)===0},
gK(){if(this.b==null){var s=this.c
return new A.ao(s,A.p(s).h("ao<1>"))}return new A.ds(this)},
B(a,b){var s,r,q,p,o=this
t.cA.a(b)
if(o.b==null)return o.c.B(0,b)
s=o.a7()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.fd(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.e(A.aj(o))}},
a7(){var s=t.g.a(this.c)
if(s==null)s=this.c=A.c(Object.keys(this.a),t.s)
return s},
c4(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.fd(this.a[a])
return this.b[a]=s}}
A.ds.prototype={
gm(a){return this.a.gm(0)},
F(a,b){var s=this.a
if(s.b==null)s=s.gK().F(0,b)
else{s=s.a7()
if(!(b>=0&&b<s.length))return A.a(s,b)
s=s[b]}return s},
gt(a){var s=this.a
if(s.b==null){s=s.gK()
s=s.gt(s)}else{s=s.a7()
s=new J.aN(s,s.length,A.G(s).h("aN<1>"))}return s}}
A.cy.prototype={}
A.cB.prototype={}
A.bM.prototype={
k(a){var s=A.cC(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
A.cK.prototype={
k(a){return"Cyclic error in JSON stringify"}}
A.cJ.prototype={
aB(a,b){var s=A.lt(a,this.gcm().a)
return s},
aC(a,b){var s=A.ky(a,this.gcn().b,null)
return s},
gcn(){return B.O},
gcm(){return B.N}}
A.dY.prototype={}
A.dX.prototype={}
A.eS.prototype={
bB(a){var s,r,q,p,o,n,m=a.length
for(s=this.c,r=0,q=0;q<m;++q){p=a.charCodeAt(q)
if(p>92){if(p>=55296){o=p&64512
if(o===55296){n=q+1
n=!(n<m&&(a.charCodeAt(n)&64512)===56320)}else n=!1
if(!n)if(o===56320){o=q-1
o=!(o>=0&&(a.charCodeAt(o)&64512)===55296)}else o=!1
else o=!0
if(o){if(q>r)s.a+=B.b.A(a,r,q)
r=q+1
o=A.L(92)
s.a+=o
o=A.L(117)
s.a+=o
o=A.L(100)
s.a+=o
o=p>>>8&15
o=A.L(o<10?48+o:87+o)
s.a+=o
o=p>>>4&15
o=A.L(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.L(o<10?48+o:87+o)
s.a+=o}}continue}if(p<32){if(q>r)s.a+=B.b.A(a,r,q)
r=q+1
o=A.L(92)
s.a+=o
switch(p){case 8:o=A.L(98)
s.a+=o
break
case 9:o=A.L(116)
s.a+=o
break
case 10:o=A.L(110)
s.a+=o
break
case 12:o=A.L(102)
s.a+=o
break
case 13:o=A.L(114)
s.a+=o
break
default:o=A.L(117)
s.a+=o
o=A.L(48)
s.a=(s.a+=o)+o
o=p>>>4&15
o=A.L(o<10?48+o:87+o)
s.a+=o
o=p&15
o=A.L(o<10?48+o:87+o)
s.a+=o
break}}else if(p===34||p===92){if(q>r)s.a+=B.b.A(a,r,q)
r=q+1
o=A.L(92)
s.a+=o
o=A.L(p)
s.a+=o}}if(r===0)s.a+=a
else if(r<m)s.a+=B.b.A(a,r,m)},
ak(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw A.e(new A.cK(a,null))}B.a.j(s,a)},
ae(a){var s,r,q,p,o=this
if(o.bA(a))return
o.ak(a)
try{s=o.b.$1(a)
if(!o.bA(s)){q=A.hW(a,null,o.gb9())
throw A.e(q)}q=o.a
if(0>=q.length)return A.a(q,-1)
q.pop()}catch(p){r=A.a9(p)
q=A.hW(a,r,o.gb9())
throw A.e(q)}},
bA(a){var s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
q.c.a+=B.K.k(a)
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){s=q.c
s.a+='"'
q.bB(a)
s.a+='"'
return!0}else if(t.j.b(a)){q.ak(a)
q.cJ(a)
s=q.a
if(0>=s.length)return A.a(s,-1)
s.pop()
return!0}else if(t.f.b(a)){q.ak(a)
r=q.cK(a)
s=q.a
if(0>=s.length)return A.a(s,-1)
s.pop()
return r}else return!1},
cJ(a){var s,r,q=this.c
q.a+="["
s=J.aK(a)
if(s.gN(a)){this.ae(s.i(a,0))
for(r=1;r<s.gm(a);++r){q.a+=","
this.ae(s.i(a,r))}}q.a+="]"},
cK(a){var s,r,q,p,o,n,m=this,l={}
if(a.gu(a)){m.c.a+="{}"
return!0}s=a.gm(a)*2
r=A.i_(s,null,!1,t.X)
q=l.a=0
l.b=!0
a.B(0,new A.eT(l,r))
if(!l.b)return!1
p=m.c
p.a+="{"
for(o='"';q<s;q+=2,o=',"'){p.a+=o
m.bB(A.v(r[q]))
p.a+='":'
n=q+1
if(!(n<s))return A.a(r,n)
m.ae(r[n])}p.a+="}"
return!0}}
A.eT.prototype={
$2(a,b){var s,r
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
B.a.l(s,r.a++,a)
B.a.l(s,r.a++,b)},
$S:11}
A.eR.prototype={
gb9(){var s=this.c.a
return s.charCodeAt(0)==0?s:s}}
A.dp.prototype={
bf(a,b,c){var s
this.$ti.c.a(b)
s=this.a
if(s!=null)s.register(a,b,c)}}
A.dk.prototype={
k(a){return this.b4()},
$ifX:1}
A.r.prototype={
gY(){return A.kd(this)}}
A.cu.prototype={
k(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.cC(s)
return"Assertion failed"}}
A.aw.prototype={}
A.aa.prototype={
gap(){return"Invalid argument"+(!this.a?"(s)":"")},
gao(){return""},
k(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.n(p),n=s.gap()+q+o
if(!s.a)return n
return n+s.gao()+": "+A.cC(s.gaG())},
gaG(){return this.b}}
A.bW.prototype={
gaG(){return A.iA(this.b)},
gap(){return"RangeError"},
gao(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.n(q):""
else if(q==null)s=": Not greater than or equal to "+A.n(r)
else if(q>r)s=": Not in inclusive range "+A.n(r)+".."+A.n(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.n(r)
return s}}
A.cD.prototype={
gaG(){return A.u(this.b)},
gap(){return"RangeError"},
gao(){if(A.u(this.b)<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gm(a){return this.f}}
A.c3.prototype={
k(a){return"Unsupported operation: "+this.a}}
A.dd.prototype={
k(a){return"UnimplementedError: "+this.a}}
A.c0.prototype={
k(a){return"Bad state: "+this.a}}
A.cA.prototype={
k(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.cC(s)+"."}}
A.cV.prototype={
k(a){return"Out of Memory"},
gY(){return null},
$ir:1}
A.c_.prototype={
k(a){return"Stack Overflow"},
gY(){return null},
$ir:1}
A.eE.prototype={
k(a){return"Exception: "+this.a}}
A.dQ.prototype={
k(a){var s=this.a,r=""!==s?"FormatException: "+s:"FormatException",q=this.b
if(typeof q=="string"){if(q.length>78)q=B.b.A(q,0,75)+"..."
return r+"\n"+q}else return r}}
A.f.prototype={
ad(a,b){return A.hQ(this,A.p(this).h("f.E"),b)},
aK(a,b,c){var s=A.p(this)
return A.k6(this,s.q(c).h("1(f.E)").a(b),s.h("f.E"),c)},
cu(a,b){var s,r
A.p(this).h("f.E(f.E,f.E)").a(b)
s=this.gt(this)
if(!s.n())throw A.e(A.h0())
r=s.gp()
while(s.n())r=b.$2(r,s.gp())
return r},
gm(a){var s,r=this.gt(this)
for(s=0;r.n();)++s
return s},
gu(a){return!this.gt(this).n()},
gN(a){return!this.gu(this)},
F(a,b){var s,r
A.i6(b,"index")
s=this.gt(this)
for(r=b;s.n();){if(r===0)return s.gp();--r}throw A.e(A.fZ(b,b-r,this,"index"))},
k(a){return A.jW(this,"(",")")}}
A.a5.prototype={
k(a){return"MapEntry("+A.n(this.a)+": "+A.n(this.b)+")"}}
A.K.prototype={
gD(a){return A.k.prototype.gD.call(this,0)},
k(a){return"null"}}
A.k.prototype={$ik:1,
W(a,b){return this===b},
gD(a){return A.cX(this)},
k(a){return"Instance of '"+A.cY(this)+"'"},
gC(a){return A.lX(this)},
toString(){return this.k(this)}}
A.dA.prototype={
k(a){return""},
$iaG:1}
A.bn.prototype={
gm(a){return this.a.length},
k(a){var s=this.a
return s.charCodeAt(0)==0?s:s},
$ikm:1}
A.e3.prototype={
k(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."}}
A.fJ.prototype={
$1(a){return this.a.aw(this.b.h("0/?").a(a))},
$S:3}
A.fK.prototype={
$1(a){if(a==null)return this.a.bg(new A.e3(a===undefined))
return this.a.bg(a)},
$S:3}
A.bk.prototype={
gm(a){var s=this.c
s===$&&A.q()
return s}}
A.bj.prototype={
bM(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=$.a6,f=g==null?A.O(A.M(u.h)):g,e=a.length,d=J.bx(e,0)?1:e
if(typeof d!=="number")return d.S()
s=A.u(f.a.malloc(d*4))
d=J.bx(e,0)?1:e
if(typeof d!=="number")return d.S()
r=A.u(f.a.malloc(d*4))
q=A.c([],t.t)
try{p=0
d=v.G
l=t.i
for(;;){k=p
j=e
if(typeof k!=="number")return k.cN()
if(typeof j!=="number")return A.m_(j)
if(!(k<j))break
o=A.iT(B.a.i(a,p)).a
k=J.ay(o)===0?1:J.ay(o)
n=A.u(f.a.malloc(k))
f.bz(n,o)
k=s
j=p
if(typeof j!=="number")return j.S()
if(typeof k!=="number")return k.aO()
i=A.u(n)
A.H(new d.DataView(l.a(A.H(f.a.memory).buffer))).setUint32(k+j*4,i,!0)
i=r
j=p
if(typeof j!=="number")return j.S()
if(typeof i!=="number")return i.aO()
k=J.ay(o)
A.H(new d.DataView(l.a(A.H(f.a.memory).buffer))).setInt32(i+j*4,k,!0)
J.jA(q,n)
k=p
if(typeof k!=="number")return k.aO()
p=k+1}d=A.u(s)
l=A.u(r)
k=A.u(e)
k=A.u(f.a.onig_shim_scanner_new(d,l,k))
this.a!==$&&A.j9()
this.a=k
if(k===0){d=A.M("Failed to create Oniguruma scanner")
throw A.e(d)}}finally{for(d=q,l=d.length,h=0;h<d.length;d.length===l||(0,A.y)(d),++h){m=d[h]
k=A.u(m)
f.a.free(k)}d=A.u(s)
f.a.free(d)
d=A.u(r)
f.a.free(d)}},
M(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this,d=$.a6
if(d==null)d=A.O(A.M(u.h))
s=a.b
r=e.a
r===$&&A.q()
q=a.e
q===$&&A.q()
p=a.d
p===$&&A.q()
o=e.b
n=e.c
m=e.d
l=d.a
k=A.u(l.onig_shim_find.apply(l,[r,q,p,s.cI(b),o,n,m,64]))
if(k<0)return null
j=A.u(A.H(new v.G.DataView(t.i.a(A.H(l.memory).buffer))).getInt32(o,!0))
i=d.bt(n,j)
h=d.bt(m,j)
g=J.hT(j,t.f3)
for(r=s.d,q=s.c,p=h.length,o=i.length,f=0;f<j;++f){if(!(f<o))return A.a(i,f)
n=i[f]
if(n<0)n=-1
else if(!q){if(!(n<r.length))return A.a(r,n)
n=r[n]}if(!(f<p))return A.a(h,f)
m=h[f]
if(m<0)m=-1
else if(!q){if(!(m<r.length))return A.a(r,m)
m=r[m]}g[f]=new A.cU(n,m)}return new A.e6(k,g)}}
A.cU.prototype={
gm(a){return this.b-this.a}}
A.e6.prototype={}
A.df.prototype={
cI(a){var s,r=this
if(a<=0)return 0
if(a>=r.b)return r.a.length
if(r.c)s=a
else{s=r.e
if(!(a<s.length))return A.a(s,a)
s=s[a]}return s}}
A.f8.prototype={
$1(a){return 0},
$S:16}
A.f9.prototype={
$4(a,b,c,d){return 0},
$S:13}
A.e8.prototype={
bz(a,b){var s=b.length
if(s===0)return
A.H(new v.G.Uint8Array(t.i.a(A.H(this.a.memory).buffer),a,s)).set(b)},
bt(a,b){if(b<=0)return new Int32Array(0)
return t.ha.a(new v.G.Int32Array(t.i.a(A.H(this.a.memory).buffer),a,b))}}
A.ab.prototype={}
A.fL.prototype={
$0(){var s=this.a.r,r=A.G(s),q=r.h("X<1,ah>")
s=A.W(new A.X(s,r.h("ah(1)").a(A.m5()),q),q.h("B.E"))
return s},
$S:14}
A.ex.prototype={}
A.fD.prototype={
$1(a){return A.jN(B.P,A.v(a),t.e)},
$S:15}
A.fE.prototype={
$1(a){return A.hx(t.f.a(a).E(0,t.N,t.z))},
$S:8}
A.fQ.prototype={
$1(a){var s=J.dG(t.fB.a(a),A.mc(),t.P)
s=A.W(s,s.$ti.h("B.E"))
return s},
$S:17}
A.fR.prototype={
$1(a){return A.hx(t.f.a(a).E(0,t.N,t.z))},
$S:8}
A.hd.prototype={
gm(a){return this.c.a}}
A.fP.prototype={
$1(a4){var s=0,r=A.hp(t.H),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3
var $async$$1=A.hr(function(a6,a7){if(a6===1)return A.hk(a7,r)
for(;;)switch(s){case 0:a=t.f
a0=t.N
a1=t.z
a2=a.a(B.e.aB(a4,null)).E(0,a0,a1)
a3=a2
case 3:switch(a3.$ti.h("4?").a(a3.a.i(0,"type"))){case"config":s=5
break
case"tokenize":s=6
break
case"loadLang":s=7
break
case"loadRawLang":s=8
break
case"loadTheme":s=9
break
default:s=4
break}break
case 5:s=10
return A.bs(p.b.$0(),$async$$1)
case 10:a3=a2
j=A.mo(a.a(a3.$ti.h("4?").a(a3.a.i(0,"config"))).E(0,a0,a1))
a3=A.c([],t.k)
a=t.s
i=A.c([],a)
a=A.c([],a)
A.hY(a0,t.fb)
h=A.iK(A.j2(new A.cZ(A.c([],t.G))),null)
n=new A.en(new A.d6(A.t(a0,t.f1),A.t(a0,t.E),A.t(a0,t.a),h,p.c),A.t(a0,t.bG),A.t(a0,t.dP),A.e0(a0),A.t(a0,a0),A.e0(a0),A.e0(a0),a3,i,a,A.t(a0,t.bF))
for(a=j.d,a3=a.$ti,a=new A.V(a,a.gm(0),a3.h("V<l.E>")),a3=a3.h("l.E");a.n();){i=a.d
n.bs(i==null?a3.a(i):i)}for(a=j.b,a3=a.length,g=0;g<a.length;a.length===a3||(0,A.y)(a),++g)n.aI(A.hz(a[g]))
for(a=j.c,a3=a.$ti,a=new A.V(a,a.gm(0),a3.h("V<l.E>")),a3=a3.h("l.E");a.n();){i=a.d
n.aJ(i==null?a3.a(i):i)}p.a.a=n
A.fg(A.cL(["type","ready"],a0,a1))
s=4
break
case 6:a3=a2
o=A.u(a3.$ti.h("4?").a(a3.a.i(0,"id")))
n=p.a.a
if(n==null){A.fg(A.cL(["type","error","id",o,"message","worker not configured"],a0,a1))
s=1
break}try{a3=a2
a3=A.v(a3.$ti.h("4?").a(a3.a.i(0,"code")))
i=a2
i=a.a(i.$ti.h("4?").a(i.a.i(0,"options"))).E(0,a0,a1)
a=i.a
i=i.$ti.h("4?")
h=A.C(i.a(a.i(0,"lang")))
f=A.C(i.a(a.i(0,"theme")))
e=A.iy(i.a(a.i(0,"includeExplanation")))
d=A.hj(i.a(a.i(0,"tokenizeMaxLineLength")))
if(d==null)d=0
c=A.hj(i.a(a.i(0,"tokenizeTimeLimit")))
if(c==null)c=500
a=t.fF.a(i.a(a.i(0,"colorReplacements")))
a=a==null?null:a.E(0,a0,a1)
m=n.cj(a3,new A.eu(h,f,e===!0,d,c,a))
A.fg(A.cL(["type","result","id",o,"tokens",A.mn(m)],a0,a1))}catch(a5){l=A.a9(a5)
k=A.aL(a5)
A.fg(A.cL(["type","error","id",o,"message",J.a_(l),"stack",J.a_(k)],a0,a1))}s=4
break
case 7:a3=p.a.a
if(a3!=null){i=a2
a3.aI(A.hz(A.hx(a.a(i.$ti.h("4?").a(i.a.i(0,"lang"))).E(0,a0,a1))))}s=4
break
case 8:a=p.a.a
if(a!=null){a0=a2
a.aJ(A.v(a0.$ti.h("4?").a(a0.a.i(0,"json"))))}s=4
break
case 9:a=p.a.a
if(a!=null){a0=a2
a.bs(A.v(a0.$ti.h("4?").a(a0.a.i(0,"themeJson"))))}s=4
break
case 4:case 1:return A.hl(q,r)}})
return A.hm($async$$1,r)},
$S:18}
A.fO.prototype={
$1(a){var s,r=A.H(a).data
if(r!=null)s=!(typeof r==="string")
else s=!0
if(s)return
this.a.$1(A.v(r))},
$S:19}
A.ah.prototype={}
A.N.prototype={
b4(){return"GrammarCategory."+this.b}}
A.fN.prototype={
$2(a,b){A.v(a)
if(typeof b=="string")this.a.l(0,a,b)
else if(a===this.b&&t.f.b(b))b.B(0,new A.fM(this.a))},
$S:10}
A.fM.prototype={
$2(a,b){if(typeof b=="string")this.a.l(0,J.a_(a),b)},
$S:1}
A.em.prototype={
k(a){return"ShikiError: "+this.a}}
A.eu.prototype={}
A.dv.prototype={}
A.en.prototype={
br(a){var s,r,q,p,o=this
t.P.a(a)
p=o.at
s=p===0
o.at=p+1
try{if(s)o.aX(B.e.aC(a,null))
r=A.kf(a)
p=t.E.a(r)
o.b.b.l(0,p.b,p)
o.r.j(0,r.b)
p=o.f
p.l(0,r.b,r.b)
q=r.f
if(q!=null)p.l(0,q.toLowerCase(),r.b)}finally{--o.at}},
aJ(a){var s,r,q,p,o,n=this,m=n.at,l=m===0
n.at=m+1
try{if(l)n.aX(a)
s=B.e.aB(a,null)
if(t.j.b(s))for(m=J.af(s),q=t.f,p=t.N,o=t.z;m.n();){r=m.gp()
n.br(q.a(r).E(0,p,o))}else n.br(t.f.a(s).E(0,t.N,t.z))}finally{--n.at}},
aI(a){var s,r,q,p,o,n,m,l,k=this,j=a.b
if(k.r.aA(0,j))return
p=k.w
if(!p.j(0,j))return
o=k.at
s=o===0
k.at=o+1
try{if(s)k.bU(a)
for(o=J.af(a.e.$0());o.n();){r=o.gp()
k.aI(r)}k.aJ(a.d)
o=k.f
o.l(0,a.a.toLowerCase(),j)
for(n=a.f,m=n.$ti,n=new A.V(n,n.gm(0),m.h("V<l.E>")),m=m.h("l.E");n.n();){l=n.d
q=l==null?m.a(l):l
o.l(0,q.toLowerCase(),j)}}finally{--k.at
p.aL(0,j)}},
cr(a){var s,r,q,p=this
t.P.a(a)
q=p.ax
s=q===0
p.ax=q+1
try{if(s)p.aY(B.e.aC(a,null))
r=A.ma(A.kn(a))
p.c.l(0,r.a,r)
p.x=r.a
q=r.a
return q}finally{--p.ax}},
bs(a){var s=this,r=s.ax,q=r===0
s.ax=r+1
try{if(q)s.aY(a)
r=s.cr(t.P.a(B.e.aB(a,null)))
return r}finally{--s.ax}},
c8(a){var s,r,q,p=this.d,o=p.i(0,a)
if(o!=null)return o
s=this.c.i(0,a)
if(s==null)throw A.e(A.ha('Theme "'+a+'" is not loaded'))
r=A.iK(A.j2(new A.cZ(s.c)),null)
q=new A.dv(s,r,r.a.bC())
p.l(0,a,q)
return q},
cj(a,b){var s,r,q,p,o,n,m,l,k,j,i=this,h=null,g=b.b
if(g==null)g=i.x
s=b.a
if(s==null)s="text"
if(s==="text"||s==="plaintext"||s==="txt"||g==="none"){r=A.c([],t.J)
for(q=A.j6(a),p=q.length,o=t.R,n=0;n<q.length;q.length===p||(0,A.y)(q),++n){m=q[n]
r.push(A.c([new A.S(m.a,m.b,h,0,h)],o))}return r}if(g==null)throw A.e(A.ha("No theme specified and no theme has been loaded"))
l=i.c8(g)
r=i.b
r.d=l.b
k=i.f.i(0,s.toLowerCase())
j=r.bE(k==null?s:k,0,h,h,h)
if(j==null)A.O(A.ha('Language "'+s+'" is not loaded'))
return i.cc(a,j,l,b)},
bU(a){B.a.j(this.z,A.iW(a,null))},
aX(a){B.a.j(this.Q,a)},
aY(a){B.a.j(this.as,a)},
cc(b9,c0,c1,c2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3=null,b4=c1.a,b5=A.md(b4.a,b4.f,c2.f),b6=c1.c,b7=A.j6(b9),b8=A.c([],t.J)
for(b4=b7.length,s=t.s,r=t.S,q=t.R,p=c2.e,o=c2.c,n=c2.d,m=n>0,l=b3,k=0;k<b7.length;b7.length===b4||(0,A.y)(b7),++k){j=b7[k]
i=j.a
h=j.b
if(i===""){B.a.j(b8,A.c([],q))
continue}if(m&&i.length>=n){B.a.j(b8,A.c([new A.S(i,h,"",0,b3)],q))
continue}if(o){g=c0.bd(i,l,!1,p)
f=g.b
e=g.a
d=f.b
if(d.length!==0&&B.a.gH(d).a===e-1){if(0>=d.length)return A.a(d,-1)
d.pop()}if(d.length===0){f.d=-1
f.v(g.c.x,e)
B.a.gH(d).a=0}c=new A.et(d)}else c=b3
g=c0.bd(i,l,!0,p)
f=g.b
l=g.c
e=g.a
d=f.c
b=d.length
if(b!==0){a=b-2
if(!(a>=0))return A.a(d,a)
a=d[a]===e-1}else a=!1
if(a){if(0>=b)return A.a(d,-1)
d.pop()
if(0>=d.length)return A.a(d,-1)
d.pop()}if(d.length===0){f.d=-1
f.v(l.x,e)
B.a.l(d,d.length-2,0)}f=A.i0(d,!0,r)
a0=f.length/2|0
a1=A.c([],q)
for(a2=i.length,a3=0,a4=0;a4<a0;){e=2*a4
d=f.length
if(!(e<d))return A.a(f,e)
a5=f[e];++a4
if(a4<a0){b=e+2
if(!(b<d))return A.a(f,b)
a6=f[b]}else a6=a2
if(a5===a6)continue;++e
if(!(e<d))return A.a(f,e)
a7=f[e]
e=a7>>>15&511
if(!(e<b6.length))return A.a(b6,e)
a8=A.lH(b6[e],b5)
a9=a7>>>11&7
if(c!=null){b0=A.c([],s)
e=c.a
b1=0
for(;;){if(!(a5+b1<a6&&a3<e.length))break
if(!(a3>=0&&a3<e.length))return A.a(e,a3)
b2=e[a3]
b1+=b2.b-b2.a
B.a.a0(b0,b2.c);++a3}}else b0=b3
e=B.b.A(i,a5,a6)
d=a9===-1?0:a9
B.a.j(a1,new A.S(e,h+a5,a8,d,b0))}B.a.j(b8,a1)}return b8}}
A.d8.prototype={
cE(){var s,r,q,p,o,n,m,l,k,j,i=this,h="settings",g=t.N,f=t.z,e=A.t(g,f)
e.l(0,"name",i.a)
e.l(0,"type",i.b)
s=i.d
if(s!=null)e.l(0,"fg",s)
s=i.e
if(s!=null)e.l(0,"bg",s)
s=i.r
if(s.a!==0)e.l(0,"colors",s)
s=i.f
if(s.a!==0)e.l(0,"colorReplacements",s)
s=A.c([],t.c7)
for(r=i.c,q=r.length,p=t.dk,o=0;o<r.length;r.length===q||(0,A.y)(r),++o){n=r[o]
m=A.t(g,f)
l=n.a
if(l!=null)m.l(0,"name",l)
l=n.b
if(l!=null)m.l(0,"scope",l)
l=A.t(g,p)
k=n.c
j=k.a
if(j!=null)l.l(0,"fontStyle",j)
j=k.b
if(j!=null)l.l(0,"foreground",j)
k=k.c
if(k!=null)l.l(0,"background",k)
m.l(0,h,l)
s.push(m)}e.l(0,h,s)
return e},
sbG(a){this.c=t.b9.a(a)},
sck(a){this.f=t.ck.a(a)}}
A.eq.prototype={
$2(a,b){if(typeof b=="string")this.a.l(0,J.a_(a),b)},
$S:1}
A.er.prototype={
$2(a,b){if(typeof b=="string")this.a.l(0,J.a_(a),b)},
$S:1}
A.fH.prototype={
$1(a){var s,r,q
A.v(a)
s=this.b
r=s.i(0,a)
if(r!=null)return r
q="#"+B.b.ct(B.d.cF(++this.a.a,16),8,"0").toLowerCase()
s.l(0,a,q)
return q},
$S:22}
A.S.prototype={
k(a){return"ThemedToken("+A.hB(this.a,"\n","\\n")+", color: "+A.n(this.c)+", fontStyle: "+this.e+")"}}
A.az.prototype={}
A.dH.prototype={
gc1(){var s=this.c
return s===$?this.c=new A.bd(new A.dI(this),A.t(t.N,t.fV),t.bg):s},
aQ(a){return this.gc1().aP(a)},
cb(a){var s,r=$.jc().bl(a)
if(r==null)return 8
s=r.b
if(1>=s.length)return A.a(s,1)
switch(s[1]){case"comment":return 1
case"string":return 2
case"regex":return 3
case"meta.embedded":return 0}throw A.e(A.M("Unexpected match for standard token type!"))}}
A.dI.prototype={
$1(a){var s,r
A.v(a)
s=this.a
r=s.b.R(a)
if(r==null)r=0
return new A.az(r,s.cb(a))},
$S:46}
A.eY.prototype={
bO(a){var s,r,q,p,o,n=this,m=a.length
if(m===0)n.b=n.a=null
else{s=A.t(t.N,t.S)
for(r=0;r<a.length;a.length===m||(0,A.y)(a),++r){q=a[r]
s.l(0,q.a,q.b)}n.a=s
m=A.G(a)
s=m.h("X<1,d>")
p=A.W(new A.X(a,m.h("d(1)").a(new A.eZ()),s),s.h("B.E"))
B.a.bH(p)
m=A.G(p).h("av<1>")
o=A.W(new A.av(p,m),m.h("B.E"))
n.b=A.Y("^(("+B.a.I(o,")|(")+"))($|\\.)",!0,!1)}},
R(a){var s,r,q=this.b
if(q==null)return null
s=q.bl(a)
if(s==null)return null
q=this.a
q.toString
r=s.b
if(1>=r.length)return A.a(r,1)
return q.i(0,r[1])}}
A.eZ.prototype={
$1(a){return A.iU(t.cK.a(a).a)},
$S:24}
A.da.prototype={
k(a){return"("+this.a+"-"+this.b+" "+B.a.I(this.c,", ")+")"}}
A.et.prototype={}
A.ak.prototype={}
A.fG.prototype={
$1(a){var s,r,q,p
A.v(a)
for(s=this.a,r=s.a,q=this.b,p=J.aK(q);r<p.gm(q);++r)if(A.lz(p.i(q,r),a)){s.a=r+1
return!0}return!1},
$S:25}
A.bE.prototype={
bL(a,b,c,d,e,f,g,h){var s=A.t(t.N,t.S),r=s.$ti.h("a4<1,2>")
s=A.W(new A.a4(s,r),r.h("f.E"))
s=A.kF(s)
this.x!==$&&A.j9()
this.x=new A.dH(new A.az(c,8),s)
this.r=A.iZ(b,null)},
bY(){var s,r=this,q=A.c([],t.cU),p=r.a,o=new A.dT(r).$1(p)
if(o!=null){s=o.d
if(s!=null)s.B(0,new A.dR(r,q,o))
r.f.c.i(0,p)}B.a.a5(q,new A.dS())
return q},
aS(){var s=this.w
return s==null?this.w=this.bY():s},
bv(a,b){var s,r,q
A.lN(b,t.r,"T","registerRule")
b.h("0(b)").a(a)
s=++this.c
r=a.$1(s)
for(q=this.d;q.length<=s;)B.a.j(q,null)
B.a.l(q,s,r)
return r},
aR(a,b){var s,r=this.e
if(r.a2(a))return r.i(0,a)
s=this.f.b.i(0,a)
if(s!=null){r.l(0,a,A.iZ(s,b==null?null:b.a.i(0,"$base")))
return r.i(0,a)}return null},
bD(a){return this.aR(a,null)},
bd(a,a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=null
if(c.b===-1){s=c.r
s===$&&A.q()
s=s.a.a.i(0,"$self")
s.toString
c.b=A.aX(s,c,c.r.a)
c.aS()}r=a0==null||a0===$.je()
if(r){s=c.x
s===$&&A.q()
q=s.a
p=c.f
o=p.d.b
n=A.fW(0,q.a,q.b,b,o.a,o.b,o.c)
m=c.b
l=c.d
if(!(m>=0&&m<l.length))return A.a(l,m)
k=l[m].a4(b,b)
if(k!=null){j=new A.bZ(b,k)
i=new A.by(j,A.hK(n,s.aQ(k),p.d.R(j)))}else i=new A.by(new A.bZ(b,"unknown"),n)
h=A.eo(b,c.b,-1,-1,!1,b,i,i)}else{a0.cw()
h=a0}g=a+"\n"
f=c.Q.bi(g)
e=new A.dZ(a1,A.c([],t.aT),A.c([],t.t),c.y,c.z)
d=A.ja(c,f,r,0,h,e,!0,a2)
return new A.f1(g.length,e,d.a,d.b)},
$iki:1,
$ika:1,
$ijT:1}
A.dT.prototype={
$1(a){var s=this.a
if(a===s.a){s=s.r
s===$&&A.q()}else s=s.bD(a)
return s},
$S:26}
A.dR.prototype={
$2(a,b){A.l_(this.b,A.v(a),t.Y.a(b),this.a,this.c)},
$S:7}
A.dS.prototype={
$2(a,b){var s=t.aR
return s.a(a).c-s.a(b).c},
$S:28}
A.f1.prototype={}
A.by.prototype={
k(a){return B.a.I(this.b.X()," ")},
V(a,b){var s,r,q,p
if(a==null)return this
if(!B.b.aA(a," "))return A.hL(this,a,b)
s=a.split(" ")
for(r=s.length,q=this,p=0;p<r;++p)q=A.hL(q,s[p],b)
return q}}
A.c1.prototype={
cw(){for(var s=this;s!=null;){s.d=s.c=-1
s=s.a}},
aN(a){var s,r=this
if(r.x===a)return r
s=r.a
s.toString
return A.eo(s,r.b,r.c,r.d,r.f,r.r,r.w,a)},
by(a){var s=this
if(s.r===a)return s
return A.eo(s.a,s.b,s.c,s.d,s.f,a,s.w,s.x)},
bm(a){var s=a.b,r=a.c,q=this
for(;;){if(!(q!=null&&q.c===r))break
if(q.b===s)return!0
q=q.a}return!1}}
A.dZ.prototype={
v(a,b){var s,r,q,p,o,n,m,l=this,k=null
if(l.d>=b)return
if(l.a){s=a==null
r=s?k:a.c
if(r==null)r=0
q=l.e
p=q.length
if(p!==0){o=s?k:a.b.X()
if(o==null)o=A.c([],t.s)
for(s=q.length,n=0;n<q.length;q.length===s||(0,A.y)(q),++n){m=q[n]
if(m.a.$1(o))r=A.fW(r,0,A.ml(m.b),k,-1,0,0)}}s=l.c
if(s.length!==0&&B.a.gH(s)===r){l.d=b
return}B.a.j(s,l.d)
B.a.j(s,r)
l.d=b
return}o=a==null?k:a.b.X()
if(o==null)o=A.c([],t.s)
B.a.j(l.b,new A.da(l.d,b,o))
l.d=b}}
A.aC.prototype={
b4(){return"IncludeReferenceKind."+this.b}}
A.aT.prototype={}
A.bQ.prototype={}
A.ft.prototype={
$0(){var s,r,q,p,o=this,n=o.a,m=n.a
if(m==="-"){n.a=o.b.$0()
return new A.fr(o.c.a8().$0(),o.f)}if(m==="("){m=o.b
n.a=m.$0()
s=o.d.a8().$0()
if(n.a===")")n.a=m.$0()
return s}if(m!=null){r=$.hI()
m=r.b.test(m)}else m=!1
if(m){q=A.c([],t.s)
m=o.b
do{r=n.a
r.toString
B.a.j(q,r)
p=n.a=m.$0()
if(p!=null){r=$.hI()
r=r.b.test(p)}else r=!1}while(r)
return new A.fs(o.e,q,o.f)}return null},
$S(){return this.f.h("w(0)?()")}}
A.fr.prototype={
$1(a){var s
this.b.a(a)
s=this.a
return s!=null&&!s.$1(a)},
$S(){return this.b.h("w(0)")}}
A.fs.prototype={
$1(a){return this.a.$2(this.b,this.c.a(a))},
$S(){return this.c.h("w(0)")}}
A.fu.prototype={
$0(){var s,r=this.b,q=A.c([],r.h("j<w(0)>")),p=this.a,o=p.a8().$0()
while(o!=null){B.a.j(q,o)
s=p.b
if(s===p)A.O(A.h4(""))
o=s.$0()}return new A.fq(q,r)},
$S(){return this.b.h("w(0)()")}}
A.fq.prototype={
$1(a){var s=this.b
return B.a.bj(this.a,new A.fo(s.a(a),s))},
$S(){return this.b.h("w(0)")}}
A.fo.prototype={
$1(a){return this.b.h("w(0)").a(a).$1(this.a)},
$S(){return this.b.h("w(w(0))")}}
A.fv.prototype={
$0(){var s,r,q,p,o=this,n=o.d,m=A.c([],n.h("j<w(0)>")),l=o.b,k=l.a8().$0()
for(s=o.c,r=o.a;;){B.a.j(m,k)
q=r.a
if(q==="|"||q===","){do p=r.a=s.$0()
while(p==="|"||p===",")}else break
q=l.b
if(q===l)A.O(A.h4(""))
k=q.$0()}return new A.fp(m,n)},
$S(){return this.d.h("w(0)()")}}
A.fp.prototype={
$1(a){var s=this.b
return B.a.cf(this.a,new A.fn(s.a(a),s))},
$S(){return this.b.h("w(0)")}}
A.fn.prototype={
$1(a){return this.b.h("w(0)").a(a).$1(this.a)},
$S(){return this.b.h("w(w(0))")}}
A.ff.prototype={
$0(){var s=this.a
if(!s.n())return null
s=s.d
s=(s==null?t.d.a(s):s).b
if(0>=s.length)return A.a(s,0)
return s[0]},
$S:29}
A.ad.prototype={
G(){var s,r,q,p=this,o=p.a,n=A.fc(p.f),m=A.fc(p.w),l=A.fc(p.y),k=A.fc(p.Q),j=p.as
if(j==null)j=null
else{s=A.c([],t.h)
for(r=j.length,q=0;q<j.length;j.length===r||(0,A.y)(j),++q)s.push(j[q].G())
j=s}s=p.at
s=s==null?null:s.G()
return new A.ad(o,p.b,p.c,p.d,p.e,n,p.r,m,p.x,l,p.z,k,j,s,p.ax)}}
A.fb.prototype={
$2(a,b){var s=J.a_(a)
if(s==="$vscodeTextmateLocation")return
if(t.f.b(b))this.a.l(0,s,A.ef(b.E(0,t.N,t.z)))},
$S:1}
A.ec.prototype={
G(){var s,r,q=A.t(t.N,t.Y)
for(s=this.a,s=new A.a4(s,A.p(s).h("a4<1,2>")).gt(0);s.n();){r=s.d
q.l(0,r.a,r.b.G())}return A.ed(q)}}
A.ee.prototype={
$2(a,b){A.v(a)
if(a==="$vscodeTextmateLocation")return
if(t.f.b(b))this.a.l(0,a,A.ef(b.E(0,t.N,t.z)))},
$S:10}
A.bl.prototype={
G(){var s,r,q,p,o,n=this,m=n.d
if(m!=null){s=A.t(t.N,t.Y)
for(m=new A.a4(m,A.p(m).h("a4<1,2>")).gt(0);m.n();){r=m.d
s.l(0,r.a,r.b.G())}q=s}else q=null
m=A.c([],t.h)
for(s=n.c,p=s.length,o=0;o<s.length;s.length===p||(0,A.y)(s),++o)m.push(s[o].G())
s=n.a.G()
p=n.r
if(p==null)p=null
else p=A.W(p,t.N)
return A.i7(p,n.w,n.e,q,n.f,m,s,n.b)}}
A.eb.prototype={
$2(a,b){var s
if(t.f.b(b)){s=this.a.a
s.toString
s.l(0,J.a_(a),A.ef(b.E(0,t.N,t.z)))}},
$S:1}
A.d6.prototype={
bE(a,b,c,d,e){var s,r,q,p=this,o=p.a
if(!o.a2(a)){s=p.b.i(0,a)
if(s==null)return null
r=p.e
q=new A.bE(a,A.c([null],t.df),A.t(t.N,t.E),p,A.c([],t.gI),e,r)
q.bL(a,s,b,c,d,e,p,r)
o.l(0,a,q)}return o.i(0,a)},
$ijS:1}
A.a2.prototype={
a4(a,b){var s,r=this
t.g2.a(b)
if(!r.c||r.b==null||a==null||b==null)return r.b
s=r.b
return A.i9(s==null?A.v(s):s,a,b)},
af(a,b){var s,r=this
t.u.a(b)
if(!r.e||r.d==null)return r.d
s=r.d
return A.i9(s==null?A.v(s):s,a,b)}}
A.dO.prototype={}
A.aA.prototype={
L(a,b){throw A.e(A.M("Not supported!"))},
T(a,b,c,d){throw A.e(A.M("Not supported!"))}}
A.bP.prototype={
L(a,b){b.U(this.f)},
T(a,b,c,d){return this.Z(a).a1(a,c,d)},
Z(a){var s=this.w
return s==null?this.w=new A.e2(this,a).$0():s}}
A.e2.prototype={
$0(){var s=new A.at(A.c([],t.O),new A.b_())
s.U(this.a.f)
return s},
$S:2}
A.bF.prototype={
L(a,b){var s,r,q,p,o
for(s=this.f,r=s.length,q=a.d,p=0;p<s.length;s.length===r||(0,A.y)(s),++p){o=s[p]
if(!(o>=0&&o<q.length))return A.a(q,o)
q[o].L(a,b)}},
T(a,b,c,d){return this.Z(a).a1(a,c,d)},
Z(a){var s=this.w
return s==null?this.w=new A.dU(this,a).$0():s}}
A.dU.prototype={
$0(){var s=new A.at(A.c([],t.O),new A.b_())
this.a.L(this.b,s)
return s},
$S:2}
A.aO.prototype={
L(a,b){b.U(this.f)},
T(a,b,c,d){return this.c2(a,b).a1(a,c,d)},
c2(a,b){var s,r,q,p,o,n,m=this,l=m.at
if(l==null){l=A.c([],t.O)
s=new A.at(l,new A.b_())
for(r=m.as,q=r.length,p=a.d,o=0;o<r.length;r.length===q||(0,A.y)(r),++o){n=r[o]
if(!(n>=0&&n<p.length))return A.a(p,n)
p[n].L(a,s)}if(m.z){l=m.w
r=l.d
r===$&&A.q()
if(r){r=l.a
r===$&&A.q()
l=A.as(r,l.b)}s.U(l)}else{r=m.w
q=r.d
q===$&&A.q()
if(q){q=r.a
q===$&&A.q()
r=A.as(q,r.b)}B.a.bn(l,0,r)
if(!s.b){l=r.c
l===$&&A.q()}else l=!0
s.b=l}m.at=s
l=s}r=m.w.d
r===$&&A.q()
if(r)if(m.z){r=l.a.length
b.toString
l.ag(r-1,b)}else{b.toString
l.ag(0,b)}l=m.at
l.toString
return l}}
A.aP.prototype={
L(a,b){b.U(this.f)},
T(a,b,c,d){return this.Z(a).a1(a,c,d)},
Z(a){var s=this.as
return s==null?this.as=new A.dJ(this,a).$0():s},
c3(a,b){var s,r=this,q=r.at
if(q==null)q=r.at=new A.dK(r).$0()
s=r.x.d
s===$&&A.q()
if(s)q.ag(0,b==null?"\uffff":b)
q=r.at
q.toString
return q}}
A.dJ.prototype={
$0(){var s,r,q,p,o,n,m=new A.at(A.c([],t.O),new A.b_())
for(s=this.a.Q,r=s.length,q=this.b,p=q.d,o=0;o<s.length;s.length===r||(0,A.y)(s),++o){n=s[o]
if(!(n>=0&&n<p.length))return A.a(p,n)
p[n].L(q,m)}return m},
$S:2}
A.dK.prototype={
$0(){var s=new A.at(A.c([],t.O),new A.b_()),r=this.a.x,q=r.d
q===$&&A.q()
if(q){q=r.a
q===$&&A.q()
r=A.as(q,r.b)}s.U(r)
return s},
$S:2}
A.ey.prototype={}
A.d_.prototype={
bN(a,b){var s,r,q,p,o,n,m,l=this,k=a.length,j=A.c([],t.s)
for(s=0,r=!1,q=0;q<k;++q)if(a[q]==="\\"){p=q+1
if(p<k){o=a[p]
if(o==="z"){B.a.j(j,B.b.A(a,s,q))
B.a.j(j,"$(?!\\n)(?<!\\n)")
s=q+2}else if(o==="A"||o==="G")r=!0
q=p}}l.c=r
if(s===0)l.a=a
else{B.a.j(j,B.b.A(a,s,k))
l.a=B.a.I(j,"")}if(l.c)l.e=l.aW()
else l.e=null
n=$.js()
m=l.a
m===$&&A.q()
l.d=n.b.test(m)},
bF(a){var s=this,r=s.a
r===$&&A.q()
if(r===a)return
s.a=a
r=s.c
r===$&&A.q()
if(r)s.e=s.aW()},
bw(a,b){var s,r,q,p,o,n
t.u.a(b)
s=A.c([],t.s)
for(r=b.length,q=a.length,p=0;p<b.length;b.length===r||(0,A.y)(b),++p){o=b[p]
n=o.a
s.push(n>=0&&o.b<=q?B.b.A(a,n,o.b):"")}r=this.a
r===$&&A.q()
return A.hA(r,$.jq(),t.A.a(t.I.a(new A.eg(s))),null)},
aW(){var s,r,q,p,o=t.s,n=A.c([],o),m=A.c([],o),l=A.c([],o),k=A.c([],o)
o=this.a
o===$&&A.q()
s=o.length
r=0
for(;r<s;++r){o=this.a
if(!(r<o.length))return A.a(o,r)
q=o[r]
B.a.j(n,q)
B.a.j(m,q)
B.a.j(l,q)
B.a.j(k,q)
if(q==="\\"&&r+1<s){o=this.a;++r
if(!(r<o.length))return A.a(o,r)
p=o[r]
if(p==="A"){B.a.j(n,"\uffff")
B.a.j(m,"\uffff")
B.a.j(l,"A")
B.a.j(k,"A")}else if(p==="G"){B.a.j(n,"\uffff")
B.a.j(m,"G")
B.a.j(l,"\uffff")
B.a.j(k,"G")}else{B.a.j(n,p)
B.a.j(m,p)
B.a.j(l,p)
B.a.j(k,p)}}}return new A.ey(B.a.I(n,""),B.a.I(m,""),B.a.I(l,""),B.a.I(k,""))},
cz(a,b){var s=this,r=s.c
r===$&&A.q()
if(!r||s.e==null){r=s.a
r===$&&A.q()
return r}if(a){r=s.e
return b?r.d:r.c}else{r=s.e
return b?r.b:r.a}}}
A.eg.prototype={
$1(a){var s,r,q,p=a.i(0,1)
p.toString
s=A.j_(p,null)
p=this.a
r=p.length
if(s<r){if(!(s>=0))return A.a(p,s)
q=p[s]}else q=""
return A.iU(q)},
$S:5}
A.b_.prototype={}
A.at.prototype={
gm(a){return this.a.length},
U(a){var s
B.a.j(this.a,a)
if(!this.b){s=a.c
s===$&&A.q()}else s=!0
this.b=s},
ag(a,b){var s,r,q=this.a,p=q.length
if(!(a>=0&&a<p))return A.a(q,a)
s=q[a]
r=s.a
r===$&&A.q()
if(r!==b){this.c=null
r=this.d
r.d=r.c=r.b=r.a=null
if(!(a<p))return A.a(q,a)
s.bF(b)}},
cl(a){var s,r,q,p,o=this.c
if(o==null){o=A.c([],t.s)
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.y)(s),++q){p=s[q].a
p===$&&A.q()
o.push(p)}r=A.c([],t.t)
for(p=s.length,q=0;q<s.length;s.length===p||(0,A.y)(s),++q)r.push(s[q].b)
o=this.c=new A.cz(a.Q.bh(t.a.a(o)),o,r)}return o},
a1(a,b,c){var s,r,q=this
if(!q.b)return q.cl(a)
if(b){s=q.d
if(c){r=s.d
return r==null?s.d=q.aa(a,!0,!0):r}else{r=s.c
return r==null?s.c=q.aa(a,!0,!1):r}}else{s=q.d
if(c){r=s.b
return r==null?s.b=q.aa(a,!1,!0):r}else{r=s.a
return r==null?s.a=q.aa(a,!1,!1):r}}},
aa(a,b,c){var s,r,q,p,o=A.c([],t.s)
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.y)(s),++q)o.push(s[q].cz(b,c))
r=A.c([],t.t)
for(p=s.length,q=0;q<s.length;s.length===p||(0,A.y)(s),++q)r.push(s[q].b)
return new A.cz(a.Q.bh(t.a.a(o)),o,r)}}
A.dP.prototype={}
A.cz.prototype={
M(a,b){var s,r,q=this.a.M(a,b)
if(q==null)return null
s=this.c
r=q.a
if(!(r>=0&&r<s.length))return A.a(s,r)
return new A.dP(s[r],q.b)},
k(a){var s,r,q,p,o=A.c([],t.s)
for(s=this.c,r=this.b,q=0;q<s.length;++q){p=s[q]
if(!(q<r.length))return A.a(r,q)
B.a.j(o,"   - "+p+": "+r[q])}return B.a.I(o,"\n")}}
A.ej.prototype={
$1(a){var s=this.a,r=this.b
return new A.aA(this.c,s,A.au(s),r,A.au(r))},
$S:32}
A.ek.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null,f=h.a
f.a=a
s=f.e
if(s!=null){r=f.c
f=A.d0(f.f,h.b,h.c)
return new A.bP(A.as(s,a),f,r,A.au(r),g,A.au(g))}s=f.r
if(s==null){q=h.c
s=f.at
if(s!=null){r=A.hZ(q.a,t.N,t.Y)
r.a0(0,s.a)
q=A.ed(r)}p=f.as
if(p==null&&f.b!=null)p=A.c([new A.ad(g,f.b,g,g,g,g,g,g,g,g,g,g,g,g,g)],t.h)
f.a.toString
s=f.c
f=f.d
r=A.h8(p,h.b,q)
return new A.bF(r.a,r.b,s,A.au(s),f,A.au(f))}r=f.z
if(r!=null){o=f.c
n=f.d
m=f.w
if(m==null)m=f.f
l=h.b
k=h.c
m=A.d0(m,l,k)
j=f.Q
j=A.d0(j==null?f.f:j,l,k)
k=A.h8(f.as,l,k)
s=A.as(s,a)
l=A.as(r,-2)
r=A.as(r,-2).d
r===$&&A.q()
return new A.aP(s,m,j,l,r,k.b,k.a,o,A.au(o),n,A.au(n))}r=f.c
o=f.d
n=f.w
if(n==null)n=f.f
m=h.b
l=h.c
n=A.d0(n,m,l)
k=f.x
j=f.y
j=A.d0(j==null?f.f:j,m,l)
l=A.h8(f.as,m,l)
s=A.as(s,a)
m=k==null
i=A.as(m?"\uffff":k,-1)
k=A.as(m?"\uffff":k,-1).d
k===$&&A.q()
return new A.aO(s,n,i,k,j,f.ax===!0,l.b,l.a,r,A.au(r),o,A.au(o))},
$S:33}
A.ei.prototype={
$2(a,b){var s,r,q=this
A.v(a)
t.Y.a(b)
s=A.h6(a,null)
if(s==null)return
r=b.as!=null?A.aX(b,q.a,q.b):0
B.a.l(q.c,s,A.kj(q.a,b.c,b.d,r))},
$S:7}
A.aF.prototype={}
A.c2.prototype={}
A.cZ.prototype={}
A.d5.prototype={}
A.bZ.prototype={
X(){var s,r,q=A.c([],t.s)
for(s=this;s!=null;){B.a.j(q,s.b)
s=s.a}r=t.bJ
r=A.W(new A.av(q,r),r.h("B.E"))
return r},
k(a){return B.a.I(this.X()," ")}}
A.aq.prototype={}
A.dM.prototype={
bK(a){this.a=!1},
a3(a){var s,r,q,p,o=this
if(a==null)return 0
s=a.toUpperCase()
r=o.d
q=r.i(0,s)
if(q!=null)return q
if(o.a)throw A.e(A.M("Missing color in color map - "+s))
p=++o.b
r.l(0,s,p)
o.c.l(0,p,s)
return p},
bC(){var s,r,q=this.c,p=q.a===0?-1:new A.ao(q,A.p(q).h("ao<1>")).cu(0,new A.dN()),o=A.c([],t.s)
for(s=0;s<=p;++s){r=q.i(0,s)
o.push(r==null?"":r)}return o}}
A.dN.prototype={
$2(a,b){A.u(a)
A.u(b)
return a>b?a:b},
$S:34}
A.R.prototype={
G(){var s=this
return A.hc(s.a,s.b,s.c,s.d,s.e)},
be(a,b,c,d){var s=this
if(s.a<=a)s.a=a
if(b!==-1)s.c=b
if(c!==0)s.d=c
if(d!==0)s.e=d}}
A.d9.prototype={
R(a){var s,r,q,p,o
if(a!==""){s=B.b.aF(a,".")
if(s===-1){r=a
q=""}else{r=B.b.A(a,0,s)
q=B.b.O(a,s+1)}p=this.c.i(0,r)
if(p!=null)return p.R(q)}o=A.W(this.b,t.cu)
o.push(this.a)
B.a.a5(o,A.mi())
return o},
bo(a,b,c,d,e,f,g){var s,r,q,p,o,n=this
t.bk.a(d)
if(c===""){n.bZ(b,d,e,f,g)
return}s=B.b.aF(c,".")
if(s===-1){r=c
q=""}else{r=B.b.A(c,0,s)
q=B.b.O(c,s+1)}p=n.c
o=p.i(0,r)
if(o==null){o=A.ic(n.a.G(),A.ko(n.b))
p.l(0,r,o)}o.bo(0,b+1,q,d,e,f,g)},
bZ(a,b,c,d,e){var s,r,q,p,o=this
t.bk.a(b)
if(b==null){o.a.be(a,c,d,e)
return}for(s=o.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.y)(s),++q){p=s[q]
if(A.j7(p.b,b)===0){p.be(a,c,d,e)
return}}if(c===-1)c=o.a.c
if(d===0)d=o.a.d
B.a.j(s,A.hc(a,b,c,d,e===0?o.a.e:e))}}
A.ep.prototype={
gbT(){var s=this.d
return s===$?this.d=new A.bd(new A.es(this),A.t(t.N,t.db),t.aV):s},
R(a){var s,r,q
for(s=J.af(this.gbT().aP(a.b)),r=a.a;s.n();){q=s.gp()
if(A.ly(r,q.b))return new A.d5(q.c,q.d,q.e)}return null}}
A.es.prototype={
$1(a){return this.a.c.R(A.v(a))},
$S:35}
A.fh.prototype={
$2(a,b){var s,r=t.cP
r.a(a)
r.a(b)
s=A.j8(a.a,b.a)
if(s!==0)return s
s=A.j7(a.b,b.b)
if(s!==0)return s
return a.c-b.c},
$S:36}
A.db.prototype={}
A.f5.prototype={}
A.dB.prototype={}
A.cc.prototype={}
A.eU.prototype={}
A.du.prototype={}
A.fy.prototype={
$1(a){return"\\"+A.n(a.i(0,0))},
$S:5}
A.bd.prototype={
aP(a){var s,r,q,p,o=this.$ti
o.c.a(a)
s=this.b
r=s.i(0,a)
q=r==null
if(!q||s.a2(a))return q?o.y[1].a(r):r
p=this.a.$1(a)
s.l(0,a,p)
return p}}
A.eh.prototype={
$1(a){var s,r,q,p,o,n,m=a.i(0,1)
if(m==null)m=a.i(0,2)
s=a.i(0,3)
m.toString
r=A.j_(m,null)
q=this.a
p=q.length
if(r<p){if(!(r>=0))return A.a(q,r)
o=q[r]
n=B.b.A(this.b,o.a,o.b)
for(;;){q=n.length
if(q!==0){if(0>=q)return A.a(n,0)
q=n[0]==="."}else q=!1
if(!q)break
n=B.b.O(n,1)}switch(s){case"downcase":return n.toLowerCase()
case"upcase":return n.toUpperCase()
default:return n}}q=a.i(0,0)
q.toString
return q},
$S:5}
A.ap.prototype={
gm(a){return this.c}}
A.e5.prototype={}
A.e7.prototype={}
A.fl.prototype={
$1(a){var s,r
t.x.a(a)
s=$.a6
if(s==null)s=A.O(A.M(u.h))
r=a.e
r===$&&A.q()
return s.a.free(r)},
$S:37}
A.fk.prototype={
$1(a){var s,r,q
t.c.a(a)
s=$.a6
if(s==null)s=A.O(A.M(u.h))
r=a.a
r===$&&A.q()
q=s.a
q.onig_shim_scanner_free(r)
q.free(a.b)
q.free(a.c)
q.free(a.d)
return null},
$S:38}
A.d2.prototype={
bh(a){var s,r,q,p=u.h,o=t.a.a(a)
o=o
s=$.a6
s=A.u((s==null?A.O(A.M(p)):s).a.malloc(4))
r=$.a6
r=A.u((r==null?A.O(A.M(p)):r).a.malloc(256))
q=$.a6
s=new A.bj(s,r,A.u((q==null?A.O(A.M(p)):q).a.malloc(256)))
s.bM(o)
r=new A.dn(s)
$.jv().bf(r,s,r)
return r},
bi(a){var s=A.i2(a),r=new A.dm(s,a)
$.jw().bf(r,s,r)
return r},
$ikk:1}
A.dm.prototype={}
A.dn.prototype={
M(a,b){var s,r,q,p
if(a instanceof A.dm){r=this.a.M(a.b,b)
return r==null?null:A.ij(r)}s=A.i2(a.a)
try{r=this.a.M(s,b)
q=r==null?null:A.ij(r)
return q}finally{q=$.a6
if(q==null)q=A.O(A.M(u.h))
p=s.e
p===$&&A.q()
q.a.free(p)}},
$ik9:1}
A.eF.prototype={
$1(a){var s,r,q=this.a.b
if(!(a<q.length))return A.a(q,a)
s=q[a]
q=s.a
if(q<0||s.b<0)return B.U
r=s.b
return new A.ap(q,r,r-q)},
$S:39};(function aliases(){var s=J.aE.prototype
s.bJ=s.k})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._static_1,q=hunkHelpers._static_0,p=hunkHelpers.installStaticTearOff
s(J,"lb","k_",40)
r(A,"lJ","ku",4)
r(A,"lK","kv",4)
r(A,"lL","kw",4)
q(A,"iR","lC",0)
r(A,"lP","l0",12)
p(A,"lM",0,null,["$2$bytes$url","$0"],["cr",function(){return A.cr(null,null)}],42,0)
r(A,"m5","hz",43)
r(A,"mc","mj",44)
s(A,"lZ","m9",45)
s(A,"mi","kp",30)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.k,null)
q(A.k,[A.h2,J.cE,A.bY,J.aN,A.f,A.bz,A.J,A.aB,A.r,A.el,A.V,A.bO,A.P,A.b1,A.bA,A.c8,A.ev,A.e4,A.bD,A.ci,A.e_,A.aU,A.bN,A.bI,A.cb,A.bo,A.d4,A.dz,A.eD,A.a7,A.dq,A.f2,A.f_,A.dh,A.a0,A.dj,A.aZ,A.F,A.di,A.dx,A.cn,A.bm,A.dt,A.ca,A.l,A.cy,A.cB,A.eS,A.dp,A.dk,A.cV,A.c_,A.eE,A.dQ,A.a5,A.K,A.dA,A.bn,A.e3,A.bk,A.bj,A.cU,A.e6,A.df,A.e8,A.ab,A.ex,A.hd,A.ah,A.em,A.eu,A.dv,A.en,A.d8,A.S,A.az,A.dH,A.eY,A.da,A.et,A.ak,A.bE,A.f1,A.by,A.c1,A.dZ,A.aT,A.bQ,A.ad,A.ec,A.bl,A.d6,A.a2,A.dO,A.ey,A.d_,A.b_,A.at,A.dP,A.cz,A.aF,A.c2,A.cZ,A.d5,A.bZ,A.aq,A.dM,A.R,A.d9,A.ep,A.db,A.f5,A.dB,A.cc,A.eU,A.du,A.bd,A.ap,A.e5,A.e7,A.d2,A.dn])
q(J.cE,[J.cG,J.bH,J.bK,J.bJ,J.bL,J.be,J.aD])
q(J.bK,[J.aE,J.j,A.bg,A.bT])
q(J.aE,[J.cW,J.aY,J.al])
r(J.cF,A.bY)
r(J.dV,J.j)
q(J.be,[J.bG,J.cH])
q(A.f,[A.aI,A.i,A.aV,A.c7,A.dg,A.dy])
q(A.aI,[A.aQ,A.co])
r(A.c6,A.aQ)
r(A.c5,A.co)
r(A.ag,A.c5)
q(A.J,[A.aR,A.am,A.dr])
q(A.aB,[A.cx,A.cw,A.d7,A.fz,A.fB,A.eA,A.ez,A.f6,A.eO,A.eX,A.fJ,A.fK,A.f8,A.f9,A.fD,A.fE,A.fQ,A.fR,A.fP,A.fO,A.fH,A.dI,A.eZ,A.fG,A.dT,A.fr,A.fs,A.fq,A.fo,A.fp,A.fn,A.eg,A.ej,A.ek,A.es,A.fy,A.eh,A.fl,A.fk,A.eF])
q(A.cx,[A.dL,A.dW,A.fA,A.f7,A.fm,A.eP,A.e1,A.eT,A.fN,A.fM,A.eq,A.er,A.dR,A.dS,A.fb,A.ee,A.eb,A.ei,A.dN,A.fh])
q(A.r,[A.an,A.aw,A.cI,A.de,A.d1,A.dl,A.bM,A.cu,A.aa,A.c3,A.dd,A.c0,A.cA])
q(A.i,[A.B,A.ao,A.a4])
r(A.bC,A.aV)
q(A.B,[A.X,A.av,A.ds])
r(A.bq,A.b1)
r(A.b2,A.bq)
r(A.bB,A.bA)
r(A.bV,A.aw)
q(A.d7,[A.d3,A.bc])
r(A.bf,A.bg)
q(A.bT,[A.cM,A.bi])
q(A.bi,[A.cd,A.cf])
r(A.ce,A.cd)
r(A.bR,A.ce)
r(A.cg,A.cf)
r(A.bS,A.cg)
q(A.bR,[A.cN,A.cO])
q(A.bS,[A.cP,A.bh,A.cQ,A.cR,A.cS,A.bU,A.cT])
r(A.br,A.dl)
q(A.cw,[A.eB,A.eC,A.f0,A.eG,A.eK,A.eJ,A.eI,A.eH,A.eN,A.eM,A.eL,A.eW,A.fj,A.fL,A.ft,A.fu,A.fv,A.ff,A.e2,A.dU,A.dJ,A.dK])
r(A.c4,A.dj)
r(A.dw,A.cn)
r(A.ch,A.bm)
r(A.c9,A.ch)
r(A.cK,A.bM)
r(A.cJ,A.cy)
q(A.cB,[A.dY,A.dX])
r(A.eR,A.eS)
q(A.aa,[A.bW,A.cD])
q(A.dk,[A.N,A.aC])
q(A.a2,[A.aA,A.bP,A.bF,A.aO,A.aP])
r(A.dm,A.e7)
s(A.co,A.l)
s(A.cd,A.l)
s(A.ce,A.P)
s(A.cf,A.l)
s(A.cg,A.P)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{b:"int",m:"double",T:"num",d:"String",w:"bool",K:"Null",h:"List",k:"Object",E:"Map",z:"JSObject"},mangledNames:{},types:["~()","~(@,@)","at()","~(@)","~(~())","d(ac)","K()","~(d,ad)","ab(@)","K(@)","~(d,@)","~(k?,k?)","@(@)","m(k?,k?,k?,k?)","h<ah>()","N(@)","m(k?)","h<E<d,@>>(h<S>)","a1<~>(d)","K(z)","K(k,aG)","~(b,@)","d(d)","K(@,aG)","d(a5<d,b>)","w(d)","bl?(d)","@(d)","b(ak,ak)","d?()","b(R,R)","@(@,d)","aA(b)","a2(b)","b(b,b)","h<R>(d)","b(aq,aq)","~(bk)","~(bj)","ap(b)","b(@,@)","K(~())","a1<~>({bytes:dc?,url:d?})","ah(ab)","E<d,@>(S)","w(h<d>,h<d>)","az(d)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;content,offset":(a,b)=>c=>c instanceof A.b2&&a.b(c.a)&&b.b(c.b)}}
A.kO(v.typeUniverse,JSON.parse('{"al":"aE","cW":"aE","aY":"aE","mv":"bg","cG":{"w":[],"o":[]},"bH":{"o":[]},"bK":{"z":[]},"aE":{"z":[]},"j":{"h":["1"],"i":["1"],"z":[],"f":["1"]},"cF":{"bY":[]},"dV":{"j":["1"],"h":["1"],"i":["1"],"z":[],"f":["1"]},"aN":{"I":["1"]},"be":{"m":[],"T":[],"ai":["T"]},"bG":{"m":[],"b":[],"T":[],"ai":["T"],"o":[]},"cH":{"m":[],"T":[],"ai":["T"],"o":[]},"aD":{"d":[],"ai":["d"],"e9":[],"o":[]},"aI":{"f":["2"]},"bz":{"I":["2"]},"aQ":{"aI":["1","2"],"f":["2"],"f.E":"2"},"c6":{"aQ":["1","2"],"aI":["1","2"],"i":["2"],"f":["2"],"f.E":"2"},"c5":{"l":["2"],"h":["2"],"aI":["1","2"],"i":["2"],"f":["2"]},"ag":{"c5":["1","2"],"l":["2"],"h":["2"],"aI":["1","2"],"i":["2"],"f":["2"],"l.E":"2","f.E":"2"},"aR":{"J":["3","4"],"E":["3","4"],"J.K":"3","J.V":"4"},"an":{"r":[]},"i":{"f":["1"]},"B":{"i":["1"],"f":["1"]},"V":{"I":["1"]},"aV":{"f":["2"],"f.E":"2"},"bC":{"aV":["1","2"],"i":["2"],"f":["2"],"f.E":"2"},"bO":{"I":["2"]},"X":{"B":["2"],"i":["2"],"f":["2"],"B.E":"2","f.E":"2"},"av":{"B":["1"],"i":["1"],"f":["1"],"B.E":"1","f.E":"1"},"b2":{"bq":[],"b1":[]},"bA":{"E":["1","2"]},"bB":{"bA":["1","2"],"E":["1","2"]},"c7":{"f":["1"],"f.E":"1"},"c8":{"I":["1"]},"bV":{"aw":[],"r":[]},"cI":{"r":[]},"de":{"r":[]},"ci":{"aG":[]},"aB":{"aS":[]},"cw":{"aS":[]},"cx":{"aS":[]},"d7":{"aS":[]},"d3":{"aS":[]},"bc":{"aS":[]},"d1":{"r":[]},"am":{"J":["1","2"],"hX":["1","2"],"E":["1","2"],"J.K":"1","J.V":"2"},"ao":{"i":["1"],"f":["1"],"f.E":"1"},"aU":{"I":["1"]},"a4":{"i":["a5<1,2>"],"f":["a5<1,2>"],"f.E":"a5<1,2>"},"bN":{"I":["a5<1,2>"]},"bq":{"b1":[]},"bI":{"kg":[],"e9":[]},"cb":{"bX":[],"ac":[]},"dg":{"f":["bX"],"f.E":"bX"},"bo":{"I":["bX"]},"d4":{"ac":[]},"dy":{"f":["ac"],"f.E":"ac"},"dz":{"I":["ac"]},"bf":{"z":[],"o":[]},"bh":{"h_":[],"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"bg":{"z":[],"o":[]},"bT":{"z":[]},"cM":{"z":[],"o":[]},"bi":{"U":["1"],"z":[]},"bR":{"l":["m"],"h":["m"],"U":["m"],"i":["m"],"z":[],"f":["m"],"P":["m"]},"bS":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"]},"cN":{"l":["m"],"h":["m"],"U":["m"],"i":["m"],"z":[],"f":["m"],"P":["m"],"o":[],"l.E":"m"},"cO":{"l":["m"],"h":["m"],"U":["m"],"i":["m"],"z":[],"f":["m"],"P":["m"],"o":[],"l.E":"m"},"cP":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"cQ":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"cR":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"cS":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"bU":{"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"cT":{"dc":[],"l":["b"],"h":["b"],"U":["b"],"i":["b"],"z":[],"f":["b"],"P":["b"],"o":[],"l.E":"b"},"dl":{"r":[]},"br":{"aw":[],"r":[]},"a0":{"r":[]},"c4":{"dj":["1"]},"F":{"a1":["1"]},"cn":{"ih":[]},"dw":{"cn":[],"ih":[]},"c9":{"bm":["1"],"h9":["1"],"i":["1"],"f":["1"]},"ca":{"I":["1"]},"J":{"E":["1","2"]},"bm":{"h9":["1"],"i":["1"],"f":["1"]},"ch":{"bm":["1"],"h9":["1"],"i":["1"],"f":["1"]},"dr":{"J":["d","@"],"E":["d","@"],"J.K":"d","J.V":"@"},"ds":{"B":["d"],"i":["d"],"f":["d"],"B.E":"d","f.E":"d"},"bM":{"r":[]},"cK":{"r":[]},"cJ":{"cy":["k?","d"]},"m":{"T":[],"ai":["T"]},"b":{"T":[],"ai":["T"]},"h":{"i":["1"],"f":["1"]},"T":{"ai":["T"]},"bX":{"ac":[]},"d":{"ai":["d"],"e9":[]},"dk":{"fX":[]},"cu":{"r":[]},"aw":{"r":[]},"aa":{"r":[]},"bW":{"r":[]},"cD":{"r":[]},"c3":{"r":[]},"dd":{"r":[]},"c0":{"r":[]},"cA":{"r":[]},"cV":{"r":[]},"c_":{"r":[]},"dA":{"aG":[]},"bn":{"km":[]},"N":{"fX":[]},"bE":{"jT":[],"ki":[],"ka":[]},"aC":{"fX":[]},"d6":{"jS":[]},"aA":{"a2":[]},"bP":{"a2":[]},"bF":{"a2":[]},"aO":{"a2":[]},"aP":{"a2":[]},"d2":{"kk":[]},"dn":{"k9":[]},"jV":{"h":["b"],"i":["b"],"f":["b"]},"dc":{"h":["b"],"i":["b"],"f":["b"]},"ks":{"h":["b"],"i":["b"],"f":["b"]},"jU":{"h":["b"],"i":["b"],"f":["b"]},"kq":{"h":["b"],"i":["b"],"f":["b"]},"h_":{"h":["b"],"i":["b"],"f":["b"]},"kr":{"h":["b"],"i":["b"],"f":["b"]},"jQ":{"h":["m"],"i":["m"],"f":["m"]},"jR":{"h":["m"],"i":["m"],"f":["m"]}}'))
A.kN(v.typeUniverse,JSON.parse('{"co":2,"bi":1,"ch":1,"cB":2}'))
var u={c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",h:"Oniguruma wasm is not loaded. Call `await loadWasm()` once at startup before constructing an OnigScanner/OnigString on web."}
var t=(function rtii(){var s=A.dE
return{n:s("a0"),fV:s("az"),eb:s("aO"),bg:s("bd<d,az>"),aV:s("bd<d,h<R>>"),ds:s("aA"),e8:s("ai<@>"),U:s("i<@>"),C:s("r"),Z:s("aS"),bF:s("a1<h<h<S>>>"),f1:s("bE"),e:s("N"),aR:s("ak"),hf:s("f<@>"),p:s("j<N>"),cU:s("j<ak>"),k:s("j<ab>"),J:s("j<h<S>>"),c7:s("j<E<d,@>>"),gw:s("j<aq>"),h:s("j<ad>"),G:s("j<aF>"),B:s("j<+content,offset(d,b)>"),O:s("j<d_>"),s:s("j<d>"),w:s("j<R>"),R:s("j<S>"),aT:s("j<da>"),dg:s("j<du>"),gI:s("j<mM>"),fj:s("j<dB>"),q:s("j<@>"),t:s("j<b>"),ac:s("j<aA?>"),df:s("j<a2?>"),T:s("bH"),m:s("z"),W:s("al"),aU:s("U<@>"),D:s("ab"),u:s("h<ap>"),b9:s("h<aF>"),a:s("h<d>"),db:s("h<R>"),fB:s("h<S>"),j:s("h<@>"),cK:s("a5<d,b>"),ck:s("E<d,d>"),P:s("E<d,@>"),f:s("E<@,@>"),dm:s("bP"),i:s("bf"),ha:s("bh"),b:s("K"),K:s("k"),f3:s("cU"),gR:s("ap"),c:s("bj"),x:s("bk"),cP:s("aq"),E:s("bl"),Y:s("ad"),fN:s("aF"),gT:s("mw"),bQ:s("+()"),d:s("bX"),bJ:s("av<d>"),r:s("a2"),l:s("aG"),N:s("d"),I:s("d(ac)"),bG:s("d8"),go:s("d9"),cu:s("R"),aN:s("S"),ci:s("o"),eK:s("aw"),ak:s("aY"),fb:s("mK"),_:s("F<@>"),dP:s("dv"),y:s("w"),ah:s("w(h<d>)"),al:s("w(k)"),V:s("m"),z:s("@"),fO:s("@()"),v:s("@(k)"),Q:s("@(k,aG)"),S:s("b"),eH:s("a1<K>?"),an:s("z?"),e0:s("al?"),g2:s("h<ap>?"),bk:s("h<d>?"),g:s("h<@>?"),fF:s("E<@,@>?"),X:s("k?"),dk:s("d?"),A:s("d(ac)?"),F:s("aZ<@,@>?"),L:s("dt?"),fQ:s("w?"),cD:s("m?"),h6:s("b?"),cg:s("T?"),o:s("T"),H:s("~"),M:s("~()"),cA:s("~(d,@)")}})();(function constants(){var s=hunkHelpers.makeConstList
B.J=J.cE.prototype
B.a=J.j.prototype
B.d=J.bG.prototype
B.K=J.be.prototype
B.b=J.aD.prototype
B.L=J.al.prototype
B.M=J.bK.prototype
B.m=J.cW.prototype
B.i=J.aY.prototype
B.j=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.n=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.t=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.o=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.r=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.q=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.p=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.k=function(hooks) { return hooks; }

B.e=new A.cJ()
B.u=new A.cV()
B.h=new A.el()
B.v=new A.d2()
B.c=new A.dw()
B.f=new A.dA()
B.F=new A.aC(0,"base")
B.G=new A.aC(1,"self")
B.H=new A.aC(2,"relativeReference")
B.I=new A.aC(3,"topLevelReference")
B.l=new A.aC(4,"topLevelRepositoryReference")
B.N=new A.dX(null)
B.O=new A.dY(null)
B.w=new A.N(0,"web")
B.x=new A.N(1,"markup")
B.y=new A.N(2,"general")
B.z=new A.N(3,"scripting")
B.A=new A.N(4,"data")
B.B=new A.N(5,"dsl")
B.C=new A.N(6,"utility")
B.D=new A.N(7,"config")
B.E=new A.N(8,"lisp")
B.P=s([B.w,B.x,B.y,B.z,B.A,B.B,B.C,B.D,B.E],t.p)
B.Q=s([],t.p)
B.R=s([],t.s)
B.T={}
B.S=new A.bB(B.T,[],A.dE("bB<@,@>"))
B.U=new A.ap(4294967295,4294967295,0)
B.V=new A.b2("",0)
B.W=A.a8("mr")
B.X=A.a8("ms")
B.Y=A.a8("jQ")
B.Z=A.a8("jR")
B.a_=A.a8("jU")
B.a0=A.a8("h_")
B.a1=A.a8("jV")
B.a2=A.a8("k")
B.a3=A.a8("kq")
B.a4=A.a8("kr")
B.a5=A.a8("ks")
B.a6=A.a8("dc")})();(function staticFields(){$.eQ=null
$.Z=A.c([],A.dE("j<k>"))
$.i3=null
$.hO=null
$.hN=null
$.iY=null
$.iQ=null
$.j4=null
$.fx=null
$.fC=null
$.hv=null
$.eV=A.c([],A.dE("j<h<k>?>"))
$.bt=null
$.cp=null
$.cq=null
$.ho=!1
$.x=B.c
$.a6=null})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal
s($,"mu","jd",()=>A.iX("_$dart_dartClosure"))
s($,"mt","fS",()=>A.iX("_$dart_dartClosure_dartJSInterop"))
s($,"mY","ju",()=>A.c([new J.cF()],A.dE("j<bY>")))
s($,"mz","jf",()=>A.ax(A.ew({
toString:function(){return"$receiver$"}})))
s($,"mA","jg",()=>A.ax(A.ew({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"mB","jh",()=>A.ax(A.ew(null)))
s($,"mC","ji",()=>A.ax(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"mF","jl",()=>A.ax(A.ew(void 0)))
s($,"mG","jm",()=>A.ax(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"mE","jk",()=>A.ax(A.id(null)))
s($,"mD","jj",()=>A.ax(function(){try{null.$method$}catch(r){return r.message}}()))
s($,"mI","jo",()=>A.ax(A.id(void 0)))
s($,"mH","jn",()=>A.ax(function(){try{(void 0).$method$}catch(r){return r.message}}()))
s($,"mJ","hC",()=>A.kt())
s($,"mL","jp",()=>typeof FinalizationRegistry=="function"?FinalizationRegistry:null)
s($,"mR","fT",()=>A.j1(B.a2))
s($,"mq","jc",()=>A.Y("\\b(comment|string|regex|meta\\.embedded)\\b",!0,!1))
s($,"mx","je",()=>{var r=null
return A.eo(r,0,0,0,!1,r,r,r)})
s($,"n0","jx",()=>A.Y("([LR]:|[\\w.:][\\w.:\\-]*|[,|\\-()])",!0,!1))
s($,"mW","hI",()=>A.Y("[\\w.:]+",!0,!1))
s($,"mQ","js",()=>A.Y("\\\\(\\d+)",!0,!1))
s($,"mN","jq",()=>A.Y("\\\\(\\d+)",!0,!1))
s($,"mX","jt",()=>A.Y("^,+",!0,!1))
s($,"n1","jy",()=>A.Y(",+$",!0,!1))
s($,"mU","hG",()=>A.Y("^#[0-9a-f]{6}$",!1,!1))
s($,"mV","hH",()=>A.Y("^#[0-9a-f]{8}$",!1,!1))
s($,"mS","hE",()=>A.Y("^#[0-9a-f]{3}$",!1,!1))
s($,"mT","hF",()=>A.Y("^#[0-9a-f]{4}$",!1,!1))
s($,"mP","jr",()=>A.Y("[\\-\\\\\\{\\}\\*\\+\\?\\|\\^\\$\\.\\,\\[\\]\\(\\)\\#\\s]",!0,!1))
s($,"mO","hD",()=>A.Y("\\$(\\d+)|\\$\\{(\\d+):/(downcase|upcase)\\}",!0,!1))
s($,"n_","jw",()=>A.hS(new A.fl(),t.x))
s($,"mZ","jv",()=>A.hS(new A.fk(),t.c))})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({SharedArrayBuffer:A.bg,ArrayBuffer:A.bf,ArrayBufferView:A.bT,DataView:A.cM,Float32Array:A.cN,Float64Array:A.cO,Int16Array:A.cP,Int32Array:A.bh,Int8Array:A.cQ,Uint16Array:A.cR,Uint32Array:A.cS,Uint8ClampedArray:A.bU,CanvasPixelArray:A.bU,Uint8Array:A.cT})
hunkHelpers.setOrUpdateLeafTags({SharedArrayBuffer:true,ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.bi.$nativeSuperclassTag="ArrayBufferView"
A.cd.$nativeSuperclassTag="ArrayBufferView"
A.ce.$nativeSuperclassTag="ArrayBufferView"
A.bR.$nativeSuperclassTag="ArrayBufferView"
A.cf.$nativeSuperclassTag="ArrayBufferView"
A.cg.$nativeSuperclassTag="ArrayBufferView"
A.bS.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$2$0=function(){return this()}
Function.prototype.$1$0=function(){return this()}
Function.prototype.$1$1=function(a){return this(a)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.m7
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()