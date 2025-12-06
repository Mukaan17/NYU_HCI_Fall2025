//
//  String+HTML.swift
//  VioletVibes
//
//  Extension to strip HTML tags and decode HTML entities from strings

import Foundation

extension String {
    /// Strips HTML tags and decodes HTML entities from the string
    var strippingHTML: String {
        return self.removingHTMLTags
    }
    
    /// Removes HTML tags using regex (fallback method)
    private var removingHTMLTags: String {
        // Remove HTML tags
        let htmlTagPattern = "<[^>]+>"
        var cleaned = self.replacingOccurrences(
            of: htmlTagPattern,
            with: "",
            options: .regularExpression
        )
        
        // Decode common HTML entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&mdash;": "—",
            "&ndash;": "–",
            "&hellip;": "..."
        ]
        
        for (entity, replacement) in entities {
            cleaned = cleaned.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Clean up multiple spaces and newlines
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
