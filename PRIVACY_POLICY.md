# Candy Match — Gizlilik Politikası

**Son güncelleme:** 5 Ağustos 2026
**Geliştirici:** Blue Labs Games
**İletişim:** bluelabsgames@gmail.com

## Özet

Oyunun kendisi sizden hiçbir bilgi istemez ve hiçbir bilgi toplamaz. Hesap
açmanız gerekmez, isim ya da e-posta sorulmaz, analiz (analytics) aracı
kullanılmaz.

Oyunda **isteğe bağlı ödüllü reklamlar** vardır. Reklamları Google AdMob
gösterir ve AdMob kendi verilerini toplar; aşağıdaki bölüm bunu açıklar.
Reklam izlemediğiniz sürece oyun oynanırken veri gönderilmez.

## Toplanan veriler

**Hiçbiri.** Uygulama şunları toplamaz:

- Ad, e-posta, telefon numarası veya başka kimlik bilgisi
- Konum bilgisi
- Kişiler, fotoğraflar, dosyalar, takvim veya mikrofon/kamera verisi
- Cihaz kimliği, reklam kimliği (advertising ID) veya benzeri tanımlayıcılar
- Kullanım/analiz verisi, çökme raporu
- Ödeme veya finansal bilgi

## Cihazınızda saklanan bilgiler

Oyunun ilerlemesini hatırlayabilmesi için **yalnızca cihazınızın kendi
belleğinde** üç bilgi tutulur:

| Saklanan | İçeriği |
|---|---|
| En yüksek skor | Bir sayı |
| Yarım kalan oyun | Tahtadaki şekerlerin dizilimi, skor, hamle sayısı, seviye |
| İpucu gösterildi mi | Evet/hayır bilgisi |

Bu bilgiler:

- Uygulamanın kendi özel alanında (Android `SharedPreferences`) tutulur,
- **Hiçbir sunucuya gönderilmez**, başka uygulamalarla paylaşılmaz,
- Uygulamayı kaldırdığınızda ya da Ayarlar → Uygulamalar → Candy Match →
  Depolama → Verileri temizle dediğinizde tamamen silinir.

Bunlar kişisel veri değildir ve sizi tanımlamaz.

## İzinler

Uygulamanın istediği izinlerin tamamı reklam SDK'sından gelir:

| İzin | Ne için |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Reklamı indirmek ve bağlantıyı kontrol etmek |
| `AD_ID`, `ACCESS_ADSERVICES_*` | Reklam kimliği ve Android'in reklam ölçüm API'leri |
| `WAKE_LOCK`, `FOREGROUND_SERVICE` | Reklam videosu oynarken ekranın kapanmaması |

Oyunun kendisi hiçbir izin istemez: kameraya, mikrofona, rehbere, konuma ya da
dosyalarınıza erişmez.

## Analiz

Uygulamada analiz (analytics) aracı ya da takip teknolojisi yoktur. Üçüncü
taraflarla tek veri paylaşımı yukarıda anlatılan reklam SDK'sı üzerindendir.

## Üçüncü taraf bileşenler

Oyun açık kaynaklı Flutter ve Flame kütüphaneleriyle geliştirilmiştir. Ses
efektleri sıfırdan sentezlenmiştir; dışarıdan indirilen içerik kullanılmaz.
Kullanılan kütüphanelerin hiçbiri veri toplamaz.

## Çocukların gizliliği

Uygulama hiç kimseden, çocuklar dahil, veri toplamaz. 13 yaş altı
kullanıcılardan bilerek veri toplanmaz çünkü hiçbir kullanıcıdan veri
toplanmaz.

## Bu politikadaki değişiklikler

Politika değişirse bu sayfa güncellenir ve yukarıdaki "Son güncelleme" tarihi
değiştirilir.

## İletişim

Sorularınız için: **bluelabsgames@gmail.com**
