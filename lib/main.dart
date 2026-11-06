import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color cream = Color(0xFFFFF9F2);
const Color pink = Color(0xFFF6DCE5);
const Color lavender = Color(0xFFE7DDF8);
const Color mint = Color(0xFFDDF1E7);
const Color brown = Color(0xFF574653);
const Color muted = Color(0xFF958590);
const Color danger = Color(0xFFC0566B);

const String apiBase = 'http://192.168.100.74/api/products.php';


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

Future<bool?> confirmDelete(BuildContext context, String title) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cream,
      title: const Text(
        'Hapus produk?',
        style: TextStyle(color: brown, fontWeight: FontWeight.w800),
      ),
      content: Text(
        '"$title" akan dihapus dari koleksi.',
        style: const TextStyle(color: muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal', style: TextStyle(color: brown)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
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
      Uri.parse('$apiBase?action=categories'),
    );

    if (response.statusCode == 200 && mounted) {
      setState(() {
        categories = List<String>.from(jsonDecode(response.body));
      });
    }
  } catch (_) {
    // Kategori opsional
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

    if (search.trim().isNotEmpty) {
      selectedCategory = '';
    }
  });

  try {
    final params = <String, String>{};

    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    } else if (selectedCategory.isNotEmpty) {
      params['category'] = selectedCategory;
    }

    final uri = Uri.parse(apiBase).replace(
      queryParameters: params.isEmpty ? null : params,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil produk');
    }

    final data = jsonDecode(response.body);
    final fetched = List<Map<String, dynamic>>.from(
      (data['products'] as List).map((item) {
        final p = Map<String, dynamic>.from(item);
        p['price'] = num.tryParse(p['price'].toString()) ?? 0;
        p['stock'] = int.tryParse(p['stock'].toString()) ?? 0;
        p['id'] = int.tryParse(p['id'].toString()) ?? p['id'];
        return p;
      }),
    );

    if (!mounted) return;

    setState(() {
      products = fetched;
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loading = false;
      error = 'Tidak dapat memuat produk. Periksa koneksi backend.';
    });
  }
}


  // ===================== CRUD =====================

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: brown,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// CREATE (product == null) atau UPDATE (product != null).
  /// Mengembalikan produk hasil simpan, atau null jika dibatalkan.
  Future<Map<String, dynamic>?> _openForm([dynamic product]) async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (_) => ProductFormPage(
        product: product,
        categories: categories,
      ),
    ),
  );

  if (result == null || !mounted) return null;

  await fetchCategories();
  await fetchProducts(search: query);

  if (product == null) {
    _snack('Produk berhasil ditambahkan ♡');
  } else {
    _snack('Produk berhasil diperbarui ♡');
  }

  return result;
}

  /// DELETE. Mengembalikan true jika berhasil dihapus.
  Future<bool> _deleteProduct(dynamic product) async {
  final id = product['id'];

  try {
    final uri = Uri.parse(apiBase).replace(
      queryParameters: {'id': id.toString()},
    );

    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus produk');
    }

    if (!mounted) return false;

    await fetchProducts(search: query);

    _snack('Produk berhasil dihapus ♡');
    return true;
  } catch (e) {
    if (!mounted) return false;

    _snack('Gagal menghapus produk');
    return false;
  }
}

  void _openDetail(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          onEdit: _openForm,
          onDelete: _deleteProduct,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFD9B8CF),
        foregroundColor: brown,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add product',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
                                16, 0, 16, 90,
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
                                  key: ValueKey(product['id']),
                                  product: product,
                                  index: index,
                                  onTap: () => _openDetail(product),
                                  onEdit: () => _openForm(product),
                                  onDelete: () => _deleteProduct(product),
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
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                color: colors[index % colors.length],
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
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
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Options',
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: brown,
                          ),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 18, color: brown),
                                  SizedBox(width: 8),
                                  Text('Edit',
                                      style: TextStyle(color: brown)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: danger),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

class ProductDetailPage extends StatefulWidget {
  final dynamic product;
  final Future<Map<String, dynamic>?> Function(dynamic product) onEdit;
  final Future<bool> Function(dynamic product) onDelete;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late dynamic product = widget.product;

  Future<void> _edit() async {
    final updated = await widget.onEdit(product);
    if (updated != null && mounted) {
      setState(() => product = updated);
    }
  }

