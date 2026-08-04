# Play Console — Data Safety formu için cevaplar

Candy Match'in **release** derlemesi incelenerek çıkarıldı.

## Özet

Uygulama **hiçbir veri toplamıyor ve paylaşmıyor**. Reklam SDK'sı,
analitik, giriş sistemi ya da ağ erişimi yok. Release paketinin manifest'inde
Android'in normal izinlerinden **hiçbiri** bulunmuyor.

## Form cevapları

**Uygulamanız kullanıcı verisi topluyor veya paylaşıyor mu?** → **Hayır**

Bu cevabı verdiğinde form biter; veri türü tablosu açılmaz.

**Uygulamanız reklam kimliği kullanıyor mu?** → **Hayır**

## Cihazda kalan veriler

Şunlar yalnızca telefonda saklanıyor, hiçbir yere gönderilmiyor. Google bunları
"toplama" saymıyor çünkü cihazdan çıkmıyorlar:

- En yüksek puan
- Yarım kalan oyunun durumu ("Devam et" için)
- Bilgi ipucunun daha önce gösterilip gösterilmediği
- Sesin açık/kapalı olması

Uygulama silinince bunlar da silinir.

## Release izinleri (doğrulanmış)

Birleştirilmiş release manifest'inde yalnızca Android'in kendi ürettiği
şu iç izin var; kullanıcıya sorulmaz ve bir yetki vermez:

```
com.ozge.candy_match.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

İnternet izni bile yok — oyun tamamen çevrimdışı.

## Gizlilik politikası

Play Console gizlilik politikasının **herkese açık bir URL'de** yayınlanmasını
şart koşuyor. `PRIVACY_POLICY.md` hazır ama bir yerde yayınlanması gerekiyor.
