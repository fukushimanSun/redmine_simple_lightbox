require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name 'Redmine Simple Lightbox'
  author 'Fukushima'
  description 'Click images in wiki/issues to open a simple lightbox modal.'
  version '1.0.0'
  requires_redmine version_or_higher: '6.0.0'
end
module RedmineSimpleLightbox
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      <<~HTML.html_safe
        <style>
          /* === 本文の画像は“見やすいサイズ”に抑える（必要なら600→800等に変更） === */
          #content img:not(.gravatar),
          .wiki img,.wiki-content img,.journal .wiki img,.issue .wiki img,.news .wiki img,.preview .wiki img{
            max-width:400px !important;   /* ←ここを好みの幅に */
            width:100%;
            height:auto !important;
          }
          /* === モーダル === */
          .rm-lb{position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.75);z-index:9999;padding:2rem}
          .rm-lb.is-open{display:flex}
          .rm-lb img{max-width:95vw;max-height:90vh;box-shadow:0 10px 30px rgba(0,0,0,.5);border-radius:8px}
          .rm-lb .x{position:absolute;top:12px;right:16px;font-size:32px;color:#fff;cursor:pointer}
        </style>
        <script>
          document.addEventListener('DOMContentLoaded',function(){
            var sels=['#content img:not(.gravatar)', '.wiki img','.wiki-content img','.journal .wiki img','.issue .wiki img','.news .wiki img','.preview .wiki img'];
            var imgs=document.querySelectorAll(sels.join(','));
            if(!imgs.length) return;

            // モーダル生成
           var ov=document.createElement('div'); ov.className='rm-lb';
            ov.innerHTML='<img alt=""><span class="x" aria-label="Close">×</span>';
            document.body.appendChild(ov);
            var big=ov.querySelector('img');

            function open(src,alt){ big.src=src; big.alt=alt||''; ov.classList.add('is-open'); }
            function close(){ ov.classList.remove('is-open'); big.removeAttribute('src'); big.removeAttribute('alt'); }
            ov.addEventListener('click',function(e){ if(e.target===ov||e.target.classList.contains('x')) close(); });
            document.addEventListener('keydown',function(e){ if(e.key==='Escape') close(); });

            // サムネURL → 原寸URL への変換（Redmineの典型パターンを面倒見ます）
            function fullSrcFrom(url){
              if(!url) return url;
              // /attachments/thumbnail/ID/200 → /attachments/download/ID
              var m=url.match(/\\/attachments\\/thumbnail\\/(\\d+)\\/(\\d+)/);
              if(m){ return '/attachments/download/'+m[1]; }
              return url; // もともと原寸ならそのまま
            }

            imgs.forEach(function(img){
              // a[href] で囲まれていれば href を優先（原寸リンクのことが多い）
              var a=img.closest('a[href]');
              var base=(a?a.getAttribute('href'):img.getAttribute('src'))||'';
              var src=fullSrcFrom(base);

              img.style.cursor='zoom-in';
              img.addEventListener('click',function(ev){ ev.preventDefault(); open(src,img.getAttribute('alt')); });
            });
          });
        </script>
      HTML
    end
  end
end
