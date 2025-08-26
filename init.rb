# plugins/redmine_simple_lightbox/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Click images in wiki/issues to open a simple lightbox modal. Thumbnails too.'
  version     '1.0.7'
  requires_redmine version_or_higher: '6.0.0'
end

module RedmineSimpleLightbox
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      <<~HTML.html_safe
        <style>
          .rm-lightbox-overlay{position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.75);z-index:9999;padding:2rem;}
          .rm-lightbox-overlay.is-open{display:flex;}
          .rm-lightbox-image{max-width:95vw;max-height:90vh;box-shadow:0 10px 30px rgba(0,0,0,.5);border-radius:8px;}
          .rm-lightbox-close{position:absolute;top:12px;right:16px;font-size:32px;line-height:1;color:#fff;cursor:pointer;user-select:none;}
          /* 本文内の画像は枠にフィット（ファイル名リンクのアイコン等には影響しない） */
          #content .wiki img,
          #content .wiki-content img,
          #content .journal .wiki img,
          #content .issue .wiki img,
          #content .news .wiki img,
          #content .preview .wiki img{
            max-width:100% !important; height:auto !important;
          }
        </style>
        <script>
          document.addEventListener('DOMContentLoaded', function(){
            // -------- Lightbox 本体 --------
            var overlay=document.createElement('div');
            overlay.className='rm-lightbox-overlay';
            overlay.innerHTML='<span class="rm-lightbox-close" aria-label="Close">×</span><img class="rm-lightbox-image" alt="">';
            document.body.appendChild(overlay);
            var closeBtn=overlay.querySelector('.rm-lightbox-close');
            var imgEl=overlay.querySelector('.rm-lightbox-image');

            function openLightbox(src, alt){
              imgEl.removeAttribute('src'); // ちらつき防止
              imgEl.setAttribute('alt', alt || '');
              overlay.classList.add('is-open');
              imgEl.setAttribute('src', src);
            }
            function closeLightbox(){ overlay.classList.remove('is-open'); }
            overlay.addEventListener('click', function(e){
              if(e.target===overlay || e.target===closeBtn){ closeLightbox(); }
            });
            document.addEventListener('keydown', function(e){
              if(e.key==='Escape'){ closeLightbox(); }
            });

            // -------- URL 変換ユーティリティ --------
            // inline画像やサムネイルから、原寸URLに変換
            function fullSrcFrom(href){
              if(!href) return href;
              try{
                var u=new URL(href, window.location.origin);
                var p=u.pathname;

                // サムネイルURL -> 原寸（download 優先、なければ attachments）
                // /attachments/thumbnail/:id/:size  -> /attachments/download/:id
                var m=p.match(/^\\/attachments\\/thumbnail\\/(\\d+)\\//);
                if(m){ return '/attachments/download/'+m[1]; }

                // すでに /attachments/download/:id ならそのまま
                if(/^\\/attachments\\/download\\/(\\d+)/.test(p)){ return u.pathname+u.search; }

                // /attachments/:id(/filename) もそのまま原寸表示される
                if(/^\\/attachments\\/(\\d+)/.test(p)){ return u.pathname+u.search; }

                // 通常の画像ソース (/attachments/…) 以外はそのまま返す
                return href;
              }catch(_e){
                return href;
              }
            }

            // -------- 1) 本文中の画像（wiki/issue/news等） --------
            var inlineImgs = document.querySelectorAll([
              '#content .wiki img',
              '#content .wiki-content img',
              '#content .journal .wiki img',
              '#content .issue .wiki img',
              '#content .news .wiki img',
              '#content .preview .wiki img'
            ].join(','));

            inlineImgs.forEach(function(img){
              // a[href] で囲まれていれば href を原寸候補に
              var a = img.closest('a[href]');
              var base = (a ? a.getAttribute('href') : img.getAttribute('src')) || '';
              var src  = fullSrcFrom(base);

              img.style.cursor='zoom-in';
              img.addEventListener('click', function(ev){
                ev.preventDefault(); // 本文中は必ずモーダル
                openLightbox(src, img.getAttribute('alt'));
              });
            });

            // -------- 2) 添付ファイルのサムネイル（画像だけモーダル） --------
            // ファイル一覧のテキストリンク（a.icon-attachment）は除外して通常遷移にする
            var thumbs = document.querySelectorAll('div.attachments .thumbnails a[href] > img');

            thumbs.forEach(function(img){
              var a = img.parentElement; // サムネイルの <a>
              var href = a.getAttribute('href') || '';
              var src  = fullSrcFrom(href);

              img.style.cursor='zoom-in';
              a.addEventListener('click', function(ev){
                // モーダルで拡大（テキストリンクはこのハンドラが付かないので通常遷移）
                ev.preventDefault();
                openLightbox(src, img.getAttribute('alt'));
              });
            });

            // 念のため：添付ファイル名のテキストリンクは何もしない（通常の /attachments/ 遷移）
            // ここにはハンドラを付けないことで干渉ゼロにしています。
          });
        </script>
      HTML
    end
  end
end
