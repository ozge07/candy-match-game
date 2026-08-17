# Play Console — Data Safety formu için cevaplar

Candy Match'in **release** derlemesi incelenerek çıkarıldı. Formu doldururken
bu tabloyu kullan.

## Özet

Uygulamanın kendisi **hiçbir veri toplamıyor**. Toplanan her şey Unity Ads
reklam SDK'sından geliyor. Google, Unity Ads'u kullanan geliştiricinin bu verileri
"toplanıyor" olarak beyan etmesini istiyor.

SDK `main.dart` içinde **oyun açılışında** başlatılıyor (`ads.initialise()`),
kullanıcı reklam izlemeyi seçmeden. Yani toplama "reklam izlerse" koşuluna
bağlı değil; forma da öyle beyan ediliyor.

## Form cevapları

**Uygulamanız kullanıcı verisi topluyor veya paylaşıyor mu?** → **Evet**
(reklam SDK'sı nedeniyle)

**Verileriniz aktarım sırasında şifreleniyor mu?** → **Evet** (Unity Ads HTTPS
kullanıyor)

**Kullanıcılar verilerinin silinmesini isteyebiliyor mu?** → **Hayır**
(uygulamanın kendi topladığı veri yok; reklam kimliği cihaz ayarlarından
sıfırlanabiliyor)

### Toplanan veri türleri

| Kategori | Veri türü | Toplanıyor | Paylaşılıyor | Amaç | Zorunlu mu |
|---|---|---|---|---|---|
| Konum | Yaklaşık konum | Evet | Evet | Reklamcılık | İsteğe bağlı |
| Uygulama etkinliği | Uygulama içi etkileşimler | Evet | Evet | Reklamcılık, analiz | İsteğe bağlı |
| Cihaz veya diğer kimlikler | Cihaz/diğer kimlikler (reklam kimliği) | Evet | Evet | Reklamcılık | İsteğe bağlı |

"Paylaşılıyor" evet, çünkü veri üçüncü tarafa (**Unity Technologies**) gidiyor.

### Toplanmayanlar

Kişisel bilgi (isim, e-posta, telefon), finansal bilgi, sağlık bilgisi,
mesajlar, fotoğraf/video, ses, kişiler, takvim, dosyalar, arama geçmişi,
SMS — **hiçbiri toplanmıyor**.

## Reklam kimliği beyanı

Play Console ayrı olarak "Uygulamanız reklam kimliği kullanıyor mu?" diye
soruyor → **Evet**, reklamcılık amacıyla.

## Kapalı test (closed testing) — beyan aynı kalıyor

Kapalı testte paket `tool/build_qa.sh appbundle` ile üretiliyor;
`UNITY_TEST_MODE=true` geçtiği için testçiler **test reklamı** görüyor
(gelir yazmaz, gösterim sayılmaz, geçersiz trafik riski yok).

**Data Safety formunda hiçbir şey değişmiyor.** Test modu yalnızca hangi
reklam videosunun oynatılacağını değiştiriyor; SDK yine başlatılıyor, reklam
kimliği yine okunuyor, izinler manifest birleşiminden geldiği için birebir
aynı. Dolayısıyla kapalı testten üretime geçerken formu yeniden doldurmak
gerekmiyor — bir kez doğru doldur, öyle kalsın.

Aynı sebeple gizlilik politikası da test/üretim ayrımı yapmıyor: her iki
durumda da doğru.

## Release izinleri (doğrulanmış)

Aşağıdakiler birleştirilmiş release manifest'inden okundu
(`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`,
17 Ağustos 2026'da yeniden üretilip doğrulandı). Tamamı reklam SDK'sından
geliyor; oyunun kendisi hiçbir izin istemiyor.

```
android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
android.permission.WAKE_LOCK
android.permission.FOREGROUND_SERVICE
android.permission.RECEIVE_BOOT_COMPLETED
com.google.android.gms.permission.AD_ID
android.permission.ACCESS_ADSERVICES_ATTRIBUTION
android.permission.ACCESS_ADSERVICES_TOPICS
```

Listeyi kendin doğrulamak istersen:

```bash
cd android && ./gradlew :app:processReleaseManifest
grep -oE 'android:name="[A-Za-z0-9_.]*permission[A-Za-z0-9_.]*"' \
  ../build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml \
  | sed 's/android:name="//;s/"//' | sort -u
```

> Not: bu listede `ACCESS_ADSERVICES_AD_ID` **yok** — daha önceki sürümde
> yanlışlıkla yazılmıştı. `RECEIVE_BOOT_COMPLETED` ise var ama eksikti.
> İkisi de düzeltildi.

## Gizlilik politikası

Yayında, herkese açık:

| Dil | Adres |
|---|---|
| Türkçe | <https://ozge07.github.io/candy-match-game/privacy-policy.html> |
| İngilizce | <https://ozge07.github.io/candy-match-game/privacy-policy-en.html> |

GitHub Pages `main` dalının `/docs` klasöründen yayınlıyor, HTTPS zorunlu.
Play Console'da kaydın diline göre ilgili adresi gir.

Politikanın "Reklam yazılımının topladıkları" tablosu yukarıdaki üç veri
türüyle **birebir aynı** olacak şekilde yazıldı — Play, formu politikayla
karşılaştırdığı için bu ikisi ayrışırsa uygulama reddediliyor. Birini
değiştirirsen diğerini de değiştir.
