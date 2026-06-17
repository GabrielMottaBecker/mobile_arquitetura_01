import '../../auth/session/session_controller.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/entities/product.dart';
import '../viewmodels/product_state.dart';
import '../viewmodels/product_viewmodel.dart';
import 'product_form_page.dart';

class ProductPage extends StatefulWidget {
  final ProductViewModel viewModel;

  const ProductPage({super.key, required this.viewModel});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProducts();
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(viewModel: widget.viewModel),
      ),
    );
  }

  Future<void> _syncProducts() async {
    await widget.viewModel.syncProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista sincronizada com a API!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Recarrega os produtos manualmente (botão refresh).
  Future<void> _refreshProducts() async {
    await widget.viewModel.loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produtos atualizados!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Encerra a sessão e volta para o login.
  Future<void> _logout() async {
    await SessionController.instance.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Produtos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // sem botão voltar (sessão ativa)
        actions: [
          // Avatar + nome do usuário → abre perfil
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Builder(builder: (_) {
                    final user = SessionController.instance.user;
                    if (user == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          backgroundImage: user.image.isNotEmpty
                              ? NetworkImage(user.image)
                              : null,
                          child: user.image.isEmpty
                              ? const Icon(Icons.person,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(user.firstName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          // Filtro favoritos
          ValueListenableBuilder<ProductState>(
            valueListenable: widget.viewModel.state,
            builder: (_, state, __) {
              final isFiltering = state.showOnlyFavorites;
              return IconButton(
                icon: Icon(
                  isFiltering ? Icons.favorite : Icons.favorite_border,
                  color: isFiltering ? Colors.pinkAccent : Colors.white,
                ),
                tooltip: isFiltering ? 'Mostrar todos' : 'Só favoritos',
                onPressed: widget.viewModel.toggleFavoriteFilter,
              );
            },
          ),
          // Sincronizar
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Sincronizar com API',
            onPressed: _syncProducts,
          ),
          // Refresh manual
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar lista',
            onPressed: _refreshProducts,
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
        tooltip: 'Cadastrar produto',
      ),
      body: ValueListenableBuilder<ProductState>(
        valueListenable: widget.viewModel.state,
        builder: (context, state, _) {
          switch (state.status) {
            case ProductStatus.initial:
              return const Center(child: Text('Inicializando...'));

            case ProductStatus.loading:
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                    SizedBox(height: 16),
                    Text('Buscando produtos...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );

            case ProductStatus.unauthorized:
              // Executa logout e redireciona — usando addPostFrameCallback
              // para não chamar Navigator durante o build
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await SessionController.instance.logout();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sessão expirada. Faça login novamente.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false,
                );
              });
              return const Center(child: CircularProgressIndicator());

            case ProductStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_outlined,
                          size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Não foi possível carregar os produtos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'Erro desconhecido.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.viewModel.loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.home, (route) => false),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Voltar ao início'),
                      ),
                    ],
                  ),
                ),
              );

            case ProductStatus.success:
              if (state.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum produto encontrado.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar produto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Contadores para o cabeçalho
              final totalApi =
                  state.products.where((p) => !p.isLocal).length;
              final totalLocal =
                  state.products.where((p) => p.isLocal).length;
              final favoriteCount = state.favoriteCount;
              final visibleProducts = state.visibleProducts;

              return Column(
                children: [
                  // Cabeçalho com contadores
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF6A1B9A).withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          state.showOnlyFavorites
                              ? '$favoriteCount favorito${favoriteCount != 1 ? 's' : ''}'
                              : '${state.products.length} produtos',
                          style: const TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (favoriteCount > 0)
                          _OriginChip(
                            label: '★ $favoriteCount',
                            color: Colors.pinkAccent,
                          ),
                        if (favoriteCount > 0) const SizedBox(width: 6),
                        _OriginChip(
                          label: 'API $totalApi',
                          color: const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 6),
                        _OriginChip(
                          label: 'LOCAL $totalLocal',
                          color: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                  // Aviso quando o filtro está ativo mas não há favoritos
                  if (state.showOnlyFavorites && visibleProducts.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Nenhum favorito ainda.',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: widget.viewModel.toggleFavoriteFilter,
                              icon: const Icon(Icons.list),
                              label: const Text('Ver todos os produtos'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: visibleProducts.length,
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          return _ProductCard(
                            product: product,
                            viewModel: widget.viewModel,
                          );
                        },
                      ),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}

// ── Badge de contagem no cabeçalho ───────────────────────────────────

class _OriginChip extends StatelessWidget {
  final String label;
  final Color color;
  const _OriginChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── Card de produto ──────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final ProductViewModel viewModel;
  const _ProductCard({required this.product, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: product.isFavorite ? 4 : 2,
      color: product.isFavorite ? Colors.pink.shade50 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: {
              'product': product,
              'viewModel': viewModel,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagem
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + badge de origem
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SourceBadge(isLocal: product.isLocal),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'R\$ ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          product.ratingRate.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Botão de favorito
              IconButton(
                icon: Icon(
                  product.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: product.isFavorite ? Colors.pinkAccent : Colors.grey,
                ),
                tooltip: product.isFavorite
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                onPressed: () => viewModel.toggleFavorite(product.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge API / LOCAL no card ────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final bool isLocal;
  const _SourceBadge({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    final label = isLocal ? 'LOCAL' : 'API';
    final icon = isLocal ? Icons.storage_rounded : Icons.cloud_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
