# OpenSeadragon button sprites (vendored)

Button images for the deep-zoom viewer on the `/scarves` page. Copied from the
`openseadragon` npm package (`build/openseadragon/images/`). The viewer's
JavaScript comes from the npm dependency (bundled by Astro); only these image
assets need to be served statically, referenced via OpenSeadragon's `prefixUrl`.

To refresh after upgrading the package:
`cp node_modules/openseadragon/build/openseadragon/images/*.png public/vendor/openseadragon/images/`
