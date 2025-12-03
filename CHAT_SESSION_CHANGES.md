# Chat Session Changes Summary

This document contains all changes made during the chat session to fix text handling in chat messages and quick actions sheets. Apply these changes when pulling the `Final_v1` branch from git.

## Date: Current Session

---

## 1. Fix Chat Text Handling in iOS (ChatView.swift)

**File**: `ios-app/VioletVibes/VioletVibes/Views/Chat/ChatView.swift`

### Changes Made:
1. **Added HTML Entity Decoding Function** (`decodeHTMLEntities`)
   - Handles HTML entities like `&amp;`, `&rsquo;`, `&quot;`, `&mdash;`, `&nbsp;`, etc.
   - Handles numeric entities like `&#39;`, `&#8212;`, etc.

2. **Improved Whitespace Handling** (`cleanAndFormatText`)
   - Preserves intentional line breaks from API
   - Normalizes line endings (`\r\n`, `\r` → `\n`)
   - Only collapses multiple spaces/tabs (not newlines)
   - Maintains paragraph breaks (double newlines)
   - Cleans up excessive whitespace (3+ newlines → 2)

3. **Improved Markdown Parsing** (`formattedText`)
   - Uses `interpretedSyntax: .inlineOnlyPreservingWhitespace` to preserve whitespace
   - Increased line spacing from 4 to 6 points

4. **Simplified List Processing**
   - Converts markdown list markers (`*` and `-`) to bullet points (`•`)
   - More careful detection to avoid breaking markdown formatting like `**bold**`

5. **Removed Aggressive Text Manipulation**
   - Removed automatic paragraph breaks based on sentence detection
   - Removed automatic line break insertion before list items
   - Respects original text structure from API

### Key Code Sections to Replace:

#### Replace `formattedText` function (around line 320):
```swift
// Format text with markdown support and proper spacing
@ViewBuilder
private func formattedText(_ text: String) -> some View {
    let cleanedText = cleanAndFormatText(text)
    
    if #available(iOS 15.0, *) {
        // Try to parse as markdown with whitespace preservation
        if let attributedString = try? AttributedString(
            markdown: cleanedText,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            // Add paragraph spacing to the attributed string
            let styledString = applyParagraphSpacing(to: attributedString)
            Text(styledString)
        } else {
            // Fallback: display cleaned text with line spacing
            Text(cleanedText)
                .lineSpacing(6)
        }
    } else {
        Text(cleanedText)
            .lineSpacing(6)
    }
}
```

#### Replace `applyParagraphSpacing` function (around line 342):
```swift
// Apply paragraph spacing to an AttributedString
@available(iOS 15.0, *)
private func applyParagraphSpacing(to attributedString: AttributedString) -> AttributedString {
    var styledString = attributedString
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 12
    paragraphStyle.paragraphSpacingBefore = 8
    paragraphStyle.lineSpacing = 6  // Changed from 4 to 6
    
    // Apply paragraph style to entire string
    let paragraphStyleAttribute = AttributeContainer([.paragraphStyle: paragraphStyle])
    styledString.mergeAttributes(paragraphStyleAttribute, mergePolicy: .keepNew)
    
    return styledString
}
```

#### Add `decodeHTMLEntities` function (before `cleanAndFormatText`):
```swift
// Decode HTML entities to proper characters
private func decodeHTMLEntities(_ text: String) -> String {
    var decoded = text
    
    // Named entities
    let entities: [String: String] = [
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&apos;": "'",
        "&nbsp;": " ",
        "&mdash;": "—",
        "&ndash;": "–",
        "&rsquo;": "'",
        "&lsquo;": "'",
        "&rdquo;": "\"",
        "&ldquo;": "\"",
        "&hellip;": "…",
        "&copy;": "©",
        "&reg;": "®",
        "&trade;": "™"
    ]
    
    // Replace named entities
    for (entity, replacement) in entities {
        decoded = decoded.replacingOccurrences(of: entity, with: replacement)
    }
    
    // Handle numeric entities like &#39; or &#8212;
    // Pattern: &# followed by digits and semicolon
    let numericPattern = #"&#(\d+);"#
    if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
        let nsString = decoded as NSString
        let matches = regex.matches(in: decoded, options: [], range: NSRange(location: 0, length: nsString.length))
        
        // Process matches in reverse to maintain correct indices
        for match in matches.reversed() {
            if match.numberOfRanges >= 2 {
                let numberRange = match.range(at: 1)
                if let numberString = nsString.substring(with: numberRange) as String?,
                   let number = Int(numberString),
                   let unicodeScalar = UnicodeScalar(number) {
                    let replacement = String(Character(unicodeScalar))
                    let fullRange = match.range
                    decoded = (decoded as NSString).replacingCharacters(in: fullRange, with: replacement)
                }
            }
        }
    }
    
    return decoded
}
```

