import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color cream = Color(0xFFFFF9F2);
const Color pink = Color(0xFFF6DCE5);
const Color lavender = Color(0xFFE7DDF8);
const Color mint = Color(0xFFDDF1E7);
const Color brown = Color(0xFF574653);
const Color muted = Color(0xFF958590);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoonCéra',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD6A9C0),
          surface: cream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: brown,
          elevation: 0,
        ),
      ),
      home: const ProductHomePage(),
    );
  }
}

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({super.key});

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  List<dynamic> products = [];
  bool loading = true;
  String error = '';
  String query = '';

  List<String> categories = [];
  String selectedCategory = '';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://dummyjson.com/products/category-list'),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          categories = List<String>.from(jsonDecode(response.body));
        });
      }
    } catch (_) {
      // kategori opsional, abaikan kalau gagal
    }
  }

  void selectCategory(String category) {
    searchController.clear();
    query = '';
    setState(() => selectedCategory = category);
    fetchProducts();
  }

  String formatCategory(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> fetchProducts({String search = ''}) async {
    setState(() {
      loading = true;
      error = '';
      // kalau lagi search, reset kategori ke All
      if (search.trim().isNotEmpty) selectedCategory = '';
    });

    try {
      final Uri uri;
      if (search.trim().isNotEmpty) {
        uri = Uri.https(
          'dummyjson.com',
          '/products/search',
          {'q': search.trim()},
        );
      } else if (selectedCategory.isNotEmpty) {
        uri = Uri.parse(
          'https://dummyjson.com/products/category/$selectedCategory?limit=0',
        );
      } else {
        uri = Uri.parse('https://dummyjson.com/products?limit=0');
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;

        setState(() {
          products = List<dynamic>.from(data['products']);
          loading = false;
        });
      } else {
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Tidak dapat memuat produk. Periksa koneksi internet.';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MoonCeraLogo(size: 38),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MoonCéra',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: brown,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'The Art of Curated Living.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'serif',
                                fontFamilyFallback: [
                                  'Georgia',
                                  'Times New Roman',
                                  'serif',
                                ],
                                letterSpacing: 0.8,
                                color: Color(0xFFA6845C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: brown,
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      query = value;
                    },
                    onSubmitted: (value) {
                      query = value;
                      fetchProducts(search: value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search your favorites...',
                      hintStyle: const TextStyle(color: muted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: brown,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: brown,
                        ),
                        onPressed: () {
                          query = searchController.text;
                          fetchProducts(search: query);
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final value = i == 0 ? '' : categories[i - 1];
                        final label = i == 0 ? 'All' : formatCategory(value);
                        final selected = selectedCategory == value;

                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => selectCategory(value),
                          selectedColor: pink,
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(
                            color: brown,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lovely finds',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: brown,
                          ),
                        ),
                      ),
                      if (!loading)
                        Text(
                          '${products.length} products',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD6A9C0),
                      ),
                    )
                  : error.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  size: 48,
                                  color: muted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: brown),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () =>
                                      fetchProducts(search: query),
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : products.isEmpty
                          ? const Center(
                              child: Text(
                                'Produk tidak ditemukan ♡',
                                style: TextStyle(color: brown),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 20,
                              ),
                              itemCount: products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 13,
                                mainAxisSpacing: 13,
                                childAspectRatio: 0.55,
                              ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ProductCard(
                                  product: product,
                                  index: index,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo MoonCéra: bulan sabit + bintang berkilau, emas gradasi.
/// Digambar dengan CustomPaint, tanpa gambar/asset.
class MoonCeraLogo extends StatelessWidget {
  final double size;

  const MoonCeraLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE3C998), Color(0xFFB08A58), Color(0xFF8F6B3F)],
      ).createShader(bounds),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _MoonPainter()),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white; // putih supaya gradient tampil

    // Bulan sabit = lingkaran besar dikurangi lingkaran yang digeser
    final r = size.width * 0.42;
    final c = Offset(size.width * 0.46, size.height * 0.54);
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final cut = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(c.dx + r * 0.58, c.dy - r * 0.28),
        radius: r * 0.82,
      ));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, cut), paint);

    // Bintang 4 sudut di dalam lekukan bulan
    final sc = Offset(size.width * 0.76, size.height * 0.30);
    final s = size.width * 0.14;
    final star = Path()
      ..moveTo(sc.dx, sc.dy - s)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx + s, sc.dy)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx, sc.dy + s)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx - s, sc.dy)
      ..quadraticBezierTo(sc.dx, sc.dy, sc.dx, sc.dy - s)
      ..close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [pink, lavender, mint, const Color(0xFFF8EACD)];
    final imageUrl = product['thumbnail']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                color: colors[index % colors.length],
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: muted,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['category'] ?? 'product')
                          .toString()
                          .replaceAll('-', ' ')
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        product['title']?.toString() ?? 'Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: brown,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFE5AE55),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${product['rating'] ?? '-'}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\$${(product['price'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: brown,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final dynamic product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['thumbnail']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(24),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 60,
                    color: muted,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: pink,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  (product['category'] ?? 'product')
                      .toString()
                      .replaceAll('-', ' ')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: brown,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                product['title']?.toString() ?? 'Product',
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFE5AE55),
                    size: 22,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${product['rating'] ?? '-'} / 5',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: brown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: muted,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Stock: ${product['stock'] ?? '-'}',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '\$${(product['price'] as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'About this item ♡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                product['description']?.toString() ??
                    'No description available.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: muted,
                ),
              ),
              const SizedBox(height: 24),
              if (product['brand'] != null)
                _DetailInfo(
                  label: 'Brand',
                  value: product['brand'].toString(),
                ),
              if (product['availabilityStatus'] != null)
                _DetailInfo(
                  label: 'Availability',
                  value: product['availabilityStatus'].toString(),
                ),
              if (product['warrantyInformation'] != null)
                _DetailInfo(
                  label: 'Warranty',
                  value: product['warrantyInformation'].toString(),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD9B8CF),
                    foregroundColor: brown,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    'Back to collection',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  final String label;
  final String value;

  const _DetailInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: brown,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}