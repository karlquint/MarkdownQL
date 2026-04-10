# MarkdownQL

**Quick Look Plugin for macOS** – renders `.md` Markdown files directly in Finder Preview.

Just select any `.md` file in Finder and press **Space**.

![Preview Screenshot](screenshot.png)

## Features

- Headings H1–H6
- **Bold**, *Italic*, ~~Strikethrough~~
- `Inline code` and fenced code blocks
- Blockquotes
- Unordered and ordered lists
- Tables
- Links
- Horizontal rules
- Dark Mode support (automatic)

## Installation

### Option 1 – Direct Download (recommended)

1. Download the latest release from [Releases](../../releases) (`MarkdownQL.zip`)
2. Unzip and drag `MarkdownQL.app` into your **Applications** folder
3. **Launch the app once** (Right-click → Open → Open Anyway)
4. Reset Quick Look to activate the extension:
   ```bash
   qlmanage -r
   ```

That's it – `.md` files will now show a formatted preview in Finder when you press Space.

> **Note:** On first launch macOS will show a security warning because the app is not from the App Store. Right-click → Open → "Open Anyway" is only needed once.

### Option 2 – Build from Source (Xcode)

```bash
git clone https://github.com/karlquint/MarkdownQL.git
cd MarkdownQL
open MarkdownQL.xcodeproj
```

In Xcode: **Product → Archive → Distribute App → Custom → Copy App → Export**

Then install:
```bash
cp -r ~/Desktop/MarkdownQL.app /Applications/MarkdownQL.app
open /Applications/MarkdownQL.app
qlmanage -r
```

## Troubleshooting

**Preview not showing after installation?**
```bash
qlmanage -r
```

**Preview stopped working after a macOS update?**
1. Delete and reinstall the app from Applications
2. Launch it once
3. Run `qlmanage -r`

**Check if the extension is active:**
```bash
pluginkit -m | grep -i markdown
```
A `+` means active, `!` means there is a problem.

**Force re-enable the extension:**
```bash
pluginkit -e use -i com.quinthealthcare.MarkdownQL.MarkdownQLExtension
```

## Requirements

- macOS 12 Monterey or later
- No external dependencies

## Uninstall

```bash
rm -rf /Applications/MarkdownQL.app
qlmanage -r
```

## License

MIT License – free to use and modify.
