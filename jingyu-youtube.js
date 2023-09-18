// ==UserScript==
// @name                Youtube jingyu
// @name:zh             Youtube jingyu
// @namespace           Anong0u0
// @version             0.6.8
// @description         shorts is a shit, fuck you youtube
// @description:zh      短片就是坨屎，去你的youtube
// @author              Anong0u0
// @match               *://*.youtube.com/*
// @icon                https://www.google.com/s2/favicons?sz=64&domain=youtube.com
// @grant               GM_setValue
// @grant               GM_getValue
// @grant               GM_registerMenuCommand
// @grant               GM_unregisterMenuCommand
// @run-at              document-start
// @license             MIT
// ==/UserScript==

console.log("[Anti Shorts] load start");

const defaultConfig = '';
const userConfig = GM_getValue("filters", defaultConfig);
GM_registerMenuCommand("配置", () => {
  const newConfig = prompt("输入过滤列表:", JSON.stringify(userConfig));
  if (newConfig) {
    GM_setValue("filters", JSON.parse(newConfig));
  }
});

let Hide_Shorts_Renderer = GM_getValue("Hide_Shorts_Renderer", true);
let Hide_Shorts_Game = GM_getValue("Hide_Shorts_Game", true);
let Hide_Shorts_Video = GM_getValue("Hide_Shorts_Video", true);
let Redirect_Shorts_URL = GM_getValue("Redirect_Shorts_URL", true);

Node.prototype.getParentElement = function(times = 0){let e=this;for(let i=0;i<times;i++)e=e.parentElement;return e;}
NodeList.prototype.filter = Array.prototype.filter
NodeList.prototype.slice = Array.prototype.slice

const delay = (ms = 0) => {return new Promise((r)=>{setTimeout(r, ms)})}

const waitElementLoad = (elementSelector, isSelectAll, tryTimes = 1, interval = 0) =>
{
    return new Promise(async (resolve, reject)=>
    {
        let t = 1, result;
        while(true)
        {
            if(isSelectAll) {if((result = document.querySelectorAll(elementSelector)).length > 0) break;}
            else {if(result = document.querySelector(elementSelector)) break;}

            if(tryTimes>0 && ++t>tryTimes) {return reject(new Error("Wait Timeout"))}
            await delay(interval);
        }
        resolve(result);
    })
}

const fillRow = () =>
{
    if(window.location.pathname!="/feed/subscriptions") return;
    console.log("[Anti Shorts] fill row count")
    let row = document.querySelector("ytd-browse[page-subtype='subscriptions'] ytd-rich-grid-renderer > div#contents.ytd-rich-grid-renderer > ytd-rich-grid-row")
    const rowCount = getComputedStyle(row).getPropertyValue("--ytd-rich-grid-items-per-row")
    while(row.nextElementSibling?.tagName=="YTD-RICH-GRID-ROW")
    {
        const showedItem = row.querySelectorAll("ytd-rich-item-renderer").filter((e)=>getComputedStyle(e).display!="none")
        let need = rowCount-showedItem.length
        let nextRow = row
        while(need>0 && nextRow.nextElementSibling!=null)
        {
            nextRow = nextRow.nextElementSibling
            const rowContent = row.querySelector("div#contents.ytd-rich-grid-row")
            for (const e of nextRow.querySelectorAll("ytd-rich-item-renderer"))
            {
                if (need == 0) break;
                if (getComputedStyle(e).display != "none")
                {
                    rowContent.appendChild(e);
                    need--;
                }
            }
        }
        row = row.nextElementSibling
    }
}

const unfillRow = () =>
{
    if(window.location.pathname!="/feed/subscriptions") return;
    console.log("[Anti Shorts] unfill row count")
    let row = document.querySelector("ytd-browse[page-subtype='subscriptions'] ytd-rich-grid-renderer > div#contents.ytd-rich-grid-renderer > ytd-rich-grid-row")
    const rowCount = getComputedStyle(row).getPropertyValue("--ytd-rich-grid-items-per-row")
    while(row.nextElementSibling?.tagName=="YTD-RICH-GRID-ROW")
    {
        const rowContent = row.nextElementSibling.querySelector("div#contents.ytd-rich-grid-row")
        row.querySelectorAll("ytd-rich-item-renderer").slice(rowCount).forEach((e)=>
        {
            rowContent.appendChild(e)
        })
        row = row.nextElementSibling
    }
}

const debounce = ()=>
{
    clearTimeout(lockID)
    lockID = setTimeout(() => {fillRow()}, 50);
}

if((()=>{try{document.querySelector(":has(body)");return false;}catch{return true;}})())
{
    alert(`[Anti Shorts] Warning:
Your browser Does Not Support CSS4 selector (:has).
Please update or change your browser.
For Firefox users, please to go to "about:config" and enable "layout.css.has-selector.enabled" setting.`)
}

let menuID = [], oldHref = null, lockID = null;

const css =
{
    hideRenderer: document.createElement("style"),
    hideGame: document.createElement("style"),
    hideVideo: document.createElement("style"),
}
css.hideRenderer.innerHTML = `
ytd-reel-shelf-renderer.style-scope.ytd-item-section-renderer,
ytd-mini-guide-entry-renderer[aria-label='Shorts'],
ytd-rich-shelf-renderer[is-shorts],
a.yt-simple-endpoint.style-scope.ytd-guide-entry-renderer[title='Shorts']
{display:none !important}`;


