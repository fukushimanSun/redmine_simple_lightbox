require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Lightbox only for inline images in wiki/issues; attachments list stays as normal links.'
  version     '1.0.6'
  requires_redmine :version_or_higher => '6.0.0'
end

module RedmineSimpleLightbox
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      <<~HTML.html_safe
        <style>
          /* 本文画像は本文幅にフィット（添付のサムネは触らない） */
          #content .wiki img,
          #content .wiki-content img,
          #content .journal .wiki img,
          #content .issue .wiki img,
          #content .news .wiki img,
          #content .preview .wiki img {
            max-width: 600px !important;
            width: 100%;
            height: auto !important;
          }

          /* モーダル */
          .rm-lb { position: fixed; inset: 0; display: none; align-items: center; justify-content: center;
                   background: rgba(0,0,0,.75); z-index: 9999; padding: 2rem; }
          .rm-lb.is-open { display: flex; }
          .rm-lb img { max-width: 95vw; max-height: 90vh; box-shadow: 0 10px 30px rgba(0,0,0,.5); border-radius: 8px; }
          .rm-lb .x { position: absolute; top: 12px; right: 16px; font-size: 32px; color: #fff; cursor: pointer; }
        </style>

        <script>
          document.addEventListener('DOMContentLoaded', function(){
            // 対象は「本文中の画像」。ただし添付エリア内は除外する。
            var selectors = [
              '#content .wiki img',
              '#content .wiki-content img',
              '#content .journal .wiki img',
              '#content .issue .wiki img',
              '#content .news .wiki img',
              '#content .preview .wiki img'
            ];
            var imgs = document.querySelectorAll(selectors.join(','));
            if (!imgs.length) return;

            // モーダル生成
            var ov = document.createElement('div');
            ov.className = 'rm-lb';
            ov.innerHTML = '<img alt=""><span class="x" aria-label="Close">×</span>';
            document.body.appendChild(ov);
            var big = ov.querySelector('img');

            function open(src, alt){ big.src = src; big.alt = alt || ''; ov.classList.add('is-open'); }
            function close(){ ov.classList.remove('is-open'); big.removeAttribute('src'); big.removeAttribute('alt'); }
            ov.addEventListener('click', function(e){ if (e.target === ov || e.target.classList.contains('x')) close(); });
            document.addEventListener('keydown', function(e){ if (e.key === 'Escape') close(); });

            // 添付（thumbnails/attachments）かどうかの判定
            function isInAttachments(node){
              return !!(node.closest('.attachments') ||
                        node.closest('.thumbnails') ||
                        node.closest('.attachments-list') ||
                        node.closest('.thumbnails-list'));
            }

            // サムネ → 原寸に変換（本文内でサムネが混ざってた場合の保険）
            function fullSrcFrom(hrefOrSrc){
              if (!hrefOrSrc) return '';
              var m = hrefOrSrc.match(/\\/attachments\\/thumbnail\\/(\\d+)\\/\\d+/);
              if (m) return '/attachments/download/' + m[1];
              return hrefOrSrc;
            }

            imgs.forEach(function(img){
              // 添付エリア内の画像は対象外（＝通常のリンク遷移のまま）
              if (isInAttachments(img)) return;

              var a   = img.closest('a[href]');
              var raw = a ? a.getAttribute('href') : img.getAttribute('src');
              var src = fullSrcFrom(raw);

              // a[href] が /attachments/〜 を指している場合も本文内ならモーダルで表示
              // （ただし添付エリアは前段で除外済み）
              img.style.cursor = 'zoom-in';
              img.addEventListener('click', function(ev){
                if (a) ev.preventDefault(); // 本文内は常にモーダル
                open(src, img.getAttribute('alt'));
              });
            });
          });
        </script>
      HTML
    end
  end
end
