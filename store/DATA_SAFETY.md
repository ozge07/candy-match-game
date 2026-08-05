# Play Console — Data Safety formu için cevaplar

Candy Match'in **release** derlemesi incelenerek çıkarıldı. Formu doldururken
bu tabloyu kullan.

## Özet

Uygulamanın kendisi **hiçbir veri toplamıyor**. Toplanan her şey Google AdMob
reklam SDK'sından geliyor. Google, AdMob'u kullanan geliştiricinin bu verileri
"toplanıyor" olarak beyan etmesini istiyor.

## Form cevapları

**Uygulamanız kullanıcı verisi topluyor veya paylaşıyor mu?** → **Evet**
(reklam SDK'sı nedeniyle)

**Verileriniz aktarım sırasında şifreleniyor mu?** → **Evet** (AdMob HTTPS
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

"Paylaşılıyor" evet, çünkü veri üçüncü tarafa (Google) gidiyor.

### Toplanmayanlar

Kişisel bilgi (isim, e-posta, telefon), finansal bilgi, sağlık bilgisi,
mesajlar, fotoğraf/video, ses, kişiler, takvim, dosyalar, arama geçmişi,
SMS — **hiçbiri toplanmıyor**.

## Reklam kimliği beyanı

Play Console ayrı olarak "Uygulamanız reklam kimliği kullanıyor mu?" diye
soruyor → **Evet**, reklamcılık amacıyla.

## Release izinleri (doğrulanmış)

Aşağıdakiler birleştirilmiş release manifest'inden okundu. Tamamı reklam
SDK'sından geliyor; oyunun kendisi hiçbir izin istemiyor.

```
android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
android.permission.WAKE_LOCK
android.permission.FOREGROUND_SERVICE
com.google.android.gms.permission.AD_ID
android.permission.ACCESS_ADSERVICES_AD_ID
android.permission.ACCESS_ADSERVICES_ATTRIBUTION
android.permission.ACCESS_ADSERVICES_TOPICS
```

## Gizlilik politikası

Play Console gizlilik politikasının **herkese açık bir URL'de** yayınlanmasını
şart koşuyor. `PRIVACY_POLICY.md` hazır ama bir yerde yayınlanması gerekiyor —
GitHub Pages, Google Sites ya da benzeri ücretsiz bir yer yeterli.
