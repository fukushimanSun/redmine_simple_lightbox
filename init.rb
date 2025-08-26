require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Click images, thumbnails, and attachment links in wiki/issues to open a simple lightbox modal.'
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

          /* 添付リンクやサムネにも拡大カーソル */
          a[href*="/attachments/"], a[href*="/attachments/"] img {
            cursor: zoom-in;
          }
        </style>

        <script>
          document.addEventListener('DOMContentLoaded', function(){
            // モーダル生成
            var ov = document.createElement('div');
            ov.className = 'rm-lb';
            ov.innerHTML = '<img alt=""><span class="x" aria-label="Close">×</span>';
            document.body.appendChild(ov);
            var big = ov.querySelector('img');

            function open(src,alt){ big.src=src; big.alt=alt||''; ov.classList.add('is-open'); }
            function close(){ ov.classList.remove('is-open'); big.removeAttribute('src'); big.removeAttribute('alt'); }

            ov.addEventListener('click',function(e){
              if(e.target===ov||e.target.classList.contains('x')) close();
            });
            document.addEventListener('keydown',function(e){
              if(e.key==='Escape') close();
            });

            // URLを原寸用に正規化
            function normalizeHref(href){
              if(!href) return '';

              // /attachments/thumbnail/ID/200 → /attachments/download/ID
              var m = href.match(/\\/attachments\\/thumbnail\\/(\\d+)\\/\\d+/);
              if(m) return '/attachments/download/' + m[1];

              // /attachments/123 → ?download=1 を付けて生ファイル
              if (/\\/attachments\\/\\d+(?:$|[?#])/.test(href) && !/\\/download\\//.test(href)) {
                href += (href.includes('?') ? '&' : '?') + 'download=1';
              }

              return href;
            }

            // クリックイベントを一括で監視（イベント委譲）
            document.addEventListener('click', function(e){
              var a = e.target.closest('a[href]');
              if (!a) return;

              var href = a.getAttribute('href') || '';
              var isAttachment =
                /\\/attachments\\/(thumbnail|download)\\/\\d+/.test(href) ||
                /\\/attachments\\/\\d+(?:$|[?#])/.test(href);

              var hasThumbImg =
                a.querySelector('img') &&
                /\\/attachments\\/thumbnail\\/\\d+\\/\\d+/.test(a.querySelector('img').src);

              if (!isAttachment && !hasThumbImg) return;

              e.preventDefault();
              href = normalizeHref(href);

              // ファイル名を補完
              var innerImg = a.querySelector('img');
              var fname =
                a.getAttribute('data-filename') ||
                (innerImg && innerImg.getAttribute('alt')) ||
                a.textContent.trim();

              if (/\\/attachments\\/download\\/\\d+(\\/)?$/.test(href) && fname) {
                href = href.replace(/\\/$/, '') + '/' + encodeURIComponent(fname);
              }

              var altText = innerImg ? (innerImg.getAttribute('alt') || '') : (a.getAttribute('title') || a.textContent.trim());
              open(href, altText);
            });
          });
        </script>
      HTML
    end
  end
end
