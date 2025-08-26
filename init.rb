# plugins/redmine_simple_lightbox/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Lightbox for inline images and attachment thumbnails. Text links keep normal navigation.'
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
          /* 本文内画像は本文幅にフィット（テキストリンクのアイコン等には影響しない） */
          #content .wiki img,
          #content .wiki-content img,
          #content .journal .wiki img,
          #content .issue .wiki img,
          #content .news .wiki img,
          #content .preview .wiki img{
            max-width:600px !important; height:auto !important;
          }
        </style>
        <script>
          document.addEventListener('DOMContentLoaded', function(){
            // ===== Lightbox本体 =====
            var overlay=document.createElement('div');
            overlay.className='rm-lightbox-overlay';
            overlay.innerHTML='<span class="rm-lightbox-close" aria-label="Close">×</span><img class="rm-lightbox-image" alt="">';
            document.body.appendChild(overlay);
            var closeBtn=overlay.querySelector('.rm-lightbox-close');
            var imgEl=overlay.querySelector('.rm-lightbox-image');
            function openLightbox(src, alt){
              imgEl.removeAttribute('src');
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

            // ===== URL 変換（サムネ -> 原寸） =====
            function fullSrcFrom(href){
              if(!href) return href;
              try{
                var u=new URL(href, window.location.origin);
                var p=u.pathname;

                // /attachments/thumbnail/:id/:size -> /attachments/download/:id
                var m=p.match(/^\\/attachments\\/thumbnail\\/(\\d+)\\//);
                if(m){ return '/attachments/download/'+m[1]; }

                // 既に download or attachments はそのまま
                if(/^\\/attachments\\/(download\\/)?\\d+/.test(p)){ return u.pathname+u.search; }

                return href;
              }catch(_e){ return href; }
            }

            // ===== 1) 本文中の画像は必ずモーダル =====
            var inlineImgs = document.querySelectorAll([
              '#content .wiki img',
              '#content .wiki-content img',
              '#content .journal .wiki img',
              '#content .issue .wiki img',
              '#content .news .wiki img',
              '#content .preview .wiki img'
            ].join(','));
            inlineImgs.forEach(function(img){
              var a = img.closest('a[href]');
              var base = (a ? a.getAttribute('href') : img.getAttribute('src')) || '';
              var src  = fullSrcFrom(base);
              img.style.cursor='zoom-in';
              img.addEventListener('click', function(ev){
                ev.preventDefault();
                openLightbox(src, img.getAttribute('alt'));
              });
            });

            // ===== 2) 添付サムネはモーダル、テキストリンクは通常遷移 =====
            // テキストリンク（通常遷移させたい対象）… a.icon-attachment
            // サムネイル … .thumbnails a[href] > img
            var thumbImgs = document.querySelectorAll([
              '#content .attachments .thumbnails a[href] > img',
              '#content .thumbnails a[href] > img',
              '.attachments .thumbnails a[href] > img',
              '.thumbnails a[href] > img'
            ].join(','));

            thumbImgs.forEach(function(img){
              var a = img.parentElement;
              if(!a) return;

              // 念のため：テキストリンク(アイコン)には触らない
              if(a.classList.contains('icon-attachment')) return;

              var href = a.getAttribute('href') || '';
              var src  = fullSrcFrom(href);
              img.style.cursor='zoom-in';

              // 既にバインド済みなら重複回避
              if(a.dataset.rmLightboxBound==='1') return;
              a.dataset.rmLightboxBound='1';

              a.addEventListener('click', function(ev){
                ev.preventDefault();           // サムネイルはモーダル
                openLightbox(src, img.getAttribute('alt'));
              }, true);
            });

            // （重要）テキストリンク a.icon-attachment にはハンドラを付けない＝通常遷移のまま
          });
        </script>
      HTML
    end
  end
end
