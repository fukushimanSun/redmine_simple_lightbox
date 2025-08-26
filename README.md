# Redmine Simple Lightbox

A minimal Redmine plugin that makes wiki/issue images clickable with a simple modal lightbox.

- Tested with Redmine 6.0.6
- No external JS libraries required
- Just CSS + vanilla JS
- Lightweight alternative to heavy gallery/lightbox plugins

## Installation

1. Clone this repository into your Redmine plugins directory:

   ```bash
   cd /opt/redmine/redmine/plugins
   git clone https://github.com/fukushimanSun/redmine_simple_lightbox.git
   ```

2. Set correct ownership if needed (example: user `redmine`):

   ```bash
   sudo chown -R redmine:redmine redmine_simple_lightbox
   ```

3. Restart Redmine:

   ```bash
   sudo systemctl restart redmine
   ```

That’s it! No migrations required.

## Usage

Any image in wiki pages, issues, or news posts becomes clickable.  
Clicking opens a simple modal overlay (lightbox).  
Images scale to fit the viewport (max 95% width / 90% height).

## Screenshots

(Add some screenshots here once you can!)

## Compatibility

- Redmine 6.0.6  
- Should also work with 5.x, but not tested.

## License

This plugin is released under the MIT License. See [LICENSE](LICENSE) for details.
