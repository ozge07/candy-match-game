# Play Store hazırlığı — Candy Match

Bu dosya Play Console'a girilecek bilgileri bir arada tutuyor; her yayında
formu sıfırdan doldurmamak için.

## Kimlik

| Alan | Değer |
| --- | --- |
| Geliştirici adı | Blue Labs Games (dört oyunda da aynı) |
| Uygulama adı | Candy Match |
| Paket adı | `com.bluelabsgames.candymatch` (**bir daha değiştirilemez**) |
| Kategori | Oyun → Bulmaca |
| İçerik derecelendirmesi | Herkes (şiddet, satın alma, kullanıcı etkileşimi yok) |
| Ücret | Ücretsiz, uygulama içi satın alma yok |
| Diller | Türkçe, İngilizce |

## Kısa açıklama (80 karakter sınırı)

> Üçlü eşleştir, patlat, seviye atla. Süre yok, hamle sınırı yok.

(63 karakter)

## Uzun açıklama

> Aynı şekilden üçünü yan yana getir, patlat, puanı topla.
>
> • Süre baskısı yok — istediğin kadar düşün
> • Her 2000 puanda seviye atlıyorsun; yeni şeker türleri geliyor
> • Bomba ve gökkuşağı şekerleri: dört ve beşli eşleşmelerin ödülü
> • Hamlen kalmadığında kısa bir reklamla devam edebilirsin
> • Yarım kalan oyun kaydediliyor, kaldığın yerden devam
> • Türkçe ve İngilizce
> • İnternet gerekmez, hesap gerekmez

## Görseller

| Varlık | Dosya |
| --- | --- |
| Uygulama ikonu 512×512 | `store/icon-512.png` |
| Öne çıkan görsel 1024×500 | `store/feature-1024x500.png` |
| Ekran görüntüleri | `store/screenshots/en/` — Ana menü, Oynanış |

Görsellerin tamamı `tool/gen_icon.py` ile koddan üretiliyor; dışarıdan
lisanslı dosya kullanılmıyor. Ekran görüntüleri her iki dil kaydında da
kullanılabilir — Play dile özel görüntü zorunlu tutmuyor.

## Data Safety formu

Ayrıntılı yanıtlar: [`../store/DATA_SAFETY.md`](../store/DATA_SAFETY.md)

Özet: uygulamanın kendisi veri toplamıyor; toplanan her şey Unity Ads reklam
SDK'sından geliyor ve reklamcılık amacıyla Google ile paylaşılıyor.

## Gizlilik politikası

Sayfa: `docs/privacy-policy.html` (Türkçe + İngilizce, tek dosya).

Yayınlamak için **Settings → Pages → Source: main / docs**. Adres:

    https://ozge07.github.io/candy-match-game/privacy-policy.html

Bu adres Play Console'da gizlilik politikası alanına girilecek.

## Hesaplar

Hangi Google hesabının Play Console ve Unity Ads'u sahiplendiği **Traffic Escape
deposundaki** `docs/ACCOUNTS.md` dosyasında — o dosya depoya girmiyor.
Dört oyun aynı hesapları kullanıyor, bilgi tek yerde duruyor.

Mağazada görünen kimlik: geliştirici adı **Blue Labs Games**, destek
e-postası `bluelabsgames@gmail.com`.

## Yayın öncesi kontrol listesi

- [x] Paket adı `com.bluelabsgames.candymatch` olarak ayarlandı
- [x] Uygulama adı ve uyarlanabilir ikon hazır
- [x] Açılış ekranı oyunun koyu paletiyle uyumlu (beyaz sıçrama yok)
- [x] R8 (kod küçültme) ve kaynak temizliği açık
- [x] 16 KB sayfa hizalaması — Android 15 zorunluluğu, yerel kütüphaneler uyumlu
- [x] İzinler yalnızca Unity Ads'un gerektirdikleri; fazladan izin yok
- [x] İmzalama ortak anahtarla (`~/.android-keystores/bluelabsgames.jks`, takma ad bu oyuna özel)
- [x] Unity Ads kimlikleri kaynak kodda değil; hata ayıklamada her zaman test kimliği
- [x] Gizlilik politikası sayfası hazır
- [x] Mağaza ikonu, öne çıkan görsel ve ekran görüntüleri hazır
- [ ] GitHub Pages açıldı ve politika adresi Play Console'a girildi
- [ ] Play Console'da uygulama oluşturuldu
- [ ] `tool/build_release.sh` ile imzalı AAB üretilip yüklendi
- [ ] Unity Ads'da uygulama Play kaydına bağlandı