  Future<void> _delete() async {
    final deleted = await widget.onDelete(product);
    if (deleted && mounted) Navigator.pop(context);
  }

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
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: danger),
            onPressed: _delete,
          ),
        ],
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
                (product['description']?.toString().isNotEmpty ?? false)
                    ? product['description'].toString()
                    : 'No description available.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: muted,
                ),
              ),
              const SizedBox(height: 24),
              if (product['brand'] != null &&
                  product['brand'].toString().isNotEmpty)
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brown,
                        side: const BorderSide(color: Color(0xFFD9B8CF)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        'Edit',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: danger,
                        side: const BorderSide(color: danger),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

/// Form untuk CREATE (product == null) dan UPDATE (product != null).
/// Pop dengan Map produk hasil simpan, atau null jika dibatalkan.
class ProductFormPage extends StatefulWidget {
  final dynamic product;
  final List<String> categories;

  const ProductFormPage({
  super.key,
  this.product,
  required this.categories,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool saving = false;

  bool get isEdit => widget.product != null;

  late final TextEditingController titleC;
  late final TextEditingController priceC;
  late final TextEditingController stockC;
  late final TextEditingController brandC;
  late final TextEditingController descC;
  late final TextEditingController imageC;
  late final TextEditingController categoryC; // dipakai jika daftar kategori kosong
  String? category;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    titleC = TextEditingController(text: p?['title']?.toString() ?? '');
    priceC = TextEditingController(text: p?['price']?.toString() ?? '');
    stockC = TextEditingController(text: p?['stock']?.toString() ?? '');
    brandC = TextEditingController(text: p?['brand']?.toString() ?? '');
    descC = TextEditingController(text: p?['description']?.toString() ?? '');
    imageC = TextEditingController(text: p?['thumbnail']?.toString() ?? '');
    categoryC = TextEditingController(text: p?['category']?.toString() ?? '');
    category = p?['category']?.toString();
  }

  @override
  void dispose() {
    titleC.dispose();
    priceC.dispose();
    stockC.dispose();
    brandC.dispose();
    descC.dispose();
    imageC.dispose();
    categoryC.dispose();
    super.dispose();
  }

  String _format(String slug) => slug
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: danger),
      ),
    );
  }

  Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  final selectedCategory = widget.categories.isNotEmpty
      ? (category ?? '')
      : categoryC.text.trim();

  final body = <String, dynamic>{
    'title': titleC.text.trim(),
    'price': double.parse(priceC.text.trim().replaceAll(',', '.')),
    'stock': int.parse(stockC.text.trim()),
    'category': selectedCategory,
    'brand': brandC.text.trim(),
    'description': descC.text.trim(),
    'thumbnail': imageC.text.trim(),
  };

  setState(() => saving = true);

  try {
    final headers = {'Content-Type': 'application/json'};
    late final http.Response res;

    if (!isEdit) {
      // CREATE
      res = await http.post(
        Uri.parse(apiBase),
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode != 201) {
        throw Exception('Gagal menambah produk');
      }
    } else {
      // UPDATE
      final original = Map<String, dynamic>.from(widget.product);

      final uri = Uri.parse(apiBase).replace(
        queryParameters: {'id': original['id'].toString()},
      );

      res = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception('Gagal memperbarui produk');
      }
    }

    final result = Map<String, dynamic>.from(jsonDecode(res.body));

    result['id'] = int.tryParse(result['id'].toString()) ?? result['id'];
    result['price'] = num.tryParse(result['price'].toString()) ?? 0;
    result['stock'] = int.tryParse(result['stock'].toString()) ?? 0;

    if (!mounted) return;
    Navigator.pop(context, result);
  } catch (e) {
    if (!mounted) return;
    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal menyimpan. Periksa koneksi backend.'),
        backgroundColor: brown,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final cats = [...widget.categories];
    if (category != null && category!.isNotEmpty && !cats.contains(category)) {
      cats.add(category!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit product' : 'Add product',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              TextFormField(
                controller: titleC,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceC,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Price (\$)'),
                      validator: (v) {
                        final n =
                            double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                        if (n == null) return 'Angka tidak valid';
                        if (n < 0) return 'Tidak boleh negatif';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: stockC,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Stock'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null) return 'Angka tidak valid';
                        if (n < 0) return 'Tidak boleh negatif';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (cats.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: _dec('Category'),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              _format(c),
                              style: const TextStyle(color: brown),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => category = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Pilih kategori' : null,
                )
              else
                TextFormField(
                  controller: categoryC,
                  decoration: _dec('Category', hint: 'mis. beauty'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kategori wajib diisi'
                      : null,
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: brandC,
                decoration: _dec('Brand (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: imageC,
                keyboardType: TextInputType.url,
                decoration: _dec('Image URL (optional)', hint: 'https://...'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descC,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Description'),
              ),
              const SizedBox(height: 24),
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
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: brown,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    isEdit ? 'Save changes' : 'Add to collection',
                    style: const TextStyle(fontWeight: FontWeight.w800),
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