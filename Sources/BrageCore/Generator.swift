/**
 *  Brage
 *  Copyright (c) Michael Enger 2021
 *  MIT license, see LICENSE file for details
 */

import Files
import Foundation

/// Generator which constructs an example site with a bunch of example files.
public struct Generator {
    /// Generate a site into the target directory.
    ///
    /// - Parameter target: Destination for the example files.
    public static func generate(target targetDirectory: Folder) throws {
        // Site config
        try targetDirectory.createFile(named: "site.yaml").write("""
        ---
        title: Test Page
        description: This is the page desc.
        image: bob.png

        emoji:
          - 🍍
          - 🥶
          - 🆑
        attempt: "made"
        objects:
          - type: explosive
            title: Bombs
          - type: benign
            title: Also bombs
          - type: harmless
            title: Bombs again
        """)

        // Layout
        try targetDirectory.createFile(named: "layout.html").write("""
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>
              {{ page.title }} - {{ site.title }}
            </title>
            <link rel="stylesheet" type="text/css" href="{{ site.assets }}styles.css">
          </head>
          <body>
            <h1>Example Site</h1>
            <nav>
                <a href="{{ site.root }}">Home</a>
                &middot;
                <a href="{{ site.root }}markdown">Markdown</a>
                &middot;
                <a href="{{ site.root }}sub/page">Sub-page</a>
            </nav>
            {{ page.content }}
          </body>
        </html>
        """)

        // Assets

        let assetsDirectory = try targetDirectory.createSubfolderIfNeeded(at: "assets")
        try assetsDirectory.createFile(named: "styles.css").write("""
        body {
            background: #f2f2f2;
            color: #222;
            font-family: 'Helvetica Neue', Helvetica, sans-serif;
        }
        """)
        try assetsDirectory.createFile(named: "bob.png").write(Data(base64Encoded: """
        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
        """, options: .ignoreUnknownCharacters)!)

        // Pages

        let pagesDirectory = try targetDirectory.createSubfolderIfNeeded(at: "pages")
        try pagesDirectory.createFile(named: "index.html").write("""
        <p>This is the {{ page.title }} page and will be rendered at {{ page.uri }}.</p>

        <p><img src="{{ site.image }}"></p>

        <p>
            An attempt was {{ data.attempt }}
            {% for emoji in data.emoji %}
                {{ emoji }}
            {% endfor %}
        </p>
        """)
        try pagesDirectory.createFile(named: "markdown.markdown").write("""
        ## Markdown

        This is rendered as _Markdown_.

        It supports **bold**, _italized_, and ~~strikethrough~~ text as well as

        * unordered
        * and

        1. ordered
        2. lists

        See the [Markdown Guide](https://www.markdownguide.org/) for more information.
        """)
        try pagesDirectory.createSubfolderIfNeeded(at: "sub").createFile(named: "page.html").write("""
        <h2>Sub-page</h2>

        This is a sub page and is rendered at {{ page.uri }}.

        {% include "template.html" %}
        {% include "template.markdown" %}

        <ul>
          {% for item in data.objects %}
          <li>{{ item.type }} - {{ item.title }}</a></li>
          {% endfor %}
        </ul>
        """)

        // Templates

        let templatesDirectory = try targetDirectory.createSubfolderIfNeeded(at: "templates")
        try templatesDirectory.createFile(named: "template.html").write("I come from a template.")
        try templatesDirectory.createFile(named: "template.markdown").write("I come from a _**Markdown**_ template.")
    }
}
