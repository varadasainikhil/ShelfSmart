//
//  HTMLTextCleaner.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 10/23/25.
//

import Foundation
internal import UIKit

extension String {
    var cleanHTMLText: String {
        guard !self.isEmpty else {
            return self
        }

        // CRITICAL FIX: Decode HTML entities FIRST (API sends &lt;ul&gt; instead of <ul>)
        let decodedHTML = self.decodeHTMLEntities()

        // Now try NSAttributedString approach with the decoded HTML
        if let cleaned = decodedHTML.cleanWithNSAttributedString(), !cleaned.isEmpty {
            return cleaned
        }

        // Fallback to regex stripping
        let result = decodedHTML.stripHTMLWithRegex()
        return result
    }

    // Primary method: NSAttributedString HTML parsing (requires full HTML document)
    private func cleanWithNSAttributedString() -> String? {
        // Wrap HTML fragment in proper document structure for iOS NSAttributedString
        let wrappedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>body { font-family: -apple-system; }</style>
        </head>
        <body>
        \(self)
        </body>
        </html>
        """

        guard let data = wrappedHTML.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
        ]

        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            let plainText = attributedString.string
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if plainText.isEmpty {
                return nil
            }

            return plainText
        } catch {
            return nil
        }
    }

    // Decode HTML entities (must be done BEFORE NSAttributedString parsing)
    private func decodeHTMLEntities() -> String {
        var text = self

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&ndash;", "–"),
            ("&mdash;", "—"),
            ("&hellip;", "…"),
            ("&rsquo;", "\u{2019}"),  // Right single quotation mark
            ("&lsquo;", "\u{2018}"),  // Left single quotation mark
            ("&rdquo;", "\u{201D}"),  // Right double quotation mark
            ("&ldquo;", "\u{201C}")   // Left double quotation mark
        ]

        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Decode numeric HTML entities (e.g., &#8217; or &#x2019;)
        // Note: These are removed rather than decoded to avoid complexity
        text = text.replacingOccurrences(
            of: "&#(\\d+);",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "&#x([0-9a-fA-F]+);",
            with: "",
            options: .regularExpression
        )

        return text
    }

    // Fallback method: Comprehensive regex HTML tag stripping
    private func stripHTMLWithRegex() -> String {
        var text = self

        // Remove all HTML tags (including self-closing and with attributes)
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Clean up excessive whitespace
        text = text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }
}
