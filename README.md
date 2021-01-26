# Heimdall

Site builder for generating sites based on YAML, Markdown, and [Mustache](https://mustache.github.io/) templates.

**NOTE** This application is currently under development and a lot of this readme is reflecting ambitious plans rather than reality.

## Usage

Run the CLI tool along with any of the commands along with an optional site directory. If no directory is present it will use the current directory.

```shell
heimdall [command] [DIRECTORY]
```

The resulting HTML will be placed in a `build` directory.

### Commands

* `new` Create a new website based on a basic template.
* `build` Generate the HTML.
* `serve` Serve the HTML via a basic localhost server.

## Site Generation

The site generation is based on YAML files and Mustache templates. The only requirements to start with is a config file, a layout template, and an index page.

### Config File

The config is defined in a `site.yml` file in the site directory. It defines some basic meta data as well as other contents (explained below).

* `title` Title of the site.
* `description` Description of the site, used in meta tags.

### Layout Template

The layout template is defined in a `layout.mustache` file at the root of the site directory and is used when generating all the pages. It will be rendered with the following available variables:

* `site` Site meta data
  * `title` Title of the site.
  * `description` Description of the site, used in meta tags.
  * `root` Relative path to the root directory.
  * `assets` Relative path to the assets directory.
* `page` Page meta data
  * `title` Title of the page
  * `content` Content of the page
  * `path` URI path to the page

### Pages

Pages are defined in files contained in the `pages` directory. They can be either Mustache templates, Markdown files, or YAML files defining content blocks to use.

There is only one required file, `index` which defines the index page. Any other files in the directory will be turned into pages in subfolders so that the path to the generated HTML file is correct based on the template file's location.

For example the file `pages/example/hello.mustache` would become the file `build/example/hello/index.html` and have the URI `/example/hello`.

### Assets

Any files in a directory called `assets` will be copied as-is to the build directory.

### Collections

TODO

### Forms

TODO

## Development

### Requirements

* [Swift 5](https://swift.org/)
