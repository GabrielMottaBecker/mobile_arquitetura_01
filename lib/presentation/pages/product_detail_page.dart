import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/product.dart';
import '../viewmodels/product_viewmodel.dart';
import 'product_form_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isDeleting = false;
  bool _isLoadingDetail = false; 

  late Product _product;
  late ProductViewModel _vm;
  bool _argsLoaded = false;

  // ── Cores dos ícones de ação ─────────────────────────────────────
  static const _iconColor = Color(0xFF424242); // cinza escuro visível

  // ── Delete com confirmação ───────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja realmente remover "${_product.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final success = await _vm.deleteProduct(_product.id!);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto removido com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao remover produto.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Navegação para edição ────────────────────────────────────────

  Future<void> _goToEdit(BuildContext context) async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(viewModel: _vm, product: _product),
      ),
    );

    // Se o form retornou um Product atualizado, reflete na tela imediatamente
    if (result != null && mounted) {
      setState(() => _product = result);
    }
  }

  Future<void> _fetchProductDetail(int id) async {
    setState(() => _isLoadingDetail = true);
    try {
      final updated = await _vm.repository.getProductById(id);
      if (updated != null && mounted) {
        setState(() => _product = updated.copyWith(isFavorite: _product.isFavorite));
      }
    } catch (_) {
      // falha silenciosa — mantém o produto recebido via arguments
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Carrega os args apenas na primeira vez; depois usa o state local
    if (!_argsLoaded) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _product = args['product'] as Product;
      _vm = args['viewModel'] as ProductViewModel;
      _argsLoaded = true;

    // Chama GET /products/{id} para buscar dados atualizados da API
    if (_product.id != null) {
      _fetchProductDetail(_product.id!);
    }
}

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem expandida
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            // foregroundColor branco causava ícones invisíveis sobre fundo branco
            // → definimos cada ícone individualmente com _iconColor
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _iconColor),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Voltar',
            ),
            actions: [
              // Botão Editar
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: _iconColor),
                tooltip: 'Editar produto',
                onPressed: () => _goToEdit(context),
              ),
              // Botão Excluir
              _isDeleting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      tooltip: 'Excluir produto',
                      onPressed: () => _confirmDelete(context),
                    ),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: _iconColor),
                tooltip: 'Ir ao início',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (route) => false,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
                child: Image.network(
                  _product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria + badge de origem + Avaliação
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6A1B9A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _product.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge API / LOCAL
                      _OriginBadge(isLocal: _product.isLocal),
                      const Spacer(),
                      _RatingBadge(
                          rate: _product.ratingRate,
                          count: _product.ratingCount),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Título
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _product.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (_isLoadingDetail)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Preço
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Preço',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(
                          'R\$ ${_product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              label: 'Nota',
                              value:
                                  _product.ratingRate.toStringAsFixed(1),
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.people_outline,
                              iconColor: const Color(0xFF6A1B9A),
                              label: 'Avaliações',
                              value: _product.ratingCount.toString(),
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.tag,
                              iconColor: Colors.blueGrey,
                              label: 'ID',
                              value: '#${_product.id}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Descrição
                  const Text(
                    'Descrição',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _product.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produto adicionado ao carrinho! 🛒'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text(
                'Adicionar ao Carrinho',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge de origem na tela de detalhes ──────────────────────────────

class _OriginBadge extends StatelessWidget {
  final bool isLocal;
  const _OriginBadge({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    final label = isLocal ? 'LOCAL' : 'API';
    final icon = isLocal ? Icons.storage_rounded : Icons.cloud_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rate;
  final int count;
  const _RatingBadge({required this.rate, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            '$rate ($count)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label,
            style:
                const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}