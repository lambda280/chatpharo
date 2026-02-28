"
A MicTextStyler subclass that adds Noto Emoji font attributes for emoji Unicode
code points during Microdown rich-text composition.

When PostTextTreatment: is called on a text run, this styler scans each
character and applies a TextFontReference to the 'Noto Emoji' LogicalFont for
any character whose code point falls in an emoji Unicode block.  Characters
outside those ranges are unaffected, preserving all other font and style
attributes set by the composer.

The font is loaded lazily from the Pharo image's Fonts directory via
ensureEmojiFont.  If the font file is absent the styler degrades gracefully,
leaving emoji as un-rendered glyphs (the original behaviour).
"
Class {
	#name : 'ChatPharoEmojiTextStyler',
	#superclass : 'MicTextStyler',
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'initialization' }
ChatPharoEmojiTextStyler class >> ensureEmojiFont [
	"Register the Noto Emoji font with FreeTypeFontProvider if it is not already
	 loaded.  The font file NotoEmoji-Regular.ttf must exist in the Pharo image's
	 Fonts directory.  Silently does nothing when the file is absent so callers
	 can degrade gracefully."
	(FreeTypeFontProvider current families includesKey: 'Noto Emoji') ifFalse: [
		| fontFile updator |
		fontFile := FreeTypeFontProvider current imageRelativeFontFolder
			/ 'NotoEmoji-Regular.ttf'.
		fontFile exists ifFalse: [ ^ self ].
		updator := FreeTypeFontFileUpdator
			withFileInfoProvider: FreeTypeFontProvider current.
		updator updateFromFile: fontFile.
		FreeTypeFontProvider current buildFamilies ]
]

{ #category : 'testing' }
ChatPharoEmojiTextStyler >> isEmojiCodePoint: anInteger [
	"Return true if anInteger is in a Unicode block that contains emoji.
	 Covers Miscellaneous Technical (U+2300–U+23FF),
	        Miscellaneous Symbols (U+2600–U+27BF),
	        Emoticons / Emoji block ranges (U+1F300–U+1FAFF)."
	(anInteger >= 16r2300 and: [ anInteger <= 16r27BF ]) ifTrue: [ ^ true ].
	(anInteger >= 16r1F300 and: [ anInteger <= 16r1FAFF ]) ifTrue: [ ^ true ].
	^ false
]

{ #category : 'styling' }
ChatPharoEmojiTextStyler >> postTextTreatment: aText [
	"Add a Noto Emoji TextFontReference attribute at every character position that
	 falls in an emoji Unicode range so those glyphs are drawn from the emoji font
	 instead of rendering as empty boxes.

	 If Noto Emoji is not available the text is returned unchanged, preserving the
	 existing (box-glyph) behaviour."
	| emojiAttr |
	self class ensureEmojiFont.
	(FreeTypeFontProvider current families includesKey: 'Noto Emoji') ifFalse: [
		^ super postTextTreatment: aText ].
	emojiAttr := TextFontReference toFont:
		(LogicalFont familyName: 'Noto Emoji' pointSize: 12).
	1 to: aText size do: [ :i |
		(self isEmojiCodePoint: (aText string at: i) asInteger)
			ifTrue: [ aText addAttribute: emojiAttr from: i to: i ] ].
	^ aText
]
