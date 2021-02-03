# Brage

_Brage er i den norrøne mytologien guden for diktning og skaldekunst._ [WikiPedia](https://no.wikipedia.org/wiki/Brage)

Site builder for generating sites based on [Stencil](https://github.com/stencilproject/Stencil) and [Markdown](https://www.markdownguide.org/) templates.

**NOTE** This application is currently under development and a lot of this readme is reflecting ambitious plans rather than reality.

## Usage

Run the CLI tool along with any of the commands along with an optional site directory. If no directory is present it will use the current directory.

```shell
brage [command] [DIRECTORY]
```

The resulting HTML will be placed in a `build` directory.

### Commands

* `new` Create a new website based on a basic template.
* `build` Generate the HTML.
* `serve` Serve the HTML via a basic localhost server.

## Site Generation

The site generation is based on Stencil and Markdown templates. The only requirements to start with is a config file, a layout template, and one or more pages.

### Config File

The config is defined in a `site.yaml` file in the site directory. It defines some basic meta data as well as other contents (explained below).

* `title` Title of the site.
* `description` Description of the site.
* `image` Social media preview image relative to the assets directory.

### Layout Template

The layout template is defined in a `layout.html` file at the root of the site directory and is used when generating all the pages. The page templates are rendered and placed inside the layout template where their content is available in the `page.content` variable. 

### Pages

Pages are defined in files contained in the `pages` directory. They can be either Stencil templates or Markdown files.

There is only one special file, the `index` file, which defines the index page. It will be generated with a resulting URI of `/`. Any other files in the directory will be turned into pages in subfolders so that the path to the generated HTML file is correct based on the template file's location.

For example the file `pages/example/hello.html` would become the file `build/example/hello/index.html` and have the URI `/example/hello`.

### Rendering Templates

All Stencil template (including the layout template) are renderered with the following variables available:

* `site` Site meta data.
    * `title` Title of the site (from the site config).
    * `description` Description of the site (from the site config).
    * `image` Social media preview image (from the site config).
    * `root` Relative path to the root directory.
    * `assets` Relative path to the assets directory.
* `page` Page meta data.
    * `title` Title of the page.
    * `content` Content of the page (only available in the layout template).
    * `path` URI path to the page.

#### Including/extending Templates

It's possible to extend/include templates (as per the [Stencil documentation](https://stencil.fuller.li/en/latest/templates.html#template-inheritance)) with files found in the `templates` directory (within the main site directory).

### Assets

Any files in a directory called `assets` will be copied as-is to an `assets` directory in the build directory.

### Collections

TODO

### Forms

TODO

## Development

### Requirements

* [Swift 5](https://swift.org/)