const titlesToHide = ["植物", "僵", "殭", "Zombie", "zombie", "ZOMBIE", "PVZ", "pvz", "Pvz", "PvZ", "pVz", "\u3000-\u9FFF", "\uAC00-\uD7AF"];
let cssRules = "yt-chip-cloud-chip-renderer.style-scope.ytd-feed-filter-chip-bar-renderer,";
titlesToHide.forEach(title => {
  // 首页
  cssRules += `
    ytd-rich-item-renderer:has(a.yt-simple-endpoint.focus-on-expand.style-scope.ytd-rich-grid-media[title*="${title}"]),
  `;
  // 媒体库
  cssRules += `
    ytd-grid-video-renderer:has(a[title*="${title}"]),
  `;
  // 历史记录
  cssRules += `
    .style-scope ytd-video-renderer:has(yt-formatted-string[aria-label*="${title}"]),
  `;
  // 视频页右侧
  cssRules += `
    ytd-compact-video-renderer:has(span[title*="${title}"]),
  `;
  // 视频结尾推荐
  cssRules += `
    a[aria-label*="${title}"],
  `;
});
cssRules = cssRules.slice(0, -4);
cssRules += `{display:none !important}`;
css.hideGame.innerHTML = cssRules;

css.hideVideo.innerHTML = `
[is-short],
[is-shorts-grid] ytd-continuation-item-renderer,
ytd-video-renderer:has(a[href^='/shorts']),
ytd-browse[page-subtype='subscriptions'] ytd-rich-item-renderer:has(a[href^='/shorts']),
ytd-grid-video-renderer:has(a[href^='/shorts']),
ytd-compact-video-renderer:has(a[href^='/shorts']),
ytd-search ytd-shelf-renderer:has(a[href^='/shorts']),
ytd-browse ytd-item-section-renderer:has(yt-img-shadow#avatar):has(div#title-text):has(ytd-video-renderer):has(a[href^='/shorts'])
{display:none !important}`;
// ":has" selector is simple and "efficient", Use it instead of javascript DOM manipulation

const onPageUpdate = () =>
{
    console.log("[Anti Shorts] page updated");
    if (oldHref != window.location.href)
    {
        oldHref = window.location.href;
        toggle.redirect();
    }
}

const toggle =
{
    renderer: ()=>
    {
        if(Hide_Shorts_Renderer) document.documentElement.append(css.hideRenderer);
        else css.hideRenderer.remove();
    },

    game: ()=>
    {
        if(Hide_Shorts_Game) {
            document.documentElement.append(css.hideGame);
        } else {
            css.hideGame.remove();
        }
    },

    video: async ()=>
    {
        if(Hide_Shorts_Video)
        {
            document.addEventListener("yt-rendererstamper-finished", debounce)
            document.documentElement.append(css.hideVideo);
            fillRow();
        }
        else
        {
            document.removeEventListener("yt-rendererstamper-finished", debounce)
            css.hideVideo.remove();
            unfillRow()
        }
    },

    redirect: ()=>
    {
        if(Redirect_Shorts_URL)
        {
            if(window.location.pathname.indexOf("/shorts/")!=-1)
            {console.log("[Anti Shorts] redirected");window.location.replace(window.location.href.replace("/shorts/","/watch?v="));}
        }
    }
}

const setMenu = ()=>
{
    menuID.forEach((e)=>{GM_unregisterMenuCommand(e)})
    menuID = [];
    menuID.push(GM_registerMenuCommand(`${Hide_Shorts_Renderer?"Dis":"En"}able "Hide Shorts Renderer"`, ()=>
    {
        Hide_Shorts_Renderer = !Hide_Shorts_Renderer;
        GM_setValue("Hide_Shorts_Renderer", Hide_Shorts_Renderer);
        toggle.renderer();
        setMenu();
    }))
    menuID.push(GM_registerMenuCommand(`${Hide_Shorts_Game?"Dis":"En"}able "Hide Shorts Game"`, ()=>
    {
        Hide_Shorts_Game = !Hide_Shorts_Game;
        GM_setValue("Hide_Shorts_Game", Hide_Shorts_Game);
        toggle.renderer();
        setMenu();
    }))
    menuID.push(GM_registerMenuCommand(`${Hide_Shorts_Video?"Dis":"En"}able "Hide Shorts Video"`, ()=>
    {
        Hide_Shorts_Video = !Hide_Shorts_Video;
        GM_setValue("Hide_Shorts_Video", Hide_Shorts_Video);
        toggle.video();
        setMenu();
    }))
    menuID.push(GM_registerMenuCommand(`${Redirect_Shorts_URL?"Dis":"En"}able "Redirect Shorts URL"`, ()=>
    {
        Redirect_Shorts_URL = !Redirect_Shorts_URL;
        GM_setValue("Redirect_Shorts_URL", Redirect_Shorts_URL);
        toggle.redirect();
        setMenu();
    }))
}

console.log("[Anti Shorts] try to call function");

toggle.redirect();
toggle.game();
toggle.renderer();
toggle.video();
setMenu();


document.addEventListener("yt-page-data-fetched", onPageUpdate)
document.addEventListener("yt-navigate-finish", onPageUpdate);
waitElementLoad("yt-page-navigation-progress",false,40,250)
    .then((e)=>{new MutationObserver(onPageUpdate).observe(e, {attributes: true});})

console.log("[Anti Shorts] loaded");
