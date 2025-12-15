import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sticker picker bottom sheet
class StickerPicker extends StatefulWidget {
  final EditorController controller;

  const StickerPicker({super.key, required this.controller});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Emoji categories
  static const Map<String, List<String>> _emojiCategories = {
    'Smileys': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '😉',
      '😍',
      '🥰',
      '😘',
      '😜',
      '🤪',
      '😎',
      '🤩',
      '🥳',
      '😤',
      '😱',
      '🤯',
      '😴',
      '🤢',
      '🤮',
    ],
    'Gestures': [
      '👍',
      '👎',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '🤝',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤞',
      '✌️',
      '🤟',
      '🤘',
      '👌',
      '🤌',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '✋',
      '🤚',
      '🖐️',
    ],
    'Hearts': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❤️‍🔥',
      '❤️‍🩹',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
    ],
    'Animals': [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🙈',
      '🙉',
      '🙊',
      '🐔',
      '🐧',
      '🐦',
      '🦅',
      '🦆',
      '🦉',
      '🐺',
    ],
    'Food': [
      '🍎',
      '🍐',
      '🍊',
      '🍋',
      '🍌',
      '🍉',
      '🍇',
      '🍓',
      '🫐',
      '🍒',
      '🍑',
      '🥭',
      '🍍',
      '🥥',
      '🥝',
      '🍔',
      '🍟',
      '🍕',
      '🌭',
      '🥪',
      '🌮',
      '🌯',
      '🍜',
      '🍝',
      '🍣',
    ],
    'Travel': [
      '✈️',
      '🚗',
      '🚕',
      '🚌',
      '🚎',
      '🏎️',
      '🚓',
      '🚑',
      '🚒',
      '🛵',
      '🏍️',
      '🚲',
      '🛴',
      '🚁',
      '🛸',
      '🚀',
      '🛶',
      '⛵',
      '🚤',
      '🛳️',
      '⛴️',
      '🗼',
      '🗽',
      '🏰',
      '🗿',
    ],
    'Activities': [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🥎',
      '🎾',
      '🏐',
      '🏉',
      '🥏',
      '🎱',
      '🪀',
      '🏓',
      '🏸',
      '🏒',
      '🥊',
      '🎯',
      '⛳',
      '🎿',
      '🛷',
      '🥌',
      '🎮',
      '🎲',
      '🎭',
      '🎨',
      '🎬',
    ],
    'Objects': [
      '📱',
      '💻',
      '🖥️',
      '📷',
      '📸',
      '🎥',
      '📺',
      '🔮',
      '💎',
      '💰',
      '💳',
      '🎁',
      '🏆',
      '🥇',
      '🥈',
      '🥉',
      '🎖️',
      '🏅',
      '🔑',
      '🔒',
      '💡',
      '📚',
      '✏️',
      '🖊️',
      '🎯',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _emojiCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add Sticker',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.borderBlack,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: _emojiCategories.keys.map((category) {
              return Tab(text: category);
            }).toList(),
          ),

          // Emoji grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _emojiCategories.entries.map((entry) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final emoji = entry.value[index];
                    return GestureDetector(
                      onTap: () {
                        widget.controller.addSticker(
                          emoji,
                          isEmoji: true,
                          emojiChar: emoji,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text input dialog
class TextInputDialog extends StatefulWidget {
  final EditorController controller;
  final String? initialText;
  final String? editingItemId;

  const TextInputDialog({
    super.key,
    required this.controller,
    this.initialText,
    this.editingItemId,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _textController;
  Color _selectedColor = Colors.white;
  String _selectedFont = 'Bangers';
  bool _hasBackground = false;
  Color _backgroundColor = Colors.black;

  static const List<String> _fonts = [
    'Bangers',
    'Bebas Neue',
    'Pacifico',
    'Roboto',
    'Permanent Marker',
    'Dancing Script',
  ];

  static const List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Text input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  style: GoogleFonts.inter(fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Enter text...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Font selector
              Text(
                'Font',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fonts.length,
                  itemBuilder: (context, index) {
                    final font = _fonts[index];
                    final isSelected = font == _selectedFont;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFont = font),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.borderBlack
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.borderBlack
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Aa',
                            style: _getFontStyle(font).copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.borderBlack,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Color selector
              Text(
                'Text Color',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: color == Colors.white
                            ? [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Background toggle
              Row(
                children: [
                  Text(
                    'Background',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _hasBackground,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (value) =>
                        setState(() => _hasBackground = value),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add button
              GestureDetector(
                onTap: () {
                  if (_textController.text.trim().isNotEmpty) {
                    if (widget.editingItemId != null) {
                      widget.controller.updateTextItem(
                        widget.editingItemId!,
                        text: _textController.text,
                        textColor: _selectedColor,
                        backgroundColor: _hasBackground
                            ? _backgroundColor
                            : null,
                        fontFamily: _selectedFont,
                      );
                    } else {
                      widget.controller.setTextColor(_selectedColor);
                      widget.controller.setTextFontFamily(_selectedFont);
                      widget.controller.addText(_textController.text);

                      // Update background if needed
                      if (_hasBackground) {
                        final item = widget.controller.selectedItem;
                        if (item != null) {
                          widget.controller.updateTextItem(
                            item.id,
                            backgroundColor: _backgroundColor,
                          );
                        }
                      }
                    }
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.editingItemId != null ? 'Update' : 'Add Text',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _getFontStyle(String fontFamily) {
    switch (fontFamily) {
      case 'Bangers':
        return GoogleFonts.bangers();
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue();
      case 'Pacifico':
        return GoogleFonts.pacifico();
      case 'Roboto':
        return GoogleFonts.roboto();
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker();
      case 'Dancing Script':
        return GoogleFonts.dancingScript();
      default:
        return GoogleFonts.inter();
    }
  }
}
