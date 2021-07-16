// JavaScript Document
window.onload = function() {
    var a=document.getElementById('next'),
        l=document.location.href,
        s=Math.max(l.lastIndexOf('\\'),l.lastIndexOf('/')),
        d=l.indexOf('.'),
        f=l.substring(s+1,l.indexOf('.')),
        p=l.substring(0,s+1),
        e=l.substring(s+1+f.length, l.length),
        n=parseInt(f,10) + 1;
    if (a) {
       a.href= p + n.toString()+e;
    }
};