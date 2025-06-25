# 🌱 Field AR Mobile – Tarımda Artırılmış Gerçeklik Uygulaması

Bu proje, uydu görüntülerini artırılmış gerçeklik ortamında tarım arazilerine yansıtan ve su stresi tahminleriyle üreticilere erken uyarılar sunan bir **Flutter tabanlı mobil uygulamadır**.

> ⚠️ **Uyarı:** Bu uygulamanın düzgün çalışabilmesi için hem mobil hem de backend projeleri birlikte çalıştırılmalıdır.

## 🔗 Bağlantılı Projeler

- 🔧 Backend: [field-ar-backend](https://github.com/yunusefeyilmaz/field-ar-backend)
- 📱 Backend tahmin modeli: [field-ar-machine-learning](https://github.com/yunusefeyilmaz/field-ar-machine-learning)

---

## 🚀 Özellikler

- 📡 Uydu görüntülerinin alınması ve analiz edilmesi  
- 🧠 Su stresi seviyelerinin tahmini  
- 📱 Artırılmış gerçeklik (AR) ile tarla görselleştirme  
- 🔐 JWT ile kullanıcı kimlik doğrulama  
- 🌍 Gerçek zamanlı uyarı sistemi

---

## 🛠️ Kurulum Adımları

### 1. Backend'i Başlat

Backend servislerini çalıştırmak için şu repoları kurup başlatmalısın:  
➡️ [field-ar-backend](https://github.com/yunusefeyilmaz/field-ar-backend)
➡️ [field-ar-machine-learning](https://github.com/yunusefeyilmaz/field-ar-machine-learning)

Ayrıntılı talimatlar ilgili repoda yer almaktadır.

### 2. Mobil Uygulamayı Çalıştır

```bash
git clone https://github.com/yunusefeyilmaz/field-ar-mobile.git
cd field-ar-mobile
flutter pub get
```
### 3. Backend URL'ini Tanımla
Backend'e bağlanabilmek için aşağıdaki dosyada API adresini kendi sunucuna göre düzenlemelisin:

```bash
/lib/core/constants/app_constants.dart
```
```bash
static final String baseUrl = "http://<YOUR_BACKEND_IP>:<PORT>";
```
Örnek:
```bash
static final String baseUrl = "http://192.168.1.100:8080";
```

### 4. Uygulamayı Başlat
```bash
flutter run
```

### 🖼️ Artırılmış Gerçeklik Özelliği
Uygulama, tarla verilerini aldıktan sonra, AR modülü üzerinden bu verileri cihaz kamerası üzerine 3D olarak yansıtır.
Su stresi seviyeleri görsel olarak kodlanır ve kullanıcıya görselleştirme ile sunulur.
