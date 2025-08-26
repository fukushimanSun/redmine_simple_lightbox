require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Click images in wiki/issues to open a simple lightbox modal.'
  version     '1.0.1'
  requires_redmine :version_or_higher => '6.0.0'
end

module RedmineSimpleLightbox
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      <<~HTML.html_safe
        <style>
          /* 本文画像の表示幅制御 */
          #content img:not(.gravatar),
          .wiki img,.wiki-content img,
          .journal .wiki img,.issue .wiki img,
          .news .wiki img,.preview .wiki img {
            max-width: 600px !important;
            width: 100%;
            height: auto !important;
          }

          /* モーダル */
          .rm-lb {
            position: fixed; inset: 0;
            display: none; align-items: center; justify-content: center;
            background: rgba(0,0,0,.75);
            z-index: 9999; padding: 2rem;
          }
          .rm-lb.is-open { display: flex; }
          .rm-lb img {
            max-width: 95vw; max-height: 90vh;
            box-shadow: 0 10px 30px rgba(0,0,0,.5);
            border-radius: 8px;
          }
          .rm-lb .x {
            position: absolute; top: 12px; right: 16px;
            font-size: 32px; color: #fff; cursor: pointer;
          }
        </style>

        <script>
          document.addEventListener('DOMContentLoaded',function(){
            var sels=[
              '#content img:not(.gravatar)',
              '.wiki img','.wiki-content img',
              '.journal .wiki img','.issue .wiki img',
              '.news .wiki img','.preview .wiki img'
            ];
            var imgs=document.querySelectorAll(sels.join(','));
            if(!imgs.length) return;

            // モーダル生成
            var ov=document.createElement('div');
            ov.className='rm-lb';
            ov.innerHTML='<img alt=""><span class="x" aria-label="Close">×</span>';
            document.body.appendChild(ov);
            var big=ov.querySelector('img');

            function open(src,alt){ big.src=src; big.alt=alt||''; ov.classList.add('is-open'); }
            function close(){ ov.classList.remove('is-open'); big.removeAttribute('src'); big.removeAttribute('alt'); }

            ov.addEventListener('click',function(e){
              if(e.target===ov||e.target.classList.contains('x')) close();
            });
            document.addEventListener('keydown',function(e){
              if(e.key==='Escape') close();
            });

            imgs.forEach(function(img){
              // まず a[href] をチェック
              var a = img.closest('a[href]');
              var src = img.getAttribute('src') || '';

              if (a) {
                var href = a.getAttribute('href') || '';

                if (href) {
                  // 添付サムネ → 原寸ダウンロードURLに置換
                  href = href.replace(/\\/attachments\\/thumbnail\\/(\\d+)\\/\\d+/, '/attachments/download/$1');

                  // 添付ページ (/attachments/123) は ?download=1 を付与
                  if (/\\/attachments\\/\\d+(?:$|[?#])/.test(href) && !/\\/download\\//.test(href)) {
                    href += (href.includes('?') ? '&' : '?') + 'download=1';
                  }

                  // ファイル名が分かれば download/{id}/{filename} 形式に
                  var fname = a.getAttribute('data-filename') ||
                              img.getAttribute('data-filename') ||
                              img.getAttribute('alt');
                  if (/\\/attachments\\/download\\/\\d+(\\/)?$/.test(href) && fname) {
                    href = href.replace(/\\/$/, '') + '/' + encodeURIComponent(fname);
                  }

                  src = href;
                }
              }

              img.style.cursor = 'zoom-in';
              img.addEventListener('click', function(ev){
                ev.preventDefault();
                open(src, img.getAttribute('alt') || '');
              });
            });
          });
        </script>
      HTML
    end
  end
end
