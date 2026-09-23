# İçerik filtresi testleri

Proje kökünden çalıştırın:

```sh
swiftc -swift-version 6 -module-cache-path /tmp/meydan-swift-cache \
  Meydan-IOS/Core/Validation/BlockedTerms.swift \
  Meydan-IOS/Core/Validation/ContentFilter.swift \
  Tests/ContentFilterTests.swift -o /tmp/meydan-content-filter-tests
/tmp/meydan-content-filter-tests
```

Testler DOCX'ten alınan 1.039 girdinin tamamını, Türkçe büyük/küçük harfleri,
noktalama işaretlerini, çok satırlı ifadeleri, görünmez karakterleri ve normal
kelimelerin içindeki kısa eşleşmelerin engellenmemesini kontrol eder.

Filtre gönderme/kaydetme sırasında çalışır. Liste girdileri tam kelime/ifade
olarak değerlendirilir; kök, ek veya bağlam analizi yapılmaz. Türkçe harfler
korunur: “şık” ile “sik” aynı sayılmaz. Belgedeki noktalama işaretleri joker
karakter değildir. Şifre, e-posta, doğrulama kodu ve arama alanları içerik
filtresine dahil değildir. Bu kontroller iOS istemcisinde uygulanır.
