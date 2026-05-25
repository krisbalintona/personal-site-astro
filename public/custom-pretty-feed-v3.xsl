<?xml version="1.0" encoding="utf-8"?>
<!--

# Pretty Feed (with Dark Mode)

Styles an RSS/Atom feed, making it friendly for humans viewers, and adds a link
to aboutfeeds.com for new user onboarding. See it in action:

   https://interconnected.org/home/feed

Dark mode support added via @media (prefers-color-scheme: dark).
Respects the OS/browser color scheme preference automatically.

## How to use

1. Download this XML stylesheet from the following URL and host it on your own
   domain (this is a limitation of XSL in browsers):

   https://github.com/genmon/aboutfeeds/blob/main/tools/pretty-feed-v3.xsl

2. Include the XSL at the top of the RSS/Atom feed, like:

```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet href="/PATH-TO-YOUR-STYLES/pretty-feed-v3.xsl" type="text/xsl"?>
```

3. Serve the feed with the following HTTP headers:

```
Content-Type: application/xml; charset=utf-8  # not application/rss+xml
x-content-type-options: nosniff
```

(These headers are required to style feeds for users with Safari on iOS/Mac.)



## Limitations

- Styling the feed *prevents* the browser from automatically opening a
  newsreader application. This is a trade off, but it's a benefit to new users
  who won't have a newsreader installed, and they are saved from seeing or
  downloaded obscure XML content. For existing newsreader users, they will know
  to copy-and-paste the feed URL, and they get the benefit of an in-browser feed
  preview.
- Feed styling, for all browsers, is only available to site owners who control
  their own platform. The need to add both XML and HTTP headers makes this a
  limited solution.


## Credits

pretty-feed is based on work by lepture.com:

   https://lepture.com/en/2019/rss-style-with-xsl

This current version is maintained by aboutfeeds.com:

   https://github.com/genmon/aboutfeeds


## Feedback

This file is in BETA. Please test and contribute to the discussion:

     https://github.com/genmon/aboutfeeds/issues/8

