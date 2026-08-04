# Candy Match

Flutter + [Flame](https://flame-engine.org) ile yazılmış match-3 (üç eşle) mobil oyunu.

## Çalıştırma

```bash
cd ~/candy_match

# Emulator'ı başlat (arka planda)
emulator -avd candy_pixel &

# Bağlı cihazları gör
flutter devices

# Oyunu çalıştır (r = hot reload, R = hot restart, q = çıkış)
flutter run
```

Fiziksel telefonda denemek için telefonda **Geliştirici seçenekleri → USB hata ayıklama**'yı
açıp USB ile bağlaman yeterli; `flutter run` cihazı otomatik bulur.

## Ekran akışı

```
Açılış (yükleme)  →  Menü  →  Oyun  →  Oyun bitti kartı
                       ↑        │            │
                       └────────┴── Menüye ──┘
```

Yeni oyun her zaman menüden başlıyor; oyun içindeki 🏠 düğmesi ve oyun sonu
kartındaki **MENÜYE DÖN** aynı yere çıkıyor.

### Devam et

Menüdeki **DEVAM ET**, yarım kalan oyunu bıraktığın yerden açar: tahtanın her
hücresi, skor, hamle ve seviye aynen geri gelir (`GameSaveStore`).

- Kayıt, tahta her oturduğunda yazılıyor (açılış dökülmesinden sonra ve her
  hamlenin sonunda). Animasyon ortasında ızgara eksik olabileceği için o anda
  kayıt atlanıyor, bir önceki geçerli kalıyor.
- **Oyun bitince kayıt siliniyor**, dolayısıyla DEVAM ET menüden kayboluyor.
- Kayıt varken DEVAM ET birincil, YENİ OYUN ikincil düğme oluyor.

## Seviyeler

Her `2000` puanda bir seviye atlanıyor ve **seviye sayısı sınırsız**.

### Bilgi ipucu

Seviye çubuğundaki ⓘ düğmesi, zorluğun nasıl arttığını anlatan bir kart açıyor.

- Kart **ilk oyunda kendiliğinden** açılıyor ve **5 saniye** sonra kapanıyor.
- Gösterildiği bilgisi cihazda saklanıyor (`TipStore`), bir daha kendiliğinden
  açılmıyor.
- ⓘ düğmesine basmak kartı her zaman tekrar açıyor (basılıysa kapatıyor).

### Görünüm

Seviyeyle değişen tek şey **tahta rengi**: `LevelTheme.forLevel(n)` tahta
panelinin rengini her seviyede `47°` döndürüyor (47, 360'ın böleni olmadığı
için uzun süre tekrar etmiyor). Şekerlerin **şekli ve rengi sabit** —
oyuncu her seviyede aynı elemanlarla oynuyor, yeniden tanıma yapmak zorunda
kalmıyor. Arka plan ve vurgu rengi de sabit.

Seviye atlarken efekt **her seviyede değişiyor** (dörtlü döngü):

| Seviye % 4 | Efekt |
|---|---|
| 1 | Merkezden açılan dört şok halkası + sarsıntı |
| 2 | Tahtayı tarayan ışınlar |
| 3 | Yıldız patlaması + ekran parlaması + güçlü sarsıntı |
| 0 | Konfeti yağmuru + ekran parlaması |

Hepsinde `levelup.wav` (yükselen beşli merdiven) çalıyor ve ekranın altındaki
**seviye çubuğu** bir sonraki seviyeye kalan puanı gösteriyor.

## En yüksek skor

Rekor cihazda `shared_preferences` ile saklanıyor (`HighScoreStore`).

- **Menüde** kupa rozeti olarak, nefes alan altın bir haleyle gösteriliyor.
  Henüz rekor yoksa rozet hiç görünmüyor — boş bir "0" göstermek yerine ilk
  skoru hedef bırakıyoruz.
- **Oyun içinde** HUD'da 🏆 REKOR kartı var. Skor rekoru yakaladığı an kart
  altın çerçeveye bürünüp "lider sensin" yazıyor.
- **Rekor kırıldığı an** kutlama: `record.wav` fanfarı, ekranın üstünden
  dökülen konfeti, altın parlama, hafif sarsıntı ve **"YENİ REKOR!"** yazısı.
  Kutlama oyun başına bir kez ve yalnızca gerçek bir rekor varken çalışıyor —
  ilk oyunda "0'ı geçtin" diye kutlamıyor.
- Rekor skor arttıkça anında yazılıyor, oyun sonunu beklemiyor; uygulama
  kapansa bile kaybolmuyor.

Depolama yanıt vermezse (kısıtlı cihaz) 5 saniyede zaman aşımına düşüyor ve
oyun rekorsuz devam ediyor — açılış ekranı kilitlenmiyor.

- **Açılış**: vektör illüstrasyon, oyun adı ve **gerçek** bir yükleme çubuğu —
  ses dosyaları burada yükleniyor, çubuk sahte değil. Ses altyapısı yanıt
  vermezse 8 saniyede zaman aşımına düşüp oyun sessiz devam ediyor, ekran
  kilitlenmiyor.
- **Menü**: `YENİ OYUN` ve `ÇIKIŞ`.
- **Oyun bitti**: hamle kalmadığında ekran beyazlayıp sarsılıyor, iniş motifi
  (`gameover.wav`) çalıyor ve skor sıfırdan sayarak yükselen bir kartla
  gösteriliyor. `MENÜYE DÖN` menüye çıkar, `ÇIKIŞ` uygulamadan çıkar.

> Tahta artık hamle kalmadığında karıştırılmıyor — oyun biter. 8x11 ve 6 renkle
> bu nadir bir durum; hamle sınırlı bir mod istenirse `CandyGame` içine kolayca
> eklenebilir.

## Depo güvenliği

Gizli bilgilerin yanlışlıkla commit edilmesini engelleyen bir git kancası var.
Depoyu yeni klonladıysan bir kez çalıştır:

```bash
git config core.hooksPath tool/git-hooks
```

`tool/git-hooks/pre-commit` şunları engeller:

- Dosya adına göre: `*.jks`, `*.keystore`, `*.p12`, `*.pem`, `key.properties`,
  `.env*`, `google-services.json`, `id_rsa` …
- İçeriğe göre: özel anahtar blokları, `storePassword`/`keyPassword` satırları,
  Google/GitHub/OpenAI/AWS/Slack token biçimleri

Yanlış alarm olduğuna eminsen `git commit --no-verify` ile geçebilirsin.

> Bu kanca **yereldir** ve GitHub'ın secret scanning'inin yerini tutmaz; o
> özellik private repolarda ücretli. Asıl koruma, keystore ve
> `key.properties`'i hiçbir zaman depo klasörüne koymamak.

## Kod yapısı

| Dosya | Sorumluluk |
|---|---|
| `lib/main.dart` | Uygulama girişi, paylaşılan `AudioController` |
| `lib/ui/splash_screen.dart` | Açılış ekranı ve yükleme çubuğu |
| `lib/ui/menu_screen.dart` | Ana menü |
| `lib/ui/candy_artwork.dart` | Açılış/menü illüstrasyonu (vektör, asset yok) |
| `lib/ui/game_page.dart` | `GameWidget` ve overlay'lerin bağlanması |
| `lib/ui/game_over_overlay.dart` | Oyun sonu kartı |
| `lib/game/candy_game.dart` | Oyunun kökü (`FlameGame`), yerleşim, skor/hamle/seviye, kamera sarsıntısı, kutlamalar |
| `lib/game/level_theme.dart` | Sabit şeker paleti + seviyeye göre üretilen tahta rengi |
| `lib/game/high_score_store.dart` | Rekorun cihazda saklanması |
| `lib/ui/level_bar.dart` | Alttaki seviye çubuğu, bilgi düğmesi ve ipucu kartı |
| `lib/game/game_save_store.dart` | Yarım kalan oyunun kaydı |
| `lib/game/tip_store.dart` | İpucunun gösterilip gösterilmediği |
| `lib/ui/high_score_badge.dart` | Menüdeki kupa rozeti |
| `lib/game/board.dart` | Izgara, girdi işleme, eşleşme/küme bulma, bomba, patlama, yerçekimi |
| `lib/game/candy.dart` | Tek bir şekerin çizimi (renk + şekil, bomba görünümü) |
| `lib/game/effects.dart` | Parçacık patlamaları, şok dalgası, uçuşan yazılar |
| `lib/game/audio_controller.dart` | Ses efektleri, `AudioPool`, sessize alma |
| `lib/ui/hud_overlay.dart` | Skor / rekor kartları, ses ve menü düğmeleri |

### Nasıl çalışıyor

- Tahta `8x11`, `6` farklı şeker türü. Her tür hem renk hem şekille çiziliyor,
  böylece renk körlüğü olan oyuncular da ayırt edebiliyor.
- Şekerler **hacimli** çiziliyor: altta yumuşak gölge, gövdede sol üstten
  aydınlatılmış radyal gradyan, alt kenarda ters ışık (rim light) ve üstte
  keskin parlama. Şekil ve renk seviyeden bağımsız.
- **Yeni tahta yukarıdan dökülerek geliyor**: sütunlar 50 ms arayla sırayla
  düşüyor, her şeker inişini küçük bir sekmeyle (`Curves.bounceOut`)
  tamamlıyor ve `pour.wav` (pentatonik boncuk akışı) çalıyor. Animasyon
  boyunca girdi kapalı. Hem "Yeni Oyun" hem "Tekrar Oyna" böyle başlıyor.

  Şekerler `ClipComponent` ile kırpılan bir katmanda duruyor: dökülürken
  tahtanın dışında görünmüyor, ızgaranın üst kenarının arkasından çıkıyorlar.
  Parçacık, şimşek, ışın ve yazı efektleri bilerek bu katmanın **dışında** —
  onların tahtadan taşması gerekiyor.

  > Animasyon `onLoad` içinde beklenemez: Flame bileşeni ancak `onLoad`
  > bittikten sonra ekrana basıyor, o yüzden şekerler düşerken görünmezdi.
  > Bu yüzden `onMount` içinde başlatılıyor.
- Kamera **sabit genişlikli**: dünya her cihazda tam 720 birim geniş, yükseklik
  ekran oranından hesaplanıyor (`camera.viewfinder.zoom = size.x / 720`).
  Böylece tüm ölçüler tek referansa göre ayarlanabiliyor **ve** uzun
  telefonlarda ekranın üstünde/altında bant kalmıyor.
- Tahta `8x11` ve kenar boşluğu 14 birim: enin neredeyse tamamını kaplıyor.
  HUD ile alttaki seviye çubuğu arasındaki alana ortalanıyor.
- Bir hamle: iki komşu şeker takas edilir → eşleşme oluşmazsa animasyonla geri alınır.
- Eşleşme varsa patlar, üstteki şekerler düşer, tahtanın üstünden yenileri gelir ve
  yeni eşleşme kalmayana kadar bu döngü sürer (**cascade**). Zincirin her adımı
  daha çok puan verir: `patlayan sayısı × 10 × zincir sırası`.

### Ses tablosu

Her durumun ayrı sesi var:

| Durum | Ses |
|---|---|
| Tahta dökülüyor | `pour` |
| Seviye atlandı | `levelup` |
| Yeni rekor | `record` |
| Oyun bitti | `gameover` |
| Takas | `swap` |
| Geçersiz hamle | `invalid` |
| Normal patlama | `pop1..pop6` (zincire göre tizleşir) |
| Özel şeker doğdu | `bomb_create` |
| 💣 bomba patladı (3x3) | `bomb` |
| 💿 renk bombası patladı (renk süpürme) | `rainbow` |
| 💣+💣 çapraz patlama | `cross` |
| 💿+💿 mega patlama | `mega` |
| Zincir tebriki | `praise1..praise3` |

### Ses

`assets/audio/` altındaki tüm sesler `tool/gen_audio.py` ile **sıfırdan
sentezlenmiştir** (saf Python, harici kütüphane yok). Telifli hiçbir ses
kullanılmadığı için Play Store'a çıkarken lisans sorunu yok. Sesleri
değiştirmek için betiği düzenleyip çalıştırman yeterli:

```bash
python3 tool/gen_audio.py
```

Patlama sesleri pentatonik bir dizi (`pop1..pop6`) — zincir uzadıkça bir üst
nota çalınıyor, böylece arka arkaya patlamalar ezgi gibi duyuluyor.

## Ayarlar

`lib/game/candy_game.dart` içinde `rows`, `cols`; `lib/game/candy.dart` içinde
`typeCount` ve renk paleti değiştirilebilir.

## Görsel asset eklemek

Şu an şekerler `Candy.render` içinde `Canvas` ile çiziliyor. Gerçek görsellere
geçmek için:

1. PNG'leri `assets/images/` altına koy, `pubspec.yaml`'da `assets:` bölümüne ekle.
2. `Candy`'yi `SpriteComponent` yapıp `render` metodunu kaldır.

## Play Store'a çıkmadan önce

- **Paket adı** şu an `com.ozge.candy_match` (`android/app/build.gradle.kts` içindeki
  `applicationId`). Play Store'da benzersiz olmalı ve yayınlandıktan sonra
  değiştirilemez — yayına çıkmadan önce kendi seçtiğin adla değiştir.
- `flutter build appbundle --release` ile imzalı bir `.aab` üretilmeli; bunun için
  `android/key.properties` ve bir keystore oluşturman gerekir.
  Bkz. https://docs.flutter.dev/deployment/android
- Uygulama adı `android/app/src/main/AndroidManifest.xml` içindeki `android:label`.

## Depoda olmayanlar

Aşağıdaki dosyalar `.gitignore` ile hariç tutuldu:

- `lib/game/board.dart` — eşleşme motoru: dizi ve kare bulma, küme birleştirme,
  özel şeker doğurma, patlama yayılımı, yerçekimi, yeniden doldurma, hamle
  ipucu ve oyun sonu kontrolü
- `test/bomb_test.dart`, `test/rainbow_swap_test.dart`, `test/hint_test.dart` —
  yukarıdaki kuralların testleri

Bu yüzden `flutter run` ve `flutter test` bu depo tek başına klonlandığında
çalışmaz. Depo arayüzü, şeker çizimini, efektleri, ses/kayıt katmanlarını ve
proje iskeletini gösteriyor.
