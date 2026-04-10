import Cocoa

/// Wandelt Markdown direkt in NSAttributedString um – kein WebKit, sandbox-sicher.
struct MarkdownAttributedRenderer {

    // MARK: - Fonts & Colors

    private static let bodyFont   = NSFont.systemFont(ofSize: 14, weight: .regular)
    private static let codeFont   = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private static let h1Font     = NSFont.systemFont(ofSize: 28, weight: .bold)
    private static let h2Font     = NSFont.systemFont(ofSize: 22, weight: .bold)
    private static let h3Font     = NSFont.systemFont(ofSize: 18, weight: .semibold)
    private static let h4Font     = NSFont.systemFont(ofSize: 16, weight: .semibold)
    private static let h5Font     = NSFont.systemFont(ofSize: 14, weight: .semibold)
    private static let h6Font     = NSFont.systemFont(ofSize: 13, weight: .semibold)

    private static var textColor:       NSColor { .labelColor }
    private static var secondaryColor:  NSColor { .secondaryLabelColor }
    private static var codeBackground:  NSColor { NSColor(white: 0.5, alpha: 0.12) }
    private static var quoteColor:      NSColor { .secondaryLabelColor }
    private static var linkColor:       NSColor { .linkColor }
    private static var separatorColor:  NSColor { .separatorColor }

    // MARK: - Main

    static func render(_ markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                result.append(codeBlock(codeLines.joined(separator: "\n")))
                i += 1
                continue
            }

            // Horizontal rule
            if isHR(line) {
                result.append(horizontalRule())
                i += 1
                continue
            }

