#!/bin/bash
# Bu dosyayı "build_release.sh" adıyla kopyalayıp kendi ödüllü reklam birimi
# kimliğini yaz. Gerçek dosya .gitignore'da olduğu için depoya girmez.
#
#   cp tool/build_release.example.sh tool/build_release.sh
#   chmod +x tool/build_release.sh
#
# Biçimi: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ  (eğik çizgiye dikkat)
set -euo pipefail

REWARDED_ANDROID="ca-app-pub-3940256099942544/5224354917"
TARGET="${1:-appbundle}"

flutter build "$TARGET" --release \
  --dart-define=ADMOB_REWARDED_ANDROID="$REWARDED_ANDROID"
