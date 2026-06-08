# 🎴 Card Clash - 1v1 Split-Screen Kart Eşleştirme Oyunu

Godot 4.6 ile geliştirilmiş, iki oyuncunun aynı klavye üzerinden yerel (local) olarak rekabet ettiği, modern estetik tasarıma ve yenilikçi prosedürel ses teknolojisine sahip dinamik bir kart eşleştirme ve refleks oyunudur.

---

## 🚀 Öne Çıkan Özellikler

### 1. Oyun Modları
*   **Klasik Mod (Classic Mode):**
    *   Her oyuncunun kendi ekran yarısında (split-screen) bağımsız kart desteleri bulunur.
    *   2 saniyelik başlangıç ezberleme süresinden sonra kartlar kapanır.
    *   Klasik hafıza oyunu kuralları geçerlidir: Aynı sembole sahip kartlar eşleştirilir.
    *   Seviye ilerledikçe kart sayısı artar (12, 16, 20 kart). Seviye 3'te kart yerleri zamanla kayar (shift).
*   **Refleks Modu (Reflex Mode):**
    *   Ortak bir alanda 40 adet açık kart (8x5 boyutunda) yer alır.
    *   Ekranın üst kısmında rastgele bir hedef sembol gösterilir.
    *   Oyuncular kendi imleçleriyle bu hedef sembolü en hızlı şekilde bulmaya çalışır.
    *   Yanlış seçim yapan oyuncu 1.5 saniye donma cezası alır.
    *   **Seviye 2 (Monokrom):** Tüm renkler kaybolur, oyuncuların sadece şekil geometrisine odaklanması gerekir.
    *   **Seviye 3 (Hafıza Refleksi):** 3 adet hedef sembol 3 saniyeliğine gösterilir ve ardından gizlenir. Oyuncuların bu sembolleri 10 saniye içinde hatırlayıp bulması gerekir.
    *   Her doğru eşleşmede tüm kartlar yeniden karıştırılarak (shuffle) heyecan üst düzeyde tutulur.

### 2. Premium Prosedürel Görsel Tasarım
*   **Çizimler (Kod Tabanlı):** Harici resim dosyaları yerine, 30 farklı geometrik şekil (kalp, yıldız, hilal, kalkan, dişli vb.) Godot'nun 2D çizim motoru (`_draw()`) aracılığıyla dinamik olarak üretilir.
*   **Neon Göstergeler:** Oyuncuların imleçleri neon parlamalara sahiptir (Oyuncu 1 için Orchid Moru, Oyuncu 2 için Elektrik Sarısı).
*   **Akıcı Animasyonlar:** Kart çevirme esnasında 3D hissi veren ölçekleme tween'leri, eşleşen kartların yukarı uçarak sönmesi ve skor baloncuğu tepkileri.

### 3. Prosedürel Ses Sentezleyici (`AudioManager.gd`)
Projemiz **hiçbir harici ses dosyası (.mp3, .wav) kullanmaz**. Tüm müzikler ve ses efektleri, matematiksel formüller ve algoritmalar kullanılarak çalışma zamanında (runtime) sentezlenir:
*   **Karplus-Strong Yay Sentezi:** Akustik gitar tellerinin tınlamasını simüle eder.
*   **Rhodes Klasik Piyano Sentezi:** Arka plan müziklerindeki sıcak akorları oluşturur.
*   **Analog Ritimler:** Davul, kick ve hi-hat sesleri frekans kaydırma yöntemiyle üretilir.
*   Doğru hamle (tahta blok sesi), hatalı hamle (tok vuruş), kombo (arp yükselişi) ve şampiyonluk kutlaması için ayrı prosedürel ses efektleri bulunur.

---

## 🎮 Kontroller

Oyun, tek bir klavye üzerinden iki oyuncunun rahatça oynaması için optimize edilmiştir:

| Eylem | 🟣 Oyuncu 1 (Sol Ekran) | 🟡 Oyuncu 2 (Sağ Ekran) |
| :--- | :--- | :--- |
| **Gezinme (Yukarı/Aşağı/Sol/Sağ)** | `W` / `S` / `A` / `D` | `↑` / `↓` / `←` / `→` |
| **Kart Seç / Çevir** | `Boşluk (Space)` | `Giriş (Enter)` |

---

## 📂 Dosya Yapısı

*   📁 [addons/godot_ai/](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/addons/godot_ai/) - Editör içi yapay zeka yardımcı araçları ve MCP entegrasyonu.
*   📄 [Card.gd](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/Card.gd) - Kart nesnesinin davranışlarını, 3D çevrilme animasyonunu ve prosedürel çizim kodlarını barındırır.
*   📄 [Game.gd](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/Game.gd) - Skor takibi, seviye geçişleri, oyun modları ve klavye gezinme lojistiklerini yöneten ana oyun döngüsü.
*   📄 [GameUI.gd](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/GameUI.gd) - Ana menü, isim giriş ekranı, skor balonları, kombo göstergeleri, turnuva sonu paneli ve ses seviyesi ayarlarını içeren UI kontrolcüsü.
*   📄 [AudioManager.gd](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/AudioManager.gd) - Matematiksel ses sentezleme motoru ve ses yönetimi.
*   📄 [project.godot](file:///c:/Users/merve/Dosyalar/godot/yeni-oyun-projesi/project.godot) - Godot proje ayarları ve autoload tanımlamaları.

---

## 🛠️ Kurulum ve Çalıştırma

1.  Bilgisayarınızda **Godot Engine 4.6** veya üzeri bir sürümün kurulu olduğundan emin olun.
2.  Bu projeyi yerel bilgisayarınıza klonlayın veya indirin.
3.  Godot Engine'i açın ve **"Import" (İçe Aktar)** seçeneğiyle `project.godot` dosyasını seçin.
4.  Projeyi editörde açtıktan sonra **F5** tuşuna basarak oyunu başlatabilirsiniz.
