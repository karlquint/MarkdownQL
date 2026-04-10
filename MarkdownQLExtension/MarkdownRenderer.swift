import Foundation

/// Converts Markdown text to HTML.
/// Supports: headers, bold, italic, strikethrough, inline code, code blocks,
/// blockquotes, unordered/ordered lists, task lists, tables, links, images, HR.
struct MarkdownRenderer {

    static func render(_ markdown: String) -> String {
        var lines = markdown.components(separatedBy: "\n")
        var output = [String]()
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines = [String]()
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(escapeHTML(lines[i]))
                    i += 1
                }
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(lang)\""
                output.append("<pre><code\(langAttr)>\(codeLines.joined(separator: "\n"))</code></pre>")
                i += 1
                continue
            }

            // Horizontal rule
            if isHorizontalRule(line) {
                output.append("<hr>")
                i += 1
                continue
            }

            // ATX headers
            if let (level, text) = parseHeader(line) {
                let id = text.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .filter { $0.isLetter || $0.isNumber || $0 == "-" }
                output.append("<h\(level) id=\"\(id)\">\(inlineMarkdown(text))</h\(level)>")
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                var quoteLines = [String]()
                while i < lines.count && (lines[i].hasPrefix(">") || lines[i].isEmpty && i + 1 < lines.count && lines[i + 1].hasPrefix(">")) {
                    let stripped = lines[i].hasPrefix("> ") ? String(lines[i].dropFirst(2))
                                 : lines[i].hasPrefix(">") ? String(lines[i].dropFirst(1))
                                 : lines[i]
                    quoteLines.append(stripped)
                    i += 1
                }
                let inner = render(quoteLines.joined(separator: "\n"))
                output.append("<blockquote>\(inner)</blockquote>")
                continue
            }

            // Table
            if i + 1 < lines.count && isTableSeparator(lines[i + 1]) {
                var tableLines = [lines[i]]
                i += 2 // skip header + separator
                while i < lines.count && lines[i].contains("|") {
                    tableLines.append(lines[i])
                    i += 1
                }
                output.append(renderTable(tableLines))
                continue
            }

            // Unordered list
            if isUnorderedListItem(line) {
                var items = [String]()
                while i < lines.count && isUnorderedListItem(lines[i]) {
                    items.append(lines[i])
                    i += 1
                }
                output.append(renderUnorderedList(items))
                continue
            }

            // Ordered list
            if isOrderedListItem(line) {
                var items = [String]()
                while i < lines.count && isOrderedListItem(lines[i]) {
                    items.append(lines[i])
                    i += 1
                }
                output.append(renderOrderedList(items))
                continue
            }

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            // Paragraph
            var paraLines = [String]()
            while i < lines.count {
                let l = lines[i]
                if l.trimmingCharacters(in: .whitespaces).isEmpty { break }
                if parseHeader(l) != nil { break }
                if l.hasPrefix(">") { break }
                if l.hasPrefix("```") { break }
                if isHorizontalRule(l) { break }
                if isUnorderedListItem(l) { break }
                if isOrderedListItem(l) { break }
                if i + 1 < lines.count && isTableSeparator(lines[i + 1]) { break }
                paraLines.append(l)
                i += 1
            }
            if !paraLines.isEmpty {
                output.append("<p>\(inlineMarkdown(paraLines.joined(separator: " ")))</p>")
            }
        }

        return output.joined(separator: "\n")
    }

    // MARK: - Block helpers

    private static func parseHeader(_ line: String) -> (Int, String)? {
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            if line.hasPrefix(prefix + " ") {
                return (level, String(line.dropFirst(level + 1)).trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        return (stripped == "---" || stripped == "***" || stripped == "___") && stripped.count >= 3
    }

    private static func isUnorderedListItem(_ line: String) -> Bool {
        return line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    private static func isOrderedListItem(_ line: String) -> Bool {
        let pattern = #"^\d+\.\s"#
        return line.range(of: pattern, options: .regularExpression) != nil
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") || trimmed.contains("---") else { return false }
        let stripped = trimmed.replacingOccurrences(of: "|", with: "")
                              .replacingOccurrences(of: "-", with: "")
                              .replacingOccurrences(of: ":", with: "")
                              .replacingOccurrences(of: " ", with: "")
        return stripped.isEmpty
    }

    private static func renderUnorderedList(_ lines: [String]) -> String {
        var items = [String]()
        for line in lines {
            let text: String
            var isTask = false
            var taskChecked = false

            let body: String
            if line.hasPrefix("- ") { body = String(line.dropFirst(2)) }
            else if line.hasPrefix("* ") { body = String(line.dropFirst(2)) }
            else if line.hasPrefix("+ ") { body = String(line.dropFirst(2)) }
            else { body = line }

            if body.hasPrefix("[ ] ") {
                isTask = true; taskChecked = false
                text = String(body.dropFirst(4))
            } else if body.hasPrefix("[x] ") || body.hasPrefix("[X] ") {
                isTask = true; taskChecked = true
                text = String(body.dropFirst(4))
            } else {
                text = body
            }

            if isTask {
                let checked = taskChecked ? " checked" : ""
                items.append("<li class=\"task-list-item\"><input type=\"checkbox\"\(checked) disabled> \(inlineMarkdown(text))</li>")
            } else {
                items.append("<li>\(inlineMarkdown(text))</li>")
            }
        }
        return "<ul>\(items.joined())</ul>"
    }

    private static func renderOrderedList(_ lines: [String]) -> String {
        var items = [String]()
        for line in lines {
            if let range = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let text = String(line[range.upperBound...])
                items.append("<li>\(inlineMarkdown(text))</li>")
            }
        }
        return "<ol>\(items.joined())</ol>"
    }

    private static func renderTable(_ lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }

        func cells(_ row: String) -> [String] {
            var s = row.trimmingCharacters(in: .whitespaces)
            if s.hasPrefix("|") { s = String(s.dropFirst()) }
            if s.hasSuffix("|") { s = String(s.dropLast()) }
            return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        let headers = cells(lines[0])
        var html = "<table><thead><tr>"
        for h in headers { html += "<th>\(inlineMarkdown(h))</th>" }
        html += "</tr></thead><tbody>"

        for row in lines.dropFirst() {
            html += "<tr>"
            for cell in cells(row) { html += "<td>\(inlineMarkdown(cell))</td>" }
            html += "</tr>"
        }
        html += "</tbody></table>"
        return html
    }

    // MARK: - Inline Markdown

    static func inlineMarkdown(_ text: String) -> String {
        var s = text

        // Images before links
        s = applyRegex(s, pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#) { m in
            "<img src=\"\(m[2])\" alt=\"\(escapeHTML(m[1]))\">"
        }

        // Links
        s = applyRegex(s, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#) { m in
            "<a href=\"\(escapeHTMLAttr(m[2]))\">\(m[1])</a>"
        }

        // Bold+italic
        s = applyRegex(s, pattern: #"\*\*\*(.+?)\*\*\*"#) { m in "<strong><em>\(m[1])</em></strong>" }
        s = applyRegex(s, pattern: #"___(.+?)___"#)          { m in "<strong><em>\(m[1])</em></strong>" }

        // Bold
        s = applyRegex(s, pattern: #"\*\*(.+?)\*\*"#) { m in "<strong>\(m[1])</strong>" }
        s = applyRegex(s, pattern: #"__(.+?)__"#)      { m in "<strong>\(m[1])</strong>" }

        // Italic
        s = applyRegex(s, pattern: #"\*(.+?)\*"#) { m in "<em>\(m[1])</em>" }
        s = applyRegex(s, pattern: #"_(.+?)_"#)   { m in "<em>\(m[1])</em>" }

        // Strikethrough
        s = applyRegex(s, pattern: #"~~(.+?)~~"#) { m in "<del>\(m[1])</del>" }

        // Inline code (escape HTML inside)
        s = applyRegex(s, pattern: #"`([^`]+)`"#) { m in "<code>\(escapeHTML(m[1]))</code>" }

        // Hard line break (two trailing spaces)
        s = s.replacingOccurrences(of: "  \n", with: "<br>")

        return s
    }

    // MARK: - Utilities

    private static func applyRegex(_ input: String, pattern: String, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return input
        }
        let ns = input as NSString
        var result = ""
        var lastEnd = input.startIndex

        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        for match in matches {
            let matchRange = Range(match.range, in: input)!
            result += input[lastEnd..<matchRange.lowerBound]
            var groups = [String]()
            for g in 0..<match.numberOfRanges {
                if let r = Range(match.range(at: g), in: input) {
                    groups.append(String(input[r]))
                } else {
                    groups.append("")
                }
            }
            result += transform(groups)
            lastEnd = matchRange.upperBound
        }
        result += input[lastEnd...]
        return result
    }

    static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func escapeHTMLAttr(_ s: String) -> String {
        escapeHTML(s).replacingOccurrences(of: "\"", with: "&quot;")
    }
}