-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
      <head>
        <title><xsl:value-of select="/rss/channel/title"/> Web Feed</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
        <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
        <style type="text/css">/*! normalize.css v4.1.1 | MIT License | github.com/necolas/normalize.css */html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,details,figcaption,figure,footer,header,main,menu,nav,section{display:block}summary{display:list-item}audio,canvas,progress,video{display:inline-block}audio:not([controls]){display:none;height:0}progress{vertical-align:baseline}[hidden],template{display:none!important}a{background-color:transparent}a:active,a:hover{outline-width:0}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:inherit}b,strong{font-weight:bolder}dfn{font-style:italic}h1{font-size:2em;margin:.67em 0}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}img{border-style:none}svg:not(:root){overflow:hidden}code,kbd,pre,samp{font-family:monospace,monospace;font-size:1em}figure{margin:1em 40px}hr{box-sizing:content-box;height:0;overflow:visible}button,input,select,textarea{font:inherit;margin:0}optgroup{font-weight:700}button,input{overflow:visible}button,select{text-transform:none}[type=reset],[type=submit],button,html [type=button]{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}fieldset{border:1px solid silver;margin:0 2px;padding:.35em .625em .75em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-cancel-button,[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-input-placeholder{color:inherit;opacity:.54}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}*{box-sizing:border-box}button,input,select,textarea{font-family:inherit;font-size:inherit;line-height:inherit}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";font-size:14px;line-height:1.5;color:#24292e;background-color:#fff}a{color:#0366d6;text-decoration:none}a:hover{text-decoration:underline}b,strong{font-weight:600}.rule,hr{height:0;margin:15px 0;overflow:hidden;background:0 0;border:0;border-bottom:1px solid #dfe2e5}.rule::before,hr::before{display:table;content:""}.rule::after,hr::after{display:table;clear:both;content:""}table{border-spacing:0;border-collapse:collapse}td,th{padding:0}button{cursor:pointer;border-radius:0}[hidden][hidden]{display:none!important}details summary{cursor:pointer}details:not([open])>* :not(summary){display:none!important}h1,h2,h3,h4,h5,h6{margin-top:0;margin-bottom:0}h1{font-size:32px;font-weight:600}h2{font-size:24px;font-weight:600}h3{font-size:20px;font-weight:600}h4{font-size:16px;font-weight:600}h5{font-size:14px;font-weight:600}h6{font-size:12px;font-weight:600}p{margin-top:0;margin-bottom:10px}small{font-size:90%}blockquote{margin:0}ol,ul{padding-left:0;margin-top:0;margin-bottom:0}ol ol,ul ol{list-style-type:lower-roman}ol ol ol,ol ul ol,ul ol ol,ul ul ol{list-style-type:lower-alpha}dd{margin-left:0}code,tt{font-family:SFMono-Regular,Consolas,"Liberation Mono",Menlo,Courier,monospace;font-size:12px}pre{margin-top:0;margin-bottom:0;font-family:SFMono-Regular,Consolas,"Liberation Mono",Menlo,Courier,monospace;font-size:12px}.octicon{vertical-align:text-bottom}.anim-fade-in{animation-name:fade-in;animation-duration:1s;animation-timing-function:ease-in-out}.anim-fade-in.fast{animation-duration:.3s}@keyframes fade-in{0%{opacity:0}100%{opacity:1}}.anim-fade-out{animation-name:fade-out;animation-duration:1s;animation-timing-function:ease-out}.anim-fade-out.fast{animation-duration:.3s}@keyframes fade-out{0%{opacity:1}100%{opacity:0}}.anim-fade-up{opacity:0;animation-name:fade-up;animation-duration:.3s;animation-fill-mode:forwards;animation-timing-function:ease-out;animation-delay:1s}@keyframes fade-up{0%{opacity:.8;transform:translateY(100%)}100%{opacity:1;transform:translateY(0)}}.anim-fade-down{animation-name:fade-down;animation-duration:.3s;animation-fill-mode:forwards;animation-timing-function:ease-in}@keyframes fade-down{0%{opacity:1;transform:translateY(0)}100%{opacity:.5;transform:translateY(100%)}}.anim-grow-x{width:0%;animation-name:grow-x;animation-duration:.3s;animation-fill-mode:forwards;animation-timing-function:ease;animation-delay:.5s}@keyframes grow-x{to{width:100%}}.anim-shrink-x{animation-name:shrink-x;animation-duration:.3s;animation-fill-mode:forwards;animation-timing-function:ease-in-out;animation-delay:.5s}@keyframes shrink-x{to{width:0%}}.anim-scale-in{animation-name:scale-in;animation-duration:.15s;animation-timing-function:cubic-bezier(.2,0,.13,1.5)}@keyframes scale-in{0%{opacity:0;transform:scale(.5)}100%{opacity:1;transform:scale(1)}}.anim-pulse{animation-name:pulse;animation-duration:2s;animation-timing-function:linear;animation-iteration-count:infinite}@keyframes pulse{0%{opacity:.3}10%{opacity:1}100%{opacity:.3}}.anim-pulse-in{animation-name:pulse-in;animation-duration:.5s}@keyframes pulse-in{0%{transform:scale3d(1,1,1)}50%{transform:scale3d(1.1,1.1,1.1)}100%{transform:scale3d(1,1,1)}}.hover-grow{transition:transform .3s;backface-visibility:hidden}.hover-grow:hover{transform:scale(1.025)}.border{border:1px #e1e4e8 solid!important}.border-y{border-top:1px #e1e4e8 solid!important;border-bottom:1px #e1e4e8 solid!important}.border-0{border:0!important}.border-dashed{border-style:dashed!important}.border-blue{border-color:#0366d6!important}.border-blue-light{border-color:#c8e1ff!important}.border-green{border-color:#34d058!important}.border-green-light{border-color:#a2cbac!important}.border-red{border-color:#d73a49!important}.border-red-light{border-color:#cea0a5!important}.border-purple{border-color:#6f42c1!important}.border-yellow{border-color:#d9d0a5!important}.border-gray-light{border-color:#eaecef!important}.border-gray-dark{border-color:#d1d5da!important}.border-black-fade{border-color:rgba(27,31,35,.15)!important}.border-top{border-top:1px #e1e4e8 solid!important}.border-right{border-right:1px #e1e4e8 solid!important}.border-bottom{border-bottom:1px #e1e4e8 solid!important}.border-left{border-left:1px #e1e4e8 solid!important}.border-top-0{border-top:0!important}.border-right-0{border-right:0!important}.border-bottom-0{border-bottom:0!important}.border-left-0{border-left:0!important}.rounded-0{border-radius:0!important}.rounded-1{border-radius:3px!important}.rounded-2{border-radius:6px!important}.rounded-top-0{border-top-left-radius:0!important;border-top-right-radius:0!important}.rounded-top-1{border-top-left-radius:3px!important;border-top-right-radius:3px!important}.rounded-top-2{border-top-left-radius:6px!important;border-top-right-radius:6px!important}.rounded-right-0{border-top-right-radius:0!important;border-bottom-right-radius:0!important}.rounded-right-1{border-top-right-radius:3px!important;border-bottom-right-radius:3px!important}.rounded-right-2{border-top-right-radius:6px!important;border-bottom-right-radius:6px!important}.rounded-bottom-0{border-bottom-right-radius:0!important;border-bottom-left-radius:0!important}.rounded-bottom-1{border-bottom-right-radius:3px!important;border-bottom-left-radius:3px!important}.rounded-bottom-2{border-bottom-right-radius:6px!important;border-bottom-left-radius:6px!important}.rounded-left-0{border-bottom-left-radius:0!important;border-top-left-radius:0!important}.rounded-left-1{border-bottom-left-radius:3px!important;border-top-left-radius:3px!important}.rounded-left-2{border-bottom-left-radius:6px!important;border-top-left-radius:6px!important}@media (min-width:544px){.border-sm-top{border-top:1px #e1e4e8 solid!important}.border-sm-right{border-right:1px #e1e4e8 solid!important}.border-sm-bottom{border-bottom:1px #e1e4e8 solid!important}.border-sm-left{border-left:1px #e1e4e8 solid!important}.border-sm-top-0{border-top:0!important}.border-sm-right-0{border-right:0!important}.border-sm-bottom-0{border-bottom:0!important}.border-sm-left-0{border-left:0!important}.rounded-sm-0{border-radius:0!important}.rounded-sm-1{border-radius:3px!important}.rounded-sm-2{border-radius:6px!important}.rounded-sm-top-0{border-top-left-radius:0!important;border-top-right-radius:0!important}.rounded-sm-top-1{border-top-left-radius:3px!important;border-top-right-radius:3px!important}.rounded-sm-top-2{border-top-left-radius:6px!important;border-top-right-radius:6px!important}.rounded-sm-right-0{border-top-right-radius:0!important;border-bottom-right-radius:0!important}.rounded-sm-right-1{border-top-right-radius:3px!important;border-bottom-right-radius:3px!important}.rounded-sm-right-2{border-top-right-radius:6px!important;border-bottom-right-radius:6px!important}.rounded-sm-bottom-0{border-bottom-right-radius:0!important;border-bottom-left-radius:0!important}.rounded-sm-bottom-1{border-bottom-right-radius:3px!important;border-bottom-left-radius:3px!important}.rounded-sm-bottom-2{border-bottom-right-radius:6px!important;border-bottom-left-radius:6px!important}.rounded-sm-left-0{border-bottom-left-radius:0!important;border-top-left-radius:0!important}.rounded-sm-left-1{border-bottom-left-radius:3px!important;border-top-left-radius:3px!important}.rounded-sm-left-2{border-bottom-left-radius:6px!important;border-top-left-radius:6px!important}}@media (min-width:768px){.border-md-top{border-top:1px #e1e4e8 solid!important}.border-md-right{border-right:1px #e1e4e8 solid!important}.border-md-bottom{border-bottom:1px #e1e4e8 solid!important}.border-md-left{border-left:1px #e1e4e8 solid!important}.border-md-top-0{border-top:0!important}.border-md-right-0{border-right:0!important}.border-md-bottom-0{border-bottom:0!important}.border-md-left-0{border-left:0!important}.rounded-md-0{border-radius:0!important}.rounded-md-1{border-radius:3px!important}.rounded-md-2{border-radius:6px!important}.rounded-md-top-0{border-top-left-radius:0!important;border-top-right-radius:0!important}.rounded-md-top-1{border-top-left-radius:3px!important;border-top-right-radius:3px!important}.rounded-md-top-2{border-top-left-radius:6px!important;border-top-right-radius:6px!important}.rounded-md-right-0{border-top-right-radius:0!important;border-bottom-right-radius:0!important}.rounded-md-right-1{border-top-right-radius:3px!important;border-bottom-right-radius:3px!important}.rounded-md-right-2{border-top-right-radius:6px!important;border-bottom-right-radius:6px!important}.rounded-md-bottom-0{border-bottom-right-radius:0!important;border-bottom-left-radius:0!important}.rounded-md-bottom-1{border-bottom-right-radius:3px!important;border-bottom-left-radius:3px!important}.rounded-md-bottom-2{border-bottom-right-radius:6px!important;border-bottom-left-radius:6px!important}.rounded-md-left-0{border-bottom-left-radius:0!important;border-top-left-radius:0!important}.rounded-md-left-1{border-bottom-left-radius:3px!important;border-top-left-radius:3px!important}.rounded-md-left-2{border-bottom-left-radius:6px!important;border-top-left-radius:6px!important}}@media (min-width:1012px){.border-lg-top{border-top:1px #e1e4e8 solid!important}.border-lg-right{border-right:1px #e1e4e8 solid!important}.border-lg-bottom{border-bottom:1px #e1e4e8 solid!important}.border-lg-left{border-left:1px #e1e4e8 solid!important}.border-lg-top-0{border-top:0!important}.border-lg-right-0{border-right:0!important}.border-lg-bottom-0{border-bottom:0!important}.border-lg-left-0{border-left:0!important}.rounded-lg-0{border-radius:0!important}.rounded-lg-1{border-radius:3px!important}.rounded-lg-2{border-radius:6px!important}.rounded-lg-top-0{border-top-left-radius:0!important;border-top-right-radius:0!important}.rounded-lg-top-1{border-top-left-radius:3px!important;border-top-right-radius:3px!important}.rounded-lg-top-2{border-top-left-radius:6px!important;border-top-right-radius:6px!important}.rounded-lg-right-0{border-top-right-radius:0!important;border-bottom-right-radius:0!important}.rounded-lg-right-1{border-top-right-radius:3px!important;border-bottom-right-radius:3px!important}.rounded-lg-right-2{border-top-right-radius:6px!important;border-bottom-right-radius:6px!important}.rounded-lg-bottom-0{border-bottom-right-radius:0!important;border-bottom-left-radius:0!important}.rounded-lg-bottom-1{border-bottom-right-radius:3px!important;border-bottom-left-radius:3px!important}.rounded-lg-bottom-2{border-bottom-right-radius:6px!important;border-bottom-left-radius:6px!important}.rounded-lg-left-0{border-bottom-left-radius:0!important;border-top-left-radius:0!important}.rounded-lg-left-1{border-bottom-left-radius:3px!important;border-top-left-radius:3px!important}.rounded-lg-left-2{border-bottom-left-radius:6px!important;border-top-left-radius:6px!important}}@media (min-width:1280px){.border-xl-top{border-top:1px #e1e4e8 solid!important}.border-xl-right{border-right:1px #e1e4e8 solid!important}.border-xl-bottom{border-bottom:1px #e1e4e8 solid!important}.border-xl-left{border-left:1px #e1e4e8 solid!important}.border-xl-top-0{border-top:0!important}.border-xl-right-0{border-right:0!important}.border-xl-bottom-0{border-bottom:0!important}.border-xl-left-0{border-left:0!important}.rounded-xl-0{border-radius:0!important}.rounded-xl-1{border-radius:3px!important}.rounded-xl-2{border-radius:6px!important}.rounded-xl-top-0{border-top-left-radius:0!important;border-top-right-radius:0!important}.rounded-xl-top-1{border-top-left-radius:3px!important;border-top-right-radius:3px!important}.rounded-xl-top-2{border-top-left-radius:6px!important;border-top-right-radius:6px!important}.rounded-xl-right-0{border-top-right-radius:0!important;border-bottom-right-radius:0!important}.rounded-xl-right-1{border-top-right-radius:3px!important;border-bottom-right-radius:3px!important}.rounded-xl-right-2{border-top-right-radius:6px!important;border-bottom-right-radius:6px!important}.rounded-xl-bottom-0{border-bottom-right-radius:0!important;border-bottom-left-radius:0!important}.rounded-xl-bottom-1{border-bottom-right-radius:3px!important;border-bottom-left-radius:3px!important}.rounded-xl-bottom-2{border-bottom-right-radius:6px!important;border-bottom-left-radius:6px!important}.rounded-xl-left-0{border-bottom-left-radius:0!important;border-top-left-radius:0!important}.rounded-xl-left-1{border-bottom-left-radius:3px!important;border-top-left-radius:3px!important}.rounded-xl-left-2{border-bottom-left-radius:6px!important;border-top-left-radius:6px!important}}.circle{border-radius:50%!important}.box-shadow{box-shadow:0 1px 1px rgba(27,31,35,.1)!important}.box-shadow-medium{box-shadow:0 1px 5px rgba(27,31,35,.15)!important}.box-shadow-large{box-shadow:0 1px 15px rgba(27,31,35,.15)!important}.box-shadow-extra-large{box-shadow:0 10px 50px rgba(27,31,35,.07)!important}.box-shadow-none{box-shadow:none!important}.bg-white{background-color:#fff!important}.bg-blue{background-color:#0366d6!important}.bg-blue-light{background-color:#f1f8ff!important}.bg-gray-dark{background-color:#24292e!important}.bg-gray{background-color:#f6f8fa!important}.bg-gray-light{background-color:#fafbfc!important}.bg-green{background-color:#28a745!important}.bg-green-light{background-color:#dcffe4!important}.bg-red{background-color:#d73a49!important}.bg-red-light{background-color:#ffdce0!important}.bg-yellow{background-color:#ffd33d!important}.bg-yellow-light{background-color:#fff5b1!important}.bg-purple{background-color:#6f42c1!important}.bg-purple-light{background-color:#f5f0ff!important}.bg-shade-gradient{background-image:linear-gradient(180deg,rgba(27,31,35,.065),rgba(27,31,35,0))!important;background-repeat:no-repeat!important;background-size:100% 200px!important}.text-blue{color:#0366d6!important}.text-red{color:#cb2431!important}.text-gray-light{color:#6a737d!important}.text-gray{color:#586069!important}.text-gray-dark{color:#24292e!important}.text-green{color:#28a745!important}.text-orange{color:#a04100!important}.text-orange-light{color:#e36209!important}.text-purple{color:#6f42c1!important}.text-white{color:#fff!important}.text-inherit{color:inherit!important}.text-pending{color:#b08800!important}.bg-pending{color:#dbab09!important}.link-gray{color:#586069!important}.link-gray:hover{color:#0366d6!important}.link-gray-dark{color:#24292e!important}.link-gray-dark:hover{color:#0366d6!important}.link-hover-blue:hover{color:#0366d6!important}.muted-link{color:#586069!important}.muted-link:hover{color:#0366d6!important;text-decoration:none}.details-overlay[open]>summary::before{position:fixed;top:0;right:0;bottom:0;left:0;z-index:80;display:block;cursor:default;content:" ";background:0 0}.details-overlay-dark[open]>summary::before{z-index:99;background:rgba(27,31,35,.5)}.flex-row{flex-direction:row!important}.flex-row-reverse{flex-direction:row-reverse!important}.flex-column{flex-direction:column!important}.flex-wrap{flex-wrap:wrap!important}.flex-nowrap{flex-wrap:nowrap!important}.flex-justify-start{justify-content:flex-start!important}.flex-justify-end{justify-content:flex-end!important}.flex-justify-center{justify-content:center!important}.flex-justify-between{justify-content:space-between!important}.flex-justify-around{justify-content:space-around!important}.flex-items-start{align-items:flex-start!important}.flex-items-end{align-items:flex-end!important}.flex-items-center{align-items:center!important}.flex-items-baseline{align-items:baseline!important}.flex-items-stretch{align-items:stretch!important}.flex-content-start{align-content:flex-start!important}.flex-content-end{align-content:flex-end!important}.flex-content-center{align-content:center!important}.flex-content-between{align-content:space-between!important}.flex-content-around{align-content:space-around!important}.flex-content-stretch{align-content:stretch!important}.flex-auto{flex:1 1 auto!important}.flex-shrink-0{flex-shrink:0!important}.flex-self-auto{align-self:auto!important}.flex-self-start{align-self:flex-start!important}.flex-self-end{align-self:flex-end!important}.flex-self-center{align-self:center!important}.flex-self-baseline{align-self:baseline!important}.flex-self-stretch{align-self:stretch!important}.flex-item-equal{flex-grow:1;flex-basis:0}.position-static{position:static!important}.position-relative{position:relative!important}.position-absolute{position:absolute!important}.position-fixed{position:fixed!important}.top-0{top:0!important}.right-0{right:0!important}.bottom-0{bottom:0!important}.left-0{left:0!important}.v-align-middle{vertical-align:middle!important}.v-align-top{vertical-align:top!important}.v-align-bottom{vertical-align:bottom!important}.v-align-text-top{vertical-align:text-top!important}.v-align-text-bottom{vertical-align:text-bottom!important}.v-align-baseline{vertical-align:baseline!important}.overflow-hidden{overflow:hidden!important}.overflow-scroll{overflow:scroll!important}.overflow-auto{overflow:auto!important}.clearfix::before{display:table;content:""}.clearfix::after{display:table;clear:both;content:""}.float-left{float:left!important}.float-right{float:right!important}.float-none{float:none!important}.width-fit{max-width:100%!important}.width-full{width:100%!important}.height-fit{max-height:100%!important}.height-full{height:100%!important}.min-width-0{min-width:0!important}.m-0{margin:0!important}.mt-0{margin-top:0!important}.mr-0{margin-right:0!important}.mb-0{margin-bottom:0!important}.ml-0{margin-left:0!important}.mx-0{margin-right:0!important;margin-left:0!important}.my-0{margin-top:0!important;margin-bottom:0!important}.m-1{margin:4px!important}.mt-1{margin-top:4px!important}.mr-1{margin-right:4px!important}.mb-1{margin-bottom:4px!important}.ml-1{margin-left:4px!important}.mx-1{margin-right:4px!important;margin-left:4px!important}.my-1{margin-top:4px!important;margin-bottom:4px!important}.m-2{margin:8px!important}.mt-2{margin-top:8px!important}.mr-2{margin-right:8px!important}.mb-2{margin-bottom:8px!important}.ml-2{margin-left:8px!important}.mx-2{margin-right:8px!important;margin-left:8px!important}.my-2{margin-top:8px!important;margin-bottom:8px!important}.m-3{margin:16px!important}.mt-3{margin-top:16px!important}.mr-3{margin-right:16px!important}.mb-3{margin-bottom:16px!important}.ml-3{margin-left:16px!important}.mx-3{margin-right:16px!important;margin-left:16px!important}.my-3{margin-top:16px!important;margin-bottom:16px!important}.m-4{margin:24px!important}.mt-4{margin-top:24px!important}.mr-4{margin-right:24px!important}.mb-4{margin-bottom:24px!important}.ml-4{margin-left:24px!important}.mx-4{margin-right:24px!important;margin-left:24px!important}.my-4{margin-top:24px!important;margin-bottom:24px!important}.m-5{margin:32px!important}.mt-5{margin-top:32px!important}.mr-5{margin-right:32px!important}.mb-5{margin-bottom:32px!important}.ml-5{margin-left:32px!important}.mx-5{margin-right:32px!important;margin-left:32px!important}.my-5{margin-top:32px!important;margin-bottom:32px!important}.m-6{margin:40px!important}.mt-6{margin-top:40px!important}.mr-6{margin-right:40px!important}.mb-6{margin-bottom:40px!important}.ml-6{margin-left:40px!important}.mx-6{margin-right:40px!important;margin-left:40px!important}.my-6{margin-top:40px!important;margin-bottom:40px!important}.mx-auto{margin-right:auto!important;margin-left:auto!important}.ml-n1{margin-left:-4px!important}.p-0{padding:0!important}.pt-0{padding-top:0!important}.pr-0{padding-right:0!important}.pb-0{padding-bottom:0!important}.pl-0{padding-left:0!important}.px-0{padding-right:0!important;padding-left:0!important}.py-0{padding-top:0!important;padding-bottom:0!important}.p-1{padding:4px!important}.pt-1{padding-top:4px!important}.pr-1{padding-right:4px!important}.pb-1{padding-bottom:4px!important}.pl-1{padding-left:4px!important}.px-1{padding-right:4px!important;padding-left:4px!important}.py-1{padding-top:4px!important;padding-bottom:4px!important}.p-2{padding:8px!important}.pt-2{padding-top:8px!important}.pr-2{padding-right:8px!important}.pb-2{padding-bottom:8px!important}.pl-2{padding-left:8px!important}.px-2{padding-right:8px!important;padding-left:8px!important}.py-2{padding-top:8px!important;padding-bottom:8px!important}.p-3{padding:16px!important}.pt-3{padding-top:16px!important}.pr-3{padding-right:16px!important}.pb-3{padding-bottom:16px!important}.pl-3{padding-left:16px!important}.px-3{padding-right:16px!important;padding-left:16px!important}.py-3{padding-top:16px!important;padding-bottom:16px!important}.p-4{padding:24px!important}.pt-4{padding-top:24px!important}.pr-4{padding-right:24px!important}.pb-4{padding-bottom:24px!important}.pl-4{padding-left:24px!important}.px-4{padding-right:24px!important;padding-left:24px!important}.py-4{padding-top:24px!important;padding-bottom:24px!important}.p-5{padding:32px!important}.pt-5{padding-top:32px!important}.pr-5{padding-right:32px!important}.pb-5{padding-bottom:32px!important}.pl-5{padding-left:32px!important}.px-5{padding-right:32px!important;padding-left:32px!important}.py-5{padding-top:32px!important;padding-bottom:32px!important}.p-6{padding:40px!important}.pt-6{padding-top:40px!important}.pr-6{padding-right:40px!important}.pb-6{padding-bottom:40px!important}.pl-6{padding-left:40px!important}.px-6{padding-right:40px!important;padding-left:40px!important}.py-6{padding-top:40px!important;padding-bottom:40px!important}.p-responsive{padding-right:16px!important;padding-left:16px!important}@media (min-width:544px){.p-responsive{padding-right:40px!important;padding-left:40px!important}}@media (min-width:1012px){.p-responsive{padding-right:16px!important;padding-left:16px!important}}.h1{font-size:26px!important}@media (min-width:768px){.h1{font-size:32px!important}}.h2{font-size:22px!important}@media (min-width:768px){.h2{font-size:24px!important}}.h3{font-size:18px!important}@media (min-width:768px){.h3{font-size:20px!important}}.h4{font-size:16px!important}.h5{font-size:14px!important}.h6{font-size:12px!important}.h1,.h2,.h3,.h4,.h5,.h6{font-weight:600!important}.f1{font-size:26px!important}@media (min-width:768px){.f1{font-size:32px!important}}.f2{font-size:22px!important}@media (min-width:768px){.f2{font-size:24px!important}}.f3{font-size:18px!important}@media (min-width:768px){.f3{font-size:20px!important}}.f4{font-size:16px!important}@media (min-width:768px){.f4{font-size:16px!important}}.f5{font-size:14px!important}.f6{font-size:12px!important}.text-small{font-size:12px!important}.lead{margin-bottom:30px;font-size:20px;font-weight:300;color:#586069}.lh-condensed-ultra{line-height:1!important}.lh-condensed{line-height:1.25!important}.lh-default{line-height:1.5!important}.lh-0{line-height:0!important}.text-right{text-align:right!important}.text-left{text-align:left!important}.text-center{text-align:center!important}.text-normal{font-weight:400!important}.text-bold{font-weight:600!important}.text-italic{font-style:italic!important}.text-uppercase{text-transform:uppercase!important}.text-underline{text-decoration:underline!important}.no-underline{text-decoration:none!important}.no-wrap{white-space:nowrap!important}.ws-normal{white-space:normal!important}.wb-break-all{word-break:break-all!important}.text-emphasized{font-weight:600;color:#24292e}.list-style-none{list-style:none!important}.d-block{display:block!important}.d-flex{display:flex!important}.d-inline{display:inline!important}.d-inline-block{display:inline-block!important}.d-inline-flex{display:inline-flex!important}.d-none{display:none!important}.d-table{display:table!important}.d-table-cell{display:table-cell!important}.v-hidden{visibility:hidden!important}.v-visible{visibility:visible!important}.table-fixed{table-layout:fixed!important}.sr-only{position:absolute;width:1px;height:1px;padding:0;overflow:hidden;clip:rect(0,0,0,0);word-wrap:normal;border:0}.container{width:980px;margin-right:auto;margin-left:auto}.container::before{display:table;content:""}.container::after{display:table;clear:both;content:""}.container-md{max-width:768px;margin-right:auto;margin-left:auto}.container-lg{max-width:1012px;margin-right:auto;margin-left:auto}.container-xl{max-width:1280px;margin-right:auto;margin-left:auto}.markdown-body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";font-size:16px;line-height:1.5;word-wrap:break-word}.markdown-body::before{display:table;content:""}.markdown-body::after{display:table;clear:both;content:""}.markdown-body>* :first-child{margin-top:0!important}.markdown-body>* :last-child{margin-bottom:0!important}.markdown-body a:not([href]){color:inherit;text-decoration:none}.markdown-body .absent{color:#cb2431}.markdown-body blockquote,.markdown-body dl,.markdown-body ol,.markdown-body p,.markdown-body pre,.markdown-body table,.markdown-body ul{margin-top:0;margin-bottom:16px}.markdown-body hr{height:.25em;padding:0;margin:24px 0;background-color:#e1e4e8;border:0}.markdown-body blockquote{padding:0 1em;color:#6a737d;border-left:.25em solid #dfe2e5}.markdown-body h1,.markdown-body h2,.markdown-body h3,.markdown-body h4,.markdown-body h5,.markdown-body h6{margin-top:24px;margin-bottom:16px;font-weight:600;line-height:1.25}.markdown-body h1{padding-bottom:.3em;font-size:2em;border-bottom:1px solid #eaecef}.markdown-body h2{padding-bottom:.3em;font-size:1.5em;border-bottom:1px solid #eaecef}.markdown-body h6{font-size:.85em;color:#6a737d}.markdown-body table{display:block;width:100%;overflow:auto}.markdown-body table th{font-weight:600}.markdown-body table td,.markdown-body table th{padding:6px 13px;border:1px solid #dfe2e5}.markdown-body table tr{background-color:#fff;border-top:1px solid #c6cbd1}.markdown-body table tr:nth-child(2n){background-color:#f6f8fa}.markdown-body img{max-width:100%;box-sizing:content-box;background-color:#fff}.markdown-body code,.markdown-body tt{padding:.2em .4em;margin:0;font-size:85%;background-color:rgba(27,31,35,.05);border-radius:3px}.markdown-body .highlight pre,.markdown-body pre{padding:16px;overflow:auto;font-size:85%;line-height:1.45;background-color:#f6f8fa;border-radius:3px}

/* =====================================================
   DARK MODE — respects prefers-color-scheme: dark
   ===================================================== */
@media (prefers-color-scheme: dark) {
  /* Base */
  body {
    color: #e6edf3 !important;
    background-color: #0d1117 !important;
  }
  a {
    color: #58a6ff !important;
  }
  a:hover {
    color: #79b8ff !important;
  }

  /* Utility overrides used in the template */
  .bg-white {
    background-color: #0d1117 !important;
  }
  .bg-yellow-light {
    background-color: #272115 !important;
    color: #e6c87a !important;
  }
  .bg-yellow-light strong {
    color: #f0d080 !important;
  }
  .bg-yellow-light a {
    color: #79b8ff !important;
  }
  .text-gray {
    color: #8b949e !important;
  }
  .text-gray-dark {
    color: #c9d1d9 !important;
  }
  .text-emphasized {
    color: #e6edf3 !important;
  }
  .lead {
    color: #8b949e !important;
  }

  /* HR / rules */
  .rule, hr {
    border-bottom-color: #30363d !important;
  }

  /* Borders */
  .border        { border-color: #30363d !important; }
  .border-top    { border-top-color: #30363d !important; }
  .border-bottom { border-bottom-color: #30363d !important; }
  .border-left   { border-left-color: #30363d !important; }
  .border-right  { border-right-color: #30363d !important; }

  /* Markdown body */
  .markdown-body {
    color: #e6edf3;
  }
  .markdown-body hr {
    background-color: #30363d;
  }
  .markdown-body h1,
  .markdown-body h2 {
    border-bottom-color: #30363d;
  }
  .markdown-body h6 {
    color: #8b949e;
  }
  .markdown-body blockquote {
    color: #8b949e;
    border-left-color: #30363d;
  }
  .markdown-body table td,
  .markdown-body table th {
    border-color: #30363d;
  }
  .markdown-body table tr {
    background-color: #0d1117;
    border-top-color: #30363d;
  }
  .markdown-body table tr:nth-child(2n) {
    background-color: #161b22;
  }
  .markdown-body img {
    background-color: transparent;
  }
  .markdown-body code,
  .markdown-body tt {
    background-color: rgba(240,246,252,0.1);
  }
  .markdown-body .highlight pre,
  .markdown-body pre {
    background-color: #161b22;
  }
  .markdown-body .absent {
    color: #f85149;
  }

  /* Box shadows — tone down on dark bg */
  .box-shadow             { box-shadow: 0 1px 1px rgba(0,0,0,.4) !important; }
  .box-shadow-medium      { box-shadow: 0 1px 5px rgba(0,0,0,.5) !important; }
  .box-shadow-large       { box-shadow: 0 1px 15px rgba(0,0,0,.5) !important; }
  .box-shadow-extra-large { box-shadow: 0 10px 50px rgba(0,0,0,.3) !important; }
}</style>
      </head>
      <body class="bg-white">
        <nav class="container-md px-3 py-2 mt-2 mt-md-5 mb-5 markdown-body">
          <p class="bg-yellow-light ml-n1 px-1 py-1 mb-1">
            <strong>This is a web feed,</strong> also known as an RSS feed. <strong>Subscribe</strong> by copying the URL from the address bar into your newsreader.
          </p>
          <p class="text-gray">
            Visit <a href="https://aboutfeeds.com">About Feeds</a> to get started with newsreaders and subscribing. It’s free.
          </p>
        </nav>
        <div class="container-md px-3 py-3 markdown-body">
          <header class="py-5">
            <h1 class="border-0">
              <!-- https://commons.wikimedia.org/wiki/File:Feed-icon.svg -->
              <svg xmlns="http://www.w3.org/2000/svg" version="1.1" style="vertical-align: text-bottom; width: 1.2em; height: 1.2em;" class="pr-1" id="RSSicon" viewBox="0 0 256 256">
                <defs>
                  <linearGradient x1="0.085" y1="0.085" x2="0.915" y2="0.915" id="RSSg">
                    <stop  offset="0.0" stop-color="#E3702D"/><stop  offset="0.1071" stop-color="#EA7D31"/>
                    <stop  offset="0.3503" stop-color="#F69537"/><stop  offset="0.5" stop-color="#FB9E3A"/>
                    <stop  offset="0.7016" stop-color="#EA7C31"/><stop  offset="0.8866" stop-color="#DE642B"/>
                    <stop  offset="1.0" stop-color="#D95B29"/>
                  </linearGradient>
                </defs>
                <rect width="256" height="256" rx="55" ry="55" x="0"  y="0"  fill="#CC5D15"/>
                <rect width="246" height="246" rx="50" ry="50" x="5"  y="5"  fill="#F49C52"/>
                <rect width="236" height="236" rx="47" ry="47" x="10" y="10" fill="url(#RSSg)"/>
                <circle cx="68" cy="189" r="24" fill="#FFF"/>
                <path d="M160 213h-34a82 82 0 0 0 -82 -82v-34a116 116 0 0 1 116 116z" fill="#FFF"/>
                <path d="M184 213A140 140 0 0 0 44 73 V 38a175 175 0 0 1 175 175z" fill="#FFF"/>
              </svg>

              Web Feed Preview
            </h1>
            <h2><xsl:value-of select="/rss/channel/title"/></h2>
            <p><xsl:value-of select="/rss/channel/description"/></p>
            <a class="head_link" target="_blank">
              <xsl:attribute name="href">
                <xsl:value-of select="/rss/channel/link"/>
              </xsl:attribute>
              Visit Website &#x2192;
            </a>
          </header>
          <h2>Recent Items</h2>
          <xsl:for-each select="/rss/channel/item">
            <div class="pb-5">
              <h3 class="mb-0">
                <a target="_blank">
                  <xsl:attribute name="href">
                    <xsl:value-of select="link"/>
                  </xsl:attribute>
                  <xsl:value-of select="title"/>
                </a>
              </h3>
              <small class="text-gray">
                Published: <xsl:value-of select="pubDate" />
              </small>
            </div>
          </xsl:for-each>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
