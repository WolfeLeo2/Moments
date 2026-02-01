#!/bin/bash
# Print to AppLogger Migration Script
# Run from the project root: ./scripts/migrate_prints.sh

PROJECT_DIR="lib"

echo "🔍 Finding files with print statements..."
FILES=$(grep -rl "print(" "$PROJECT_DIR" --include="*.dart" | grep -v ".g.dart" | grep -v "app_logger.dart")

for file in $FILES; do
  echo "Processing: $file"
  
  # Extract class name from file path for logger tag
  BASENAME=$(basename "$file" .dart)
  CLASS_NAME=$(echo "$BASENAME" | sed -E 's/(^|_)([a-z])/\U\2/g')
  
  # Add import if not present
  if ! grep -q "app_logger.dart" "$file"; then
    sed -i '' "1i\\
import 'package:moments/core/services/app_logger.dart';
" "$file"
  fi
  
  # Add logger instance after imports if not present
  if ! grep -q "final _log = AppLogger" "$file"; then
    # Find the last import line and add logger after it
    LAST_IMPORT=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    if [ -n "$LAST_IMPORT" ]; then
      sed -i '' "${LAST_IMPORT}a\\
\\
final _log = AppLogger('$CLASS_NAME');
" "$file"
    fi
  fi
done

echo ""
echo "✅ Imports and loggers added!"
echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo "Now manually replace print() calls with appropriate logger methods:"
echo "  - print('Error...')     → _log.e('Error...', error: e)"
echo "  - print('Warning...')   → _log.w('Warning...')"
echo "  - print('Info...')      → _log.i('Info...')"
echo "  - print('Debug...')     → _log.d('Debug...')"
echo ""
echo "Run this to find remaining print statements:"
echo "  grep -rn 'print(' lib/ --include='*.dart' | grep -v .g.dart | grep -v debugPrint"
