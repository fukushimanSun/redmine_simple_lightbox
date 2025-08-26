require 'redmine'

Redmine::Plugin.register :redmine_simple_lightbox do
  name        'Redmine Simple Lightbox'
  author      'Fukushima'
  description 'Click images, thumbnails, and attachment links in wiki/issues to open a simple lightbox modal.'
  version     '1.0.6'
  requires_redmine :version_or_higher => '6.0.0'
end

module RedmineSimpleLightbox
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      <<~HTML.html_safe
        <style>
          /* 本文画像の表示幅制御（必要に応じて 600px を調整） */
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
          /* 本文中の画像にもヒント */
          #content img:not(.gravatar),
          .wiki img,.wiki-content img,
          .journal .wiki img,.issue .wiki img,
          .news .wiki img,.preview .wiki img {
            cursor: zoom-in;
          }
        </style>

        <script>
          document.addEventListener('DOMContentLoaded', function(){
            // ===== モーダル生成 =====
            var ov = document.createElement('div');
            ov.className = 'rm-lb';
            ov.innerHTML = '<img alt=""><span class="x" aria-label="Close">×</span>';
            document.body.appendChild(ov);
            var big = ov.querySelector('img');

            function open(src, alt){
              if(!src) return;
              big.src = src;
              big.alt = alt || '';
              ov.classList.add('is-open');
            }
            function close(){
              ov.classList.remove('is-open');
              big.removeAttribute('src');
              big.removeAttribute('alt');
            }

            ov.addEventListener('click', function(e){
              if (e.target === ov || e.target.classList.contains('x')) close();
            });
            document.addEventListener('keydown', function(e){
              if (e.key === 'Escape') close();
            });

            // ===== URL 正規化ユーティリティ =====
            // - /attachments/thumbnail/:id/:size -> /attachments/download/:id
            // - /attachments/:id               -> ?download=1 を付与（生ファイルへ）
            function normalizeToDownload(hrefOrSrc){
              if (!hrefOrSrc) return '';
              try{
                var u = new URL(hrefOrSrc, document.baseURI);
                var p = u.pathname;

                var m = p.match(/\\/attachments\\/thumbnail\\/(\\d+)\\/\\d+/);
                if (m) {
                  p = p.replace(/\\/attachments\\/thumbnail\\/(\\d+)\\/\\d+/, '/attachments/download/$1');
                  u.pathname = p;
                  u.search = ''; // サムネ系の余計なクエリは排除
                  return u.toString();
                }

                // /attachments/123 （末尾スラorなし）→ 生ファイル
                if (/\\/attachments\\/\\d+(?:\\/?$)/.test(p) && !/\\/attachments\\/download\\//.test(p)) {
                  u.searchParams.set('download', '1');
                  return u.toString();
                }

                // それ以外はそのまま（/attachments/download/ID 含む）
                return u.toString();
              } catch(e){
                return hrefOrSrc;
              }
            }

            // ===== クリックを一括ハンドル（イベント委譲） =====
            document.addEventListener('click', function(e){
              var a = e.target.closest('a[href]');

              // 1) まず a[href] を優先（添付ファイル名リンク / サムネ画像のリンク）
              if (a) {
                var href = a.getAttribute('href') || '';

                var isAttachmentLink =
                  /\\/attachments\\//.test(href) ||               // 添付系全般
                  !!a.querySelector('img');                       // サムネ等の画像リンク

                if (isAttachmentLink) {
                  e.preventDefault();

                  // a 内の <img> がサムネならそれを優先的に原寸化
                  var innerImg = a.querySelector('img');
                  var candidate = innerImg ? innerImg.getAttribute('src') : href;
                  var finalUrl  = normalizeToDownload(candidate);

                  // alt は画像から、なければ title/テキスト
                  var altText = innerImg ? (innerImg.getAttribute('alt') || '') :
                                (a.getAttribute('title') || a.textContent.trim());

                  open(finalUrl, altText);
                  return;
                }
              }

              // 2) 次に、本文中の裸の <img> クリック（リンクで囲まれていない画像）
              var img = e.target.closest('img');
              if (img &&
                  img.closest('#content, .wiki, .wiki-content, .journal .wiki, .issue .wiki, .news .wiki, .preview .wiki') &&
                  !img.classList.contains('gravatar')) {
                // a[href] がない（または a が添付系でない）場合のみ処理
                if (!a) {
                  e.preventDefault();
                  var src = normalizeToDownload(img.getAttribute('src'));
                  open(src, img.getAttribute('alt') || '');
                }
              }
            });
          });
        </script>
      HTML
    end
  end
end