            // Header
            if let (level, text) = headerLevel(line) {
                result.append(header(text, level: level))
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].hasPrefix(">") {
                    let stripped = lines[i].hasPrefix("> ")
                        ? String(lines[i].dropFirst(2))
                        : String(lines[i].dropFirst(1))
                    quoteLines.append(stripped)
                    i += 1
                }
                result.append(blockquote(quoteLines.joined(separator: "\n")))
                continue
            }

            // Unordered list
            if isULItem(line) {
                var items: [String] = []
                while i < lines.count && isULItem(lines[i]) {
                    let body = lines[i].hasPrefix("- ") ? String(lines[i].dropFirst(2))
                             : lines[i].hasPrefix("* ") ? String(lines[i].dropFirst(2))
                             : String(lines[i].dropFirst(2))
                    items.append(body)
                    i += 1
                }
                result.append(unorderedList(items))
                continue
            }

            // Ordered list
            if isOLItem(line) {
                var items: [String] = []
                var n = 1
                while i < lines.count && isOLItem(lines[i]) {
                    if let range = lines[i].range(of: #"^\d+\.\s"#, options: .regularExpression) {
                        items.append(String(lines[i][range.upperBound...]))
                    }
                    i += 1
                    n += 1
                }
                result.append(orderedList(items))
                continue
            }

            // Table (header row followed by separator row |---|---|)
            if i + 1 < lines.count && isTableSeparator(lines[i + 1]) {
                var tableLines: [String] = [line]
                i += 2 // skip header + separator
                while i < lines.count && lines[i].contains("|") && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                    tableLines.append(lines[i])
                    i += 1
                }
                result.append(renderTable(tableLines))
                continue
            }

            // Empty line → spacing
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(NSAttributedString(string: "\n"))
                i += 1
                continue
            }

            // Paragraph
            var paraLines: [String] = []
            while i < lines.count {
                let l = lines[i]
                if l.trimmingCharacters(in: .whitespaces).isEmpty { break }
                if headerLevel(l) != nil { break }
                if l.hasPrefix(">") || l.hasPrefix("```") { break }
                if isHR(l) || isULItem(l) || isOLItem(l) { break }
                paraLines.append(l)
                i += 1
            }
            if !paraLines.isEmpty {
                result.append(paragraph(paraLines.joined(separator: " ")))
            }
        }

        return result
    }

    // MARK: - Block elements

    private static func header(_ text: String, level: Int) -> NSAttributedString {
        let font: NSFont
        switch level {
        case 1: font = h1Font
        case 2: font = h2Font
        case 3: font = h3Font
        case 4: font = h4Font
        case 5: font = h5Font
        default: font = h6Font
        }
        let ps = NSMutableParagraphStyle()
        ps.paragraphSpacingBefore = level <= 2 ? 18 : 12
        ps.paragraphSpacing = 6

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: ps
        ]
        let result = NSMutableAttributedString(string: text + "\n", attributes: attrs)

        // Underline for H1 / H2
        if level <= 2 {
            let line = NSMutableAttributedString(string: "\n")
            let linePS = NSMutableParagraphStyle()
            linePS.paragraphSpacing = 8
            line.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: line.length))
            line.addAttribute(.strikethroughColor, value: separatorColor, range: NSRange(location: 0, length: line.length))
            result.append(line)
        }
        return result
    }

    private static func paragraph(_ text: String) -> NSAttributedString {
        let ps = NSMutableParagraphStyle()
        ps.paragraphSpacing = 6
        ps.lineSpacing = 3
        let base: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: ps
        ]
        let result = NSMutableAttributedString()
        result.append(inlineMarkdown(text, baseAttributes: base))
        result.append(NSAttributedString(string: "\n"))
        return result
    }

    private static func codeBlock(_ code: String) -> NSAttributedString {
        let ps = NSMutableParagraphStyle()
        ps.paragraphSpacingBefore = 8
        ps.paragraphSpacing = 8
        ps.headIndent = 12
        ps.firstLineHeadIndent = 12
        ps.tailIndent = -12

        let attrs: [NSAttributedString.Key: Any] = [
            .font: codeFont,
            .foregroundColor: NSColor.systemTeal,
            .backgroundColor: codeBackground,
            .paragraphStyle: ps
        ]
        let display = code.isEmpty ? code : "\n" + code + "\n"
        return NSAttributedString(string: display + "\n", attributes: attrs)
    }

    private static func blockquote(_ text: String) -> NSAttributedString {
        let ps = NSMutableParagraphStyle()
        ps.headIndent = 20
        ps.firstLineHeadIndent = 20
        ps.paragraphSpacingBefore = 4
        ps.paragraphSpacing = 4

        let attrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: quoteColor,
            .paragraphStyle: ps
        ]
        return NSAttributedString(string: "❝ " + text + "\n", attributes: attrs)
    }

    private static func unorderedList(_ items: [String]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for item in items {
            let ps = NSMutableParagraphStyle()
            ps.headIndent = 20
            ps.firstLineHeadIndent = 4
            ps.paragraphSpacing = 2
            let base: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: ps
            ]
            let line = NSMutableAttributedString(string: "  • ")
            line.addAttributes(base, range: NSRange(location: 0, length: line.length))
            line.append(inlineMarkdown(item, baseAttributes: base))
            line.append(NSAttributedString(string: "\n"))
            result.append(line)
        }
        return result
    }

    private static func orderedList(_ items: [String]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, item) in items.enumerated() {
            let ps = NSMutableParagraphStyle()
            ps.headIndent = 24
            ps.firstLineHeadIndent = 4
            ps.paragraphSpacing = 2
            let base: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: ps
            ]
            let line = NSMutableAttributedString(string: "  \(index + 1). ")
            line.addAttributes(base, range: NSRange(location: 0, length: line.length))
            line.append(inlineMarkdown(item, baseAttributes: base))
            line.append(NSAttributedString(string: "\n"))
            result.append(line)
        }
        return result
    }

    private static func horizontalRule() -> NSAttributedString {
        let ps = NSMutableParagraphStyle()
        ps.paragraphSpacingBefore = 10
        ps.paragraphSpacing = 10
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 4),
            .foregroundColor: separatorColor,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: separatorColor,
            .paragraphStyle: ps
        ]
        return NSAttributedString(string: "\u{00A0}\n", attributes: attrs)
    }

    // MARK: - Inline Markdown

    static func inlineMarkdown(_ text: String, baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttributes)
        let baseFont = (baseAttributes[.font] as? NSFont) ?? bodyFont

        applyInlineRegex(to: result, pattern: #"`([^`]+)`"#) { (full, groups, range) in
            let inner = groups[1]
            return NSAttributedString(string: inner, attributes: [
                .font: codeFont,
                .foregroundColor: NSColor.systemTeal,
                .backgroundColor: codeBackground
            ])
        }

        applyInlineRegex(to: result, pattern: #"\*\*\*(.+?)\*\*\*"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: boldItalic(baseFont),
                .foregroundColor: baseAttributes[.foregroundColor] ?? textColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"\*\*(.+?)\*\*"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: bold(baseFont),
                .foregroundColor: baseAttributes[.foregroundColor] ?? textColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"__(.+?)__"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: bold(baseFont),
                .foregroundColor: baseAttributes[.foregroundColor] ?? textColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"\*(.+?)\*"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: italic(baseFont),
                .foregroundColor: baseAttributes[.foregroundColor] ?? textColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"_(.+?)_"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: italic(baseFont),
                .foregroundColor: baseAttributes[.foregroundColor] ?? textColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"~~(.+?)~~"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: baseFont,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: secondaryColor
            ])
        }
        applyInlineRegex(to: result, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#) { (_, groups, _) in
            NSAttributedString(string: groups[1], attributes: [
                .font: baseFont,
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: groups[2]
            ])
        }

        return result
    }

    // MARK: - Font helpers

    private static func bold(_ font: NSFont) -> NSFont {
        NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
    }
    private static func italic(_ font: NSFont) -> NSFont {
        NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
    }
    private static func boldItalic(_ font: NSFont) -> NSFont {
        italic(bold(font))
    }

    // MARK: - Regex helper

    private static func applyInlineRegex(
        to string: NSMutableAttributedString,
        pattern: String,
        replacement: (String, [String], NSRange) -> NSAttributedString
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        var offset = 0
        let original = string.string
        let matches = regex.matches(in: original, range: NSRange(original.startIndex..., in: original))
        for match in matches {
            guard let fullRange = Range(match.range, in: original) else { continue }
            var groups = [String]()
            for g in 0..<match.numberOfRanges {
                if let r = Range(match.range(at: g), in: original) {
                    groups.append(String(original[r]))
                } else { groups.append("") }
            }
            let nsRange = NSRange(location: match.range.location + offset, length: match.range.length)
            let repl = replacement(groups[0], groups, nsRange)
            string.replaceCharacters(in: nsRange, with: repl)
            offset += repl.length - match.range.length
        }
    }

    // MARK: - Block detection helpers

    private static func headerLevel(_ line: String) -> (Int, String)? {
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level) + " "
            if line.hasPrefix(prefix) {
                return (level, String(line.dropFirst(prefix.count)))
            }
        }
        return nil
    }

    private static func isHR(_ line: String) -> Bool {
        let s = line.replacingOccurrences(of: " ", with: "")
        return (s == "---" || s == "***" || s == "___") && s.count >= 3
    }

    private static func isULItem(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    private static func isOLItem(_ line: String) -> Bool {
        line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.contains("-") else { return false }
        let stripped = t
            .replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " ", with: "")
        return stripped.isEmpty
    }

    private static func parseTableCells(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func renderTable(_ lines: [String]) -> NSAttributedString {
        guard !lines.isEmpty else { return NSAttributedString() }

        let headerCells = parseTableCells(lines[0])
        let numCols = max(headerCells.count, 1)
        let dataRows = lines.dropFirst()

        let table = NSTextTable()
        table.numberOfColumns = numCols
        table.layoutAlgorithm = .automatic
        table.collapsesBorders = true
        table.hidesEmptyCells = false

        let result = NSMutableAttributedString()
        var headerBGColor: NSColor { NSColor(white: 0.5, alpha: 0.15) }
        var evenBGColor:   NSColor { NSColor(white: 0.5, alpha: 0.05) }
        var borderColor:   NSColor { .separatorColor }

        func cell(text: String, row: Int, col: Int, isHeader: Bool) -> NSAttributedString {
            let block = NSTextTableBlock(
                table: table,
                startingRow: row, rowSpan: 1,
                startingColumn: col, columnSpan: 1
            )
            block.backgroundColor = isHeader ? headerBGColor : (row % 2 == 0 ? .clear : evenBGColor)
            block.setBorderColor(borderColor)
            for edge in [NSRectEdge.minX, .maxX, .minY, .maxY] {
                block.setWidth(1,   type: .absoluteValueType, for: .border,  edge: edge)
                block.setWidth(6,   type: .absoluteValueType, for: .padding, edge: edge)
            }

            let ps = NSMutableParagraphStyle()
            ps.textBlocks = [block]
            ps.paragraphSpacing = 0
            ps.paragraphSpacingBefore = 0

            let attrs: [NSAttributedString.Key: Any] = [
                .font: isHeader ? NSFont.systemFont(ofSize: 13, weight: .semibold)
                                : NSFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: textColor,
                .paragraphStyle: ps
            ]
            let base = attrs
            let cellStr = NSMutableAttributedString()
            cellStr.append(inlineMarkdown(text, baseAttributes: base))
            cellStr.append(NSAttributedString(string: "\n", attributes: attrs))
            return cellStr
        }

        // Header row
        for (col, text) in headerCells.enumerated() {
            result.append(cell(text: text, row: 0, col: col, isHeader: true))
        }

        // Data rows
        for (rowIndex, line) in dataRows.enumerated() {
            let cells = parseTableCells(line)
            for col in 0..<numCols {
                let text = col < cells.count ? cells[col] : ""
                result.append(cell(text: text, row: rowIndex + 1, col: col, isHeader: false))
            }
        }

        // Spacing after table
        result.append(NSAttributedString(string: "\n"))
        return result
    }
}