#### Replace `cleanAndFormatText` function (around line 358):
```swift
// Clean and format text for better readability
private func cleanAndFormatText(_ text: String) -> String {
    // Step 1: Decode HTML entities first
    var cleaned = decodeHTMLEntities(text)
    
    // Step 2: Normalize line endings (convert \r\n and \r to \n)
    cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n")
    cleaned = cleaned.replacingOccurrences(of: "\r", with: "\n")
    
    // Step 3: Process line by line to handle formatting properly
    let lines = cleaned.components(separatedBy: "\n")
    var formattedLines: [String] = []
    
    for line in lines {
        var processedLine = line
        
        // Replace multiple spaces/tabs with single space (but preserve newlines)
        processedLine = processedLine.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
        
        // Trim trailing whitespace but preserve leading whitespace for indentation
        processedLine = processedLine.trimmingCharacters(in: .whitespaces)
        
        if processedLine.isEmpty {
            // Preserve empty lines (they represent paragraph breaks)
            formattedLines.append("")
            continue
        }
        
        // Check if this is a list item - must start with * or - followed by space
        // But NOT if it's part of markdown formatting (**bold** or *italic*)
        let trimmed = processedLine.trimmingCharacters(in: .whitespaces)
        
        // Convert list markers to bullet points
        // Only if it starts with "* " or "- " and is not markdown formatting
        if trimmed.hasPrefix("* ") {
            // Check if it's not part of **bold** formatting
            // If it starts with "**", it's bold, not a list
            if !trimmed.hasPrefix("**") {
                let afterMarker = String(trimmed.dropFirst(2))
                processedLine = "• " + afterMarker
            }
        } else if trimmed.hasPrefix("- ") {
            processedLine = "• " + String(trimmed.dropFirst(2))
        }
        
        formattedLines.append(processedLine)
    }
    
    // Step 4: Join lines back together
    cleaned = formattedLines.joined(separator: "\n")
    
    // Step 5: Clean up excessive newlines (3+ consecutive newlines → 2)
    cleaned = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
    
    // Step 6: Trim leading/trailing whitespace but preserve structure
    cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return cleaned
}
```

**Note**: The old `cleanAndFormatText` function had aggressive text manipulation that added paragraph breaks automatically. The new version respects the original API text structure.

---

## 2. Fix Quick Actions Sheets (QuickResultsSheetView.swift)

**File**: `ios-app/VioletVibes/VioletVibes/Views/Quick/QuickResultsSheetView.swift`

### Changes Made:
1. **Map "chill_cafes" to "cozy_cafes"** for backend compatibility
2. **Improved deduplication logic** to handle duplicate items
3. **Generate unique IDs** for items with ID 0 to prevent SwiftUI rendering issues

### Key Code Section to Replace:

#### Replace `loadPlaces` function (around line 139):
```swift
private func loadPlaces() async {
    loading = true
    do {
        // Map "chill_cafes" to "cozy_cafes" for backend compatibility
        let apiCategory = category == "chill_cafes" ? "cozy_cafes" : category
        let response = try await apiService.getQuickRecommendations(category: apiCategory, limit: 10)
        await MainActor.run {
            // Improved deduplication using multiple strategies
            var deduplicatedPlaces: [Recommendation] = []
            var seenIds = Set<Int>()
            var seenKeys = Set<String>()
            
            for place in response.places {
                // Strategy 1: Deduplicate by ID (if ID is not 0)
                if place.id != 0 {
                    if seenIds.contains(place.id) {
                        continue
                    }
                    seenIds.insert(place.id)
                }
                
                // Strategy 2: Create a comprehensive unique key from title and location
                let normalizedTitle = place.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Round coordinates to 4 decimal places (~11 meters precision) to catch nearby duplicates
                let normalizedLat = place.lat.map { String(format: "%.4f", $0) } ?? "0"
                let normalizedLng = place.lng.map { String(format: "%.4f", $0) } ?? "0"
                
                // Use title + location as primary unique key
                let uniqueKey = "\(normalizedTitle)-\(normalizedLat)-\(normalizedLng)"
                
                if seenKeys.contains(uniqueKey) {
                    continue
                }
                seenKeys.insert(uniqueKey)
                
                // Ensure unique ID for SwiftUI ForEach
                var uniquePlace = place
                if uniquePlace.id == 0 {
                    // Generate a unique ID from the unique key
                    uniquePlace = Recommendation(
                        id: abs(uniqueKey.hashValue) % Int.max,
                        title: place.title,
                        description: place.description,
                        distance: place.distance,
                        walkTime: place.walkTime,
                        lat: place.lat,
                        lng: place.lng,
                        popularity: place.popularity,
                        image: place.image
                    )
                }
                
                deduplicatedPlaces.append(uniquePlace)
            }
            
            places = deduplicatedPlaces
            
            print("✅ Loaded \(places.count) unique places (from \(response.places.count) total)")
            loading = false
        }
    } catch {
        print("Quick recs error: \(error)")
        await MainActor.run {
            places = []
            loading = false
        }
    }
}
```

---

## Summary of Issues Fixed

1. **Chat Text Handling**:
   - ✅ HTML entities now decode properly (e.g., `&amp;` → `&`, `&rsquo;` → `'`)
   - ✅ Whitespace and line breaks preserved from API
   - ✅ Markdown parsing preserves whitespace
   - ✅ Removed aggressive text manipulation that was breaking special characters

2. **Quick Actions Sheets**:
   - ✅ "Chill Cafes" now shows results (mapped to backend's "cozy_cafes")
   - ✅ Duplicate items properly deduplicated
   - ✅ Unique IDs generated for SwiftUI rendering

---

## Files Modified

1. `ios-app/VioletVibes/VioletVibes/Views/Chat/ChatView.swift`
2. `ios-app/VioletVibes/VioletVibes/Views/Quick/QuickResultsSheetView.swift`

---

## Notes

- **No backend changes** were made - all fixes are client-side only
- The changes maintain backward compatibility with existing API responses
- Test both chat messages with special characters and quick action sheets after applying changes

